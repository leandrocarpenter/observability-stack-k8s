#!/bin/bash

set -e

echo "Setting up Kubernetes Observability Stack..."

# Colors for output formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

skip() {
    echo -e "${BLUE}[SKIP]${NC} $1"
}

# Verify Kind cluster is running
if ! kubectl cluster-info --context kind-observability &> /dev/null; then
    error "Kind cluster 'observability' not found!"
    echo "Run: kind create cluster --config=kind-config.yaml --name=observability"
    exit 1
fi

log "Kind cluster verified successfully"

# Check if Helm repositories are already added
check_helm_repo() {
    helm repo list 2>/dev/null | grep -q "$1" && return 0 || return 1
}

# Add Helm repositories with cache check
log "Checking Helm repositories..."
REPOS_ADDED=false

if ! check_helm_repo "prometheus-community"; then
    log "Adding prometheus-community repository..."
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    REPOS_ADDED=true
else
    skip "prometheus-community repository already exists"
fi

if ! check_helm_repo "grafana"; then
    log "Adding grafana repository..."
    helm repo add grafana https://grafana.github.io/helm-charts
    REPOS_ADDED=true
else
    skip "grafana repository already exists"
fi

if ! check_helm_repo "jaegertracing"; then
    log "Adding jaegertracing repository..."
    helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
    REPOS_ADDED=true
else
    skip "jaegertracing repository already exists"
fi

# Only update repos if new ones were added or if update is forced
if [ "$REPOS_ADDED" = true ] || [ "$FORCE_UPDATE" = true ]; then
    log "Updating Helm repositories..."
    helm repo update --timeout=30s
else
    skip "Helm repository update (use FORCE_UPDATE=true to force)"
fi

# Create observability namespace
if kubectl get namespace observability &> /dev/null; then
    skip "Namespace 'observability' already exists"
else
    log "Creating 'observability' namespace..."
    kubectl create namespace observability
fi

# Check if Prometheus Stack is already installed and running
check_helm_release() {
    helm list -n observability 2>/dev/null | grep -q "^$1" && return 0 || return 1
}

check_pods_ready() {
    local selector="$1"
    local namespace="$2"
    kubectl get pods -n "$namespace" -l "$selector" --no-headers 2>/dev/null | awk '{print $3}' | grep -v "Running\|Completed" &> /dev/null && return 1 || return 0
}

# Install Prometheus Stack with optimization
if check_helm_release "prometheus-stack" && check_pods_ready "app.kubernetes.io/part-of=kube-prometheus-stack" "observability"; then
    skip "Prometheus Stack already installed and healthy"
else
    log "Installing/Upgrading Prometheus Stack..."
    helm upgrade --install prometheus-stack prometheus-community/kube-prometheus-stack \
        --namespace observability \
        --set prometheus.service.type=NodePort \
        --set prometheus.service.nodePort=30900 \
        --set grafana.service.type=NodePort \
        --set grafana.service.nodePort=30300 \
        --set alertmanager.service.type=NodePort \
        --set alertmanager.service.nodePort=30903 \
        --set grafana.adminPassword=admin \
        --wait --timeout=300s \
        --atomic
fi

# Install Jaeger with optimization
if check_helm_release "jaeger" && check_pods_ready "app.kubernetes.io/name=jaeger" "observability"; then
    skip "Jaeger already installed and healthy"
else
    log "Installing/Upgrading Jaeger..."
    helm upgrade --install jaeger jaegertracing/jaeger \
        --namespace observability \
        --set query.service.type=NodePort \
        --set query.service.nodePort=31686 \
        --set storage.type=memory \
        --set agent.daemonset.useHostPort=false \
        --wait --timeout=180s \
        --atomic
fi

# Quick pod readiness check with timeout
log "Checking pod readiness..."
READY_COUNT=0
MAX_ATTEMPTS=30
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    NOT_READY=$(kubectl get pods -n observability --no-headers 2>/dev/null | grep -v "Running\|Completed" | wc -l)
    if [ "$NOT_READY" -eq 0 ]; then
        log "All pods are ready"
        break
    fi
    
    ATTEMPT=$((ATTEMPT + 1))
    if [ $((ATTEMPT % 10)) -eq 0 ]; then
        log "Still waiting... ($NOT_READY pods not ready, attempt $ATTEMPT/$MAX_ATTEMPTS)"
    fi
    sleep 2
done

if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
    warn "Timeout waiting for all pods to be ready, but continuing..."
fi

# Apply custom dashboards
if [ -d "dashboards" ] && [ "$(ls -A dashboards 2>/dev/null)" ]; then
    log "Applying custom dashboards..."
    kubectl apply -f dashboards/ -n observability
else
    skip "No custom dashboards found"
fi

# Deploy sample application
if [ -d "examples" ] && [ "$(ls -A examples 2>/dev/null)" ]; then
    log "Deploying sample application..."
    kubectl apply -f examples/
else
    skip "No sample applications found"
fi

echo ""
log "Observability Stack setup completed"
echo ""
echo -e "${BLUE}Application Access:${NC}"
echo -e "  • Grafana:      ${GREEN}http://localhost:3000${NC} (admin/admin)"
echo -e "  • Prometheus:   ${GREEN}http://localhost:9090${NC}"
echo -e "  • Jaeger:       ${GREEN}http://localhost:16686${NC}"
echo -e "  • Alertmanager: ${GREEN}http://localhost:9093${NC}"
echo ""
echo -e "${YELLOW}Useful Commands:${NC}"
echo "  • kubectl get pods -n observability  # Check pod status"
echo "  • kubectl logs -f -n observability <pod-name>  # View logs"
echo "  • ./cleanup.sh  # Remove all resources"
echo "  • FORCE_UPDATE=true ./setup-observability.sh  # Force helm repo update"
echo ""
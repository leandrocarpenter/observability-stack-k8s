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

# Verify Kind cluster is running
if ! kubectl cluster-info --context kind-observability &> /dev/null; then
    error "Kind cluster 'observability' not found!"
    echo "Run: kind create cluster --config=kind-config.yaml --name=observability"
    exit 1
fi

log "Kind cluster verified successfully"

# Add Helm repositories
log "Adding Helm repositories..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
helm repo update

# Create observability namespace
log "Creating 'observability' namespace..."
kubectl create namespace observability --dry-run=client -o yaml | kubectl apply -f -

# Install Prometheus Stack (includes Prometheus, Grafana, Alertmanager)
log "Installing Prometheus Stack..."
helm upgrade --install prometheus-stack prometheus-community/kube-prometheus-stack \
    --namespace observability \
    --set prometheus.service.type=NodePort \
    --set prometheus.service.nodePort=30900 \
    --set grafana.service.type=NodePort \
    --set grafana.service.nodePort=30300 \
    --set alertmanager.service.type=NodePort \
    --set alertmanager.service.nodePort=30903 \
    --set grafana.adminPassword=admin \
    --wait --timeout=600s

# Install Jaeger
log "Installing Jaeger..."
helm upgrade --install jaeger jaegertracing/jaeger \
    --namespace observability \
    --set query.service.type=NodePort \
    --set query.service.nodePort=31686 \
    --wait --timeout=300s

# Wait for all pods to be ready
log "Waiting for all pods to become ready..."
kubectl wait --for=condition=ready pod --all -n observability --timeout=600s

# Apply custom dashboards
log "Applying custom dashboards..."
kubectl apply -f dashboards/ -n observability || warn "No custom dashboards found"

# Deploy sample application
log "Deploying sample application..."
kubectl apply -f examples/ || warn "No sample applications found"

echo ""
log "Observability Stack installation completed successfully"
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
echo ""
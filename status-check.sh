#!/bin/bash

# Quick status check script
# Colors for output formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "Observability Stack Status Check"
echo "================================"

# Check if cluster exists
if ! kubectl cluster-info --context kind-observability &> /dev/null; then
    error "Kind cluster 'observability' not found!"
    exit 1
fi

log "Cluster: kind-observability ✓"

# Check namespace
if kubectl get namespace observability &> /dev/null; then
    log "Namespace: observability ✓"
else
    warn "Namespace 'observability' not found"
    exit 1
fi

# Check Helm releases
echo ""
echo "Helm Releases:"
helm list -n observability 2>/dev/null || warn "No Helm releases found"

# Check pod status
echo ""
echo "Pod Status:"
kubectl get pods -n observability --no-headers 2>/dev/null | while read line; do
    POD_NAME=$(echo $line | awk '{print $1}')
    STATUS=$(echo $line | awk '{print $3}')
    
    case $STATUS in
        "Running"|"Completed")
            echo -e "  ${GREEN}✓${NC} $POD_NAME ($STATUS)"
            ;;
        "Pending"|"ContainerCreating"|"PodInitializing")
            echo -e "  ${YELLOW}⏳${NC} $POD_NAME ($STATUS)"
            ;;
        *)
            echo -e "  ${RED}✗${NC} $POD_NAME ($STATUS)"
            ;;
    esac
done

# Check services
echo ""
echo "Services:"
kubectl get svc -n observability --no-headers 2>/dev/null | while read line; do
    SVC_NAME=$(echo $line | awk '{print $1}')
    SVC_TYPE=$(echo $line | awk '{print $2}')
    echo -e "  ${BLUE}→${NC} $SVC_NAME ($SVC_TYPE)"
done

echo ""
echo "Access URLs:"
echo "  • Grafana:      http://localhost:3000 (admin/admin)"
echo "  • Prometheus:   http://localhost:9090"
echo "  • Jaeger:       http://localhost:16686"
echo "  • Alertmanager: http://localhost:9093"
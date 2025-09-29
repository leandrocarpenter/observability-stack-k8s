#!/bin/bash

set -e

echo "Cleaning up Observability Stack..."

# Colors for output formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Confirmation prompt
read -p "Are you sure you want to remove the entire observability stack? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Operation cancelled."
    exit 0
fi

# Remove Helm releases
log "Removing Helm releases..."
helm uninstall prometheus-stack -n observability || warn "Prometheus stack not found"
helm uninstall jaeger -n observability || warn "Jaeger not found"

# Remove sample applications
log "Removing sample applications..."
kubectl delete -f examples/ || warn "No sample applications found"

# Remove namespace (removes all resources)
log "Removing 'observability' namespace..."
kubectl delete namespace observability || warn "Namespace not found"

echo ""
log "Cleanup completed successfully"
echo ""
echo -e "${YELLOW}To completely remove the Kind cluster:${NC}"
echo "   kind delete cluster --name=observability"
echo ""
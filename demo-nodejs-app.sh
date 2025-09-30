#!/bin/bash

# Node.js Application Demo Script
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

echo "Node.js Application Demo"
echo "========================"

# Check if cluster exists
if ! kubectl cluster-info --context kind-observability &> /dev/null; then
    error "Kind cluster 'observability' not found!"
    echo "Run: make create-cluster && make setup"
    exit 1
fi

# Check if application is running
if ! kubectl get pods -n observability -l app=sample-nodejs-app --no-headers 2>/dev/null | grep -q "Running"; then
    error "Node.js application not running!"
    echo "Run: ./setup-observability.sh"
    exit 1
fi

log "Node.js application is running!"

# Show application details
echo ""
echo "Application Status:"
kubectl get pods -n observability -l app=sample-nodejs-app
echo ""
echo "Service Details:"
kubectl get svc -n observability sample-nodejs-app-service

# Start port-forward if not already running
if ! pgrep -f "port-forward.*sample-nodejs-app-service" > /dev/null; then
    log "Starting port-forward to access the application..."
    kubectl port-forward -n observability svc/sample-nodejs-app-service 3001:3000 > /dev/null 2>&1 &
    sleep 2
else
    log "Port-forward already running"
fi

# Test application endpoints
echo ""
log "Testing application endpoints..."

echo ""
echo -e "${BLUE}Root Endpoint:${NC}"
curl -s http://localhost:3001/ | jq . 2>/dev/null || curl -s http://localhost:3001/

echo ""
echo -e "${BLUE}Health Check:${NC}"
curl -s http://localhost:3001/health | jq . 2>/dev/null || curl -s http://localhost:3001/health

echo ""
echo -e "${BLUE}Metrics Endpoint (first 10 lines):${NC}"
curl -s http://localhost:3001/metrics | head -10

echo ""
echo -e "${BLUE}Random Endpoint (may occasionally return 500 error):${NC}"
curl -s http://localhost:3001/random | jq . 2>/dev/null || curl -s http://localhost:3001/random

echo ""
echo -e "${BLUE}Load Test Endpoint:${NC}"
curl -s http://localhost:3001/load | jq . 2>/dev/null || curl -s http://localhost:3001/load

echo ""
echo -e "${BLUE}Application Info:${NC}"
curl -s http://localhost:3001/info | jq . 2>/dev/null || curl -s http://localhost:3001/info

echo ""
echo "================================"
log "Application is accessible at:"
echo "  • Main App:     http://localhost:3001/"
echo "  • Health Check: http://localhost:3001/health"
echo "  • App Info:     http://localhost:3001/info"
echo "  • Metrics:      http://localhost:3001/metrics"
echo "  • Random Data:  http://localhost:3001/random"
echo "  • Load Test:    http://localhost:3001/load"
echo ""
warn "Use Ctrl+C to stop the port-forward when done"
echo ""
log "You can also view metrics in Grafana at http://localhost:3000"
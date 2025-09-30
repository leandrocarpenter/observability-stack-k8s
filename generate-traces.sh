#!/bin/bash

# Simple demo script for additional trace generation
echo "Generating additional traces..."

# Quick check if services are available
if ! curl -s http://localhost:3001/ > /dev/null 2>&1; then
    echo "Application not accessible. Run ./setup-observability.sh first"
    exit 1
fi

echo "Testing all endpoints to generate more traces..."

for i in {1..5}; do
    echo "  → Test run $i/5"
    curl -s http://localhost:3001/ | jq -c '.message' 2>/dev/null || echo "OK"
    curl -s http://localhost:3001/health | jq -c '.status' 2>/dev/null || echo "OK"
    curl -s http://localhost:3001/load | jq -c '.message' 2>/dev/null || echo "OK"
    curl -s http://localhost:3001/random | jq -c '.random // .error' 2>/dev/null || echo "OK"
    curl -s http://localhost:3001/info | jq -c '.app' 2>/dev/null || echo "OK"
    sleep 1
done

echo ""
echo "✅ Additional traces generated!"
echo "🔍 View them at: http://localhost:16686"
echo "🔧 Service: nodejs-observability-demo"
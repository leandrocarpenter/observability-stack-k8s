#!/bin/bash

echo "Testing OpenTelemetry Collector Transformer"
echo "==========================================="

# Test 1: Check if collector is healthy
echo "1. Checking collector health..."
kubectl port-forward -n observability svc/otel-collector 13133:13133 > /dev/null 2>&1 &
HEALTH_PID=$!
sleep 3

HEALTH_STATUS=$(curl -s http://localhost:13133/ | jq -r '.status' 2>/dev/null)
echo "   Collector status: $HEALTH_STATUS"

kill $HEALTH_PID 2>/dev/null

# Test 2: Generate traces
echo ""
echo "2. Generating test traces..."
kubectl port-forward -n observability svc/sample-nodejs-app-service 3001:3000 > /dev/null 2>&1 &
APP_PID=$!
sleep 3

for i in {1..2}; do
    echo "   Request $i:"
    RESPONSE=$(curl -s http://localhost:3001/load)
    echo "   Response: $(echo $RESPONSE | jq -r '.message')"
done

kill $APP_PID 2>/dev/null

# Test 3: Wait and check Jaeger
echo ""
echo "3. Waiting for traces to propagate..."
sleep 15

echo "4. Checking traces in Jaeger..."
kubectl port-forward -n observability svc/jaeger-query 16686:80 > /dev/null 2>&1 &
JAEGER_PID=$!
sleep 3

TRACE_COUNT=$(curl -s "http://localhost:16686/api/traces?service=nodejs-observability-demo&limit=50" 2>/dev/null | jq '.data | length' 2>/dev/null)
echo "   Total traces: $TRACE_COUNT"

# Get the most recent trace to check for collector attributes
echo ""
echo "5. Checking for collector transformation attributes..."
RECENT_TRACE=$(curl -s "http://localhost:16686/api/traces?service=nodejs-observability-demo&limit=1" 2>/dev/null | jq '.data[0]' 2>/dev/null)

if [ "$RECENT_TRACE" != "null" ]; then
    echo "   Checking for collector attributes in recent trace..."
    
    # Check resource attributes
    RESOURCE_ATTRS=$(echo $RECENT_TRACE | jq '.processes[] | select(.serviceName == "nodejs-observability-demo") | .tags[] | select(.key | contains("otel.collector") or contains("processed"))' 2>/dev/null)
    
    # Check span attributes  
    SPAN_ATTRS=$(echo $RECENT_TRACE | jq '.spans[0].tags[] | select(.key | contains("collector") or contains("processed"))' 2>/dev/null)
    
    if [ -n "$RESOURCE_ATTRS" ] || [ -n "$SPAN_ATTRS" ]; then
        echo "   ✅ Collector transformation attributes found!"
        echo "   Resource attributes:"
        echo "$RESOURCE_ATTRS" | jq -r '"\(.key): \(.value)"' 2>/dev/null || echo "      None found"
        echo "   Span attributes:"
        echo "$SPAN_ATTRS" | jq -r '"\(.key): \(.value)"' 2>/dev/null || echo "      None found"
    else
        echo "   ❌ No collector transformation attributes found"
        echo "   This could mean:"
        echo "   - Traces are going directly to Jaeger (bypassing collector)"
        echo "   - Transformer configuration needs adjustment"
        echo "   - Traces haven't propagated yet"
    fi
else
    echo "   ❌ No traces found"
fi

kill $JAEGER_PID 2>/dev/null

echo ""
echo "6. Collector logs (last 10 lines):"
kubectl logs -n observability -l app=otel-collector --tail=10

echo ""
echo "Test complete!"
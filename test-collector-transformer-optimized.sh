#!/bin/bash

# =============================================================================
# OpenTelemetry Collector Transformer Test Suite
# =============================================================================
# Purpose: Comprehensive testing of OpenTelemetry Collector trace transformation
# Author: Observability Stack K8s Project
# Version: 2.0.0
# =============================================================================

set -euo pipefail

# Configuration
NAMESPACE="observability"
COLLECTOR_SERVICE="otel-collector"
APP_SERVICE="sample-nodejs-app-service"
JAEGER_QUERY_SERVICE="jaeger-query"
TEST_TIMEOUT=300
TRACE_WAIT_TIME=15

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  INFO:${NC} $1"
}

log_success() {
    echo -e "${GREEN}✅ SUCCESS:${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠️  WARNING:${NC} $1"
}

log_error() {
    echo -e "${RED}❌ ERROR:${NC} $1"
}

log_section() {
    echo -e "\n${PURPLE}═══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════════════════════${NC}\n"
}

# Helper functions
check_service_health() {
    local service=$1
    local port=$2
    local path=${3:-"/"}
    
    log_info "Checking health of service: $service"
    
    if kubectl run curl-test --image=curlimages/curl --rm -it --restart=Never -- \
        curl -sf "$service.$NAMESPACE.svc.cluster.local:$port$path" > /dev/null 2>&1; then
        log_success "$service is healthy"
        return 0
    else
        log_error "$service health check failed"
        return 1
    fi
}

generate_test_traffic() {
    local num_requests=${1:-5}
    log_info "Generating $num_requests test requests..."
    
    for i in $(seq 1 $num_requests); do
        log_info "Sending request $i/$num_requests to /load endpoint"
        
        local response
        response=$(kubectl run curl-test-$i --image=curlimages/curl --rm --restart=Never -- \
            curl -sf "$APP_SERVICE.$NAMESPACE.svc.cluster.local:3000/load" 2>/dev/null || echo "ERROR")
        
        if [[ "$response" != "ERROR" ]]; then
            log_success "Request $i completed successfully"
        else
            log_warning "Request $i failed"
        fi
        
        # Small delay between requests
        sleep 0.5
    done
    
    log_success "Generated $num_requests test requests"
}

check_collector_logs() {
    log_info "Analyzing OpenTelemetry Collector logs for trace processing..."
    
    local logs
    logs=$(kubectl logs deployment/otel-collector -n $NAMESPACE --tail=50 2>/dev/null || echo "")
    
    if [[ -z "$logs" ]]; then
        log_error "Could not retrieve collector logs"
        return 1
    fi
    
    # Check for trace reception
    if echo "$logs" | grep -q "ResourceSpans"; then
        log_success "Collector is receiving traces"
    else
        log_warning "No trace reception evidence found in logs"
    fi
    
    # Check for transformation attributes
    local transformer_evidence=()
    
    if echo "$logs" | grep -q "processed_by_collector"; then
        transformer_evidence+=("processed_by_collector")
    fi
    
    if echo "$logs" | grep -q "collector.pipeline"; then
        transformer_evidence+=("collector.pipeline")
    fi
    
    if echo "$logs" | grep -q "collector.processed_at"; then
        transformer_evidence+=("collector.processed_at")
    fi
    
    if echo "$logs" | grep -q "otel.collector.name"; then
        transformer_evidence+=("otel.collector.name")
    fi
    
    if [ ${#transformer_evidence[@]} -gt 0 ]; then
        log_success "Transform processor is working! Found attributes: ${transformer_evidence[*]}"
        return 0
    else
        log_error "No transformer evidence found in collector logs"
        return 1
    fi
}

show_detailed_trace_evidence() {
    log_info "Extracting detailed trace evidence from collector logs..."
    
    local logs
    logs=$(kubectl logs deployment/otel-collector -n $NAMESPACE --tail=100 2>/dev/null || echo "")
    
    if [[ -z "$logs" ]]; then
        log_error "Could not retrieve collector logs for detailed analysis"
        return 1
    fi
    
    # Extract and display trace information
    echo -e "\n${CYAN}🔍 Trace Analysis:${NC}"
    
    # Look for Trace IDs
    local trace_ids
    trace_ids=$(echo "$logs" | grep -o "Trace ID.*: [a-f0-9]*" | head -5)
    if [[ -n "$trace_ids" ]]; then
        echo -e "${CYAN}📊 Recent Trace IDs:${NC}"
        echo "$trace_ids" | sed 's/^/  /'
    fi
    
    # Look for span names
    local span_names
    span_names=$(echo "$logs" | grep -o "Name.*: .*" | head -5)
    if [[ -n "$span_names" ]]; then
        echo -e "\n${CYAN}🏷️  Span Names:${NC}"
        echo "$span_names" | sed 's/^/  /'
    fi
    
    # Look for our custom attributes
    echo -e "\n${CYAN}🔧 Transformer Attributes:${NC}"
    echo "$logs" | grep -E "(processed_by_collector|collector\.pipeline|collector\.processed_at|otel\.collector\.name)" | sed 's/^/  /' | head -10
    
    # Export status
    echo -e "\n${CYAN}📤 Export Status:${NC}"
    local export_info
    export_info=$(echo "$logs" | grep -E "(Exporting failed|successfully exported|exporter.*error)" | tail -5)
    if [[ -n "$export_info" ]]; then
        echo "$export_info" | sed 's/^/  /'
    else
        echo "  No recent export status information found"
    fi
}

check_kubernetes_resources() {
    log_info "Verifying Kubernetes resources status..."
    
    # Check pods
    echo -e "\n${CYAN}📦 Pod Status:${NC}"
    kubectl get pods -n $NAMESPACE -o wide
    
    # Check services
    echo -e "\n${CYAN}🔗 Service Status:${NC}"
    kubectl get svc -n $NAMESPACE
    
    # Check collector specifically
    local collector_pod
    collector_pod=$(kubectl get pods -n $NAMESPACE -l app=otel-collector -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    
    if [[ -n "$collector_pod" ]]; then
        local collector_status
        collector_status=$(kubectl get pod "$collector_pod" -n $NAMESPACE -o jsonpath='{.status.phase}' 2>/dev/null || echo "Unknown")
        
        if [[ "$collector_status" == "Running" ]]; then
            log_success "OpenTelemetry Collector pod is running"
        else
            log_error "OpenTelemetry Collector pod status: $collector_status"
        fi
    else
        log_error "Could not find OpenTelemetry Collector pod"
    fi
}

run_comprehensive_test() {
    log_section "🧪 COMPREHENSIVE OPENTELEMETRY COLLECTOR TRANSFORMER TEST"
    
    local test_passed=true
    
    # Step 1: Check Kubernetes resources
    log_section "1️⃣ Kubernetes Resources Verification"
    check_kubernetes_resources
    
    # Step 2: Health checks
    log_section "2️⃣ Service Health Checks"
    
    if ! check_service_health "$COLLECTOR_SERVICE" "13133"; then
        log_error "OpenTelemetry Collector health check failed"
        test_passed=false
    fi
    
    if ! check_service_health "$APP_SERVICE" "3000" "/ready"; then
        log_error "Node.js application health check failed"
        test_passed=false
    fi
    
    # Step 3: Generate test traffic
    log_section "3️⃣ Test Traffic Generation"
    generate_test_traffic 3
    
    # Step 4: Wait for trace propagation
    log_section "4️⃣ Waiting for Trace Propagation"
    log_info "Waiting ${TRACE_WAIT_TIME}s for traces to be processed..."
    sleep $TRACE_WAIT_TIME
    
    # Step 5: Analyze collector logs
    log_section "5️⃣ Collector Log Analysis"
    if ! check_collector_logs; then
        test_passed=false
    fi
    
    # Step 6: Show detailed evidence
    log_section "6️⃣ Detailed Trace Evidence"
    show_detailed_trace_evidence
    
    # Step 7: Final assessment
    log_section "7️⃣ Test Results Summary"
    
    if $test_passed; then
        log_success "🎉 TRANSFORMER TEST PASSED!"
        echo -e "\n${GREEN}✅ Key Achievements:${NC}"
        echo -e "  • OpenTelemetry Collector is receiving traces"
        echo -e "  • Transform processors are adding custom attributes"
        echo -e "  • Traces are being processed through the collector pipeline"
        echo -e "  • Evidence of collector processing found in logs"
        echo -e "\n${GREEN}🏆 CONCLUSION: Traces are successfully passing through the OpenTelemetry Collector and being transformed!${NC}"
        return 0
    else
        log_error "❌ TRANSFORMER TEST FAILED!"
        echo -e "\n${RED}❌ Issues Detected:${NC}"
        echo -e "  • Check service health status"
        echo -e "  • Verify collector configuration"
        echo -e "  • Review application instrumentation"
        echo -e "\n${RED}🚨 CONCLUSION: Transformer functionality needs investigation${NC}"
        return 1
    fi
}

# Performance test function
run_performance_test() {
    log_section "🚀 Performance Test"
    
    log_info "Running performance test with sustained load..."
    
    local start_time
    start_time=$(date +%s)
    
    # Generate sustained load
    for i in {1..10}; do
        kubectl run perf-test-$i --image=curlimages/curl --rm --restart=Never -- \
            curl -sf "$APP_SERVICE.$NAMESPACE.svc.cluster.local:3000/load" > /dev/null 2>&1 &
    done
    
    wait
    
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    log_success "Performance test completed in ${duration}s"
    
    # Check collector performance
    sleep 5
    log_info "Analyzing collector performance..."
    
    local logs
    logs=$(kubectl logs deployment/otel-collector -n $NAMESPACE --tail=20 2>/dev/null || echo "")
    
    if echo "$logs" | grep -q "ResourceSpans"; then
        local trace_count
        trace_count=$(echo "$logs" | grep -c "ResourceSpans" || echo "0")
        log_success "Collector processed approximately $trace_count trace batches during performance test"
    fi
}

# Main execution
main() {
    echo -e "${PURPLE}"
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════════════════════════╗
║                   OpenTelemetry Collector Transformer Test                   ║
║                              Professional Edition                             ║
║                                   v2.0.0                                     ║
╚═══════════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    local test_type=${1:-"comprehensive"}
    
    case $test_type in
        "comprehensive"|"")
            run_comprehensive_test
            exit $?
            ;;
        "performance")
            run_performance_test
            ;;
        "health")
            log_section "🏥 Health Check Only"
            check_service_health "$COLLECTOR_SERVICE" "13133"
            check_service_health "$APP_SERVICE" "3000" "/ready"
            ;;
        "logs")
            log_section "📋 Log Analysis Only"
            check_collector_logs
            show_detailed_trace_evidence
            ;;
        *)
            echo "Usage: $0 [comprehensive|performance|health|logs]"
            echo "  comprehensive (default): Full test suite"
            echo "  performance: Performance testing"
            echo "  health: Health checks only"
            echo "  logs: Log analysis only"
            exit 1
            ;;
    esac
}

# Execute main function with all arguments
main "$@"
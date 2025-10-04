#!/bin/bash

# =============================================================================
# Performance Test Suite
# =============================================================================
# Tests pipeline performance and resource usage
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} ${1}"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} ${1}"; }
log_error() { echo -e "${RED}[ERROR]${NC} ${1}"; }

# Performance thresholds (in seconds)
MAX_BUILD_TIME=300      # 5 minutes
MAX_SCAN_TIME=180       # 3 minutes
MAX_GATE_TIME=30        # 30 seconds

measure_time() {
    local start_time=$(date +%s)
    "$@"
    local end_time=$(date +%s)
    echo $((end_time - start_time))
}

main() {
    log_info "=== Performance Test Suite ==="
    
    local test_image="devsecops-app:perf-test-$(date +%s)"
    local results_file="${PROJECT_ROOT}/test/phase8/performance-results.txt"
    
    echo "Performance Test Results - $(date)" > "${results_file}"
    echo "========================================" >> "${results_file}"
    
    # Test 1: Build performance
    log_info "Testing build performance..."
    local build_time
    build_time=$(measure_time docker build -f "${PROJECT_ROOT}/src/Dockerfile" -t "${test_image}" "${PROJECT_ROOT}")
    
    echo "Build Time: ${build_time}s (threshold: ${MAX_BUILD_TIME}s)" >> "${results_file}"
    
    if [[ ${build_time} -le ${MAX_BUILD_TIME} ]]; then
        log_success "Build performance: PASSED (${build_time}s)"
    else
        log_error "Build performance: FAILED (${build_time}s > ${MAX_BUILD_TIME}s)"
    fi
    
    # Test 2: Scan performance
    if command -v trivy &> /dev/null; then
        log_info "Testing scan performance..."
        local scan_time
        scan_time=$(measure_time trivy image --format json --output /tmp/perf-scan.json "${test_image}")
        
        echo "Scan Time: ${scan_time}s (threshold: ${MAX_SCAN_TIME}s)" >> "${results_file}"
        
        if [[ ${scan_time} -le ${MAX_SCAN_TIME} ]]; then
            log_success "Scan performance: PASSED (${scan_time}s)"
        else
            log_error "Scan performance: FAILED (${scan_time}s > ${MAX_SCAN_TIME}s)"
        fi
        
        rm -f /tmp/perf-scan.json
    else
        echo "Scan Time: SKIPPED (Trivy not installed)" >> "${results_file}"
        log_info "Scan performance: SKIPPED (Trivy not installed)"
    fi
    
    # Test 3: Policy gate performance
    if [[ -f "${PROJECT_ROOT}/scripts/security/policy-gate.sh" ]]; then
        log_info "Testing policy gate performance..."
        
        # Create mock scan results for performance test
        mkdir -p "${PROJECT_ROOT}/scan-results"
        echo '{"Results":[{"Vulnerabilities":[{"Severity":"LOW"}]}]}' > "${PROJECT_ROOT}/scan-results/trivy-results.json"
        
        local gate_time
        gate_time=$(measure_time "${PROJECT_ROOT}/scripts/security/policy-gate.sh" -s trivy)
        
        echo "Gate Time: ${gate_time}s (threshold: ${MAX_GATE_TIME}s)" >> "${results_file}"
        
        if [[ ${gate_time} -le ${MAX_GATE_TIME} ]]; then
            log_success "Policy gate performance: PASSED (${gate_time}s)"
        else
            log_error "Policy gate performance: FAILED (${gate_time}s > ${MAX_GATE_TIME}s)"
        fi
    else
        echo "Gate Time: SKIPPED (Policy gate not found)" >> "${results_file}"
        log_info "Policy gate performance: SKIPPED (Script not found)"
    fi
    
    # System resource usage
    log_info "Collecting system resource usage..."
    echo "" >> "${results_file}"
    echo "System Resources:" >> "${results_file}"
    echo "Memory Usage: $(free -h | grep '^Mem:' | awk '{print $3 "/" $2}')" >> "${results_file}"
    echo "Disk Usage: $(df -h . | tail -1 | awk '{print $3 "/" $2 " (" $5 ")"}')" >> "${results_file}"
    echo "Docker Images: $(docker images --format 'table {{.Repository}}\t{{.Tag}}\t{{.Size}}' | wc -l) images" >> "${results_file}"
    
    # Cleanup
    docker rmi "${test_image}" || true
    
    log_success "Performance test completed. Results: ${results_file}"
}

main "$@"

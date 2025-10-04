#!/bin/bash

# =============================================================================
# End-to-End Pipeline Test
# =============================================================================
# Tests the complete DevSecOps pipeline from build to deployment
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} ${1}"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} ${1}"; }
log_error() { echo -e "${RED}[ERROR]${NC} ${1}"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} ${1}"; }

# Test configuration
TEST_IMAGE="devsecops-app:e2e-test-$(date +%s)"
TEST_RESULTS_DIR="${PROJECT_ROOT}/test/phase8/results"

main() {
    log_info "=== End-to-End Pipeline Test ==="
    
    mkdir -p "${TEST_RESULTS_DIR}"
    
    # Test 1: Build container image
    log_info "Test 1: Building container image..."
    if docker build -f "${PROJECT_ROOT}/src/Dockerfile" -t "${TEST_IMAGE}" "${PROJECT_ROOT}"; then
        log_success "Container build: PASSED"
    else
        log_error "Container build: FAILED"
        exit 1
    fi
    
    # Test 2: Security scan
    log_info "Test 2: Running security scan..."
    mkdir -p "${PROJECT_ROOT}/scan-results"
    
    if command -v trivy &> /dev/null; then
        if trivy image --format json --output "${TEST_RESULTS_DIR}/e2e-scan.json" "${TEST_IMAGE}"; then
            log_success "Security scan: PASSED"
        else
            log_error "Security scan: FAILED"
            exit 1
        fi
    else
        log_warn "Trivy not installed, skipping security scan"
    fi
    
    # Test 3: Policy gate evaluation
    log_info "Test 3: Testing policy gate..."
    if [[ -f "${PROJECT_ROOT}/scripts/security/policy-gate.sh" ]]; then
        # Copy scan results to expected location
        cp "${TEST_RESULTS_DIR}/e2e-scan.json" "${PROJECT_ROOT}/scan-results/trivy-results.json"
        
        if "${PROJECT_ROOT}/scripts/security/policy-gate.sh" -s trivy; then
            log_success "Policy gate: PASSED"
        else
            local exit_code=$?
            if [[ ${exit_code} -eq 1 ]]; then
                log_warn "Policy gate: FAILED (security gate blocked deployment - this may be expected)"
            else
                log_error "Policy gate: ERROR"
                exit 1
            fi
        fi
    else
        log_error "Policy gate script not found"
        exit 1
    fi
    
    # Test 4: Integrated pipeline
    log_info "Test 4: Testing integrated pipeline..."
    if [[ -f "${PROJECT_ROOT}/scripts/security/integrate-gate.sh" ]]; then
        if "${PROJECT_ROOT}/scripts/security/integrate-gate.sh" "${TEST_IMAGE}"; then
            log_success "Integrated pipeline: PASSED"
        else
            local exit_code=$?
            if [[ ${exit_code} -eq 1 ]]; then
                log_warn "Integrated pipeline: BLOCKED (security gate failed - may be expected)"
            else
                log_error "Integrated pipeline: ERROR"
                exit 1
            fi
        fi
    else
        log_error "Integration script not found"
        exit 1
    fi
    
    # Test 5: Cleanup
    log_info "Test 5: Cleanup..."
    docker rmi "${TEST_IMAGE}" || log_warn "Failed to remove test image"
    
    log_success "=== End-to-End Test Completed ==="
}

main "$@"

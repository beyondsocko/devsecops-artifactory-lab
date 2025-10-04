#!/bin/bash

# =============================================================================
# Security Validation Test Suite
# =============================================================================
# Validates all security controls and policies work correctly
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

main() {
    log_info "=== Security Validation Test Suite ==="
    
    local test_results=()
    
    # Test 1: Policy gate with clean image (should PASS)
    log_info "Test 1: Policy gate with clean scan results..."
    mkdir -p "${PROJECT_ROOT}/scan-results"
    
    cat > "${PROJECT_ROOT}/scan-results/trivy-results.json" << 'EOJ'
{
  "SchemaVersion": 2,
  "ArtifactName": "test:clean",
  "Results": [
    {
      "Vulnerabilities": [
        {"Severity": "LOW", "VulnerabilityID": "CVE-2023-0001"}
      ]
    }
  ]
}
EOJ
    
    if "${PROJECT_ROOT}/scripts/security/policy-gate.sh" -s trivy >/dev/null 2>&1; then
        test_results+=("✅ Clean image policy gate: PASSED")
        log_success "Clean image test: PASSED"
    else
        test_results+=("❌ Clean image policy gate: FAILED")
        log_error "Clean image test: FAILED"
    fi
    
    # Test 2: Policy gate with vulnerable image (should FAIL)
    log_info "Test 2: Policy gate with vulnerable scan results..."
    
    cat > "${PROJECT_ROOT}/scan-results/trivy-results.json" << 'EOJ'
{
  "SchemaVersion": 2,
  "ArtifactName": "test:vulnerable",
  "Results": [
    {
      "Vulnerabilities": [
        {"Severity": "CRITICAL", "VulnerabilityID": "CVE-2023-0001"},
        {"Severity": "CRITICAL", "VulnerabilityID": "CVE-2023-0002"},
        {"Severity": "HIGH", "VulnerabilityID": "CVE-2023-0003"}
      ]
    }
  ]
}
EOJ
    
    if "${PROJECT_ROOT}/scripts/security/policy-gate.sh" -s trivy >/dev/null 2>&1; then
        test_results+=("❌ Vulnerable image policy gate: FAILED (should have blocked)")
        log_error "Vulnerable image test: FAILED (gate should have blocked)"
    else
        test_results+=("✅ Vulnerable image policy gate: PASSED (correctly blocked)")
        log_success "Vulnerable image test: PASSED (correctly blocked)"
    fi
    
    # Test 3: Bypass mechanism
    log_info "Test 3: Testing bypass mechanism..."
    
    export GATE_BYPASS_TOKEN="test-bypass-$(date +%s)"
    export GATE_BYPASS_REASON="Security validation test"
    
    if "${PROJECT_ROOT}/scripts/security/policy-gate.sh" -s trivy >/dev/null 2>&1; then
        test_results+=("✅ Bypass mechanism: PASSED")
        log_success "Bypass mechanism test: PASSED"
    else
        test_results+=("❌ Bypass mechanism: FAILED")
        log_error "Bypass mechanism test: FAILED"
    fi
    
    unset GATE_BYPASS_TOKEN GATE_BYPASS_REASON
    
    # Test 4: Audit trail generation
    log_info "Test 4: Testing audit trail generation..."
    
    local audit_file="${PROJECT_ROOT}/logs/audit/policy-gate-$(date +%Y%m%d).log"
    if [[ -f "${audit_file}" ]] && [[ -s "${audit_file}" ]]; then
        test_results+=("✅ Audit trail generation: PASSED")
        log_success "Audit trail test: PASSED"
    else
        test_results+=("❌ Audit trail generation: FAILED")
        log_error "Audit trail test: FAILED"
    fi
    
    # Test 5: SBOM generation
    log_info "Test 5: Testing SBOM generation..."
    
    if command -v syft &> /dev/null; then
        local test_image="alpine:latest"
        if syft "${test_image}" -o spdx-json --file /tmp/test-sbom.json >/dev/null 2>&1; then
            if [[ -f "/tmp/test-sbom.json" ]] && [[ -s "/tmp/test-sbom.json" ]]; then
                test_results+=("✅ SBOM generation: PASSED")
                log_success "SBOM generation test: PASSED"
                rm -f /tmp/test-sbom.json
            else
                test_results+=("❌ SBOM generation: FAILED (empty file)")
                log_error "SBOM generation test: FAILED (empty file)"
            fi
        else
            test_results+=("❌ SBOM generation: FAILED (syft error)")
            log_error "SBOM generation test: FAILED (syft error)"
        fi
    else
        test_results+=("⚠️ SBOM generation: SKIPPED (syft not installed)")
        log_warn "SBOM generation test: SKIPPED (syft not installed)"
    fi
    
    # Display results
    echo
    log_info "=== Security Validation Results ==="
    for result in "${test_results[@]}"; do
        echo "  ${result}"
    done
    echo
    
    # Check overall success
    if echo "${test_results[@]}" | grep -q "❌"; then
        log_error "Some security validation tests failed"
        exit 1
    else
        log_success "All security validation tests passed!"
        exit 0
    fi
}

main "$@"

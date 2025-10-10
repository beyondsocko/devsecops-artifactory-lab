#!/bin/bash

# =============================================================================
# DevSecOps Demo - Strict Policy Gate
# =============================================================================
# Extra strict policy for demo purposes - will fail with any significant vulnerabilities
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[POLICY]${NC} ${1}"; }
log_success() { echo -e "${GREEN}[PASS]${NC} ${1}"; }
log_error() { echo -e "${RED}[FAIL]${NC} ${1}"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} ${1}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Check if we're in demo mode
DEMO_MODE=""
if [[ -f "${PROJECT_ROOT}/.env.demo" ]]; then
    DEMO_MODE=$(cat "${PROJECT_ROOT}/.env.demo" | cut -d'=' -f2)
fi

# Demo-specific thresholds based on mode
if [[ "$DEMO_MODE" == "vulnerable" ]]; then
    # Strict thresholds that will fail with vulnerable dependencies
    DEMO_MAX_CRITICAL=0
    DEMO_MAX_HIGH=2
    DEMO_MAX_MEDIUM=10
    DEMO_MAX_LOW=30
else
    # More lenient thresholds for secure mode (realistic for base images)
    DEMO_MAX_CRITICAL=0
    DEMO_MAX_HIGH=3
    DEMO_MAX_MEDIUM=25
    DEMO_MAX_LOW=100
fi

echo
echo "🛡️  DevSecOps Security Policy Gate (Demo Mode)"
echo "=============================================="
echo

# Find scan results
SCAN_RESULTS_DIR="${PROJECT_ROOT}/scan-results"
TRIVY_JSON="${SCAN_RESULTS_DIR}/trivy-results.json"

if [[ ! -f "$TRIVY_JSON" ]]; then
    log_error "No scan results found. Run security scan first."
    exit 1
fi

log_info "Analyzing scan results: $(basename "$TRIVY_JSON")"

# Parse vulnerability counts
critical=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "CRITICAL")] | length' "$TRIVY_JSON" 2>/dev/null || echo "0")
high=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "HIGH")] | length' "$TRIVY_JSON" 2>/dev/null || echo "0")
medium=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "MEDIUM")] | length' "$TRIVY_JSON" 2>/dev/null || echo "0")
low=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "LOW")] | length' "$TRIVY_JSON" 2>/dev/null || echo "0")

echo
log_info "📊 Vulnerability Summary:"
echo "   Critical: $critical (max allowed: $DEMO_MAX_CRITICAL)"
echo "   High:     $high (max allowed: $DEMO_MAX_HIGH)"
echo "   Medium:   $medium (max allowed: $DEMO_MAX_MEDIUM)"
echo "   Low:      $low (max allowed: $DEMO_MAX_LOW)"
echo

# Demo-specific messaging
if [[ "$DEMO_MODE" == "vulnerable" ]]; then
    log_warn "🔴 DEMO MODE: VULNERABLE - Expecting policy gate FAILURE"
    log_info "This demonstrates how security gates block vulnerable deployments"
elif [[ "$DEMO_MODE" == "secure" ]]; then
    log_info "🟢 DEMO MODE: SECURE - Expecting policy gate SUCCESS"  
    log_info "This demonstrates how fixed code passes security validation"
fi

echo
log_info "🔍 Applying Security Policy Rules..."

# Check against thresholds
GATE_FAILED=false
FAILURE_REASONS=()

if [[ $critical -gt $DEMO_MAX_CRITICAL ]]; then
    GATE_FAILED=true
    FAILURE_REASONS+=("Critical vulnerabilities: $critical > $DEMO_MAX_CRITICAL")
    log_error "❌ CRITICAL: $critical vulnerabilities found (max: $DEMO_MAX_CRITICAL)"
else
    log_success "✅ CRITICAL: $critical vulnerabilities (within limit: $DEMO_MAX_CRITICAL)"
fi

if [[ $high -gt $DEMO_MAX_HIGH ]]; then
    GATE_FAILED=true
    FAILURE_REASONS+=("High vulnerabilities: $high > $DEMO_MAX_HIGH")
    log_error "❌ HIGH: $high vulnerabilities found (max: $DEMO_MAX_HIGH)"
else
    log_success "✅ HIGH: $high vulnerabilities (within limit: $DEMO_MAX_HIGH)"
fi

if [[ $medium -gt $DEMO_MAX_MEDIUM ]]; then
    GATE_FAILED=true
    FAILURE_REASONS+=("Medium vulnerabilities: $medium > $DEMO_MAX_MEDIUM")
    log_error "❌ MEDIUM: $medium vulnerabilities found (max: $DEMO_MAX_MEDIUM)"
else
    log_success "✅ MEDIUM: $medium vulnerabilities (within limit: $DEMO_MAX_MEDIUM)"
fi

if [[ $low -gt $DEMO_MAX_LOW ]]; then
    GATE_FAILED=true
    FAILURE_REASONS+=("Low vulnerabilities: $low > $DEMO_MAX_LOW")
    log_error "❌ LOW: $low vulnerabilities found (max: $DEMO_MAX_LOW)"
else
    log_success "✅ LOW: $low vulnerabilities (within limit: $DEMO_MAX_LOW)"
fi

echo
echo "=============================================="

if [[ "$GATE_FAILED" == "true" ]]; then
    log_error "🚫 SECURITY GATE: FAILED"
    echo
    log_error "Failure Reasons:"
    for reason in "${FAILURE_REASONS[@]}"; do
        echo "   • $reason"
    done
    echo
    log_error "🛑 DEPLOYMENT BLOCKED"
    log_info "💡 Fix vulnerabilities and re-scan to proceed"
    
    if [[ "$DEMO_MODE" == "vulnerable" ]]; then
        echo
        log_warn "🎭 DEMO TIP: Run './scripts/demo-toggle.sh secure' to fix issues"
    fi
    
    exit 1
else
    log_success "✅ SECURITY GATE: PASSED"
    echo
    log_success "🚀 DEPLOYMENT APPROVED"
    log_info "All vulnerability thresholds met"
    
    if [[ "$DEMO_MODE" == "secure" ]]; then
        echo
        log_success "🎭 DEMO SUCCESS: Secure configuration passed all checks!"
    fi
    
    exit 0
fi

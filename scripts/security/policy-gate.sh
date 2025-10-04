#!/bin/bash

# =============================================================================
# DevSecOps Policy Gate
# =============================================================================
# This script implements security policy gates based on vulnerability scan results
# Integrates with existing Trivy/Grype scan outputs and Nexus metadata system
# =============================================================================

set -euo pipefail

# Script directory and configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
CONFIG_FILE="${PROJECT_ROOT}/.env"

# Load environment configuration
if [[ -f "${CONFIG_FILE}" ]]; then
    source "${CONFIG_FILE}"
fi

# =============================================================================
# CONFIGURATION & DEFAULTS
# =============================================================================

# Gate Policy Configuration
GATE_FAIL_ON_CRITICAL="${GATE_FAIL_ON_CRITICAL:-true}"
GATE_FAIL_ON_HIGH="${GATE_FAIL_ON_HIGH:-true}"
GATE_FAIL_ON_MEDIUM="${GATE_FAIL_ON_MEDIUM:-false}"
GATE_FAIL_ON_LOW="${GATE_FAIL_ON_LOW:-false}"

# Threshold Configuration (maximum allowed vulnerabilities)
GATE_MAX_CRITICAL="${GATE_MAX_CRITICAL:-0}"
GATE_MAX_HIGH="${GATE_MAX_HIGH:-5}"
GATE_MAX_MEDIUM="${GATE_MAX_MEDIUM:-20}"
GATE_MAX_LOW="${GATE_MAX_LOW:-50}"

# Bypass Configuration
GATE_BYPASS_ENABLED="${GATE_BYPASS_ENABLED:-true}"
GATE_BYPASS_TOKEN="${GATE_BYPASS_TOKEN:-}"
GATE_BYPASS_REASON="${GATE_BYPASS_REASON:-}"

# Audit Configuration
AUDIT_LOG_DIR="${PROJECT_ROOT}/logs/audit"
AUDIT_LOG_FILE="${AUDIT_LOG_DIR}/policy-gate-$(date +%Y%m%d).log"

# Scan Results Configuration
SCAN_RESULTS_DIR="${PROJECT_ROOT}/scan-results"
TRIVY_JSON_FILE="${SCAN_RESULTS_DIR}/trivy-results.json"
GRYPE_JSON_FILE="${SCAN_RESULTS_DIR}/grype-results.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

log() {
    echo -e "${1}" >&2
}

log_info() {
    log "${BLUE}[INFO]${NC} ${1}"
}

log_warn() {
    log "${YELLOW}[WARN]${NC} ${1}"
}

log_error() {
    log "${RED}[ERROR]${NC} ${1}"
}

log_success() {
    log "${GREEN}[SUCCESS]${NC} ${1}"
}

# Audit logging function
audit_log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    mkdir -p "${AUDIT_LOG_DIR}"
    echo "${timestamp} [${level}] ${message}" >> "${AUDIT_LOG_FILE}"
}

# =============================================================================
# SCAN RESULT PARSING FUNCTIONS
# =============================================================================

parse_trivy_results() {
    local json_file="$1"
    
    if [[ ! -f "${json_file}" ]]; then
        log_error "Trivy results file not found: ${json_file}"
        return 1
    fi
    
    # Parse vulnerability counts by severity
    local critical=$(jq -r '[.Results[]?.Vulnerabilities[]? | select(.Severity == "CRITICAL")] | length' "${json_file}" 2>/dev/null || echo "0")
    local high=$(jq -r '[.Results[]?.Vulnerabilities[]? | select(.Severity == "HIGH")] | length' "${json_file}" 2>/dev/null || echo "0")
    local medium=$(jq -r '[.Results[]?.Vulnerabilities[]? | select(.Severity == "MEDIUM")] | length' "${json_file}" 2>/dev/null || echo "0")
    local low=$(jq -r '[.Results[]?.Vulnerabilities[]? | select(.Severity == "LOW")] | length' "${json_file}" 2>/dev/null || echo "0")
    
    echo "${critical},${high},${medium},${low}"
}

parse_grype_results() {
    local json_file="$1"
    
    if [[ ! -f "${json_file}" ]]; then
        log_error "Grype results file not found: ${json_file}"
        return 1
    fi
    
    # Parse vulnerability counts by severity
    local critical=$(jq -r '[.matches[]? | select(.vulnerability.severity == "Critical")] | length' "${json_file}" 2>/dev/null || echo "0")
    local high=$(jq -r '[.matches[]? | select(.vulnerability.severity == "High")] | length' "${json_file}" 2>/dev/null || echo "0")
    local medium=$(jq -r '[.matches[]? | select(.vulnerability.severity == "Medium")] | length' "${json_file}" 2>/dev/null || echo "0")
    local low=$(jq -r '[.matches[]? | select(.vulnerability.severity == "Low")] | length' "${json_file}" 2>/dev/null || echo "0")
    
    echo "${critical},${high},${medium},${low}"
}

# =============================================================================
# POLICY EVALUATION FUNCTIONS
# =============================================================================

evaluate_severity_thresholds() {
    local critical="$1"
    local high="$2"
    local medium="$3"
    local low="$4"
    
    local violations=()
    local gate_status="PASS"
    
    # Check Critical vulnerabilities
    if [[ "${GATE_FAIL_ON_CRITICAL}" == "true" ]] && [[ ${critical} -gt ${GATE_MAX_CRITICAL} ]]; then
        violations+=("CRITICAL: ${critical} found (max allowed: ${GATE_MAX_CRITICAL})")
        gate_status="FAIL"
    fi
    
    # Check High vulnerabilities
    if [[ "${GATE_FAIL_ON_HIGH}" == "true" ]] && [[ ${high} -gt ${GATE_MAX_HIGH} ]]; then
        violations+=("HIGH: ${high} found (max allowed: ${GATE_MAX_HIGH})")
        gate_status="FAIL"
    fi
    
    # Check Medium vulnerabilities
    if [[ "${GATE_FAIL_ON_MEDIUM}" == "true" ]] && [[ ${medium} -gt ${GATE_MAX_MEDIUM} ]]; then
        violations+=("MEDIUM: ${medium} found (max allowed: ${GATE_MAX_MEDIUM})")
        gate_status="FAIL"
    fi
    
    # Check Low vulnerabilities
    if [[ "${GATE_FAIL_ON_LOW}" == "true" ]] && [[ ${low} -gt ${GATE_MAX_LOW} ]]; then
        violations+=("LOW: ${low} found (max allowed: ${GATE_MAX_LOW})")
        gate_status="FAIL"
    fi
    
    echo "${gate_status}|$(IFS=';'; echo "${violations[*]}")"
}

# =============================================================================
# BYPASS MECHANISM
# =============================================================================

check_bypass() {
    if [[ "${GATE_BYPASS_ENABLED}" != "true" ]]; then
        return 1
    fi
    
    if [[ -n "${GATE_BYPASS_TOKEN}" ]]; then
        log_warn "Security gate bypass requested"
        log_warn "Bypass token: ${GATE_BYPASS_TOKEN}"
        log_warn "Bypass reason: ${GATE_BYPASS_REASON:-Not specified}"
        
        audit_log "BYPASS" "Security gate bypassed - Token: ${GATE_BYPASS_TOKEN}, Reason: ${GATE_BYPASS_REASON:-Not specified}"
        return 0
    fi
    
    return 1
}

# =============================================================================
# METADATA INTEGRATION
# =============================================================================

update_artifact_metadata() {
    local artifact_path="$1"
    local gate_status="$2"
    local violations="$3"
    local critical="$4"
    local high="$5"
    local medium="$6"
    local low="$7"
    
    local metadata_file="${artifact_path}.metadata.json"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Create or update metadata
    local metadata=$(cat <<EOF
{
    "security": {
        "gate": {
            "status": "${gate_status}",
            "timestamp": "${timestamp}",
            "violations": "${violations}",
            "vulnerability_counts": {
                "critical": ${critical},
                "high": ${high},
                "medium": ${medium},
                "low": ${low}
            },
            "policy": {
                "fail_on_critical": ${GATE_FAIL_ON_CRITICAL},
                "fail_on_high": ${GATE_FAIL_ON_HIGH},
                "fail_on_medium": ${GATE_FAIL_ON_MEDIUM},
                "fail_on_low": ${GATE_FAIL_ON_LOW},
                "max_critical": ${GATE_MAX_CRITICAL},
                "max_high": ${GATE_MAX_HIGH},
                "max_medium": ${GATE_MAX_MEDIUM},
                "max_low": ${GATE_MAX_LOW}
            }
        }
    }
}
EOF
)
    
    echo "${metadata}" > "${metadata_file}"
    log_info "Updated metadata: ${metadata_file}"
}

# =============================================================================
# REPORTING FUNCTIONS
# =============================================================================

generate_gate_report() {
    local gate_status="$1"
    local violations="$2"
    local critical="$3"
    local high="$4"
    local medium="$5"
    local low="$6"
    local scanner="$7"
    
    local report_file="${PROJECT_ROOT}/reports/policy-gate-report-$(date +%Y%m%d-%H%M%S).md"
    mkdir -p "$(dirname "${report_file}")"
    
    cat > "${report_file}" << EOF
# Security Policy Gate Report

**Generated:** $(date '+%Y-%m-%d %H:%M:%S')  
**Scanner:** ${scanner}  
**Gate Status:** **${gate_status}**

## Vulnerability Summary

| Severity | Count | Threshold | Status |
|----------|-------|-----------|--------|
| Critical | ${critical} | ${GATE_MAX_CRITICAL} | $([ ${critical} -le ${GATE_MAX_CRITICAL} ] && echo "✅ PASS" || echo "❌ FAIL") |
| High     | ${high} | ${GATE_MAX_HIGH} | $([ ${high} -le ${GATE_MAX_HIGH} ] && echo "✅ PASS" || echo "❌ FAIL") |
| Medium   | ${medium} | ${GATE_MAX_MEDIUM} | $([ ${medium} -le ${GATE_MAX_MEDIUM} ] && echo "✅ PASS" || echo "❌ FAIL") |
| Low      | ${low} | ${GATE_MAX_LOW} | $([ ${low} -le ${GATE_MAX_LOW} ] && echo "✅ PASS" || echo "❌ FAIL") |

## Policy Configuration

- **Fail on Critical:** ${GATE_FAIL_ON_CRITICAL}
- **Fail on High:** ${GATE_FAIL_ON_HIGH}
- **Fail on Medium:** ${GATE_FAIL_ON_MEDIUM}
- **Fail on Low:** ${GATE_FAIL_ON_LOW}

## Gate Decision

EOF

    if [[ "${gate_status}" == "PASS" ]]; then
        cat >> "${report_file}" << EOF
✅ **SECURITY GATE PASSED**

The artifact meets all security policy requirements and is approved for deployment.

EOF
    else
        cat >> "${report_file}" << EOF
❌ **SECURITY GATE FAILED**

The following policy violations were detected:

EOF
        if [[ -n "${violations}" ]]; then
            IFS=';' read -ra VIOLATION_ARRAY <<< "${violations}"
            for violation in "${VIOLATION_ARRAY[@]}"; do
                echo "- ${violation}" >> "${report_file}"
            done
        fi
        
        cat >> "${report_file}" << EOF

**Action Required:** Address the security vulnerabilities before deployment.

EOF
    fi
    
    cat >> "${report_file}" << EOF
## Audit Trail

This gate decision has been logged to: \`${AUDIT_LOG_FILE}\`

---
*Generated by DevSecOps Policy Gate v1.0*
EOF
    
    log_info "Gate report generated: ${report_file}"
    echo "${report_file}"
}

# =============================================================================
# MAIN GATE LOGIC
# =============================================================================

run_policy_gate() {
    local artifact_path="${1:-}"
    local scanner="${2:-trivy}"
    
    log_info "Starting security policy gate evaluation"
    log_info "Scanner: ${scanner}"
    log_info "Artifact: ${artifact_path:-N/A}"
    
    # Parse scan results based on scanner
    local vulnerability_counts
    case "${scanner}" in
        "trivy")
            vulnerability_counts=$(parse_trivy_results "${TRIVY_JSON_FILE}")
            ;;
        "grype")
            vulnerability_counts=$(parse_grype_results "${GRYPE_JSON_FILE}")
            ;;
        *)
            log_error "Unsupported scanner: ${scanner}"
            exit 1
            ;;
    esac
    
    if [[ $? -ne 0 ]]; then
        log_error "Failed to parse scan results"
        exit 1
    fi
    
    # Extract vulnerability counts
    IFS=',' read -r critical high medium low <<< "${vulnerability_counts}"
    
    log_info "Vulnerability counts - Critical: ${critical}, High: ${high}, Medium: ${medium}, Low: ${low}"
    
    # Evaluate policy
    local evaluation_result
    evaluation_result=$(evaluate_severity_thresholds "${critical}" "${high}" "${medium}" "${low}")
    
    IFS='|' read -r gate_status violations <<< "${evaluation_result}"
    
    # Check for bypass
    local bypass_applied=false
    if [[ "${gate_status}" == "FAIL" ]] && check_bypass; then
        gate_status="BYPASS"
        bypass_applied=true
        log_warn "Security gate bypassed!"
    fi
    
    # Log audit trail
    audit_log "GATE_DECISION" "Status: ${gate_status}, Critical: ${critical}, High: ${high}, Medium: ${medium}, Low: ${low}, Violations: ${violations}"
    
    # Update artifact metadata if path provided
    if [[ -n "${artifact_path}" ]]; then
        update_artifact_metadata "${artifact_path}" "${gate_status}" "${violations}" "${critical}" "${high}" "${medium}" "${low}"
    fi
    
    # Generate report
    local report_file
    report_file=$(generate_gate_report "${gate_status}" "${violations}" "${critical}" "${high}" "${medium}" "${low}" "${scanner}")
    
    # Display results
    echo
    log_info "=== SECURITY POLICY GATE RESULTS ==="
    echo
    
    case "${gate_status}" in
        "PASS")
            log_success "✅ SECURITY GATE PASSED"
            log_success "Artifact approved for deployment"
            ;;
        "FAIL")
            log_error "❌ SECURITY GATE FAILED"
            log_error "Policy violations detected:"
            if [[ -n "${violations}" ]]; then
                IFS=';' read -ra VIOLATION_ARRAY <<< "${violations}"
                for violation in "${VIOLATION_ARRAY[@]}"; do
                    log_error "  - ${violation}"
                done
            fi
            ;;
        "BYPASS")
            log_warn "⚠️  SECURITY GATE BYPASSED"
            log_warn "Deployment allowed with override"
            ;;
    esac
    
    echo
    log_info "Detailed report: ${report_file}"
    log_info "Audit log: ${AUDIT_LOG_FILE}"
    echo
    
    # Exit with appropriate code
    case "${gate_status}" in
        "PASS"|"BYPASS")
            exit 0
            ;;
        "FAIL")
            exit 1
            ;;
    esac
}

# =============================================================================
# COMMAND LINE INTERFACE
# =============================================================================

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS] [ARTIFACT_PATH]

Security Policy Gate for DevSecOps Pipeline

OPTIONS:
    -s, --scanner SCANNER    Scanner to use (trivy|grype) [default: trivy]
    -c, --config FILE        Configuration file [default: .env]
    -h, --help              Show this help message
    
ARTIFACT_PATH:
    Optional path to artifact for metadata updates

ENVIRONMENT VARIABLES:
    GATE_FAIL_ON_CRITICAL    Fail on critical vulnerabilities [true|false]
    GATE_FAIL_ON_HIGH        Fail on high vulnerabilities [true|false]
    GATE_FAIL_ON_MEDIUM      Fail on medium vulnerabilities [true|false]
    GATE_FAIL_ON_LOW         Fail on low vulnerabilities [true|false]
    
    GATE_MAX_CRITICAL        Maximum allowed critical vulnerabilities [0]
    GATE_MAX_HIGH            Maximum allowed high vulnerabilities [5]
    GATE_MAX_MEDIUM          Maximum allowed medium vulnerabilities [20]
    GATE_MAX_LOW             Maximum allowed low vulnerabilities [50]
    
    GATE_BYPASS_ENABLED      Enable bypass mechanism [true|false]
    GATE_BYPASS_TOKEN        Bypass authorization token
    GATE_BYPASS_REASON       Reason for bypass

EXAMPLES:
    $0                                    # Run with defaults
    $0 -s grype                          # Use Grype scanner
    $0 /path/to/artifact                 # Update artifact metadata
    $0 -s trivy /path/to/artifact        # Full run with metadata update

EOF
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    local scanner="trivy"
    local artifact_path=""
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -s|--scanner)
                scanner="$2"
                shift 2
                ;;
            -c|--config)
                CONFIG_FILE="$2"
                if [[ -f "${CONFIG_FILE}" ]]; then
                    source "${CONFIG_FILE}"
                fi
                shift 2
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
            *)
                artifact_path="$1"
                shift
                ;;
        esac
    done
    
    # Validate scanner
    if [[ "${scanner}" != "trivy" && "${scanner}" != "grype" ]]; then
        log_error "Invalid scanner: ${scanner}. Must be 'trivy' or 'grype'"
        exit 1
    fi
    
    # Check dependencies
    if ! command -v jq &> /dev/null; then
        log_error "jq is required but not installed"
        exit 1
    fi
    
    # Run the policy gate
    run_policy_gate "${artifact_path}" "${scanner}"
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
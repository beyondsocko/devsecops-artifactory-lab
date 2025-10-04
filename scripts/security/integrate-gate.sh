#!/bin/bash

# =============================================================================
# DevSecOps Pipeline Integration Script
# =============================================================================
# This script integrates the policy gate with your existing scan.sh pipeline
# Provides seamless integration between Phase 4 (scanning) and Phase 5 (gates)
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

# Script paths
SCAN_SCRIPT="${PROJECT_ROOT}/scripts/security/scan.sh"
POLICY_GATE_SCRIPT="${PROJECT_ROOT}/scripts/security/policy-gate.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# =============================================================================
# PIPELINE INTEGRATION FUNCTIONS
# =============================================================================

run_scan_and_gate() {
    local image_name="$1"
    local artifact_path="${2:-}"
    local scanner="${3:-trivy}"
    
    log_info "Starting integrated scan and gate pipeline"
    log_info "Image: ${image_name}"
    log_info "Scanner: ${scanner}"
    
    # Step 1: Run security scan
    log_info "Step 1: Running security scan..."
    if ! "${SCAN_SCRIPT}" "${image_name}"; then
        log_error "Security scan failed"
        return 1
    fi
    
    log_success "Security scan completed successfully"
    
    # Step 2: Run policy gate
    log_info "Step 2: Evaluating security policy gate..."
    if "${POLICY_GATE_SCRIPT}" -s "${scanner}" "${artifact_path}"; then
        log_success "Security gate PASSED - Deployment approved"
        return 0
    else
        local exit_code=$?
        if [[ ${exit_code} -eq 1 ]]; then
            log_error "Security gate FAILED - Deployment blocked"
        else
            log_warn "Security gate evaluation encountered an error"
        fi
        return ${exit_code}
    fi
}

# =============================================================================
# NEXUS INTEGRATION FUNCTIONS
# =============================================================================

update_nexus_metadata() {
    local artifact_path="$1"
    local gate_status="$2"
    
    log_info "Updating Nexus metadata for artifact: ${artifact_path}"
    
    # Create metadata JSON
    local metadata_file="${artifact_path}.metadata.json"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    if [[ -f "${metadata_file}" ]]; then
        # Update existing metadata
        local temp_file=$(mktemp)
        jq --arg status "${gate_status}" --arg timestamp "${timestamp}" \
           '.security.gate.status = $status | .security.gate.last_updated = $timestamp' \
           "${metadata_file}" > "${temp_file}"
        mv "${temp_file}" "${metadata_file}"
    else
        # Create new metadata
        cat > "${metadata_file}" << EOF
{
    "security": {
        "gate": {
            "status": "${gate_status}",
            "last_updated": "${timestamp}"
        }
    }
}
EOF
    fi
    
    log_success "Nexus metadata updated: ${metadata_file}"
}

# =============================================================================
# CI/CD INTEGRATION HELPERS
# =============================================================================

# Function for GitHub Actions integration
github_actions_integration() {
    local gate_status="$1"
    local report_file="$2"
    
    # Set GitHub Actions outputs
    if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
        echo "gate_status=${gate_status}" >> "${GITHUB_OUTPUT}"
        echo "gate_report=${report_file}" >> "${GITHUB_OUTPUT}"
    fi
    
    # Create job summary
    if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
        cat >> "${GITHUB_STEP_SUMMARY}" << EOF
## Security Policy Gate Results

**Status:** ${gate_status}
**Report:** [View Report](${report_file})

EOF
        if [[ "${gate_status}" == "PASS" ]]; then
            echo "✅ Security gate passed - deployment approved" >> "${GITHUB_STEP_SUMMARY}"
        elif [[ "${gate_status}" == "FAIL" ]]; then
            echo "❌ Security gate failed - deployment blocked" >> "${GITHUB_STEP_SUMMARY}"
        else
            echo "⚠️ Security gate bypassed - deployment allowed with override" >> "${GITHUB_STEP_SUMMARY}"
        fi
    fi
}

# Function for Jenkins integration
jenkins_integration() {
    local gate_status="$1"
    local report_file="$2"
    
    # Set Jenkins environment variables
    if [[ -n "${JENKINS_URL:-}" ]]; then
        echo "GATE_STATUS=${gate_status}" > gate.properties
        echo "GATE_REPORT=${report_file}" >> gate.properties
        
        # Archive the report
        if command -v jenkins-cli &> /dev/null; then
            jenkins-cli archive "${report_file}"
        fi
    fi
}

# =============================================================================
# NOTIFICATION FUNCTIONS
# =============================================================================

send_slack_notification() {
    local gate_status="$1"
    local image_name="$2"
    local report_file="$3"
    
    if [[ -z "${SLACK_WEBHOOK_URL:-}" ]]; then
        return 0
    fi
    
    local color
    local emoji
    case "${gate_status}" in
        "PASS")
            color="good"
            emoji=":white_check_mark:"
            ;;
        "FAIL")
            color="danger"
            emoji=":x:"
            ;;
        "BYPASS")
            color="warning"
            emoji=":warning:"
            ;;
    esac
    
    local payload=$(cat << EOF
{
    "attachments": [
        {
            "color": "${color}",
            "title": "${emoji} Security Gate ${gate_status}",
            "fields": [
                {
                    "title": "Image",
                    "value": "${image_name}",
                    "short": true
                },
                {
                    "title": "Status",
                    "value": "${gate_status}",
                    "short": true
                },
                {
                    "title": "Report",
                    "value": "${report_file}",
                    "short": false
                }
            ],
            "footer": "DevSecOps Pipeline",
            "ts": $(date +%s)
        }
    ]
}
EOF
)
    
    curl -X POST -H 'Content-type: application/json' \
         --data "${payload}" \
         "${SLACK_WEBHOOK_URL}" || true
}

# =============================================================================
# MAIN INTEGRATION LOGIC
# =============================================================================

run_integrated_pipeline() {
    local image_name="$1"
    local artifact_path="${2:-}"
    local scanner="${3:-trivy}"
    local notify="${4:-false}"
    
    log_info "=== DevSecOps Integrated Pipeline ==="
    log_info "Image: ${image_name}"
    log_info "Scanner: ${scanner}"
    log_info "Notifications: ${notify}"
    echo
    
    # Run scan and gate
    local gate_status="UNKNOWN"
    local report_file=""
    
    if run_scan_and_gate "${image_name}" "${artifact_path}" "${scanner}"; then
        gate_status="PASS"
    else
        local exit_code=$?
        if [[ ${exit_code} -eq 1 ]]; then
            gate_status="FAIL"
        else
            gate_status="ERROR"
        fi
    fi
    
    # Find the latest report file
    report_file=$(find "${PROJECT_ROOT}/reports" -name "policy-gate-report-*.md" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2- || echo "")
    
    # Update Nexus metadata if artifact path provided
    if [[ -n "${artifact_path}" ]]; then
        update_nexus_metadata "${artifact_path}" "${gate_status}"
    fi
    
    # CI/CD integrations
    if [[ -n "${GITHUB_ACTIONS:-}" ]]; then
        github_actions_integration "${gate_status}" "${report_file}"
    fi
    
    if [[ -n "${JENKINS_URL:-}" ]]; then
        jenkins_integration "${gate_status}" "${report_file}"
    fi
    
    # Send notifications
    if [[ "${notify}" == "true" ]]; then
        send_slack_notification "${gate_status}" "${image_name}" "${report_file}"
    fi
    
    # Final status
    echo
    log_info "=== Pipeline Summary ==="
    log_info "Gate Status: ${gate_status}"
    log_info "Report: ${report_file}"
    echo
    
    case "${gate_status}" in
        "PASS")
            log_success "✅ Pipeline completed successfully - Deployment approved"
            return 0
            ;;
        "FAIL")
            log_error "❌ Pipeline failed - Deployment blocked by security gate"
            return 1
            ;;
        "BYPASS")
            log_warn "⚠️ Pipeline completed with bypass - Deployment allowed with override"
            return 0
            ;;
        *)
            log_error "❌ Pipeline encountered an error"
            return 2
            ;;
    esac
}

# =============================================================================
# COMMAND LINE INTERFACE
# =============================================================================

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS] IMAGE_NAME [ARTIFACT_PATH]

Integrated DevSecOps Pipeline - Scan + Policy Gate

ARGUMENTS:
    IMAGE_NAME          Container image to scan and evaluate
    ARTIFACT_PATH       Optional path to artifact for metadata updates

OPTIONS:
    -s, --scanner SCANNER    Scanner to use (trivy|grype) [default: trivy]
    -n, --notify            Send notifications (Slack, etc.)
    -c, --config FILE       Configuration file [default: .env]
    -h, --help             Show this help message

EXAMPLES:
    $0 myapp:latest                           # Basic scan and gate
    $0 -s grype myapp:latest                  # Use Grype scanner
    $0 -n myapp:latest /path/to/artifact      # With notifications and metadata
    $0 --scanner trivy --notify myapp:latest # Full integration

ENVIRONMENT VARIABLES:
    See policy-config.env for full configuration options

EOF
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    local image_name=""
    local artifact_path=""
    local scanner="trivy"
    local notify="false"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -s|--scanner)
                scanner="$2"
                shift 2
                ;;
            -n|--notify)
                notify="true"
                shift
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
                if [[ -z "${image_name}" ]]; then
                    image_name="$1"
                else
                    artifact_path="$1"
                fi
                shift
                ;;
        esac
    done
    
    # Validate required arguments
    if [[ -z "${image_name}" ]]; then
        log_error "Image name is required"
        show_usage
        exit 1
    fi
    
    # Check dependencies
    if [[ ! -f "${SCAN_SCRIPT}" ]]; then
        log_error "Scan script not found: ${SCAN_SCRIPT}"
        exit 1
    fi
    
    if [[ ! -f "${POLICY_GATE_SCRIPT}" ]]; then
        log_error "Policy gate script not found: ${POLICY_GATE_SCRIPT}"
        exit 1
    fi
    
    # Run the integrated pipeline
    run_integrated_pipeline "${image_name}" "${artifact_path}" "${scanner}" "${notify}"
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
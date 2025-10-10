#!/bin/bash

# =============================================================================
# DevSecOps Live Demo Script
# =============================================================================
# Complete live demonstration showing both failure and success scenarios
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

log_demo() { echo -e "${PURPLE}${BOLD}[DEMO]${NC} ${1}"; }
log_info() { echo -e "${BLUE}[INFO]${NC} ${1}"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} ${1}"; }
log_error() { echo -e "${RED}[ERROR]${NC} ${1}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Demo pause function
demo_pause() {
    local message="${1:-Press Enter to continue...}"
    echo
    echo -e "${YELLOW}${BOLD}⏸️  ${message}${NC}"
    read -r
    echo
}

# Demo header
demo_header() {
    local title="$1"
    echo
    echo -e "${BOLD}================================================================${NC}"
    echo -e "${BOLD}🎭 ${title}${NC}"
    echo -e "${BOLD}================================================================${NC}"
    echo
}

# Main demo flow
main() {
    clear
    
    demo_header "DevSecOps Pipeline Live Demo"
    
    log_demo "Welcome to the DevSecOps Security Pipeline Demonstration!"
    echo
    echo "This demo will show:"
    echo "  1. 🔴 A FAILING pipeline with security vulnerabilities"
    echo "  2. 🔧 How to fix the security issues"
    echo "  3. 🟢 A PASSING pipeline with secure configuration"
    echo
    
    demo_pause "Ready to start the demo?"
    
    # Part 1: Show vulnerable configuration
    demo_header "Part 1: Vulnerable Configuration (WILL FAIL)"
    
    log_demo "Setting up vulnerable configuration..."
    "${PROJECT_ROOT}/scripts/demo-toggle.sh" vulnerable
    
    demo_pause "Now let's run the CI pipeline and watch it FAIL due to security issues"
    
    log_demo "🚀 Running CI Pipeline with Vulnerable Code..."
    echo
    
    # Run pipeline and capture exit code
    if "${PROJECT_ROOT}/scripts/demo-toggle.sh" pipeline; then
        log_error "🚨 Unexpected: Pipeline should have FAILED with vulnerable code!"
        log_error "The security gate should have blocked this deployment"
    else
        echo
        log_demo "✅ Perfect! Pipeline correctly FAILED due to security vulnerabilities"
        log_demo "🛡️  The security gate successfully blocked the vulnerable deployment"
    fi
    
    demo_pause "Notice how the security gate blocked deployment. Now let's fix the issues..."
    
    # Part 2: Show secure configuration
    demo_header "Part 2: Secure Configuration (WILL PASS)"
    
    log_demo "Applying security fixes..."
    "${PROJECT_ROOT}/scripts/demo-toggle.sh" secure
    
    demo_pause "Configuration updated with secure dependencies. Let's run the pipeline again..."
    
    log_demo "🚀 Running CI Pipeline with Secure Code..."
    echo
    
    # Run pipeline and capture exit code
    if "${PROJECT_ROOT}/scripts/demo-toggle.sh" pipeline; then
        echo
        log_demo "🎉 Excellent! Pipeline PASSED with secure configuration!"
        log_demo "🚀 The security gate now allows deployment to proceed"
    else
        echo
        log_error "🚨 Unexpected: Pipeline should have PASSED with secure code!"
        log_error "There may still be security issues that need attention"
    fi
    
    demo_pause "Great! The security gate now approves the deployment."
    
    # Part 3: Summary
    demo_header "Demo Summary"
    
    echo "🎯 What we demonstrated:"
    echo
    echo "✅ Automated security scanning with Trivy"
    echo "✅ Policy gates that block vulnerable deployments"
    echo "✅ Live configuration switching for testing"
    echo "✅ Complete CI/CD pipeline with security integration"
    echo "✅ Infrastructure as Code with Terraform"
    echo
    
    log_success "DevSecOps pipeline successfully prevents vulnerable code from reaching production!"
    
    demo_pause "Demo complete. Restore original configuration?"
    
    log_demo "Restoring original configuration..."
    "${PROJECT_ROOT}/scripts/demo-toggle.sh" restore
    
    demo_header "Demo Complete!"
    
    log_success "🎉 Thank you for watching the DevSecOps Pipeline Demo!"
    echo
    echo "Key takeaways:"
    echo "  • Security scanning is integrated into every build"
    echo "  • Policy gates provide automated governance"
    echo "  • Infrastructure as Code ensures consistency"
    echo "  • DevSecOps shifts security left in the pipeline"
    echo
    log_info "For more information, see the project documentation."
}

# Run main function
main "$@"

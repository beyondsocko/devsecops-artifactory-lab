#!/bin/bash

# =============================================================================
# DevSecOps Demo Toggle Script
# =============================================================================
# Dynamically switches between vulnerable and secure configurations for live demos
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

log_info() { echo -e "${BLUE}[INFO]${NC} ${1}"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} ${1}"; }
log_error() { echo -e "${RED}[ERROR]${NC} ${1}"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} ${1}"; }
log_demo() { echo -e "${PURPLE}[DEMO]${NC} ${1}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Demo configurations
VULNERABLE_DEPS='{
  "express": "4.16.0",
  "jsonwebtoken": "8.3.0",
  "lodash": "4.17.15",
  "moment": "2.19.3",
  "winston": "2.4.0",
  "debug": "2.6.8",
  "qs": "6.5.1"
}'

SECURE_DEPS='{
  "express": "^4.18.2",
  "jsonwebtoken": "^9.0.2",
  "lodash": "^4.17.21",
  "moment": "^2.29.4",
  "winston": "^3.8.2"
}'

# Backup original package.json
backup_package_json() {
    if [[ ! -f "${PROJECT_ROOT}/src/package.json.original" ]]; then
        cp "${PROJECT_ROOT}/src/package.json" "${PROJECT_ROOT}/src/package.json.original"
        log_info "Created backup of original package.json"
    fi
}

# Set vulnerable configuration
set_vulnerable() {
    log_demo "🔴 SETTING VULNERABLE CONFIGURATION"
    
    backup_package_json
    
    # Update package.json with vulnerable dependencies
    cat > "${PROJECT_ROOT}/src/package.json" << EOF
{
  "name": "devsecops-sample-app",
  "version": "1.2.0-vulnerable",
  "description": "DevSecOps Lab Sample Application - VULNERABLE VERSION FOR DEMO",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "test": "node test.js",
    "lint": "echo 'Linting passed (placeholder)'"
  },
  "dependencies": ${VULNERABLE_DEPS}
}
EOF

    # Add vulnerable code snippet to server.js
    if ! grep -q "VULNERABLE_CODE_DEMO" "${PROJECT_ROOT}/src/server.js" 2>/dev/null; then
        cat >> "${PROJECT_ROOT}/src/server.js" << 'EOF'

// VULNERABLE_CODE_DEMO - Intentionally insecure for security scanning demo
const crypto = require('crypto');

// Vulnerable: Weak cryptographic algorithm
app.get('/demo/weak-crypto', (req, res) => {
    const hash = crypto.createHash('md5').update('demo-data').digest('hex');
    res.json({ hash: hash, warning: 'This uses weak MD5 hashing!' });
});

// Vulnerable: Potential command injection
app.get('/demo/command/:cmd', (req, res) => {
    const { exec } = require('child_process');
    // WARNING: Never do this in production!
    exec(`echo ${req.params.cmd}`, (error, stdout) => {
        res.json({ output: stdout, warning: 'Command injection vulnerability!' });
    });
});
EOF
    fi
    
    # Set environment variable
    echo "DEMO_MODE=vulnerable" > "${PROJECT_ROOT}/.env.demo"
    
    log_success "✅ Vulnerable configuration activated"
    log_warn "⚠️  This version WILL FAIL security gates"
    log_info "📊 Expected: High vulnerability count, security gate FAILURE"
}

# Set secure configuration  
set_secure() {
    log_demo "🟢 SETTING SECURE CONFIGURATION"
    
    backup_package_json
    
    # Update package.json with secure dependencies
    cat > "${PROJECT_ROOT}/src/package.json" << EOF
{
  "name": "devsecops-sample-app",
  "version": "1.2.0-secure",
  "description": "DevSecOps Lab Sample Application - SECURE VERSION FOR DEMO",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "test": "node test.js",
    "lint": "echo 'Linting passed (placeholder)'"
  },
  "dependencies": ${SECURE_DEPS}
}
EOF

    # Remove vulnerable code from server.js
    if [[ -f "${PROJECT_ROOT}/src/server.js" ]]; then
        # Create temp file without vulnerable code
        sed '/VULNERABLE_CODE_DEMO/,$d' "${PROJECT_ROOT}/src/server.js" > "${PROJECT_ROOT}/src/server.js.tmp"
        mv "${PROJECT_ROOT}/src/server.js.tmp" "${PROJECT_ROOT}/src/server.js"
    fi
    
    # Set environment variable
    echo "DEMO_MODE=secure" > "${PROJECT_ROOT}/.env.demo"
    
    log_success "✅ Secure configuration activated"
    log_success "🛡️  This version WILL PASS security gates"
    log_info "📊 Expected: Low vulnerability count, security gate SUCCESS"
}

# Restore original configuration
restore_original() {
    log_demo "🔄 RESTORING ORIGINAL CONFIGURATION"
    
    if [[ -f "${PROJECT_ROOT}/src/package.json.original" ]]; then
        cp "${PROJECT_ROOT}/src/package.json.original" "${PROJECT_ROOT}/src/package.json"
        log_success "✅ Original package.json restored"
    fi
    
    # Remove demo environment file
    rm -f "${PROJECT_ROOT}/.env.demo"
    
    log_success "✅ Original configuration restored"
}

# Show current configuration
show_status() {
    log_info "📊 CURRENT DEMO CONFIGURATION"
    echo
    
    if [[ -f "${PROJECT_ROOT}/.env.demo" ]]; then
        local mode=$(cat "${PROJECT_ROOT}/.env.demo" | cut -d'=' -f2)
        if [[ "$mode" == "vulnerable" ]]; then
            log_error "🔴 VULNERABLE MODE ACTIVE"
            echo "   - Using outdated, vulnerable dependencies"
            echo "   - Contains intentionally insecure code"
            echo "   - WILL FAIL security gates"
        elif [[ "$mode" == "secure" ]]; then
            log_success "🟢 SECURE MODE ACTIVE"  
            echo "   - Using latest, patched dependencies"
            echo "   - No vulnerable code patterns"
            echo "   - WILL PASS security gates"
        fi
    else
        log_info "🔵 ORIGINAL MODE ACTIVE"
        echo "   - Default configuration"
        echo "   - Mixed vulnerability profile"
    fi
    
    echo
    if [[ -f "${PROJECT_ROOT}/src/package.json" ]]; then
        local version=$(jq -r '.version' "${PROJECT_ROOT}/src/package.json" 2>/dev/null || echo "unknown")
        log_info "📦 Current version: ${version}"
    fi
}

# Run demo pipeline
run_demo_pipeline() {
    local mode="${1:-current}"
    
    log_demo "🚀 RUNNING DEMO PIPELINE (${mode} mode)"
    echo
    
    # Clean previous results
    rm -rf "${PROJECT_ROOT}/scan-results"
    
    # Run CI simulation (use ultra-clean demo version)
    if [[ -f "${PROJECT_ROOT}/scripts/demo-pipeline-clean.sh" ]]; then
        chmod +x "${PROJECT_ROOT}/scripts/demo-pipeline-clean.sh"
        "${PROJECT_ROOT}/scripts/demo-pipeline-clean.sh"
    elif [[ -f "${PROJECT_ROOT}/scripts/simulate-ci-quiet.sh" ]]; then
        chmod +x "${PROJECT_ROOT}/scripts/simulate-ci-quiet.sh"
        "${PROJECT_ROOT}/scripts/simulate-ci-quiet.sh"
    else
        log_warn "Clean demo script not found, using regular version"
        "${PROJECT_ROOT}/scripts/simulate-ci.sh"
    fi
}

# Main execution
main() {
    echo
    echo "🎭 DevSecOps Live Demo Toggle"
    echo "============================"
    echo
    
    case "${1:-help}" in
        "vulnerable"|"vuln"|"v")
            set_vulnerable
            echo
            log_demo "🎬 Ready for FAILURE demo! Run: $0 pipeline"
            ;;
        "secure"|"safe"|"s")
            set_secure  
            echo
            log_demo "🎬 Ready for SUCCESS demo! Run: $0 pipeline"
            ;;
        "restore"|"original"|"r")
            restore_original
            ;;
        "status"|"show")
            show_status
            ;;
        "pipeline"|"demo"|"run")
            run_demo_pipeline
            ;;
        "help"|*)
            echo "Usage: $0 <command>"
            echo
            echo "Commands:"
            echo "  vulnerable  - Set vulnerable configuration (WILL FAIL)"
            echo "  secure      - Set secure configuration (WILL PASS)"  
            echo "  restore     - Restore original configuration"
            echo "  status      - Show current configuration"
            echo "  pipeline    - Run demo pipeline with current config"
            echo "  help        - Show this help"
            echo
            echo "Live Demo Flow:"
            echo "  1. $0 vulnerable  # Set up for failure demo"
            echo "  2. $0 pipeline    # Show failing pipeline"
            echo "  3. $0 secure      # Fix the issues"
            echo "  4. $0 pipeline    # Show passing pipeline"
            echo "  5. $0 restore     # Clean up"
            ;;
    esac
}

# Run main function
main "$@"

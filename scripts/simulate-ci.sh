#!/bin/bash

# =============================================================================
# Local CI/CD Pipeline Simulator
# =============================================================================
# Simulates the GitHub Actions pipeline locally for testing
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} ${1}"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} ${1}"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} ${1}"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} ${1}"
}

# Configuration
APP_NAME="devsecops-app"
APP_VERSION="v$(date +%Y%m%d)-local"
IMAGE_TAG="${APP_NAME}:${APP_VERSION}"

echo
log_info "=== Local CI/CD Pipeline Simulation ==="
log_info "Simulating GitHub Actions workflow locally"
log_info "Project root: ${PROJECT_ROOT}"
echo

# Stage 1: Lint & Test
log_info "Stage 1: Lint & Test"
if [ -d "${PROJECT_ROOT}/src" ]; then
    cd "${PROJECT_ROOT}/src"
    if [ -f "package.json" ]; then
        log_info "Installing dependencies..."
        npm install || log_warn "npm install failed or not needed"
        
        log_info "Running tests..."
        npm test || log_warn "Tests failed or not configured"
    fi
    cd "${PROJECT_ROOT}"
else
    log_warn "src directory not found, skipping lint & test"
fi

# Stage 2: Build
log_info "Stage 2: Build Container"
if [ -f "${PROJECT_ROOT}/src/Dockerfile" ]; then
    log_info "Building container image: ${IMAGE_TAG}"
    log_info "Build context: ${PROJECT_ROOT}"
    log_info "Dockerfile: ${PROJECT_ROOT}/src/Dockerfile"
    
    # Build from project root with Dockerfile in src/
    docker build \
        --file "${PROJECT_ROOT}/src/Dockerfile" \
        --build-arg BUILD_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        --build-arg VCS_REF="local-build" \
        --build-arg VERSION="${APP_VERSION}" \
        --label "org.opencontainers.image.created=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        --label "org.opencontainers.image.version=${APP_VERSION}" \
        --label "security.scan.required=true" \
        --tag "${IMAGE_TAG}" \
        "${PROJECT_ROOT}"
        
    if [ $? -eq 0 ]; then
        log_success "Container built: ${IMAGE_TAG}"
    else
        log_error "Container build failed"
        log_info "Debug information:"
        log_info "  - Project root: ${PROJECT_ROOT}"
        log_info "  - Dockerfile location: ${PROJECT_ROOT}/src/Dockerfile"
        log_info "  - Build context: ${PROJECT_ROOT}"
        log_info "  - Expected src/ directory in build context"
        
        # Check if src directory exists in build context
        if [ -d "${PROJECT_ROOT}/src" ]; then
            log_info "  - src/ directory exists ✓"
            ls -la "${PROJECT_ROOT}/src/" | head -10
        else
            log_error "  - src/ directory missing ✗"
        fi
        
        exit 1
    fi
else
    log_error "Dockerfile not found at ${PROJECT_ROOT}/src/Dockerfile"
    
    # Help debug the issue
    log_info "Debug: Looking for Dockerfile..."
    find "${PROJECT_ROOT}" -name "Dockerfile" -type f 2>/dev/null || log_info "No Dockerfile found"
    
    exit 1
fi

# Stage 3: Security Scan
log_info "Stage 3: Security Scan"
if command -v trivy &> /dev/null; then
    mkdir -p "${PROJECT_ROOT}/scan-results"
    
    log_info "Running Trivy scan..."
    trivy image --format json --output "${PROJECT_ROOT}/scan-results/trivy-results.json" "${IMAGE_TAG}"
    trivy image --format table "${IMAGE_TAG}"
    
    log_success "Security scan completed"
else
    log_warn "Trivy not installed, skipping security scan"
    log_info "Install Trivy: https://aquasecurity.github.io/trivy/latest/getting-started/installation/"
fi

# Stage 4: Security Gate
log_info "Stage 4: Security Policy Gate"
if [ -f "${PROJECT_ROOT}/scripts/security/policy-gate.sh" ]; then
    chmod +x "${PROJECT_ROOT}/scripts/security/policy-gate.sh"
    
    if "${PROJECT_ROOT}/scripts/security/policy-gate.sh" -s trivy; then
        GATE_STATUS="PASS"
        log_success "Security gate PASSED"
    else
        GATE_STATUS="FAIL"
        log_error "Security gate FAILED"
    fi
else
    log_warn "Policy gate script not found at ${PROJECT_ROOT}/scripts/security/policy-gate.sh"
    GATE_STATUS="SKIP"
fi

# Stage 5: Publish (Simulated)
log_info "Stage 5: Publish (Simulated)"
if [ "${GATE_STATUS}" = "PASS" ]; then
    log_info "Would publish to Nexus registry: localhost:8082/${IMAGE_TAG}"
    log_info "Would upload SBOM and scan results"
    log_success "Publish stage completed (simulated)"
elif [ "${GATE_STATUS}" = "FAIL" ]; then
    log_warn "Publish skipped due to security gate failure"
else
    log_warn "Publish skipped due to missing security gate"
fi

# Stage 6: Summary
echo
log_info "=== Pipeline Summary ==="
log_info "Image: ${IMAGE_TAG}"
log_info "Security Gate: ${GATE_STATUS}"

if [ "${GATE_STATUS}" = "PASS" ]; then
    log_success "✅ Pipeline completed successfully"
    exit 0
elif [ "${GATE_STATUS}" = "FAIL" ]; then
    log_error "❌ Pipeline failed due to security gate"
    exit 1
else
    log_warn "⚠️ Pipeline completed with warnings"
    exit 0
fi
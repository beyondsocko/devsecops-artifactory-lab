#!/bin/bash

# =============================================================================
# Local CI/CD Pipeline Simulator - Quiet Mode
# =============================================================================
# Concise version with minimal output for better terminal experience
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} ${1}"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} ${1}"; }
log_error() { echo -e "${RED}[ERROR]${NC} ${1}"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} ${1}"; }

# Configuration
APP_NAME="devsecops-app"
APP_VERSION="v$(date +%Y%m%d)-local"
IMAGE_TAG="${APP_NAME}:${APP_VERSION}"

echo
echo "🚀 DevSecOps CI/CD Pipeline (Quiet Mode)"
echo "========================================"
echo "Image: ${IMAGE_TAG}"
echo

# Stage 1: Lint & Test
echo "📋 Stage 1: Lint & Test"
if [ -d "${PROJECT_ROOT}/src" ] && [ -f "${PROJECT_ROOT}/src/package.json" ]; then
    cd "${PROJECT_ROOT}/src"
    if npm install --silent > /dev/null 2>&1; then
        echo "  ✅ Dependencies installed"
    else
        echo "  ⚠️  Dependencies skipped"
    fi
    
    echo "  🧪 Running tests..."
    if npm test 2>/dev/null; then
        echo "  ✅ Tests passed"
    else
        echo "  ⚠️  Tests failed/not configured"
    fi
    cd "${PROJECT_ROOT}"
else
    echo "  ⚠️  No package.json found, skipping"
fi

# Stage 2: Build
echo
echo "🏗️  Stage 2: Build Container"
if [ -f "${PROJECT_ROOT}/src/Dockerfile" ]; then
    echo "  🔨 Building ${IMAGE_TAG}..."
    if docker build \
        --file "${PROJECT_ROOT}/src/Dockerfile" \
        --build-arg BUILD_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        --build-arg VCS_REF="local-build" \
        --build-arg VERSION="${APP_VERSION}" \
        --tag "${IMAGE_TAG}" \
        --quiet \
        "${PROJECT_ROOT}" > /dev/null 2>&1; then
        echo "  ✅ Container built successfully"
    else
        echo "  ❌ Container build failed"
        exit 1
    fi
else
    echo "  ❌ Dockerfile not found"
    exit 1
fi

# Stage 3: Security Scan
echo
echo "🛡️  Stage 3: Security Scan"
mkdir -p "${PROJECT_ROOT}/scan-results"

if command -v trivy &> /dev/null; then
    echo "  🔍 Scanning with Trivy..."
    
    # Generate JSON report silently (extra quiet for demos)
    echo "  🔍 Scanning for vulnerabilities..."
    if trivy image --format json --output "${PROJECT_ROOT}/scan-results/trivy-results.json" "${IMAGE_TAG}" --quiet --no-progress > /dev/null 2>&1; then
        # Parse vulnerability counts
        if [[ -f "${PROJECT_ROOT}/scan-results/trivy-results.json" ]]; then
            critical=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "CRITICAL")] | length' "${PROJECT_ROOT}/scan-results/trivy-results.json" 2>/dev/null || echo "0")
            high=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "HIGH")] | length' "${PROJECT_ROOT}/scan-results/trivy-results.json" 2>/dev/null || echo "0")
            medium=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "MEDIUM")] | length' "${PROJECT_ROOT}/scan-results/trivy-results.json" 2>/dev/null || echo "0")
            low=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "LOW")] | length' "${PROJECT_ROOT}/scan-results/trivy-results.json" 2>/dev/null || echo "0")
            
            echo "  📊 Found: Critical: ${critical}, High: ${high}, Medium: ${medium}, Low: ${low}"
            echo "  ✅ Security scan completed"
        else
            echo "  ⚠️  Scan completed but no results file"
        fi
    else
        echo "  ❌ Security scan failed"
    fi
else
    echo "  ⚠️  Trivy not available, skipping security scan"
fi

# Stage 4: Security Gate
echo
echo "🚪 Stage 4: Security Policy Gate"

# Check if we're in demo mode
if [ -f "${PROJECT_ROOT}/.env.demo" ]; then
    echo "  🎭 Using demo policy (strict thresholds)"
    chmod +x "${PROJECT_ROOT}/scripts/demo-policy-strict.sh"
    
    if "${PROJECT_ROOT}/scripts/demo-policy-strict.sh"; then
        GATE_STATUS="PASS"
        echo "  ✅ Security gate PASSED"
    else
        GATE_STATUS="FAIL"
        echo "  ❌ Security gate FAILED"
    fi
elif [ -f "${PROJECT_ROOT}/scripts/security/policy-gate.sh" ]; then
    chmod +x "${PROJECT_ROOT}/scripts/security/policy-gate.sh"
    
    if "${PROJECT_ROOT}/scripts/security/policy-gate.sh" -s trivy > /dev/null 2>&1; then
        GATE_STATUS="PASS"
        echo "  ✅ Security gate PASSED"
    else
        GATE_STATUS="FAIL"
        echo "  ❌ Security gate FAILED"
    fi
else
    GATE_STATUS="SKIP"
    echo "  ⚠️  Policy gate script not found"
fi

# Stage 5: Publish (Simulated)
echo
echo "📦 Stage 5: Publish (Simulated)"
if [ "${GATE_STATUS}" = "PASS" ]; then
    echo "  ✅ Would publish to registry: localhost:8082/${IMAGE_TAG}"
    echo "  ✅ Would upload SBOM and scan results"
elif [ "${GATE_STATUS}" = "FAIL" ]; then
    echo "  ❌ Publish blocked due to security gate failure"
else
    echo "  ⚠️  Publish skipped due to missing security gate"
fi

# Summary
echo
echo "📋 Pipeline Summary"
echo "=================="
echo "Image: ${IMAGE_TAG}"
echo "Security Gate: ${GATE_STATUS}"

if [ "${GATE_STATUS}" = "PASS" ]; then
    echo "🎉 Pipeline completed successfully!"
    exit 0
elif [ "${GATE_STATUS}" = "FAIL" ]; then
    echo "💥 Pipeline failed due to security gate"
    exit 1
else
    echo "⚠️  Pipeline completed with warnings"
    exit 0
fi

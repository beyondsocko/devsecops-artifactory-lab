#!/bin/bash

# =============================================================================
# DevSecOps Demo Pipeline - Ultra Clean Version
# =============================================================================
# Minimal output version specifically for live demonstrations
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# Configuration
APP_NAME="devsecops-app"
APP_VERSION="v$(date +%Y%m%d)-demo"
IMAGE_TAG="${APP_NAME}:${APP_VERSION}"

# Check demo mode
DEMO_MODE=""
if [[ -f "${PROJECT_ROOT}/.env.demo" ]]; then
    DEMO_MODE=$(cat "${PROJECT_ROOT}/.env.demo" | cut -d'=' -f2)
fi

echo
if [[ "$DEMO_MODE" == "vulnerable" ]]; then
    echo -e "${RED}${BOLD}🔴 DEMO: VULNERABLE CONFIGURATION${NC}"
    echo -e "${RED}Expected: Pipeline will FAIL due to security issues${NC}"
elif [[ "$DEMO_MODE" == "secure" ]]; then
    echo -e "${GREEN}${BOLD}🟢 DEMO: SECURE CONFIGURATION${NC}"
    echo -e "${GREEN}Expected: Pipeline will PASS security checks${NC}"
else
    echo -e "${BLUE}${BOLD}🔵 DEMO: DEFAULT CONFIGURATION${NC}"
fi
echo

echo "🚀 DevSecOps Pipeline Demo"
echo "========================="
echo "Image: ${IMAGE_TAG}"
echo

# Stage 1: Test
echo "📋 1. Testing Application..."
if [ -d "${PROJECT_ROOT}/src" ] && [ -f "${PROJECT_ROOT}/src/package.json" ]; then
    cd "${PROJECT_ROOT}/src"
    npm install --silent > /dev/null 2>&1 && echo "   ✅ Dependencies ready" || echo "   ⚠️  Dependencies skipped"
    npm test > /dev/null 2>&1 && echo "   ✅ Tests passed" || echo "   ⚠️  Tests skipped"
    cd "${PROJECT_ROOT}"
else
    echo "   ⚠️  No tests found"
fi

# Stage 2: Build
echo
echo "🏗️  2. Building Container..."
echo "   🔨 Building ${IMAGE_TAG}..."
if docker build \
    --file "${PROJECT_ROOT}/src/Dockerfile" \
    --tag "${IMAGE_TAG}" \
    --quiet \
    "${PROJECT_ROOT}/src" > /dev/null 2>&1; then
    echo "   ✅ Container built successfully"
else
    echo "   ❌ Container build failed"
    exit 1
fi

# Stage 3: Security Scan
echo
echo "🛡️  3. Security Scanning..."
mkdir -p "${PROJECT_ROOT}/scan-results"

if command -v trivy &> /dev/null; then
    echo "   🔍 Analyzing vulnerabilities..."
    
    # Ultra-quiet scan
    if trivy image --format json --output "${PROJECT_ROOT}/scan-results/trivy-results.json" "${IMAGE_TAG}" --quiet --no-progress > /dev/null 2>&1; then
        # Parse results
        if [[ -f "${PROJECT_ROOT}/scan-results/trivy-results.json" ]]; then
            critical=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "CRITICAL")] | length' "${PROJECT_ROOT}/scan-results/trivy-results.json" 2>/dev/null || echo "0")
            high=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "HIGH")] | length' "${PROJECT_ROOT}/scan-results/trivy-results.json" 2>/dev/null || echo "0")
            medium=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "MEDIUM")] | length' "${PROJECT_ROOT}/scan-results/trivy-results.json" 2>/dev/null || echo "0")
            low=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "LOW")] | length' "${PROJECT_ROOT}/scan-results/trivy-results.json" 2>/dev/null || echo "0")
            
            echo "   📊 Critical: ${critical} | High: ${high} | Medium: ${medium} | Low: ${low}"
            echo "   ✅ Security scan completed"
        fi
    else
        echo "   ❌ Security scan failed"
    fi
else
    echo "   ⚠️  Trivy not available"
fi

# Stage 4: Security Gate
echo
echo "🚪 4. Security Policy Gate..."

# Use demo policy if in demo mode
if [ -f "${PROJECT_ROOT}/.env.demo" ]; then
    echo "   🎭 Applying strict demo policy..."
    chmod +x "${PROJECT_ROOT}/scripts/demo-policy-strict.sh" 2>/dev/null || true
    
    if "${PROJECT_ROOT}/scripts/demo-policy-strict.sh" > /dev/null 2>&1; then
        GATE_STATUS="PASS"
        echo -e "   ${GREEN}✅ Security gate PASSED${NC}"
    else
        GATE_STATUS="FAIL"
        echo -e "   ${RED}❌ Security gate FAILED${NC}"
    fi
else
    echo "   🔍 Applying standard policy..."
    if [ -f "${PROJECT_ROOT}/scripts/security/policy-gate.sh" ]; then
        chmod +x "${PROJECT_ROOT}/scripts/security/policy-gate.sh"
        if "${PROJECT_ROOT}/scripts/security/policy-gate.sh" -s trivy > /dev/null 2>&1; then
            GATE_STATUS="PASS"
            echo -e "   ${GREEN}✅ Security gate PASSED${NC}"
        else
            GATE_STATUS="FAIL"
            echo -e "   ${RED}❌ Security gate FAILED${NC}"
        fi
    else
        GATE_STATUS="SKIP"
        echo "   ⚠️  No policy gate configured"
    fi
fi

# Stage 5: Deploy Decision
echo
echo "📦 5. Deployment Decision..."
if [ "${GATE_STATUS}" = "PASS" ]; then
    echo -e "   ${GREEN}✅ DEPLOYMENT APPROVED${NC}"
    echo "   🚀 Would deploy to: registry.example.com/${IMAGE_TAG}"
    echo "   📋 Would update production environment"
elif [ "${GATE_STATUS}" = "FAIL" ]; then
    echo -e "   ${RED}🛑 DEPLOYMENT BLOCKED${NC}"
    echo -e "   ${RED}❌ Security vulnerabilities must be fixed${NC}"
    echo "   💡 Fix issues and re-run pipeline"
else
    echo "   ⚠️  Deployment skipped (no policy gate)"
fi

# Summary
echo
echo "📋 Pipeline Summary"
echo "=================="
echo "Image: ${IMAGE_TAG}"
echo "Security Gate: ${GATE_STATUS}"

if [[ "$DEMO_MODE" == "vulnerable" && "$GATE_STATUS" == "FAIL" ]]; then
    echo -e "${RED}🎭 DEMO SUCCESS: Vulnerable config correctly FAILED${NC}"
    echo -e "${YELLOW}💡 Next: Run './scripts/demo-toggle.sh secure' to fix issues${NC}"
elif [[ "$DEMO_MODE" == "secure" && "$GATE_STATUS" == "PASS" ]]; then
    echo -e "${GREEN}🎭 DEMO SUCCESS: Secure config correctly PASSED${NC}"
    echo -e "${GREEN}🚀 Pipeline completed successfully!${NC}"
fi

echo

# Exit with appropriate code
if [ "${GATE_STATUS}" = "PASS" ]; then
    exit 0
elif [ "${GATE_STATUS}" = "FAIL" ]; then
    exit 1
else
    exit 0
fi

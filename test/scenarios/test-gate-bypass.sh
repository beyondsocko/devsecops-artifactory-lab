#!/bin/bash
# Test scenario: Gate bypass mechanism

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Copy vulnerable results to scan results directory
mkdir -p "${PROJECT_ROOT}/scan-results"
cp "${PROJECT_ROOT}/test/fixtures/trivy-vulnerable.json" "${PROJECT_ROOT}/scan-results/trivy-results.json"

# Set bypass environment variables
export GATE_BYPASS_TOKEN="emergency-override-123"
export GATE_BYPASS_REASON="Critical production hotfix"

# Run policy gate with bypass
"${PROJECT_ROOT}/scripts/security/policy-gate.sh" -s trivy

echo "Expected: BYPASS (exit 0), Actual: $?"

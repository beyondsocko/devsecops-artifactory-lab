#!/bin/bash
# Test scenario: Gate should FAIL (vulnerable image)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Copy vulnerable results to scan results directory
mkdir -p "${PROJECT_ROOT}/scan-results"
cp "${PROJECT_ROOT}/test/fixtures/trivy-vulnerable.json" "${PROJECT_ROOT}/scan-results/trivy-results.json"

# Run policy gate (should fail)
if "${PROJECT_ROOT}/scripts/security/policy-gate.sh" -s trivy; then
    echo "Expected: FAIL, Actual: PASS - TEST FAILED"
    exit 1
else
    echo "Expected: FAIL, Actual: FAIL - TEST PASSED"
    exit 0
fi

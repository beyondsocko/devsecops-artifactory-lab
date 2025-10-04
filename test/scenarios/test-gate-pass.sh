#!/bin/bash
# Test scenario: Gate should PASS (clean image)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Copy clean results to scan results directory
mkdir -p "${PROJECT_ROOT}/scan-results"
cp "${PROJECT_ROOT}/test/fixtures/trivy-clean.json" "${PROJECT_ROOT}/scan-results/trivy-results.json"

# Run policy gate
"${PROJECT_ROOT}/scripts/security/policy-gate.sh" -s trivy

echo "Expected: PASS, Actual: $?"

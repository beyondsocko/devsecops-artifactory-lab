#!/bin/bash

echo "DevSecOps Security Scanner Container"
echo "====================================="
echo ""
echo "Available security tools:"

# Check Trivy
if command -v trivy >/dev/null 2>&1; then
    echo "  ✅ Trivy: $(trivy --version 2>/dev/null | head -1)"
else
    echo "  ❌ Trivy: Not available"
fi

# Check Grype
if command -v grype >/dev/null 2>&1; then
    echo "  ✅ Grype: $(grype version 2>/dev/null | head -1)"
else
    echo "  ❌ Grype: Not available"
fi

# Check Syft
if command -v syft >/dev/null 2>&1; then
    echo "  ✅ Syft: $(syft --version 2>/dev/null | head -1)"
else
    echo "  ❌ Syft: Not available"
fi

# Check OPA
if command -v opa >/dev/null 2>&1; then
    echo "  ✅ OPA: $(opa version 2>/dev/null | head -1)"
else
    echo "  ❌ OPA: Not available"
fi

echo ""
echo "Usage examples:"
echo "  docker-compose exec security-scanner trivy image alpine:latest"
echo "  docker-compose exec security-scanner /app/scripts/security/scan.sh alpine:latest"
echo "  docker-compose exec security-scanner /app/scripts/security/policy-gate.sh"
echo ""
echo "Your scripts are mounted at: /app/scripts/"
echo "Results will be saved to: /app/scan-results/"
echo ""
echo "Container ready for security operations."

# Execute whatever command was passed to the container
exec "$@"
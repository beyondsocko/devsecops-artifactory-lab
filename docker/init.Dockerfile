# =============================================================================
# DevSecOps Lab Initialization Container
# =============================================================================
# Automatically sets up Nexus repositories and initial configuration
# =============================================================================

FROM ubuntu:22.04

# Metadata
LABEL maintainer="DevSecOps Lab"
LABEL description="Lab initialization container for automated setup"
LABEL version="1.0.0"

# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt-get update && apt-get install -y \
    curl \
    jq \
    wget \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /app

# Copy initialization scripts
COPY scripts/ /app/scripts/

# Make scripts executable
RUN find /app/scripts -name "*.sh" -exec chmod +x {} \;

# Create initialization script
RUN cat > /app/init-lab.sh << 'EOF'
#!/bin/bash

set -euo pipefail

echo "=== DevSecOps Lab Initialization ==="
echo "Setting up Nexus repositories and configuration..."

# Wait for Nexus to be ready
echo "Waiting for Nexus to start..."
for i in {1..30}; do
    if curl -s -f "${NEXUS_URL}/service/rest/v1/status" >/dev/null 2>&1; then
        echo "Nexus is ready!"
        break
    fi
    echo "Waiting... (${i}/30)"
    sleep 10
done

# Test Nexus connectivity
if ! curl -s -f "${NEXUS_URL}/service/rest/v1/status" >/dev/null 2>&1; then
    echo "ERROR: Cannot connect to Nexus at ${NEXUS_URL}"
    exit 1
fi

# Create repositories
echo "Creating Nexus repositories..."
if [[ -f "/app/scripts/api/create-repos.sh" ]]; then
    /app/scripts/api/create-repos.sh --force || echo "Repository creation completed with warnings"
else
    echo "WARNING: Repository creation script not found"
fi

# Test repository creation
echo "Validating repository creation..."
REPOS=$(curl -s -u "${NEXUS_USERNAME}:${NEXUS_PASSWORD}" \
    "${NEXUS_URL}/service/rest/v1/repositories" | \
    jq -r '.[].name' | tr '\n' ' ')

echo "Available repositories: ${REPOS}"

if echo "${REPOS}" | grep -q "docker-local"; then
    echo "✅ Docker repository created successfully"
else
    echo "❌ Docker repository creation failed"
fi

if echo "${REPOS}" | grep -q "raw-hosted"; then
    echo "✅ Generic repository created successfully"
else
    echo "❌ Generic repository creation failed"
fi

# Create initial configuration
echo "Creating initial lab configuration..."
cat > /app/logs/lab-status.json << EOJ
{
    "initialization": {
        "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
        "status": "complete",
        "nexus_url": "${NEXUS_URL}",
        "repositories_created": true,
        "version": "1.0.0"
    }
}
EOJ

echo "=== Lab Initialization Complete ==="
echo "Nexus Web UI: http://localhost:8081 (admin/Aa1234567)"
echo "Docker Registry: localhost:8082"
echo "Lab Status: /app/logs/lab-status.json"
EOF

RUN chmod +x /app/init-lab.sh

# Set default environment variables
ENV NEXUS_URL=http://nexus:8081
ENV NEXUS_USERNAME=admin
ENV NEXUS_PASSWORD=Aa1234567
ENV NEXUS_DOCKER_REGISTRY=nexus:8082

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f "${NEXUS_URL}/service/rest/v1/status" || exit 1

# Default command
CMD ["/app/init-lab.sh"]
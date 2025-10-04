#!/bin/bash
set -e

source .env

echo "🏗️ Creating Nexus repositories..."

# Function to check if repository exists
repo_exists() {
    local repo_name="$1"
    curl -s -u "$NEXUS_USERNAME:$NEXUS_PASSWORD" \
         "$NEXUS_URL/service/rest/v1/repositories" | \
    jq -r '.[].name' | grep -q "^$repo_name$"
}

# Function to create Docker hosted repository
create_docker_repo() {
    local repo_name="$1"
    
    if repo_exists "$repo_name"; then
        echo "✅ Docker repository '$repo_name' already exists"
        return 0
    fi
    
    echo "Creating Docker repository: $repo_name"
    
    if curl -s -u "$NEXUS_USERNAME:$NEXUS_PASSWORD" \
            -H "Content-Type: application/json" \
            -X POST \
            "$NEXUS_URL/service/rest/v1/repositories/docker/hosted" \
            -d "{
              \"name\": \"$repo_name\",
              \"online\": true,
              \"storage\": {
                \"blobStoreName\": \"default\",
                \"strictContentTypeValidation\": true,
                \"writePolicy\": \"ALLOW\"
              },
              \"docker\": {
                \"v1Enabled\": false,
                \"forceBasicAuth\": true,
                \"httpPort\": 8082
              }
            }"; then
        echo "✅ Docker repository '$repo_name' created successfully"
    else
        echo "❌ Failed to create Docker repository '$repo_name'"
        return 1
    fi
}

# Function to create Raw repository
create_raw_repo() {
    local repo_name="$1"
    
    if repo_exists "$repo_name"; then
        echo "✅ Raw repository '$repo_name' already exists"
        return 0
    fi
    
    echo "Creating Raw repository: $repo_name"
    
    if curl -s -u "$NEXUS_USERNAME:$NEXUS_PASSWORD" \
            -H "Content-Type: application/json" \
            -X POST \
            "$NEXUS_URL/service/rest/v1/repositories/raw/hosted" \
            -d "{
              \"name\": \"$repo_name\",
              \"online\": true,
              \"storage\": {
                \"blobStoreName\": \"default\",
                \"strictContentTypeValidation\": false,
                \"writePolicy\": \"ALLOW\"
              }
            }"; then
        echo "✅ Raw repository '$repo_name' created successfully"
    else
        echo "❌ Failed to create Raw repository '$repo_name'"
        return 1
    fi
}

# Create repositories
create_docker_repo "docker-hosted"
create_raw_repo "raw-hosted"

echo ""
echo "🎉 Repository creation complete!"
echo "📋 Available repositories:"
echo "  • docker-hosted (Docker images)"
echo "  • raw-hosted (Generic artifacts + metadata files)"
echo ""
echo "💡 The raw-hosted repository will store:"
echo "  • Your application artifacts (JARs, etc.)"
echo "  • Metadata files (*.metadata.json)"
echo "  • SBOM files (*.sbom.json)"
echo "  • Security scan results"

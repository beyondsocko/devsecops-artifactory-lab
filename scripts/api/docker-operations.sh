#!/bin/bash
set -e

source .env

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${GREEN}✅ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

DOCKER_REGISTRY="localhost:8082"

# Function to configure Docker for insecure registry
configure_docker_registry() {
    print_info "🐳 Docker Registry Configuration Guide"
    echo ""
    print_warning "Docker needs to be configured for insecure registry access"
    echo ""
    
    print_info "📋 Configuration Steps:"
    echo ""
    echo "1. Open Docker Desktop Settings"
    echo "2. Go to 'Docker Engine' section"
    echo "3. Add this configuration:"
    echo ""
    echo '{'
    echo '  "insecure-registries": ["'$DOCKER_REGISTRY'"]'
    echo '}'
    echo ""
    echo "4. Click 'Apply & Restart'"
    echo ""
    
    print_info "🐧 For Linux Docker Engine:"
    echo "Edit /etc/docker/daemon.json:"
    echo ""
    echo 'sudo tee /etc/docker/daemon.json << EOF'
    echo '{'
    echo '  "insecure-registries": ["'$DOCKER_REGISTRY'"]'
    echo '}'
    echo 'EOF'
    echo ""
    echo 'sudo systemctl restart docker'
    echo ""
    
    print_info "🧪 Test Configuration:"
    echo "docker info | grep -A5 'Insecure Registries'"
    echo ""
    
    # Test if already configured
    if docker info 2>/dev/null | grep -q "$DOCKER_REGISTRY"; then
        print_status "Docker registry is already configured!"
    else
        print_warning "Please configure Docker registry and run this command again"
    fi
}

# Function to login to Nexus Docker registry
docker_login() {
    print_info "🔐 Logging into Nexus Docker registry..."
    
    if echo "$NEXUS_PASSWORD" | docker login "$DOCKER_REGISTRY" -u "$NEXUS_USERNAME" --password-stdin; then
        print_status "Successfully logged into Docker registry"
        return 0
    else
        print_error "Failed to login to Docker registry"
        print_info "💡 Make sure:"
        echo "  • Nexus is running on port 8082"
        echo "  • Docker registry is configured for insecure access"
        echo "  • Credentials in .env are correct"
        return 1
    fi
}

# Function to build and push Docker image with metadata
build_and_push_image() {
    local dockerfile_path="$1"
    local image_name="$2"
    local tag="${3:-latest}"
    local build_number="${4:-$(date +%s)}"
    local build_name="${5:-$image_name}"
    
    # Validate inputs
    if [ ! -f "$dockerfile_path" ]; then
        print_error "Dockerfile not found: $dockerfile_path"
        return 1
    fi
    
    local full_image_name="$DOCKER_REGISTRY/$image_name:$tag"
    local build_image_name="$DOCKER_REGISTRY/$image_name:build-$build_number"
    local latest_image_name="$DOCKER_REGISTRY/$image_name:latest"
    
    print_info "🏗️  Building Docker image..."
    print_info "📁 Dockerfile: $dockerfile_path"
    print_info "🏷️  Image: $full_image_name"
    print_info "🔢 Build: $build_number"
    
    # Get git info safely
    local git_revision="unknown"
    local git_branch="main"
    if git rev-parse HEAD >/dev/null 2>&1; then
        git_revision=$(git rev-parse HEAD | head -1 | tr -d '\n\r')
        git_branch=$(git rev-parse --abbrev-ref HEAD | head -1 | tr -d '\n\r')
    fi
    
    # Build image with comprehensive metadata labels
    print_info "🔨 Building with metadata labels..."
    if docker build \
        --label "build.name=$build_name" \
        --label "build.number=$build_number" \
        --label "build.timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        --label "vcs.revision=$git_revision" \
        --label "vcs.branch=$git_branch" \
        --label "security.scanned=false" \
        --label "security.gate=pending" \
        --label "image.registry=$DOCKER_REGISTRY" \
        --label "image.repository=$image_name" \
        --label "image.tag=$tag" \
        --label "metadata.format=nexus-docker-v1" \
        -t "$full_image_name" \
        -t "$build_image_name" \
        -t "$latest_image_name" \
        -f "$dockerfile_path" \
        .; then
        print_status "Docker image built successfully"
    else
        print_error "Failed to build Docker image"
        return 1
    fi
    
    # Login to registry
    if ! docker_login; then
        return 1
    fi
    
    # Push all tags
    print_info "📤 Pushing images to registry..."
    
    local push_success=true
    
    for image in "$full_image_name" "$build_image_name" "$latest_image_name"; do
        print_info "Pushing: $image"
        if docker push "$image"; then
            print_status "Pushed: $image"
        else
            print_error "Failed to push: $image"
            push_success=false
        fi
    done
    
    if [ "$push_success" = true ]; then
        print_status "🎉 All images pushed successfully!"
        echo ""
        print_info "📦 Available images:"
        echo "  • $full_image_name"
        echo "  • $build_image_name"
        echo "  • $latest_image_name"
        echo ""
        
        # Create image metadata file in raw repository
        create_image_metadata "$image_name" "$tag" "$build_number" "$build_name" "$git_revision" "$git_branch"
        
        return 0
    else
        print_error "Some image pushes failed"
        return 1
    fi
}

# Function to create image metadata in raw repository
create_image_metadata() {
    local image_name="$1"
    local tag="$2"
    local build_number="$3"
    local build_name="$4"
    local git_revision="$5"
    local git_branch="$6"
    
    print_info "📋 Creating image metadata..."
    
    local metadata_path="docker-images/$image_name/$tag/image.metadata.json"
    local temp_metadata="/tmp/docker_metadata_$$.json"
    
    # Create comprehensive image metadata
    jq -n \
      --arg image_name "$image_name" \
      --arg tag "$tag" \
      --arg registry "$DOCKER_REGISTRY" \
      --arg build_name "$build_name" \
      --argjson build_number "$build_number" \
      --arg build_timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      --arg git_revision "$git_revision" \
      --arg git_branch "$git_branch" \
      --arg pushed_by "$(whoami | tr -d '\n\r')" \
      '{
        image: {
          name: $image_name,
          tag: $tag,
          registry: $registry,
          full_name: "\($registry)/\($image_name):\($tag)",
          type: "docker"
        },
        build: {
          name: $build_name,
          number: $build_number,
          timestamp: $build_timestamp,
          vcs: {
            revision: $git_revision,
            branch: $git_branch
          }
        },
        security: {
          gate: "pending",
          scan: {
            status: "not_scanned",
            critical: null,
            high: null,
            medium: null,
            low: null
          }
        },
        registry: {
          pushed_timestamp: $build_timestamp,
          pushed_by: $pushed_by,
          available_tags: [
            $tag,
            "build-\($build_number)",
            "latest"
          ]
        },
        metadata: {
          format: "nexus-docker-metadata-v1",
          created: $build_timestamp
        }
      }' > "$temp_metadata"
    
    # Upload metadata to raw repository
    if curl -s -u "$NEXUS_USERNAME:$NEXUS_PASSWORD" \
            -X PUT \
            "$NEXUS_URL/repository/raw-hosted/$metadata_path" \
            -T "$temp_metadata" \
            -H "Content-Type: application/json" \
            -w "%{http_code}" | grep -q "20[01]"; then
        print_status "Image metadata created: $metadata_path"
    else
        print_warning "Failed to create image metadata (non-critical)"
    fi
    
    rm -f "$temp_metadata"
}

# Function to pull and inspect image
pull_and_inspect_image() {
    local image_name="$1"
    local tag="${2:-latest}"
    
    local full_image_name="$DOCKER_REGISTRY/$image_name:$tag"
    
    print_info "📥 Pulling image: $full_image_name"
    
    # Login first
    if ! docker_login; then
        return 1
    fi
    
    # Pull image
    if docker pull "$full_image_name"; then
        print_status "Image pulled successfully"
    else
        print_error "Failed to pull image"
        return 1
    fi
    
    echo ""
    print_info "🔍 Image Inspection:"
    echo ""
    
    # Show image details
    print_info "📊 Image Details:"
    docker images "$full_image_name" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
    
    echo ""
    print_info "🏷️  Image Labels (Metadata):"
    docker inspect "$full_image_name" | jq -r '.[0].Config.Labels | to_entries[] | "  \(.key): \(.value)"'
    
    echo ""
    print_info "📋 Image History (Last 5 layers):"
    docker history "$full_image_name" --format "table {{.CreatedBy}}\t{{.Size}}" | head -6
}

# Function to list images in registry
list_registry_images() {
    print_info "📦 Listing Docker images in registry..."
    
    # Query Nexus for Docker repository contents
    curl -s -u "$NEXUS_USERNAME:$NEXUS_PASSWORD" \
         "$NEXUS_URL/service/rest/v1/components?repository=docker-hosted" | \
    jq -r '.items[] | "🐳 \(.name):\(.version) - \(.assets | length) layer(s)"'
    
    echo ""
    print_info "📋 Image Metadata Files:"
    curl -s -u "$NEXUS_USERNAME:$NEXUS_PASSWORD" \
         "$NEXUS_URL/service/rest/v1/search?repository=raw-hosted&q=docker-images" | \
    jq -r '.items[].assets[] | select(.path | contains("image.metadata.json")) | "📋 \(.path)"'
}

# Function to update image security status
update_image_security() {
    local image_name="$1"
    local tag="$2"
    local gate_status="$3"
    local critical="${4:-0}"
    local high="${5:-0}"
    local medium="${6:-0}"
    local low="${7:-0}"
    
    print_info "🔒 Updating image security status..."
    
    local metadata_path="docker-images/$image_name/$tag/image.metadata.json"
    local temp_file="/tmp/image_security_update_$$.json"
    
    # Download current metadata
    if curl -s -f -u "$NEXUS_USERNAME:$NEXUS_PASSWORD" \
            "$NEXUS_URL/repository/raw-hosted/$metadata_path" > "$temp_file"; then
        
        # Update security section
        jq --arg gate "$gate_status" \
           --argjson critical "$critical" \
           --argjson high "$high" \
           --argjson medium "$medium" \
           --argjson low "$low" \
           --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
           '.security.gate = $gate | 
            .security.scan.status = "scanned" |
            .security.scan.critical = $critical |
            .security.scan.high = $high |
            .security.scan.medium = $medium |
            .security.scan.low = $low |
            .security.scan.timestamp = $timestamp' \
           "$temp_file" > "${temp_file}.updated"
        
        # Upload updated metadata
        if curl -s -u "$NEXUS_USERNAME:$NEXUS_PASSWORD" \
                -X PUT \
                "$NEXUS_URL/repository/raw-hosted/$metadata_path" \
                -T "${temp_file}.updated" \
                -H "Content-Type: application/json" \
                -w "%{http_code}" | grep -q "20[01]"; then
            print_status "Image security status updated: $gate_status"
        else
            print_error "Failed to update image security status"
        fi
        
        rm -f "$temp_file" "${temp_file}.updated"
    else
        print_error "Image metadata not found: $metadata_path"
        return 1
    fi
}

# Command line interface
case "$1" in
    "configure")
        configure_docker_registry
        ;;
    "login")
        docker_login
        ;;
    "build-push")
        if [ "$#" -lt 3 ]; then
            echo "Usage: $0 build-push <dockerfile_path> <image_name> [tag] [build_number] [build_name]"
            echo ""
            echo "Examples:"
            echo "  $0 build-push src/Dockerfile myapp"
            echo "  $0 build-push src/Dockerfile myapp v1.0 123"
            echo "  $0 build-push src/Dockerfile myapp latest 123 myapp-build"
            exit 1
        fi
        build_and_push_image "$2" "$3" "$4" "$5" "$6"
        ;;
    "pull-inspect")
        if [ "$#" -lt 2 ]; then
            echo "Usage: $0 pull-inspect <image_name> [tag]"
            echo ""
            echo "Examples:"
            echo "  $0 pull-inspect myapp"
            echo "  $0 pull-inspect myapp v1.0"
            exit 1
        fi
        pull_and_inspect_image "$2" "$3"
        ;;
    "list")
        list_registry_images
        ;;
    "update-security")
        if [ "$#" -lt 4 ]; then
            echo "Usage: $0 update-security <image_name> <tag> <gate_status> [critical] [high] [medium] [low]"
            echo ""
            echo "Examples:"
            echo "  $0 update-security myapp latest passed"
            echo "  $0 update-security myapp v1.0 failed 2 5 10 3"
            exit 1
        fi
        update_image_security "$2" "$3" "$4" "$5" "$6" "$7" "$8"
        ;;
    *)
        echo "🐳 DevSecOps Lab - Docker Registry Operations"
        echo "Usage: $0 {configure|login|build-push|pull-inspect|list|update-security}"
        echo ""
        echo "Commands:"
        echo "  configure        Show Docker registry configuration guide"
        echo "  login           Login to Nexus Docker registry"
        echo "  build-push      Build and push Docker image with metadata"
        echo "  pull-inspect    Pull and inspect Docker image"
        echo "  list            List all images in registry"
        echo "  update-security Update image security gate status"
        echo ""
        echo "Examples:"
        echo "  $0 configure"
        echo "  $0 build-push src/Dockerfile myapp v1.0 123"
        echo "  $0 pull-inspect myapp latest"
        echo "  $0 list"
        ;;
esac
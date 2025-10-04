#!/bin/bash
set -e

source .env

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to search artifacts by name
search_artifacts() {
    local repo_name="$1"
    local query="${2:-*}"
    
    print_info "Searching artifacts in repository: $repo_name"
    print_info "Query: $query"
    echo ""
    
    curl -s -u "$NEXUS_USERNAME:$NEXUS_PASSWORD" \
         "$NEXUS_URL/service/rest/v1/search?repository=$repo_name&q=$query" | \
    jq -r '.items[] | "📦 \(.name) v\(.version // "unknown") - \(.assets[0].path)"'
}

# Function to get detailed artifact info
get_artifact_info() {
    local repo_name="$1"
    local artifact_path="$2"
    
    print_info "Getting artifact information"
    print_info "Repository: $repo_name"
    print_info "Path: $artifact_path"
    echo ""
    
    # Get basic component info
    print_info "📋 Basic Information:"
    curl -s -u "$NEXUS_USERNAME:$NEXUS_PASSWORD" \
         "$NEXUS_URL/service/rest/v1/components?repository=$repo_name" | \
    jq --arg path "$artifact_path" \
       '.items[] | select(.assets[].path | contains($path)) | {
         name: .name,
         version: .version,
         format: .format,
         assets: [.assets[] | {path: .path, size: .fileSize, checksum: .checksum}]
       }'
    
    echo ""
    
    # Try to get metadata if it exists
    local metadata_path="$artifact_path.metadata.json"
    print_info "🔍 Metadata Information:"
    
    if curl -s -f -u "$NEXUS_USERNAME:$NEXUS_PASSWORD" \
            "$NEXUS_URL/repository/$repo_name/$metadata_path" > /dev/null 2>&1; then
        curl -s -u "$NEXUS_USERNAME:$NEXUS_PASSWORD" \
             "$NEXUS_URL/repository/$repo_name/$metadata_path" | jq '.'
    else
        print_warning "No metadata file found for this artifact"
    fi
}

# Function to list all artifacts in repository
list_repository_contents() {
    local repo_name="$1"
    local format="${2:-all}"
    
    print_info "Listing contents of repository: $repo_name"
    if [ "$format" != "all" ]; then
        print_info "Format filter: $format"
    fi
    echo ""
    
    local jq_filter='.items[]'
    if [ "$format" != "all" ]; then
        jq_filter="$jq_filter | select(.format == \"$format\")"
    fi
    
    curl -s -u "$NEXUS_USERNAME:$NEXUS_PASSWORD" \
         "$NEXUS_URL/service/rest/v1/components?repository=$repo_name" | \
    jq -r "$jq_filter | \"📦 \(.name) v\(.version // \"unknown\") [\(.format)] - \(.assets | length) asset(s)\""
    
    echo ""
    print_info "📊 Repository Statistics:"
    curl -s -u "$NEXUS_USERNAME:$NEXUS_PASSWORD" \
         "$NEXUS_URL/service/rest/v1/components?repository=$repo_name" | \
    jq -r "\"Total components: \(.items | length)\""
}

# Function to get security gate status for artifacts
get_security_status() {
    local repo_name="$1"
    local build_name="${2:-all}"
    
    print_info "Security Gate Status Report"
    print_info "Repository: $repo_name"
    if [ "$build_name" != "all" ]; then
        print_info "Build filter: $build_name"
    fi
    echo ""
    
    # Get all components
    local components=$(curl -s -u "$NEXUS_USERNAME:$NEXUS_PASSWORD" \
                           "$NEXUS_URL/service/rest/v1/components?repository=$repo_name")
    
    # For each component, try to get its metadata
    echo "$components" | jq -r '.items[].assets[].path' | grep -v '\.metadata\.json$' | while read -r asset_path; do
        local metadata_path="$asset_path.metadata.json"
        
        # Try to download metadata
        local metadata=$(curl -s -f -u "$NEXUS_USERNAME:$NEXUS_PASSWORD" \
                              "$NEXUS_URL/repository/$repo_name/$metadata_path" 2>/dev/null)
        
        if [ -n "$metadata" ]; then
            local artifact_build=$(echo "$metadata" | jq -r '.build.name // "unknown"')
            local gate_status=$(echo "$metadata" | jq -r '.security.gate // "unknown"')
            local critical=$(echo "$metadata" | jq -r '.security.scan.critical // "N/A"')
            local high=$(echo "$metadata" | jq -r '.security.scan.high // "N/A"')
            
            # Apply build filter if specified
            if [ "$build_name" = "all" ] || [ "$artifact_build" = "$build_name" ]; then
                case "$gate_status" in
                    "passed")
                        echo -e "${GREEN}✅ $asset_path${NC}"
                        ;;
                    "failed")
                        echo -e "${RED}❌ $asset_path${NC}"
                        ;;
                    "pending")
                        echo -e "${YELLOW}⏳ $asset_path${NC}"
                        ;;
                    *)
                        echo -e "${BLUE}❓ $asset_path${NC}"
                        ;;
                esac
                echo "   Build: $artifact_build | Gate: $gate_status | Critical: $critical | High: $high"
                echo ""
            fi
        fi
    done
}

# Function to query by build information
query_by_build() {
    local repo_name="$1"
    local build_name="$2"
    local build_number="${3:-all}"
    
    print_info "Querying artifacts by build information"
    print_info "Repository: $repo_name"
    print_info "Build name: $build_name"
    if [ "$build_number" != "all" ]; then
        print_info "Build number: $build_number"
    fi
    echo ""
    
    # Get all components and check their metadata
    local components=$(curl -s -u "$NEXUS_USERNAME:$NEXUS_PASSWORD" \
                           "$NEXUS_URL/service/rest/v1/components?repository=$repo_name")
    
    local found=0
    echo "$components" | jq -r '.items[].assets[].path' | grep -v '\.metadata\.json$' | while read -r asset_path; do
        local metadata_path="$asset_path.metadata.json"
        
        # Try to download metadata
        local metadata=$(curl -s -f -u "$NEXUS_USERNAME:$NEXUS_PASSWORD" \
                              "$NEXUS_URL/repository/$repo_name/$metadata_path" 2>/dev/null)
        
        if [ -n "$metadata" ]; then
            local artifact_build=$(echo "$metadata" | jq -r '.build.name // ""')
            local artifact_build_num=$(echo "$metadata" | jq -r '.build.number // ""')
            
            # Check if this matches our search criteria
            if [ "$artifact_build" = "$build_name" ]; then
                if [ "$build_number" = "all" ] || [ "$artifact_build_num" = "$build_number" ]; then
                    echo "📦 Found: $asset_path"
                    echo "$metadata" | jq '{
                      build: .build,
                      security: .security,
                      artifact: .artifact
                    }'
                    echo ""
                    found=$((found + 1))
                fi
            fi
        fi
    done
    
    if [ $found -eq 0 ]; then
        print_warning "No artifacts found matching the criteria"
    fi
}

# Command line interface
case "$1" in
    "search")
        if [ "$#" -lt 2 ]; then
            echo "Usage: $0 search <repo_name> [query]"
            exit 1
        fi
        search_artifacts "$2" "$3"
        ;;
    "info")
        if [ "$#" -lt 3 ]; then
            echo "Usage: $0 info <repo_name> <artifact_path>"
            exit 1
        fi
        get_artifact_info "$2" "$3"
        ;;
    "list")
        if [ "$#" -lt 2 ]; then
            echo "Usage: $0 list <repo_name> [format]"
            exit 1
        fi
        list_repository_contents "$2" "$3"
        ;;
    "security")
        if [ "$#" -lt 2 ]; then
            echo "Usage: $0 security <repo_name> [build_name]"
            exit 1
        fi
        get_security_status "$2" "$3"
        ;;
    "build")
        if [ "$#" -lt 3 ]; then
            echo "Usage: $0 build <repo_name> <build_name> [build_number]"
            exit 1
        fi
        query_by_build "$2" "$3" "$4"
        ;;
    *)
        echo "DevSecOps Lab - Artifact Query & Management"
        echo "Usage: $0 {search|info|list|security|build} [options]"
        echo ""
        echo "Commands:"
        echo "  search    Search artifacts by name/pattern"
        echo "  info      Get detailed artifact information"
        echo "  list      List all artifacts in repository"
        echo "  security  Show security gate status for all artifacts"
        echo "  build     Query artifacts by build information"
        echo ""
        echo "Examples:"
        echo "  $0 search raw-hosted myapp"
        echo "  $0 info raw-hosted com/example/myapp/1.0/myapp-1.0.jar"
        echo "  $0 list raw-hosted"
        echo "  $0 security raw-hosted"
        echo "  $0 build raw-hosted myapp 123"
        ;;
esac
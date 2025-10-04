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

# Function to safely get git info
get_git_info() {
    local info_type="$1"
    case "$info_type" in
        "revision")
            git rev-parse HEAD 2>/dev/null | head -1 | tr -d '\n\r' || echo "unknown"
            ;;
        "branch")
            git rev-parse --abbrev-ref HEAD 2>/dev/null | head -1 | tr -d '\n\r' || echo "main"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Function to upload artifact with bulletproof metadata
upload_raw_artifact() {
    local file_path="$1"
    local repo_name="$2"
    local artifact_path="$3"
    local build_name="${4:-unknown}"
    local build_number="${5:-1}"
    local vcs_revision="${6:-$(get_git_info revision)}"
    
    # Validate inputs
    if [ ! -f "$file_path" ]; then
        print_error "File not found: $file_path"
        return 1
    fi
    
    print_info "🚀 Starting artifact upload..."
    print_info "📁 File: $file_path"
    print_info "📦 Repository: $repo_name"
    print_info "🎯 Path: $artifact_path"
    print_info "🏗️  Build: $build_name #$build_number"
    
    # Calculate checksums safely
    local file_size=$(stat -c%s "$file_path" 2>/dev/null || stat -f%z "$file_path" 2>/dev/null || echo "0")
    local file_md5=$(md5sum "$file_path" 2>/dev/null | cut -d' ' -f1 || md5 -q "$file_path" 2>/dev/null || echo "unknown")
    local file_sha1=$(sha1sum "$file_path" 2>/dev/null | cut -d' ' -f1 || shasum -a 1 "$file_path" 2>/dev/null | cut -d' ' -f1 || echo "unknown")
    
    # Upload main artifact
    print_info "📤 Uploading main artifact..."
    local upload_response=$(curl -s -w "%{http_code}" -u "$NEXUS_USERNAME:$NEXUS_PASSWORD" \
                                 -X PUT \
                                 "$NEXUS_URL/repository/$repo_name/$artifact_path" \
                                 -T "$file_path" \
                                 -H "Content-Type: application/octet-stream")
    
    local http_code="${upload_response: -3}"
    if [[ "$http_code" =~ ^20[0-9]$ ]]; then
        print_status "Main artifact uploaded successfully"
    else
        print_error "Failed to upload main artifact (HTTP: $http_code)"
        return 1
    fi
    
    # Create metadata using jq (bulletproof JSON generation)
    print_info "📋 Creating metadata..."
    local metadata_file="/tmp/metadata_$$.json"
    
    jq -n \
      --arg artifact_path "$artifact_path" \
      --arg filename "$(basename "$file_path")" \
      --argjson file_size "$file_size" \
      --arg file_md5 "$file_md5" \
      --arg file_sha1 "$file_sha1" \
      --arg build_name "$build_name" \
      --argjson build_number "$build_number" \
      --arg build_timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      --arg vcs_revision "$vcs_revision" \
      --arg vcs_branch "$(get_git_info branch)" \
      --arg upload_timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      --arg uploaded_by "$(whoami | tr -d '\n\r')" \
      '{
        artifact: {
          path: $artifact_path,
          filename: $filename,
          size: $file_size,
          checksums: {
            md5: $file_md5,
            sha1: $file_sha1
          }
        },
        build: {
          name: $build_name,
          number: $build_number,
          timestamp: $build_timestamp,
          vcs: {
            revision: $vcs_revision,
            branch: $vcs_branch
          }
        },
        security: {
          gate: "pending",
          scan: {
            status: "not_scanned",
            critical: null,
            high: null,
            medium: null,
            low: null,
            timestamp: null
          }
        },
        metadata: {
          upload_timestamp: $upload_timestamp,
          uploaded_by: $uploaded_by,
          format: "nexus-metadata-v1"
        }
      }' > "$metadata_file"
    
    # Upload metadata
    print_info "📤 Uploading metadata..."
    local metadata_path="$artifact_path.metadata.json"
    local metadata_response=$(curl -s -w "%{http_code}" -u "$NEXUS_USERNAME:$NEXUS_PASSWORD" \
                                   -X PUT \
                                   "$NEXUS_URL/repository/$repo_name/$metadata_path" \
                                   -T "$metadata_file" \
                                   -H "Content-Type: application/json")
    
    local metadata_http_code="${metadata_response: -3}"
    if [[ "$metadata_http_code" =~ ^20[0-9]$ ]]; then
        print_status "Metadata uploaded successfully"
    else
        print_error "Failed to upload metadata (HTTP: $metadata_http_code)"
        rm -f "$metadata_file"
        return 1
    fi
    
    # Cleanup
    rm -f "$metadata_file"
    
    # Success summary
    echo ""
    print_status "🎉 Upload completed successfully!"
    echo ""
    print_info "📦 Artifact: $NEXUS_URL/repository/$repo_name/$artifact_path"
    print_info "📋 Metadata: $NEXUS_URL/repository/$repo_name/$metadata_path"
    echo ""
    print_info "🔍 View metadata:"
    echo "curl -u $NEXUS_USERNAME:**** '$NEXUS_URL/repository/$repo_name/$metadata_path' | jq '.'"
    echo ""
}

# Function to update security gate (bulletproof)
update_security_gate() {
    local repo_name="$1"
    local artifact_path="$2"
    local gate_status="$3"
    local critical="${4:-0}"
    local high="${5:-0}"
    local medium="${6:-0}"
    local low="${7:-0}"
    
    local metadata_path="$artifact_path.metadata.json"
    local temp_file="/tmp/metadata_update_$$.json"
    
    print_info "🔒 Updating security gate: $gate_status"
    
    # Download current metadata
    if ! curl -s -f -u "$NEXUS_USERNAME:$NEXUS_PASSWORD" \
              "$NEXUS_URL/repository/$repo_name/$metadata_path" > "$temp_file"; then
        print_error "Failed to download current metadata"
        return 1
    fi
    
    # Update security section using jq
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
    local update_response=$(curl -s -w "%{http_code}" -u "$NEXUS_USERNAME:$NEXUS_PASSWORD" \
                                 -X PUT \
                                 "$NEXUS_URL/repository/$repo_name/$metadata_path" \
                                 -T "${temp_file}.updated" \
                                 -H "Content-Type: application/json")
    
    local update_http_code="${update_response: -3}"
    if [[ "$update_http_code" =~ ^20[0-9]$ ]]; then
        print_status "Security gate updated: $gate_status"
    else
        print_error "Failed to update security gate (HTTP: $update_http_code)"
        rm -f "$temp_file" "${temp_file}.updated"
        return 1
    fi
    
    # Cleanup
    rm -f "$temp_file" "${temp_file}.updated"
}

# Command line interface
case "$1" in
    "upload")
        if [ "$#" -lt 4 ]; then
            echo "Usage: $0 upload <file_path> <repo_name> <artifact_path> [build_name] [build_number] [vcs_revision]"
            echo ""
            echo "Examples:"
            echo "  $0 upload myapp.jar raw-hosted com/example/myapp/1.0/myapp-1.0.jar"
            echo "  $0 upload myapp.jar raw-hosted com/example/myapp/1.0/myapp-1.0.jar myapp 123"
            exit 1
        fi
        upload_raw_artifact "$2" "$3" "$4" "$5" "$6" "$7"
        ;;
    "update-gate")
        if [ "$#" -lt 4 ]; then
            echo "Usage: $0 update-gate <repo_name> <artifact_path> <gate_status> [critical] [high] [medium] [low]"
            echo ""
            echo "Examples:"
            echo "  $0 update-gate raw-hosted com/example/myapp/1.0/myapp-1.0.jar passed"
            echo "  $0 update-gate raw-hosted com/example/myapp/1.0/myapp-1.0.jar failed 2 5 10 3"
            exit 1
        fi
        update_security_gate "$2" "$3" "$4" "$5" "$6" "$7" "$8"
        ;;
    *)
        echo "🚀 DevSecOps Lab - Enterprise Artifact Management"
        echo "Usage: $0 {upload|update-gate} [options]"
        echo ""
        echo "Commands:"
        echo "  upload       Upload artifact with comprehensive metadata"
        echo "  update-gate  Update security gate status with vulnerability counts"
        echo ""
        echo "Examples:"
        echo "  $0 upload myapp.jar raw-hosted com/example/myapp/1.0/myapp-1.0.jar myapp 123"
        echo "  $0 update-gate raw-hosted com/example/myapp/1.0/myapp-1.0.jar passed"
        ;;
esac
#!/bin/bash

# =============================================================================
# Containerized Security Scanning Script
# =============================================================================
# Uses the Terraform-deployed Trivy container for security scanning
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_status() { echo -e "${GREEN}✅ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_scan() { echo -e "${CYAN}🔍 $1${NC}"; }

# Configuration
CONTAINER_NAME="devsecops-lab-security-scanner"
SCAN_DIR="scan-results"

# Function to check if container is running
check_container() {
    if ! docker ps | grep -q "$CONTAINER_NAME"; then
        print_warning "Security scanner container not running"
        print_info "Using local Trivy instead (recommended)"
        return 1
    fi
    
    # Check if container is healthy and not restarting
    local container_state=$(docker inspect --format='{{.State.Status}}' "$CONTAINER_NAME" 2>/dev/null || echo "unknown")
    local health_status=$(docker inspect --format='{{.State.Health.Status}}' "$CONTAINER_NAME" 2>/dev/null || echo "none")
    
    if [[ "$container_state" == "restarting" ]]; then
        print_warning "Security scanner container is restarting - using local Trivy instead"
        return 1
    elif [[ "$health_status" == "healthy" ]]; then
        print_status "Security scanner container is healthy"
    elif [[ "$health_status" == "starting" ]]; then
        print_info "Security scanner container is starting up..."
        sleep 15
        # Recheck after wait
        container_state=$(docker inspect --format='{{.State.Status}}' "$CONTAINER_NAME" 2>/dev/null || echo "unknown")
        if [[ "$container_state" == "restarting" ]]; then
            print_warning "Container still restarting - falling back to local Trivy"
            return 1
        fi
    else
        print_warning "Security scanner container health status: $health_status - falling back to local Trivy"
        return 1
    fi
}

# Function to scan image using containerized Trivy
scan_image_containerized() {
    local image="$1"
    local output_dir="${2:-$SCAN_DIR}"
    
    print_scan "Scanning $image using containerized Trivy"
    
    # Create output directory
    mkdir -p "$output_dir"
    
    # Check container status
    if ! check_container; then
        return 1
    fi
    
    print_info "Updating Trivy vulnerability database..."
    docker exec "$CONTAINER_NAME" trivy image --download-db-only
    
    print_info "Generating comprehensive security reports..."
    
    # JSON format (for automation)
    docker exec "$CONTAINER_NAME" trivy image --format json "$image" > "$output_dir/trivy-containerized.json"
    
    # Table format (human readable)
    docker exec "$CONTAINER_NAME" trivy image --format table "$image" > "$output_dir/trivy-containerized.txt"
    
    # SARIF format (for security tools)
    docker exec "$CONTAINER_NAME" trivy image --format sarif "$image" > "$output_dir/trivy-containerized.sarif"
    
    # Critical and High only
    docker exec "$CONTAINER_NAME" trivy image --severity CRITICAL,HIGH --format table "$image" > "$output_dir/trivy-critical-high.txt"
    
    # Secrets scanning
    docker exec "$CONTAINER_NAME" trivy image --scanners secret --format json "$image" > "$output_dir/trivy-secrets.json"
    
    # Configuration scanning
    docker exec "$CONTAINER_NAME" trivy image --scanners config --format json "$image" > "$output_dir/trivy-config.json"
    
    print_status "Containerized Trivy scan completed"
    
    # Parse vulnerability counts
    local critical=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "CRITICAL")] | length' "$output_dir/trivy-containerized.json" 2>/dev/null || echo "0")
    local high=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "HIGH")] | length' "$output_dir/trivy-containerized.json" 2>/dev/null || echo "0")
    local medium=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "MEDIUM")] | length' "$output_dir/trivy-containerized.json" 2>/dev/null || echo "0")
    local low=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "LOW")] | length' "$output_dir/trivy-containerized.json" 2>/dev/null || echo "0")
    
    print_info "📊 Containerized Trivy Results: Critical: $critical, High: $high, Medium: $medium, Low: $low"
    
    return 0
}

# Function to scan filesystem using containerized Trivy
scan_filesystem_containerized() {
    local path="$1"
    local output_dir="${2:-$SCAN_DIR}"
    
    print_scan "Scanning filesystem $path using containerized Trivy"
    
    # Create output directory
    mkdir -p "$output_dir"
    
    # Check container status
    if ! check_container; then
        return 1
    fi
    
    # Mount the path into container and scan
    docker run --rm \
        -v "$path:/scan:ro" \
        -v "$(pwd)/$output_dir:/output" \
        aquasec/trivy:latest \
        fs --format json --output /output/trivy-fs.json /scan
    
    print_status "Filesystem scan completed"
}

# Function to test containerized scanning
test_containerized_scan() {
    print_info "🧪 Testing containerized security scanning"
    
    if ! check_container; then
        print_error "Cannot test - container not available"
        return 1
    fi
    
    # Test with a small image
    print_info "Testing with alpine:latest image..."
    if scan_image_containerized "alpine:latest" "test-scan"; then
        print_status "Containerized scanning test successful"
        
        # Show results
        if [[ -f "test-scan/trivy-containerized.json" ]]; then
            local vuln_count=$(jq '[.Results[]?.Vulnerabilities[]?] | length' "test-scan/trivy-containerized.json" 2>/dev/null || echo "0")
            print_info "Found $vuln_count vulnerabilities in alpine:latest"
        fi
        
        # Cleanup test results
        rm -rf test-scan/
        return 0
    else
        print_error "Containerized scanning test failed"
        return 1
    fi
}

# Main execution
main() {
    echo "🔐 DevSecOps Lab - Containerized Security Scanning"
    echo "================================================="
    echo
    
    case "${1:-help}" in
        "scan")
            if [[ -z "${2:-}" ]]; then
                print_error "Usage: $0 scan <image-name> [output-dir]"
                exit 1
            fi
            scan_image_containerized "$2" "${3:-$SCAN_DIR}"
            ;;
        "fs")
            if [[ -z "${2:-}" ]]; then
                print_error "Usage: $0 fs <path> [output-dir]"
                exit 1
            fi
            scan_filesystem_containerized "$2" "${3:-$SCAN_DIR}"
            ;;
        "test")
            test_containerized_scan
            ;;
        "status")
            check_container
            ;;
        "help"|*)
            echo "Usage: $0 <command> [options]"
            echo
            echo "Commands:"
            echo "  scan <image>     - Scan container image"
            echo "  fs <path>        - Scan filesystem path"
            echo "  test             - Test containerized scanning"
            echo "  status           - Check container status"
            echo "  help             - Show this help"
            echo
            echo "Examples:"
            echo "  $0 scan alpine:latest"
            echo "  $0 scan myapp:v1.0 custom-output/"
            echo "  $0 fs /path/to/source"
            echo "  $0 test"
            ;;
    esac
}

# Run main function
main "$@"

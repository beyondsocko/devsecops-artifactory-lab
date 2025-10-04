#!/bin/bash
set -e

source .env

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

# Function to scan image with Trivy
scan_with_trivy() {
    local image="$1"
    local output_dir="$2"
    
    print_scan "Scanning with Trivy: $image"
    
    # Create output directory
    mkdir -p "$output_dir"
    
    # Update Trivy database
    print_info "Updating Trivy vulnerability database..."
    trivy image --download-db-only
    
    print_info "Generating Trivy reports..."
    
    # JSON format (for parsing and automation)
    trivy image --format json --output "$output_dir/trivy-report.json" "$image"
    
    # Table format (human readable)
    trivy image --format table --output "$output_dir/trivy-report.txt" "$image"
    
    # SARIF format (for security tools integration)
    trivy image --format sarif --output "$output_dir/trivy-report.sarif" "$image"
    
    # Critical and High only (for quick review)
    trivy image --severity CRITICAL,HIGH --format table --output "$output_dir/trivy-critical-high.txt" "$image"
    
    # Secrets scanning
    trivy image --scanners secret --format json --output "$output_dir/trivy-secrets.json" "$image"
    
    # Configuration scanning
    trivy image --scanners config --format json --output "$output_dir/trivy-config.json" "$image"
    
    print_status "Trivy scan completed"
    
    # Parse and return vulnerability counts
    local critical=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "CRITICAL")] | length' "$output_dir/trivy-report.json" 2>/dev/null || echo "0")
    local high=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "HIGH")] | length' "$output_dir/trivy-report.json" 2>/dev/null || echo "0")
    local medium=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "MEDIUM")] | length' "$output_dir/trivy-report.json" 2>/dev/null || echo "0")
    local low=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "LOW")] | length' "$output_dir/trivy-report.json" 2>/dev/null || echo "0")
    local unknown=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "UNKNOWN")] | length' "$output_dir/trivy-report.json" 2>/dev/null || echo "0")
    
    print_info "📊 Trivy Results: Critical: $critical, High: $high, Medium: $medium, Low: $low, Unknown: $unknown"
    
    # Return vulnerability counts
    echo "$critical,$high,$medium,$low,$unknown"
}

# Function to scan image with Grype
scan_with_grype() {
    local image="$1"
    local output_dir="$2"
    
    print_scan "Scanning with Grype: $image"
    
    # Create output directory
    mkdir -p "$output_dir"
    
    print_info "Generating Grype reports..."
    
    # JSON format (for parsing)
    grype "$image" -o json > "$output_dir/grype-report.json"
    
    # Table format (human readable)
    grype "$image" -o table > "$output_dir/grype-report.txt"
    
    # SARIF format
    grype "$image" -o sarif > "$output_dir/grype-report.sarif"
    
    # Template format for custom reporting
    grype "$image" -o template -t contrib/html.tmpl > "$output_dir/grype-report.html" 2>/dev/null || true
    
    print_status "Grype scan completed"
    
    # Parse and return vulnerability counts
    local critical=$(jq '[.matches[] | select(.vulnerability.severity == "Critical")] | length' "$output_dir/grype-report.json" 2>/dev/null || echo "0")
    local high=$(jq '[.matches[] | select(.vulnerability.severity == "High")] | length' "$output_dir/grype-report.json" 2>/dev/null || echo "0")
    local medium=$(jq '[.matches[] | select(.vulnerability.severity == "Medium")] | length' "$output_dir/grype-report.json" 2>/dev/null || echo "0")
    local low=$(jq '[.matches[] | select(.vulnerability.severity == "Low")] | length' "$output_dir/grype-report.json" 2>/dev/null || echo "0")
    local negligible=$(jq '[.matches[] | select(.vulnerability.severity == "Negligible")] | length' "$output_dir/grype-report.json" 2>/dev/null || echo "0")
    
    print_info "📊 Grype Results: Critical: $critical, High: $high, Medium: $medium, Low: $low, Negligible: $negligible"
    
    # Return vulnerability counts
    echo "$critical,$high,$medium,$low,$negligible"
}

# Function to generate SBOM with Syft
generate_sbom() {
    local image="$1"
    local output_dir="$2"
    
    print_scan "Generating SBOM with Syft: $image"
    
    mkdir -p "$output_dir"
    
    print_info "Generating SBOM in multiple formats..."
    
    # CycloneDX format (JSON)
    syft "$image" -o cyclonedx-json > "$output_dir/sbom-cyclonedx.json"
    
    # CycloneDX format (XML)
    syft "$image" -o cyclonedx-xml > "$output_dir/sbom-cyclonedx.xml"
    
    # SPDX format (JSON)
    syft "$image" -o spdx-json > "$output_dir/sbom-spdx.json"
    
    # SPDX format (Tag-Value)
    syft "$image" -o spdx-tag-value > "$output_dir/sbom-spdx.txt"
    
    # Table format (human readable)
    syft "$image" -o table > "$output_dir/sbom-summary.txt"
    
    # Syft JSON format (detailed)
    syft "$image" -o syft-json > "$output_dir/sbom-syft.json"
    
    print_status "SBOM generation completed"
    
    # Analyze SBOM
    if [ -f "$output_dir/sbom-cyclonedx.json" ]; then
        local total_components=$(jq '.components | length' "$output_dir/sbom-cyclonedx.json" 2>/dev/null || echo "0")
        print_info "📦 Total Components: $total_components"
        
        # Component breakdown
        print_info "🔧 Component Types:"
        jq -r '.components[].type' "$output_dir/sbom-cyclonedx.json" 2>/dev/null | sort | uniq -c | sort -nr || true
    fi
}

# Function to create comprehensive security report
create_security_report() {
    local image="$1"
    local output_dir="$2"
    local trivy_results="$3"
    local grype_results="$4"
    
    print_info "📋 Creating comprehensive security report..."
    
    local report_file="$output_dir/security-report.md"
    local timestamp=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
    
    # Parse vulnerability counts
    IFS=',' read -r trivy_crit trivy_high trivy_med trivy_low trivy_unk <<< "$trivy_results"
    IFS=',' read -r grype_crit grype_high grype_med grype_low grype_neg <<< "$grype_results"
    
    cat > "$report_file" << EOF
# Security Scan Report

**Image:** \`$image\`  
**Scan Date:** $timestamp  
**Scanners:** Trivy, Grype

## Executive Summary

### Vulnerability Overview

| Scanner | Critical | High | Medium | Low |
|---------|----------|------|--------|-----|
| Trivy   | ${trivy_crit:-0} | ${trivy_high:-0} | ${trivy_med:-0} | ${trivy_low:-0} |
| Grype   | ${grype_crit:-0} | ${grype_high:-0} | ${grype_med:-0} | ${grype_low:-0} |

### Risk Assessment

EOF

    # Add risk assessment
    local total_critical=-
    local total_high=-
    
    if [ $total_critical -gt 0 ]; then
        echo "🚨 **CRITICAL RISK** - $total_critical critical vulnerabilities detected" >> "$report_file"
    elif [ $total_high -gt 5 ]; then
        echo "⚠️ **HIGH RISK** - $total_high high severity vulnerabilities detected" >> "$report_file"
    elif [ $total_high -gt 0 ]; then
        echo "⚠️ **MEDIUM RISK** - $total_high high severity vulnerabilities detected" >> "$report_file"
    else
        echo "✅ **LOW RISK** - No critical or high severity vulnerabilities" >> "$report_file"
    fi
    
    cat >> "$report_file" << EOF

## Detailed Findings

### Top Critical Vulnerabilities (Trivy)

EOF

    # Add top critical vulnerabilities
    if [ -f "$output_dir/trivy-report.json" ]; then
        jq -r '.Results[]?.Vulnerabilities[]? | select(.Severity == "CRITICAL") | "- **\(.VulnerabilityID)**: \(.Title // .Description // "No description") (CVSS: \(.CVSS.nvd.V3Score // "N/A"))"' "$output_dir/trivy-report.json" | head -10 >> "$report_file" 2>/dev/null || echo "No critical vulnerabilities found" >> "$report_file"
    fi
    
    cat >> "$report_file" << EOF

### Software Bill of Materials (SBOM)

EOF

    # Add SBOM summary
    if [ -f "$output_dir/sbom-cyclonedx.json" ]; then
        local total_components=$(jq '.components | length' "$output_dir/sbom-cyclonedx.json" 2>/dev/null || echo "0")
        echo "**Total Components:** $total_components" >> "$report_file"
        echo "" >> "$report_file"
        echo "**Component Breakdown:**" >> "$report_file"
        jq -r '.components[].type' "$output_dir/sbom-cyclonedx.json" 2>/dev/null | sort | uniq -c | sort -nr | sed 's/^/- /' >> "$report_file" || true
    fi
    
    cat >> "$report_file" << EOF

## Recommendations

1. **Immediate Actions:**
   - Address all CRITICAL severity vulnerabilities
   - Review and patch HIGH severity issues
   - Update base image to latest security patches

2. **Security Improvements:**
   - Implement dependency scanning in CI/CD
   - Add security gates to prevent vulnerable deployments
   - Regular security scanning schedule

3. **Compliance:**
   - Maintain current SBOM for supply chain security
   - Document vulnerability remediation efforts
   - Implement security monitoring

## Files Generated

- \`trivy-report.json\` - Machine-readable vulnerability data
- \`trivy-report.txt\` - Human-readable vulnerability report
- \`grype-report.json\` - Alternative scanner results
- \`sbom-cyclonedx.json\` - Software Bill of Materials (CycloneDX)
- \`sbom-spdx.json\` - Software Bill of Materials (SPDX)

---
*Generated by DevSecOps Lab Security Scanner*
EOF

    print_status "Security report created: $report_file"
}

# Function to upload scan results to Nexus
upload_scan_results() {
    local image="$1"
    local output_dir="$2"
    local build_number="${3:-unknown}"
    
    print_info "📤 Uploading scan results to Nexus..."
    
    # Create archive of all scan results
    local archive_name="security-scan-$(echo "$image" | tr '/:' '-')-$build_number.tar.gz"
    tar -czf "/tmp/$archive_name" -C "$output_dir" .
    
    # Upload to raw repository
    local upload_path="security-scans/$(echo "$image" | tr '/:' '-')/$build_number/$archive_name"
    
    if curl -s -u "$NEXUS_USERNAME:$NEXUS_PASSWORD" \
            -X PUT \
            "$NEXUS_URL/repository/raw-hosted/$upload_path" \
            -T "/tmp/$archive_name" \
            -H "Content-Type: application/gzip" \
            -w "%{http_code}" | grep -q "20[01]"; then
        print_status "Scan results uploaded to Nexus"
        print_info "📁 Archive: $upload_path"
    else
        print_warning "Failed to upload scan results to Nexus"
    fi
    
    # Upload individual key files
    for file in trivy-report.json grype-report.json sbom-cyclonedx.json security-report.md; do
        if [ -f "$output_dir/$file" ]; then
            local file_path="security-scans/$(echo "$image" | tr '/:' '-')/$build_number/$file"
            curl -s -u "$NEXUS_USERNAME:$NEXUS_PASSWORD" \
                 -X PUT \
                 "$NEXUS_URL/repository/raw-hosted/$file_path" \
                 -T "$output_dir/$file" \
                 -H "Content-Type: application/json" > /dev/null
        fi
    done
    
    # Clean up temp file
    rm -f "/tmp/$archive_name"
}

# Main scanning function
scan_image() {
    local image="$1"
    local scanner="${2:-trivy}"
    local output_base="${3:-./scan-results}"
    local build_number="${4:-$(date +%s)}"
    
    if [ -z "$image" ]; then
        print_error "Usage: $0 scan <image> [scanner] [output_dir] [build_number]"
        exit 1
    fi
    
    # Create timestamped output directory
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local safe_image_name=$(echo "$image" | tr '/:' '-')
    local output_dir="$output_base/$safe_image_name-$timestamp"
    
    print_info "🚀 Starting comprehensive security scan"
    print_info "📦 Image: $image"
    print_info "🔧 Scanner: $scanner"
    print_info "📁 Output: $output_dir"
    print_info "🔢 Build: $build_number"
    echo ""
    
    # Initialize results
    local trivy_results="0,0,0,0,0"
    local grype_results="0,0,0,0,0"
    
    # Run scans based on scanner choice
    case "$scanner" in
        "trivy")
            trivy_results=$(scan_with_trivy "$image" "$output_dir")
            ;;
        "grype")
            grype_results=$(scan_with_grype "$image" "$output_dir")
            ;;
        "both")
            print_info "Running comprehensive scan with both scanners..."
            trivy_results=$(scan_with_trivy "$image" "$output_dir")
            grype_results=$(scan_with_grype "$image" "$output_dir")
            ;;
        *)
            print_error "Unknown scanner: $scanner. Use 'trivy', 'grype', or 'both'"
            exit 1
            ;;
    esac
    
    # Generate SBOM
    generate_sbom "$image" "$output_dir"
    
    # Create comprehensive report
    create_security_report "$image" "$output_dir" "$trivy_results" "$grype_results"
    
    # Upload results to Nexus
    upload_scan_results "$image" "$output_dir" "$build_number"
    
    echo ""
    print_status "🎉 Security scan completed successfully!"
    print_info "📋 Reports available in: $output_dir"
    print_info "📊 Summary report: $output_dir/security-report.md"
    
    # Return the most restrictive vulnerability counts for policy evaluation
    if [ "$scanner" = "both" ]; then
        # Use Trivy results as primary
        echo "$trivy_results"
    elif [ "$scanner" = "trivy" ]; then
        echo "$trivy_results"
    else
        echo "$grype_results"
    fi
}

# Function to scan and update artifact metadata
scan_and_update_metadata() {
    local image="$1"
    local repo_name="${2:-raw-hosted}"
    local artifact_path="$3"
    local scanner="${4:-trivy}"
    
    print_info "🔄 Scanning image and updating metadata..."
    
    # Run scan
    local scan_results=$(scan_image "$image" "$scanner" "./scan-results" "$(date +%s)")
    
    # Parse results
    IFS=',' read -r critical high medium low other <<< "$scan_results"
    
    # Determine gate status
    local gate_status="passed"
    if [ "$critical" -gt 0 ]; then
        gate_status="failed"
        print_warning "Security gate: FAILED (Critical vulnerabilities: $critical)"
    elif [ "$high" -gt 5 ]; then  # Configurable threshold
        gate_status="failed"
        print_warning "Security gate: FAILED (High vulnerabilities: $high > threshold: 5)"
    else
        gate_status="passed"
        print_status "Security gate: PASSED"
    fi
    
    # Update artifact metadata if artifact path provided
    if [ -n "$artifact_path" ]; then
        print_info "Updating artifact metadata..."
        ../scripts/api/upload-artifact.sh update-gate "$repo_name" "$artifact_path" "$gate_status" "$critical" "$high" "$medium" "$low"
    fi
    
    # Return gate status for CI/CD use
    echo "$gate_status"
}

# Command line interface
case "$1" in
    "scan")
        if [ "$#" -lt 2 ]; then
            echo "Usage: $0 scan <image> [scanner] [output_dir] [build_number]"
            echo ""
            echo "Examples:"
            echo "  $0 scan localhost:8082/devsecops-app:v1.2.0"
            echo "  $0 scan localhost:8082/devsecops-app:v1.2.0 trivy"
            echo "  $0 scan localhost:8082/devsecops-app:v1.2.0 both"
            exit 1
        fi
        scan_image "$2" "$3" "$4" "$5"
        ;;
    "scan-update")
        if [ "$#" -lt 4 ]; then
            echo "Usage: $0 scan-update <image> <repo_name> <artifact_path> [scanner]"
            echo ""
            echo "Examples:"
            echo "  $0 scan-update localhost:8082/devsecops-app:v1.2.0 raw-hosted docker-images/devsecops-app/v1.2.0/image"
            exit 1
        fi
        scan_and_update_metadata "$2" "$3" "$4" "$5"
        ;;
    "test")
        print_info "Testing security scanners..."
        trivy --version
        grype --version
        syft --version
        print_status "All security tools are working!"
        ;;
    *)
        echo "🔒 DevSecOps Lab - Security Scanner"
        echo "Usage: $0 {scan|scan-update|test}"
        echo ""
        echo "Commands:"
        echo "  scan         Scan container image for vulnerabilities"
        echo "  scan-update  Scan image and update artifact metadata"
        echo "  test         Test scanner installations"
        echo ""
        echo "Examples:"
        echo "  $0 scan localhost:8082/devsecops-app:v1.2.0 both"
        echo "  $0 scan-update localhost:8082/devsecops-app:v1.2.0 raw-hosted docker-images/devsecops-app/v1.2.0/image"
        ;;
esac

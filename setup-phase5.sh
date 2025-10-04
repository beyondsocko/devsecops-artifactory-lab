#!/bin/bash

# =============================================================================
# DevSecOps Lab - Phase 5 Setup Script
# =============================================================================
# Sets up Policy Gates & Security Controls with comprehensive testing
# =============================================================================

set -euo pipefail

# Script directory and configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}"  # Since script is in project root

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

log() {
    echo -e "${1}" >&2
}

log_info() {
    log "${BLUE}[INFO]${NC} ${1}"
}

log_warn() {
    log "${YELLOW}[WARN]${NC} ${1}"
}

log_error() {
    log "${RED}[ERROR]${NC} ${1}"
}

log_success() {
    log "${GREEN}[SUCCESS]${NC} ${1}"
}

log_step() {
    log "${PURPLE}[STEP]${NC} ${1}"
}

# =============================================================================
# SETUP FUNCTIONS
# =============================================================================

create_directory_structure() {
    log_step "Creating Phase 5 directory structure..."
    
    local directories=(
        "scripts/security"
        "policies/rego"
        "logs/audit"
        "reports"
        "test/fixtures"
        "test/scenarios"
    )
    
    for dir in "${directories[@]}"; do
        mkdir -p "${PROJECT_ROOT}/${dir}"
        log_info "Created directory: ${dir}"
    done
}

install_dependencies() {
    log_step "Installing Phase 5 dependencies..."
    
    # Check for required tools
    local tools=("jq" "curl")
    local missing_tools=()
    
    for tool in "${tools[@]}"; do
        if ! command -v "${tool}" &> /dev/null; then
            missing_tools+=("${tool}")
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_warn "Missing required tools: ${missing_tools[*]}"
        log_info "Installing missing tools..."
        
        # Install based on OS
        if command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y "${missing_tools[@]}"
        elif command -v yum &> /dev/null; then
            sudo yum install -y "${missing_tools[@]}"
        elif command -v brew &> /dev/null; then
            brew install "${missing_tools[@]}"
        else
            log_error "Unable to install dependencies automatically"
            log_error "Please install manually: ${missing_tools[*]}"
            return 1
        fi
    fi
    
    # Optional: Install OPA for advanced policy evaluation
    if ! command -v opa &> /dev/null; then
        log_info "Installing OPA (Open Policy Agent)..."
        curl -L -o opa https://openpolicyagent.org/downloads/v0.57.0/opa_linux_amd64_static
        chmod +x opa
        sudo mv opa /usr/local/bin/
        log_success "OPA installed successfully"
    fi
    
    log_success "All dependencies installed"
}

setup_configuration() {
    log_step "Setting up Phase 5 configuration..."
    
    local config_file="${PROJECT_ROOT}/.env"
    
    # Add Phase 5 specific configuration to existing .env
    if [[ -f "${config_file}" ]]; then
        log_info "Updating existing configuration file"
        
        # Check if Phase 5 config already exists
        if ! grep -q "GATE_FAIL_ON_CRITICAL" "${config_file}"; then
            cat >> "${config_file}" << 'EOF'

# =============================================================================
# PHASE 5: POLICY GATES & SECURITY CONTROLS
# =============================================================================

# Severity-based gate controls
GATE_FAIL_ON_CRITICAL=true
GATE_FAIL_ON_HIGH=true
GATE_FAIL_ON_MEDIUM=false
GATE_FAIL_ON_LOW=false

# Threshold limits
GATE_MAX_CRITICAL=0
GATE_MAX_HIGH=5
GATE_MAX_MEDIUM=20
GATE_MAX_LOW=50

# Bypass mechanism
GATE_BYPASS_ENABLED=true
GATE_BYPASS_TOKEN=""
GATE_BYPASS_REASON=""

# Scanner configuration
PRIMARY_SCANNER=trivy
SCANNER_TIMEOUT=300

# Reporting
REPORT_FORMATS=markdown,json
REPORT_RETENTION_DAYS=30

# Audit
AUDIT_RETENTION_DAYS=90
AUDIT_LOG_LEVEL=INFO

EOF
            log_success "Phase 5 configuration added to .env"
        else
            log_info "Phase 5 configuration already exists in .env"
        fi
    else
        log_error "Base .env file not found. Please run Phase 1 setup first."
        return 1
    fi
}

create_test_fixtures() {
    log_step "Creating test fixtures..."
    
    # Create mock scan results for testing
    local fixtures_dir="${PROJECT_ROOT}/test/fixtures"
    
    # Trivy results with vulnerabilities
    cat > "${fixtures_dir}/trivy-vulnerable.json" << 'EOF'
{
  "SchemaVersion": 2,
  "ArtifactName": "test-app:vulnerable",
  "ArtifactType": "container_image",
  "Results": [
    {
      "Target": "test-app:vulnerable (alpine 3.16.0)",
      "Class": "os-pkgs",
      "Type": "alpine",
      "Vulnerabilities": [
        {
          "VulnerabilityID": "CVE-2023-0001",
          "PkgName": "openssl",
          "Severity": "CRITICAL",
          "Title": "Critical vulnerability in OpenSSL"
        },
        {
          "VulnerabilityID": "CVE-2023-0002",
          "PkgName": "curl",
          "Severity": "HIGH",
          "Title": "High vulnerability in curl"
        },
        {
          "VulnerabilityID": "CVE-2023-0003",
          "PkgName": "zlib",
          "Severity": "HIGH",
          "Title": "High vulnerability in zlib"
        },
        {
          "VulnerabilityID": "CVE-2023-0004",
          "PkgName": "libxml2",
          "Severity": "MEDIUM",
          "Title": "Medium vulnerability in libxml2"
        }
      ]
    }
  ]
}
EOF

    # Trivy results clean
    cat > "${fixtures_dir}/trivy-clean.json" << 'EOF'
{
  "SchemaVersion": 2,
  "ArtifactName": "test-app:clean",
  "ArtifactType": "container_image",
  "Results": [
    {
      "Target": "test-app:clean (alpine 3.18.0)",
      "Class": "os-pkgs",
      "Type": "alpine",
      "Vulnerabilities": [
        {
          "VulnerabilityID": "CVE-2023-0005",
          "PkgName": "busybox",
          "Severity": "LOW",
          "Title": "Low vulnerability in busybox"
        }
      ]
    }
  ]
}
EOF

    # Grype results with vulnerabilities
    cat > "${fixtures_dir}/grype-vulnerable.json" << 'EOF'
{
  "matches": [
    {
      "vulnerability": {
        "id": "CVE-2023-0001",
        "severity": "Critical"
      },
      "artifact": {
        "name": "openssl",
        "version": "1.1.1"
      }
    },
    {
      "vulnerability": {
        "id": "CVE-2023-0002",
        "severity": "High"
      },
      "artifact": {
        "name": "curl",
        "version": "7.80.0"
      }
    }
  ]
}
EOF

    log_success "Test fixtures created"
}

create_test_scenarios() {
    log_step "Creating test scenarios..."
    
    local scenarios_dir="${PROJECT_ROOT}/test/scenarios"
    
    # Test scenario 1: Gate should PASS
    cat > "${scenarios_dir}/test-gate-pass.sh" << 'EOF'
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
EOF

    # Test scenario 2: Gate should FAIL
    cat > "${scenarios_dir}/test-gate-fail.sh" << 'EOF'
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
EOF

    # Test scenario 3: Gate bypass
    cat > "${scenarios_dir}/test-gate-bypass.sh" << 'EOF'
#!/bin/bash
# Test scenario: Gate bypass mechanism

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Copy vulnerable results to scan results directory
mkdir -p "${PROJECT_ROOT}/scan-results"
cp "${PROJECT_ROOT}/test/fixtures/trivy-vulnerable.json" "${PROJECT_ROOT}/scan-results/trivy-results.json"

# Set bypass environment variables
export GATE_BYPASS_TOKEN="emergency-override-123"
export GATE_BYPASS_REASON="Critical production hotfix"

# Run policy gate with bypass
"${PROJECT_ROOT}/scripts/security/policy-gate.sh" -s trivy

echo "Expected: BYPASS (exit 0), Actual: $?"
EOF

    # Make test scenarios executable
    chmod +x "${scenarios_dir}"/*.sh
    
    log_success "Test scenarios created"
}

# =============================================================================
# TESTING FUNCTIONS
# =============================================================================

run_unit_tests() {
    log_step "Running Phase 5 unit tests..."
    
    local test_results=()
    local scenarios_dir="${PROJECT_ROOT}/test/scenarios"
    
    # Test 1: Gate PASS scenario
    log_info "Running test: Gate PASS scenario"
    if "${scenarios_dir}/test-gate-pass.sh" &>/dev/null; then
        test_results+=("✅ Gate PASS scenario: PASSED")
    else
        test_results+=("❌ Gate PASS scenario: FAILED")
    fi
    
    # Test 2: Gate FAIL scenario
    log_info "Running test: Gate FAIL scenario"
    if "${scenarios_dir}/test-gate-fail.sh" &>/dev/null; then
        test_results+=("✅ Gate FAIL scenario: PASSED")
    else
        test_results+=("❌ Gate FAIL scenario: FAILED")
    fi
    
    # Test 3: Gate BYPASS scenario
    log_info "Running test: Gate BYPASS scenario"
    if "${scenarios_dir}/test-gate-bypass.sh" &>/dev/null; then
        test_results+=("✅ Gate BYPASS scenario: PASSED")
    else
        test_results+=("❌ Gate BYPASS scenario: FAILED")
    fi
    
    # Display results
    echo
    log_info "=== Unit Test Results ==="
    for result in "${test_results[@]}"; do
        echo "  ${result}"
    done
    echo
}

run_integration_tests() {
    log_step "Running Phase 5 integration tests..."
    
    # Test integration with existing scan.sh
    local scan_script="${PROJECT_ROOT}/scripts/security/scan.sh"
    local integrate_script="${PROJECT_ROOT}/scripts/security/integrate-gate.sh"
    
    if [[ -f "${scan_script}" && -f "${integrate_script}" ]]; then
        log_info "Testing integration with existing scan pipeline..."
        
        # Use the sample app image if available
        local test_image="localhost:8082/devsecops-app:v1.2.0"
        
        if docker image inspect "${test_image}" &>/dev/null; then
            log_info "Testing with existing sample app image: ${test_image}"
            
            # Run integrated pipeline (this will fail on vulnerable image, which is expected)
            if "${integrate_script}" "${test_image}" 2>/dev/null; then
                log_success "Integration test completed (gate passed)"
            else
                local exit_code=$?
                if [[ ${exit_code} -eq 1 ]]; then
                    log_success "Integration test completed (gate failed as expected)"
                else
                    log_error "Integration test encountered an error"
                fi
            fi
        else
            log_warn "Sample app image not found, skipping integration test"
            log_info "Run Phase 3 setup to build the sample application"
        fi
    else
        log_warn "Required scripts not found, skipping integration test"
    fi
}

# =============================================================================
# VALIDATION FUNCTIONS
# =============================================================================

validate_setup() {
    log_step "Validating Phase 5 setup..."
    
    local validation_results=()
    
    # Check required scripts
    local required_scripts=(
        "scripts/security/policy-gate.sh"
        "scripts/security/integrate-gate.sh"
    )
    
    for script in "${required_scripts[@]}"; do
        if [[ -f "${PROJECT_ROOT}/${script}" ]]; then
            validation_results+=("✅ ${script}: Present")
        else
            validation_results+=("❌ ${script}: Missing")
        fi
    done
    
    # Check configuration
    if grep -q "GATE_FAIL_ON_CRITICAL" "${PROJECT_ROOT}/.env" 2>/dev/null; then
        validation_results+=("✅ Configuration: Updated")
    else
        validation_results+=("❌ Configuration: Missing")
    fi
    
    # Check directories
    local required_dirs=(
        "logs/audit"
        "reports"
        "test/fixtures"
        "test/scenarios"
    )
    
    for dir in "${required_dirs[@]}"; do
        if [[ -d "${PROJECT_ROOT}/${dir}" ]]; then
            validation_results+=("✅ Directory ${dir}: Created")
        else
            validation_results+=("❌ Directory ${dir}: Missing")
        fi
    done
    
    # Check dependencies
    local required_tools=("jq" "curl")
    for tool in "${required_tools[@]}"; do
        if command -v "${tool}" &> /dev/null; then
            validation_results+=("✅ Tool ${tool}: Available")
        else
            validation_results+=("❌ Tool ${tool}: Missing")
        fi
    done
    
    # Display validation results
    echo
    log_info "=== Phase 5 Validation Results ==="
    for result in "${validation_results[@]}"; do
        echo "  ${result}"
    done
    echo
    
    # Check if all validations passed
    if echo "${validation_results[@]}" | grep -q "❌"; then
        log_error "Some validations failed. Please review and fix issues."
        return 1
    else
        log_success "All validations passed!"
        return 0
    fi
}

# =============================================================================
# MAIN SETUP LOGIC
# =============================================================================

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Phase 5 Setup Script - Policy Gates & Security Controls

OPTIONS:
    --skip-deps         Skip dependency installation
    --skip-tests        Skip running tests
    --test-only         Only run tests (skip setup)
    -h, --help          Show this help message

EXAMPLES:
    $0                  # Full setup with tests
    $0 --skip-deps      # Setup without installing dependencies
    $0 --test-only      # Only run tests

EOF
}

main() {
    local skip_deps=false
    local skip_tests=false
    local test_only=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-deps)
                skip_deps=true
                shift
                ;;
            --skip-tests)
                skip_tests=true
                shift
                ;;
            --test-only)
                test_only=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    echo
    log_info "=== DevSecOps Lab - Phase 5 Setup ==="
    log_info "Policy Gates & Security Controls"
    echo
    
    if [[ "${test_only}" == "true" ]]; then
        # Only run tests
        run_unit_tests
        run_integration_tests
        exit 0
    fi
    
    # Full setup process
    create_directory_structure
    
    if [[ "${skip_deps}" == "false" ]]; then
        install_dependencies
    fi
    
    setup_configuration
    create_test_fixtures
    create_test_scenarios
    
    # Validate setup
    if validate_setup; then
        log_success "Phase 5 setup completed successfully!"
        
        if [[ "${skip_tests}" == "false" ]]; then
            echo
            run_unit_tests
            run_integration_tests
        fi
        
        echo
        log_info "=== Next Steps ==="
        log_info "1. Review and customize policy configuration in .env"
        log_info "2. Test the policy gate with your sample application:"
        log_info "   ./scripts/security/integrate-gate.sh localhost:8082/devsecops-app:v1.2.0"
        log_info "3. Proceed to Phase 6: CI/CD Pipeline Integration"
        echo
        
    else
        log_error "Phase 5 setup failed. Please review the validation results."
        exit 1
    fi
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
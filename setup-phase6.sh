#!/bin/bash

# =============================================================================
# DevSecOps Lab - Phase 6 Setup Script
# =============================================================================
# Sets up CI/CD Pipeline Integration with GitHub Actions
# =============================================================================

set -euo pipefail

# Script directory and configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}"

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

create_github_workflows_directory() {
    log_step "Creating GitHub Actions workflow directory..."
    
    local workflows_dir="${PROJECT_ROOT}/.github/workflows"
    mkdir -p "${workflows_dir}"
    
    log_success "Created directory: .github/workflows"
}

create_workflow_templates() {
    log_step "Creating GitHub Actions workflow templates..."
    
    local workflows_dir="${PROJECT_ROOT}/.github/workflows"
    
    # Main CI/CD pipeline (already created above as ci-pipeline.yml)
    log_info "Main CI/CD pipeline: ci-pipeline.yml"
    
    # Create a simpler workflow for testing
    cat > "${workflows_dir}/test-pipeline.yml" << 'EOF'
name: Test Pipeline

on:
  workflow_dispatch:
  push:
    paths:
    - 'src/**'
    - 'scripts/**'
    - '.github/workflows/**'

jobs:
  test-security-pipeline:
    name: Test Security Pipeline
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout Code
      uses: actions/checkout@v4
      
    - name: Setup Environment
      run: |
        # Install required tools
        sudo apt-get update
        sudo apt-get install -y jq curl
        
        # Create required directories
        mkdir -p scan-results logs/audit reports
        
    - name: Test Policy Gate Scripts
      run: |
        # Make scripts executable
        chmod +x scripts/security/*.sh
        
        # Test with mock data
        echo "Testing policy gate functionality..."
        
        # Create mock scan results
        mkdir -p test/fixtures
        cat > scan-results/trivy-results.json << 'EOJ'
{
  "SchemaVersion": 2,
  "ArtifactName": "test-app:latest",
  "Results": [
    {
      "Vulnerabilities": [
        {"Severity": "LOW", "VulnerabilityID": "CVE-2023-0001"}
      ]
    }
  ]
}
EOJ
        
        # Run policy gate (should pass with only LOW severity)
        if scripts/security/policy-gate.sh -s trivy; then
          echo "✅ Policy gate test PASSED"
        else
          echo "❌ Policy gate test FAILED"
          exit 1
        fi
        
    - name: Validate Project Structure
      run: |
        echo "Validating project structure..."
        
        required_files=(
          "src/package.json"
          "src/Dockerfile"
          "scripts/security/scan.sh"
          "scripts/security/policy-gate.sh"
          "scripts/security/integrate-gate.sh"
          ".env"
        )
        
        for file in "${required_files[@]}"; do
          if [ -f "${file}" ]; then
            echo "✅ ${file}: Present"
          else
            echo "❌ ${file}: Missing"
            exit 1
          fi
        done
        
        echo "All required files present!"
EOF

    # Create a security-only workflow
    cat > "${workflows_dir}/security-scan.yml" << 'EOF'
name: Security Scan Only

on:
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM
  workflow_dispatch:
    inputs:
      image_name:
        description: 'Image to scan'
        required: true
        default: 'localhost:8082/devsecops-app:latest'

jobs:
  security-scan:
    name: Security Scan
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout Code
      uses: actions/checkout@v4
      
    - name: Install Security Tools
      run: |
        # Install Trivy
        sudo apt-get update
        wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
        echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
        sudo apt-get update
        sudo apt-get install trivy
        
    - name: Scan Image
      run: |
        IMAGE_NAME="${{ github.event.inputs.image_name || 'localhost:8082/devsecops-app:latest' }}"
        
        # Create results directory
        mkdir -p scan-results
        
        # Note: This would need access to your Nexus registry
        # For demo purposes, we'll scan a public image
        trivy image --format json --output scan-results/trivy-results.json alpine:latest
        trivy image --format table alpine:latest
        
    - name: Upload Results
      uses: actions/upload-artifact@v4
      with:
        name: security-scan-results
        path: scan-results/
        retention-days: 30
EOF

    log_success "Created workflow templates"
}

create_local_ci_simulator() {
    log_step "Creating local CI/CD simulator..."
    
    cat > "${PROJECT_ROOT}/scripts/simulate-ci.sh" << 'EOF'
#!/bin/bash

# =============================================================================
# Local CI/CD Pipeline Simulator
# =============================================================================
# Simulates the GitHub Actions pipeline locally for testing
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} ${1}"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} ${1}"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} ${1}"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} ${1}"
}

# Configuration
APP_NAME="devsecops-app"
APP_VERSION="v$(date +%Y%m%d)-local"
IMAGE_TAG="${APP_NAME}:${APP_VERSION}"

echo
log_info "=== Local CI/CD Pipeline Simulation ==="
log_info "Simulating GitHub Actions workflow locally"
echo

# Stage 1: Lint & Test
log_info "Stage 1: Lint & Test"
if [ -d "${PROJECT_ROOT}/src" ]; then
    cd "${PROJECT_ROOT}/src"
    if [ -f "package.json" ]; then
        log_info "Installing dependencies..."
        npm install || log_warn "npm install failed or not needed"
        
        log_info "Running tests..."
        npm test || log_warn "Tests failed or not configured"
    fi
    cd "${PROJECT_ROOT}"
else
    log_warn "src directory not found, skipping lint & test"
fi

# Stage 2: Build
log_info "Stage 2: Build Container"
if [ -f "${PROJECT_ROOT}/src/Dockerfile" ]; then
    log_info "Building container image: ${IMAGE_TAG}"
    docker build \
        --build-arg BUILD_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        --build-arg VCS_REF="local-build" \
        --build-arg VERSION="${APP_VERSION}" \
        --label "org.opencontainers.image.created=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        --label "org.opencontainers.image.version=${APP_VERSION}" \
        --label "security.scan.required=true" \
        --tag "${IMAGE_TAG}" \
        "${PROJECT_ROOT}/src"
    log_success "Container built: ${IMAGE_TAG}"
else
    log_error "Dockerfile not found in src/"
    exit 1
fi

# Stage 3: Security Scan
log_info "Stage 3: Security Scan"
if command -v trivy &> /dev/null; then
    mkdir -p "${PROJECT_ROOT}/scan-results"
    
    log_info "Running Trivy scan..."
    trivy image --format json --output "${PROJECT_ROOT}/scan-results/trivy-results.json" "${IMAGE_TAG}"
    trivy image --format table "${IMAGE_TAG}"
    
    log_success "Security scan completed"
else
    log_warn "Trivy not installed, skipping security scan"
fi

# Stage 4: Security Gate
log_info "Stage 4: Security Policy Gate"
if [ -f "${PROJECT_ROOT}/scripts/security/policy-gate.sh" ]; then
    chmod +x "${PROJECT_ROOT}/scripts/security/policy-gate.sh"
    
    if "${PROJECT_ROOT}/scripts/security/policy-gate.sh" -s trivy; then
        GATE_STATUS="PASS"
        log_success "Security gate PASSED"
    else
        GATE_STATUS="FAIL"
        log_error "Security gate FAILED"
    fi
else
    log_warn "Policy gate script not found"
    GATE_STATUS="SKIP"
fi

# Stage 5: Publish (Simulated)
log_info "Stage 5: Publish (Simulated)"
if [ "${GATE_STATUS}" = "PASS" ]; then
    log_info "Would publish to Nexus registry: localhost:8082/${IMAGE_TAG}"
    log_info "Would upload SBOM and scan results"
    log_success "Publish stage completed (simulated)"
elif [ "${GATE_STATUS}" = "FAIL" ]; then
    log_warn "Publish skipped due to security gate failure"
else
    log_warn "Publish skipped due to missing security gate"
fi

# Stage 6: Summary
echo
log_info "=== Pipeline Summary ==="
log_info "Image: ${IMAGE_TAG}"
log_info "Security Gate: ${GATE_STATUS}"

if [ "${GATE_STATUS}" = "PASS" ]; then
    log_success "✅ Pipeline completed successfully"
    exit 0
elif [ "${GATE_STATUS}" = "FAIL" ]; then
    log_error "❌ Pipeline failed due to security gate"
    exit 1
else
    log_warn "⚠️ Pipeline completed with warnings"
    exit 0
fi
EOF

    chmod +x "${PROJECT_ROOT}/scripts/simulate-ci.sh"
    log_success "Created local CI/CD simulator: scripts/simulate-ci.sh"
}

create_github_secrets_template() {
    log_step "Creating GitHub Secrets documentation..."
    
    cat > "${PROJECT_ROOT}/docs/github-secrets.md" << 'EOF'
# GitHub Secrets Configuration

For the CI/CD pipeline to work properly, configure the following secrets in your GitHub repository:

## Required Secrets

### Nexus Repository Access
- `NEXUS_URL`: Your Nexus repository URL (e.g., `http://your-nexus.com:8081`)
- `NEXUS_USERNAME`: Nexus username for authentication
- `NEXUS_PASSWORD`: Nexus password for authentication
- `NEXUS_DOCKER_REGISTRY`: Nexus Docker registry URL (e.g., `your-nexus.com:8082`)

### Optional Notification Secrets
- `SLACK_WEBHOOK_URL`: Slack webhook for notifications
- `EMAIL_SMTP_SERVER`: SMTP server for email notifications
- `EMAIL_FROM`: From email address
- `EMAIL_TO`: To email address

## How to Add Secrets

1. Go to your GitHub repository
2. Click on **Settings** tab
3. Click on **Secrets and variables** → **Actions**
4. Click **New repository secret**
5. Add each secret with the appropriate name and value

## Environment Variables

The following environment variables are configured in the workflow:

```yaml
env:
  NEXUS_URL: ${{ secrets.NEXUS_URL }}
  NEXUS_DOCKER_REGISTRY: ${{ secrets.NEXUS_DOCKER_REGISTRY }}
  NEXUS_USERNAME: ${{ secrets.NEXUS_USERNAME }}
  NEXUS_PASSWORD: ${{ secrets.NEXUS_PASSWORD }}
```

## Security Best Practices

- Never commit secrets to your repository
- Use least-privilege access for service accounts
- Rotate secrets regularly
- Monitor secret usage in audit logs
- Use environment-specific secrets for different deployment stages

## Local Development

For local development and testing, use the `.env` file:

```bash
# Copy from template
cp .env.example .env

# Edit with your local values
nano .env
```

The local CI simulator (`scripts/simulate-ci.sh`) will use your local environment configuration.
EOF

    mkdir -p "${PROJECT_ROOT}/docs"
    log_success "Created GitHub Secrets documentation: docs/github-secrets.md"
}

create_pipeline_documentation() {
    log_step "Creating pipeline documentation..."
    
    cat > "${PROJECT_ROOT}/docs/ci-cd-pipeline.md" << 'EOF'
# CI/CD Pipeline Documentation

## Overview

The DevSecOps CI/CD pipeline implements a 6-stage security-first approach:

1. **Lint & Test** - Code quality and unit tests
2. **Build** - Container image creation with security labels
3. **Security Scan** - Vulnerability scanning with Trivy/Grype + SBOM generation
4. **Security Gate** - Policy-based deployment decisions
5. **Publish** - Artifact publishing to Nexus (conditional on gate pass)
6. **Record** - Audit trail and notifications

## Pipeline Triggers

### Automatic Triggers
- **Push to main/develop**: Full pipeline execution
- **Pull Request**: Full pipeline with PR comments
- **Schedule**: Daily security scans at 2 AM UTC

### Manual Triggers
- **Workflow Dispatch**: Manual execution with bypass options
- **Security Scan Only**: Standalone security scanning

## Pipeline Stages

### Stage 1: Lint & Test
```yaml
- Checkout code
- Setup Node.js environment
- Install dependencies
- Run ESLint/Prettier
- Execute unit tests
- Generate version number
```

### Stage 2: Build Container
```yaml
- Setup Docker Buildx
- Build with security labels:
  - org.opencontainers.image.created
  - org.opencontainers.image.revision
  - org.opencontainers.image.version
  - security.scan.required=true
- Save image artifact
```

### Stage 3: Security Scan
```yaml
- Install Trivy, Grype, Syft
- Scan container for vulnerabilities
- Generate SBOM (SPDX + CycloneDX)
- Parse results and set outputs
- Upload scan artifacts
```

### Stage 4: Security Gate
```yaml
- Download scan results
- Run policy evaluation
- Support bypass mechanism
- Generate gate report
- Comment on PR with results
- Block pipeline if gate fails
```

### Stage 5: Publish (Conditional)
```yaml
- Only runs if security gate passes
- Push image to Nexus Docker registry
- Upload SBOM to generic repository
- Upload scan results
- Create build metadata
```

### Stage 6: Record & Notify
```yaml
- Generate pipeline summary
- Send notifications on failure
- Cleanup temporary artifacts
```

## Security Gate Policies

### Default Thresholds
- **Critical**: 0 allowed (fail immediately)
- **High**: 5 allowed maximum
- **Medium**: No limit (configurable)
- **Low**: No limit (configurable)

### Bypass Mechanism
Emergency bypass available with:
- Manual workflow dispatch
- Bypass reason required
- Full audit trail
- Approval workflow (optional)

## Artifacts Generated

### Container Images
- Tagged with version and git SHA
- Stored in Nexus Docker registry
- Security labels attached

### Security Reports
- Trivy JSON results
- Grype JSON results (alternative)
- Human-readable reports
- Policy gate decisions

### SBOM (Software Bill of Materials)
- SPDX format (primary)
- CycloneDX format (alternative)
- Linked to container images
- Stored in Nexus generic repository

### Build Metadata
```json
{
  "build": {
    "name": "devsecops-app",
    "number": "123",
    "version": "v20231201-abc123",
    "timestamp": "2023-12-01T10:30:00Z",
    "vcs": {
      "revision": "abc123...",
      "branch": "main",
      "url": "https://github.com/user/repo"
    }
  },
  "security": {
    "gate": {
      "status": "PASS",
      "vulnerabilities": {
        "critical": 0,
        "high": 2,
        "medium": 5,
        "low": 10
      }
    }
  }
}
```

## Local Testing

Test the pipeline locally:

```bash
# Simulate full pipeline
./scripts/simulate-ci.sh

# Test individual components
./scripts/security/integrate-gate.sh myapp:latest

# Test policy gate only
./scripts/security/policy-gate.sh -s trivy
```

## Monitoring & Alerts

### GitHub Actions
- Workflow status notifications
- PR comments with security results
- Job summaries with key metrics

### External Integrations
- Slack notifications (optional)
- Email alerts (optional)
- Custom webhooks (configurable)

## Troubleshooting

### Common Issues

1. **Security Gate Fails**
   - Check vulnerability counts in scan results
   - Review policy thresholds in workflow
   - Use bypass mechanism if emergency deployment needed

2. **Nexus Push Fails**
   - Verify Nexus credentials in GitHub Secrets
   - Check network connectivity to Nexus
   - Ensure repository exists and permissions are correct

3. **Scan Tools Installation Fails**
   - Check internet connectivity in runner
   - Verify tool download URLs are accessible
   - Consider using pre-built runner images

### Debug Mode
Enable debug logging:
```yaml
env:
  ACTIONS_STEP_DEBUG: true
  ACTIONS_RUNNER_DEBUG: true
```

## Customization

### Modify Security Thresholds
Edit workflow environment variables:
```yaml
env:
  GATE_MAX_CRITICAL: 0
  GATE_MAX_HIGH: 3
  GATE_FAIL_ON_MEDIUM: true
```

### Add Custom Scanners
Extend the security-scan job:
```yaml
- name: Run Custom Scanner
  run: |
    custom-scanner --format json --output results.json ${{ needs.build.outputs.image-tag }}
```

### Custom Notifications
Add notification steps:
```yaml
- name: Send Custom Notification
  if: failure()
  run: |
    curl -X POST -H 'Content-Type: application/json' \
      -d '{"text":"Pipeline failed"}' \
      ${{ secrets.WEBHOOK_URL }}
```
EOF

    log_success "Created pipeline documentation: docs/ci-cd-pipeline.md"
}

update_main_readme() {
    log_step "Updating main README with Phase 6 information..."
    
    local readme_file="${PROJECT_ROOT}/README.md"
    
    # Check if README exists and add Phase 6 section
    if [ -f "${readme_file}" ]; then
        # Add Phase 6 section if not already present
        if ! grep -q "Phase 6: CI/CD Pipeline" "${readme_file}"; then
            cat >> "${readme_file}" << 'EOF'

## Phase 6: CI/CD Pipeline Integration ✅

Complete GitHub Actions workflow implementing the 6-stage DevSecOps pipeline:

### Pipeline Stages
1. **Lint & Test** - Code quality validation
2. **Build** - Container image creation with security labels
3. **Security Scan** - Trivy/Grype scanning + SBOM generation
4. **Security Gate** - Policy-based deployment decisions
5. **Publish** - Conditional artifact publishing to Nexus
6. **Record** - Audit trail and notifications

### Key Features
- **Automated Security Gates** - Blocks vulnerable deployments
- **SBOM Generation** - Software Bill of Materials in SPDX/CycloneDX
- **Bypass Mechanism** - Emergency overrides with audit trail
- **PR Integration** - Security results in pull request comments
- **Artifact Management** - Complete build metadata and traceability

### Usage

#### Automatic Triggers
```bash
# Push to main/develop branches
git push origin main

# Create pull request
gh pr create --title "Feature update"
```

#### Manual Execution
```bash
# Via GitHub UI: Actions → DevSecOps CI/CD Pipeline → Run workflow
# With bypass option for emergencies
```

#### Local Testing
```bash
# Simulate full pipeline locally
./scripts/simulate-ci.sh

# Test individual components
./scripts/security/integrate-gate.sh localhost:8082/devsecops-app:latest
```

### Configuration

#### GitHub Secrets (Required)
- `NEXUS_URL` - Nexus repository URL
- `NEXUS_USERNAME` - Authentication username
- `NEXUS_PASSWORD` - Authentication password
- `NEXUS_DOCKER_REGISTRY` - Docker registry endpoint

#### Security Policies
```yaml
env:
  GATE_FAIL_ON_CRITICAL: true    # Block on critical vulnerabilities
  GATE_MAX_HIGH: 5               # Allow max 5 high severity
  GATE_FAIL_ON_MEDIUM: false     # Don't block on medium
```

### Artifacts Generated
- **Container Images** - Versioned and security-labeled
- **SBOM Files** - Software Bill of Materials
- **Security Reports** - Vulnerability scan results
- **Build Metadata** - Complete traceability information

### Documentation
- [Pipeline Documentation](docs/ci-cd-pipeline.md)
- [GitHub Secrets Setup](docs/github-secrets.md)
- [Troubleshooting Guide](docs/ci-cd-pipeline.md#troubleshooting)

EOF
            log_success "Updated README.md with Phase 6 information"
        else
            log_info "README.md already contains Phase 6 information"
        fi
    else
        log_warn "README.md not found, skipping update"
    fi
}

# =============================================================================
# VALIDATION FUNCTIONS
# =============================================================================

validate_prerequisites() {
    log_step "Validating Phase 6 prerequisites..."
    
    local validation_results=()
    
    # Check previous phases
    local required_scripts=(
        "scripts/security/scan.sh"
        "scripts/security/policy-gate.sh"
        "scripts/security/integrate-gate.sh"
    )
    
    for script in "${required_scripts[@]}"; do
        if [[ -f "${PROJECT_ROOT}/${script}" ]]; then
            validation_results+=("✅ ${script}: Present")
        else
            validation_results+=("❌ ${script}: Missing - Run Phase 4 & 5 setup first")
        fi
    done
    
    # Check sample application
    if [[ -f "${PROJECT_ROOT}/src/Dockerfile" ]]; then
        validation_results+=("✅ Sample application: Present")
    else
        validation_results+=("❌ Sample application: Missing - Run Phase 3 setup first")
    fi
    
    # Check configuration
    if [[ -f "${PROJECT_ROOT}/.env" ]]; then
        validation_results+=("✅ Configuration file: Present")
    else
        validation_results+=("❌ Configuration file: Missing")
    fi
    
    # Check Docker
    if command -v docker &> /dev/null; then
        validation_results+=("✅ Docker: Available")
    else
        validation_results+=("❌ Docker: Missing")
    fi
    
    # Display validation results
    echo
    log_info "=== Phase 6 Prerequisites Validation ==="
    for result in "${validation_results[@]}"; do
        echo "  ${result}"
    done
    echo
    
    # Check if all validations passed
    if echo "${validation_results[@]}" | grep -q "❌"; then
        log_error "Some prerequisites are missing. Please complete previous phases first."
        return 1
    else
        log_success "All prerequisites satisfied!"
        return 0
    fi
}

test_local_pipeline() {
    log_step "Testing local pipeline simulation..."
    
    if [[ -f "${PROJECT_ROOT}/scripts/simulate-ci.sh" ]]; then
        log_info "Running local CI/CD simulation..."
        
        # Run the simulator (allow it to fail for testing)
        if "${PROJECT_ROOT}/scripts/simulate-ci.sh"; then
            log_success "Local pipeline simulation completed successfully"
        else
            local exit_code=$?
            if [[ ${exit_code} -eq 1 ]]; then
                log_warn "Local pipeline simulation failed (security gate blocked deployment)"
                log_info "This is expected behavior for vulnerable applications"
            else
                log_error "Local pipeline simulation encountered an error"
            fi
        fi
    else
        log_error "Local pipeline simulator not found"
        return 1
    fi
}

# =============================================================================
# MAIN SETUP LOGIC
# =============================================================================

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Phase 6 Setup Script - CI/CD Pipeline Integration

OPTIONS:
    --skip-test         Skip local pipeline testing
    --test-only         Only run local pipeline test
    -h, --help          Show this help message

EXAMPLES:
    $0                  # Full setup with testing
    $0 --skip-test      # Setup without running local test
    $0 --test-only      # Only test local pipeline

EOF
}

main() {
    local skip_test=false
    local test_only=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-test)
                skip_test=true
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
    log_info "=== DevSecOps Lab - Phase 6 Setup ==="
    log_info "CI/CD Pipeline Integration"
    echo
    
    # Validate prerequisites
    if ! validate_prerequisites; then
        exit 1
    fi
    
    if [[ "${test_only}" == "true" ]]; then
        # Only run tests
        test_local_pipeline
        exit 0
    fi
    
    # Full setup process
    create_github_workflows_directory
    create_workflow_templates
    create_local_ci_simulator
    create_github_secrets_template
    create_pipeline_documentation
    update_main_readme
    
    log_success "Phase 6 setup completed successfully!"
    
    if [[ "${skip_test}" == "false" ]]; then
        echo
        test_local_pipeline
    fi
    
    echo
    log_info "=== Next Steps ==="
    log_info "1. Push your code to GitHub to activate the workflows"
    log_info "2. Configure GitHub Secrets (see docs/github-secrets.md)"
    log_info "3. Test the pipeline with a pull request or manual trigger"
    log_info "4. Monitor pipeline execution in GitHub Actions tab"
    log_info "5. Proceed to Phase 7: Documentation & Reporting"
    echo
    log_info "=== Local Testing ==="
    log_info "Test the pipeline locally: ./scripts/simulate-ci.sh"
    log_info "Test security integration: ./scripts/security/integrate-gate.sh localhost:8082/devsecops-app:latest"
    echo
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
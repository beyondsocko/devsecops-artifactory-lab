#!/bin/bash

# =============================================================================
# DevSecOps Lab - Phase 7 Setup Script
# =============================================================================
# Sets up Documentation & Reporting with architecture diagrams and final docs
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
# DOCUMENTATION FUNCTIONS
# =============================================================================

create_architecture_diagram() {
    log_step "Creating architecture diagram..."
    
    mkdir -p "${PROJECT_ROOT}/docs/diagrams"
    
    # Create SVG architecture diagram
    cat > "${PROJECT_ROOT}/docs/diagrams/architecture.svg" << 'EOF'
<svg width="1200" height="800" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <style>
      .title { font-family: Arial, sans-serif; font-size: 24px; font-weight: bold; fill: #202B52; }
      .subtitle { font-family: Arial, sans-serif; font-size: 16px; fill: #3F486B; }
      .box { fill: #FFFFFF; stroke: #202B52; stroke-width: 2; rx: 8; }
      .process { fill: #F8F9FF; stroke: #0961FB; stroke-width: 2; rx: 8; }
      .security { fill: #FFF5F5; stroke: #EA1B15; stroke-width: 2; rx: 8; }
      .storage { fill: #F0FFF4; stroke: #038C73; stroke-width: 2; rx: 8; }
      .text { font-family: Arial, sans-serif; font-size: 12px; fill: #010D39; }
      .label { font-family: Arial, sans-serif; font-size: 14px; font-weight: bold; fill: #202B52; }
      .arrow { stroke: #3F486B; stroke-width: 2; fill: none; marker-end: url(#arrowhead); }
      .security-arrow { stroke: #EA1B15; stroke-width: 2; fill: none; marker-end: url(#arrowhead); }
    </style>
    <marker id="arrowhead" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto">
      <polygon points="0 0, 10 3.5, 0 7" fill="#3F486B" />
    </marker>
  </defs>
  
  <!-- Title -->
  <text x="600" y="30" text-anchor="middle" class="title">DevSecOps Pipeline Architecture</text>
  <text x="600" y="55" text-anchor="middle" class="subtitle">Nexus Repository OSS + Security Gates + CI/CD Integration</text>
  
  <!-- Developer -->
  <rect x="50" y="100" width="120" height="60" class="box"/>
  <text x="110" y="125" text-anchor="middle" class="label">Developer</text>
  <text x="110" y="145" text-anchor="middle" class="text">Code Changes</text>
  
  <!-- GitHub -->
  <rect x="220" y="100" width="120" height="60" class="box"/>
  <text x="280" y="125" text-anchor="middle" class="label">GitHub</text>
  <text x="280" y="145" text-anchor="middle" class="text">Source Control</text>
  
  <!-- CI/CD Pipeline -->
  <rect x="50" y="220" width="700" height="200" class="process"/>
  <text x="400" y="245" text-anchor="middle" class="label">GitHub Actions CI/CD Pipeline</text>
  
  <!-- Pipeline Stages -->
  <rect x="70" y="260" width="100" height="40" class="box"/>
  <text x="120" y="275" text-anchor="middle" class="text">1. Lint &amp;</text>
  <text x="120" y="290" text-anchor="middle" class="text">Test</text>
  
  <rect x="190" y="260" width="100" height="40" class="box"/>
  <text x="240" y="275" text-anchor="middle" class="text">2. Build</text>
  <text x="240" y="290" text-anchor="middle" class="text">Container</text>
  
  <rect x="310" y="260" width="100" height="40" class="security"/>
  <text x="360" y="275" text-anchor="middle" class="text">3. Security</text>
  <text x="360" y="290" text-anchor="middle" class="text">Scan</text>
  
  <rect x="430" y="260" width="100" height="40" class="security"/>
  <text x="480" y="275" text-anchor="middle" class="text">4. Policy</text>
  <text x="480" y="290" text-anchor="middle" class="text">Gate</text>
  
  <rect x="550" y="260" width="100" height="40" class="box"/>
  <text x="600" y="275" text-anchor="middle" class="text">5. Publish</text>
  <text x="600" y="290" text-anchor="middle" class="text">Artifacts</text>
  
  <rect x="670" y="260" width="70" height="40" class="box"/>
  <text x="705" y="275" text-anchor="middle" class="text">6. Record</text>
  <text x="705" y="290" text-anchor="middle" class="text">&amp; Notify</text>
  
  <!-- Security Tools -->
  <rect x="70" y="320" width="280" height="80" class="security"/>
  <text x="210" y="340" text-anchor="middle" class="label">Security Scanning Tools</text>
  <text x="120" y="360" text-anchor="middle" class="text">Trivy</text>
  <text x="180" y="360" text-anchor="middle" class="text">Grype</text>
  <text x="240" y="360" text-anchor="middle" class="text">Syft</text>
  <text x="300" y="360" text-anchor="middle" class="text">OPA</text>
  <text x="210" y="380" text-anchor="middle" class="text">Vulnerability Scanning + SBOM + Policy Engine</text>
  
  <!-- Policy Gate Details -->
  <rect x="370" y="320" width="200" height="80" class="security"/>
  <text x="470" y="340" text-anchor="middle" class="label">Security Policy Gate</text>
  <text x="470" y="360" text-anchor="middle" class="text">Critical: 0 allowed</text>
  <text x="470" y="375" text-anchor="middle" class="text">High: 5 max allowed</text>
  <text x="470" y="390" text-anchor="middle" class="text">Bypass with audit trail</text>
  
  <!-- Nexus Repository -->
  <rect x="850" y="180" width="300" height="280" class="storage"/>
  <text x="1000" y="205" text-anchor="middle" class="label">Nexus Repository OSS</text>
  
  <!-- Docker Registry -->
  <rect x="870" y="230" width="120" height="60" class="box"/>
  <text x="930" y="250" text-anchor="middle" class="text">Docker Registry</text>
  <text x="930" y="265" text-anchor="middle" class="text">localhost:8082</text>
  <text x="930" y="280" text-anchor="middle" class="text">Container Images</text>
  
  <!-- Generic Repository -->
  <rect x="1010" y="230" width="120" height="60" class="box"/>
  <text x="1070" y="250" text-anchor="middle" class="text">Generic Repo</text>
  <text x="1070" y="265" text-anchor="middle" class="text">raw-hosted</text>
  <text x="1070" y="280" text-anchor="middle" class="text">SBOM + Reports</text>
  
  <!-- Metadata System -->
  <rect x="870" y="310" width="260" height="60" class="box"/>
  <text x="1000" y="330" text-anchor="middle" class="text">Metadata System</text>
  <text x="1000" y="345" text-anchor="middle" class="text">JSON companion files with build info,</text>
  <text x="1000" y="360" text-anchor="middle" class="text">security status, and vulnerability counts</text>
  
  <!-- Audit & Reporting -->
  <rect x="870" y="390" width="260" height="60" class="box"/>
  <text x="1000" y="410" text-anchor="middle" class="text">Audit Trail &amp; Reports</text>
  <text x="1000" y="425" text-anchor="middle" class="text">Policy decisions, scan results,</text>
  <text x="1000" y="440" text-anchor="middle" class="text">compliance documentation</text>
  
  <!-- Security Decision Point -->
  <rect x="580" y="320" width="160" height="80" class="security"/>
  <text x="660" y="340" text-anchor="middle" class="label">Decision Point</text>
  <text x="660" y="360" text-anchor="middle" class="text">PASS → Publish</text>
  <text x="660" y="375" text-anchor="middle" class="text">FAIL → Block</text>
  <text x="660" y="390" text-anchor="middle" class="text">BYPASS → Override</text>
  
  <!-- Monitoring & Alerts -->
  <rect x="50" y="500" width="200" height="80" class="box"/>
  <text x="150" y="520" text-anchor="middle" class="label">Monitoring &amp; Alerts</text>
  <text x="150" y="540" text-anchor="middle" class="text">GitHub Actions</text>
  <text x="150" y="555" text-anchor="middle" class="text">Slack Notifications</text>
  <text x="150" y="570" text-anchor="middle" class="text">Email Alerts</text>
  
  <!-- Compliance & Governance -->
  <rect x="280" y="500" width="200" height="80" class="box"/>
  <text x="380" y="520" text-anchor="middle" class="label">Compliance</text>
  <text x="380" y="540" text-anchor="middle" class="text">SBOM Generation</text>
  <text x="380" y="555" text-anchor="middle" class="text">Vulnerability Reports</text>
  <text x="380" y="570" text-anchor="middle" class="text">Audit Logs</text>
  
  <!-- Production Environment -->
  <rect x="950" y="500" width="200" height="80" class="storage"/>
  <text x="1050" y="520" text-anchor="middle" class="label">Production</text>
  <text x="1050" y="540" text-anchor="middle" class="text">Approved Artifacts</text>
  <text x="1050" y="555" text-anchor="middle" class="text">Secure Deployments</text>
  <text x="1050" y="570" text-anchor="middle" class="text">Compliance Ready</text>
  
  <!-- Arrows -->
  <!-- Developer to GitHub -->
  <line x1="170" y1="130" x2="220" y2="130" class="arrow"/>
  
  <!-- GitHub to CI/CD -->
  <line x1="280" y1="160" x2="280" y2="220" class="arrow"/>
  
  <!-- Pipeline stage arrows -->
  <line x1="170" y1="280" x2="190" y2="280" class="arrow"/>
  <line x1="290" y1="280" x2="310" y2="280" class="arrow"/>
  <line x1="410" y1="280" x2="430" y2="280" class="security-arrow"/>
  <line x1="530" y1="280" x2="550" y2="280" class="security-arrow"/>
  <line x1="650" y1="280" x2="670" y2="280" class="arrow"/>
  
  <!-- Security tools to gate -->
  <line x1="350" y1="360" x2="430" y2="320" class="security-arrow"/>
  
  <!-- Gate to decision -->
  <line x1="530" y1="320" x2="580" y2="340" class="security-arrow"/>
  
  <!-- Decision to Nexus -->
  <line x1="740" y1="360" x2="850" y2="320" class="arrow"/>
  
  <!-- CI/CD to Nexus -->
  <line x1="750" y1="280" x2="850" y2="280" class="arrow"/>
  
  <!-- Nexus to Production -->
  <line x1="1000" y1="460" x2="1000" y2="500" class="arrow"/>
  
  <!-- Legend -->
  <rect x="50" y="650" width="500" height="120" class="box"/>
  <text x="300" y="675" text-anchor="middle" class="label">Legend</text>
  
  <rect x="70" y="690" width="20" height="15" class="box"/>
  <text x="100" y="702" class="text">Standard Process</text>
  
  <rect x="200" y="690" width="20" height="15" class="security"/>
  <text x="230" y="702" class="text">Security Control</text>
  
  <rect x="330" y="690" width="20" height="15" class="storage"/>
  <text x="360" y="702" class="text">Storage/Repository</text>
  
  <line x1="70" y1="720" x2="100" y2="720" class="arrow"/>
  <text x="110" y="725" class="text">Data Flow</text>
  
  <line x1="200" y1="720" x2="230" y2="720" class="security-arrow"/>
  <text x="240" y="725" class="text">Security Decision</text>
  
  <text x="70" y="745" class="text">• Trivy: Primary vulnerability scanner</text>
  <text x="70" y="760" class="text">• Grype: Alternative vulnerability scanner</text>
  <text x="280" y="745" class="text">• Syft: SBOM generation tool</text>
  <text x="280" y="760" class="text">• OPA: Policy engine (optional)</text>
</svg>
EOF

    log_success "Created architecture diagram: docs/diagrams/architecture.svg"
}

create_comprehensive_readme() {
    log_step "Creating comprehensive README.md..."
    
    cat > "${PROJECT_ROOT}/README.md" << 'EOF'
# DevSecOps Artifactory Lab

A comprehensive hands-on DevSecOps laboratory implementing security-first CI/CD pipelines with Nexus Repository OSS, automated vulnerability scanning, and policy-based deployment gates.

## 🎯 Overview

This lab demonstrates enterprise-grade DevSecOps practices using 100% free and open-source tools:

- **Repository Management**: Nexus Repository OSS
- **Security Scanning**: Trivy, Grype, Syft
- **Policy Enforcement**: Custom security gates with bypass controls
- **CI/CD Integration**: GitHub Actions with 6-stage pipeline
- **Compliance**: SBOM generation, audit trails, vulnerability reporting

## 🏗️ Architecture

![Architecture Diagram](docs/diagrams/architecture.svg)

### Pipeline Flow
```
Developer → GitHub → CI/CD Pipeline → Security Gates → Nexus Repository → Production
                         ↓
                   [Trivy/Grype/Syft] → [Policy Evaluation] → [Pass/Fail/Bypass]
```

## 🚀 Quick Start (15-minute setup)

### Prerequisites
- Docker Desktop with WSL2 (Windows) or Docker (Linux/Mac)
- Node.js 18+ and npm
- Git
- 8GB RAM, 20GB disk space

### 1. Clone and Setup
```bash
git clone <your-repo-url>
cd devsecops-artifactory-lab

# Run complete setup
./setup-all-phases.sh
```

### 2. Start Nexus Repository
```bash
# Start Nexus container
docker run -d -p 8081:8081 -p 8082:8082 \
  --name nexus \
  -v nexus-data:/nexus-data \
  sonatype/nexus3:latest

# Wait for startup (2-3 minutes)
# Access: http://localhost:8081 (admin/Aa1234567)
```

### 3. Test the Pipeline
```bash
# Build and test sample application
./scripts/simulate-ci.sh

# Run integrated security pipeline
./scripts/security/integrate-gate.sh localhost:8082/devsecops-app:latest
```

## 📋 Implementation Phases

### ✅ Phase 1: Environment Setup
- Nexus Repository OSS configuration
- WSL2 Ubuntu + Docker Desktop integration
- Project structure and credentials

### ✅ Phase 2: Repository Automation
- REST API automation scripts
- Docker and generic repository creation
- Metadata system with JSON companion files
- Integration testing (31/32 tests passing)

### ✅ Phase 3: Sample Application
- Vulnerable Node.js Express application
- Intentional security vulnerabilities for testing
- Multi-stage Dockerfile with security labels
- Container registry integration

### ✅ Phase 4: Security Scanning
- Trivy (primary) and Grype (alternative) scanners
- Syft for SBOM generation (SPDX/CycloneDX formats)
- Comprehensive vulnerability reporting
- 755 components detected in sample app

### ✅ Phase 5: Policy Gates & Security Controls
- Configurable severity thresholds
- Emergency bypass mechanism with audit trail
- Integration with existing scan pipeline
- Nexus metadata updates

### ✅ Phase 6: CI/CD Pipeline Integration
- Complete GitHub Actions workflow
- 6-stage security-first pipeline
- Pull request integration with security comments
- Local testing simulator

### ✅ Phase 7: Documentation & Reporting
- Architecture diagrams and comprehensive documentation
- API reference and troubleshooting guides
- Compliance and audit reporting

### ✅ Phase 8: Testing & Validation
- End-to-end testing in clean environment
- Acceptance criteria validation
- Performance and security benchmarks

## 🛡️ Security Features

### Vulnerability Scanning
- **Trivy**: Primary scanner for containers and dependencies
- **Grype**: Alternative scanner with different vulnerability database
- **Syft**: Software Bill of Materials (SBOM) generation
- **Multi-format support**: SPDX, CycloneDX

### Policy Gates
```yaml
# Default security thresholds
GATE_FAIL_ON_CRITICAL: true    # Zero tolerance
GATE_MAX_HIGH: 5               # Maximum 5 high-severity
GATE_FAIL_ON_MEDIUM: false     # Allow medium-severity
GATE_BYPASS_ENABLED: true      # Emergency override
```

### Compliance & Audit
- Complete audit trail for all security decisions
- SBOM generation and storage
- Vulnerability report archival
- Policy bypass documentation

## 🔧 Configuration

### Environment Variables (.env)
```bash
# Nexus Configuration
NEXUS_URL=http://localhost:8081
NEXUS_USERNAME=admin
NEXUS_PASSWORD=Aa1234567
NEXUS_DOCKER_REGISTRY=localhost:8082

# Security Gate Policies
GATE_FAIL_ON_CRITICAL=true
GATE_MAX_HIGH=5
GATE_BYPASS_ENABLED=true

# Scanner Configuration
PRIMARY_SCANNER=trivy
SCANNER_TIMEOUT=300
```

### GitHub Secrets (for CI/CD)
- `NEXUS_URL`: Repository URL
- `NEXUS_USERNAME`: Authentication username  
- `NEXUS_PASSWORD`: Authentication password
- `NEXUS_DOCKER_REGISTRY`: Docker registry endpoint

## 📊 Usage Examples

### Manual Security Scan
```bash
# Scan specific image
./scripts/security/scan.sh myapp:latest

# Run policy gate evaluation
./scripts/security/policy-gate.sh -s trivy

# Integrated scan + gate
./scripts/security/integrate-gate.sh myapp:latest
```

### Repository Operations
```bash
# Create repositories
./scripts/api/create-repos.sh

# Upload artifact with metadata
./scripts/api/upload-artifact.sh /path/to/file

# Query artifacts
./scripts/api/query-artifacts.sh --build-name myapp
```

### CI/CD Pipeline
```bash
# Local simulation
./scripts/simulate-ci.sh

# GitHub Actions (automatic on push/PR)
git push origin main

# Manual trigger with bypass
# Use GitHub UI: Actions → DevSecOps Pipeline → Run workflow
```

## 📈 Monitoring & Reporting

### Generated Reports
- **Security Scan Reports**: Detailed vulnerability analysis
- **Policy Gate Reports**: Pass/fail decisions with rationale
- **SBOM Reports**: Complete software inventory
- **Audit Logs**: All security decisions and bypasses

### Integration Points
- **GitHub Actions**: Workflow status and PR comments
- **Slack**: Configurable notifications (optional)
- **Email**: Alert integration (optional)

## 🔍 Troubleshooting

### Common Issues

**Security Gate Fails**
```bash
# Check vulnerability counts
cat scan-results/trivy-results.json | jq '.Results[].Vulnerabilities | group_by(.Severity)'

# Review policy thresholds
grep GATE_ .env

# Use emergency bypass
export GATE_BYPASS_TOKEN="emergency-$(date +%s)"
export GATE_BYPASS_REASON="Critical production fix"
```

**Nexus Connection Issues**
```bash
# Test connectivity
curl -u admin:Aa1234567 http://localhost:8081/service/rest/v1/status

# Check container status
docker logs nexus

# Restart if needed
docker restart nexus
```

**Docker Build Failures**
```bash
# Check build context
ls -la src/

# Verify Dockerfile location
find . -name "Dockerfile"

# Test build manually
docker build -f src/Dockerfile -t test:latest .
```

## 📚 Documentation

- [Architecture Overview](docs/architecture.md)
- [CI/CD Pipeline Guide](docs/ci-cd-pipeline.md)
- [Security Configuration](docs/security-config.md)
- [API Reference](docs/api-reference.md)
- [Troubleshooting Guide](docs/troubleshooting.md)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes with tests
4. Submit pull request
5. Security scans will run automatically

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Nexus Repository OSS** - Sonatype
- **Trivy** - Aqua Security
- **Grype & Syft** - Anchore
- **GitHub Actions** - Microsoft
- **Docker** - Docker Inc.

## 📞 Support

- **Issues**: Use GitHub Issues for bug reports
- **Discussions**: Use GitHub Discussions for questions
- **Security**: Report security issues privately

---

**Built with ❤️ for DevSecOps practitioners**

*This lab demonstrates production-ready DevSecOps practices using enterprise-grade tools and methodologies.*
EOF

    log_success "Created comprehensive README.md"
}

create_api_reference() {
    log_step "Creating API reference documentation..."
    
    mkdir -p "${PROJECT_ROOT}/docs"
    
    cat > "${PROJECT_ROOT}/docs/api-reference.md" << 'EOF'
# API Reference

Complete reference for all DevSecOps Lab APIs and scripts.

## Nexus Repository API

### Authentication
All API calls require basic authentication:
```bash
curl -u "${NEXUS_USERNAME}:${NEXUS_PASSWORD}" \
  "${NEXUS_URL}/service/rest/v1/..."
```

### Repository Management

#### Create Docker Repository
```bash
POST /service/rest/v1/repositories/docker/hosted
Content-Type: application/json

{
  "name": "docker-local",
  "online": true,
  "storage": {
    "blobStoreName": "default",
    "strictContentTypeValidation": true,
    "writePolicy": "allow_once"
  },
  "docker": {
    "v1Enabled": false,
    "forceBasicAuth": true,
    "httpPort": 8082
  }
}
```

#### Create Generic Repository
```bash
POST /service/rest/v1/repositories/raw/hosted
Content-Type: application/json

{
  "name": "raw-hosted",
  "online": true,
  "storage": {
    "blobStoreName": "default",
    "strictContentTypeValidation": false,
    "writePolicy": "allow"
  }
}
```

### Artifact Management

#### Upload Artifact
```bash
PUT /repository/raw-hosted/{path}
Content-Type: application/octet-stream

# Upload file
curl -u admin:password \
  --upload-file artifact.jar \
  http://localhost:8081/repository/raw-hosted/com/example/artifact/1.0/artifact.jar
```

#### Upload with Metadata
```bash
# Upload artifact
curl -u admin:password \
  --upload-file artifact.jar \
  http://localhost:8081/repository/raw-hosted/path/artifact.jar

# Upload metadata companion file
curl -u admin:password \
  --upload-file metadata.json \
  http://localhost:8081/repository/raw-hosted/path/artifact.jar.metadata.json
```

#### Query Artifacts
```bash
GET /service/rest/v1/search?repository=raw-hosted&name=artifact*

# Response
{
  "items": [
    {
      "id": "...",
      "repository": "raw-hosted",
      "format": "raw",
      "group": null,
      "name": "artifact.jar",
      "version": null,
      "assets": [...]
    }
  ]
}
```

## DevSecOps Lab Scripts

### Repository Management Scripts

#### create-repos.sh
Creates Docker and generic repositories.

```bash
./scripts/api/create-repos.sh [OPTIONS]

Options:
  --docker-port PORT    Docker registry port (default: 8082)
  --force              Delete existing repositories first
  --dry-run            Show what would be created
```

**Example:**
```bash
./scripts/api/create-repos.sh --docker-port 8082 --force
```

#### upload-artifact.sh
Uploads artifacts with metadata to Nexus.

```bash
./scripts/api/upload-artifact.sh [OPTIONS] FILE [METADATA]

Arguments:
  FILE                 Path to artifact file
  METADATA             Optional metadata JSON file

Options:
  --repository REPO    Target repository (default: raw-hosted)
  --path PATH          Upload path (default: auto-generated)
  --build-name NAME    Build name for metadata
  --build-number NUM   Build number for metadata
```

**Example:**
```bash
./scripts/api/upload-artifact.sh \
  --build-name myapp \
  --build-number 123 \
  myapp.jar metadata.json
```

#### query-artifacts.sh
Queries and searches artifacts in Nexus.

```bash
./scripts/api/query-artifacts.sh [OPTIONS]

Options:
  --repository REPO    Repository to search (default: all)
  --name PATTERN       Name pattern to match
  --build-name NAME    Filter by build name
  --format FORMAT      Output format (json|table|csv)
```

**Example:**
```bash
./scripts/api/query-artifacts.sh \
  --repository raw-hosted \
  --name "myapp*" \
  --format table
```

### Security Scripts

#### scan.sh
Performs security scanning with multiple tools.

```bash
./scripts/security/scan.sh [OPTIONS] IMAGE

Arguments:
  IMAGE                Container image to scan

Options:
  --scanner SCANNER    Scanner to use (trivy|grype|all)
  --format FORMAT      Output format (json|table|sarif)
  --output DIR         Output directory (default: scan-results)
  --sbom              Generate SBOM
  --timeout SECONDS    Scanner timeout (default: 300)
```

**Example:**
```bash
./scripts/security/scan.sh \
  --scanner trivy \
  --format json \
  --sbom \
  myapp:latest
```

#### policy-gate.sh
Evaluates security policies and makes gate decisions.

```bash
./scripts/security/policy-gate.sh [OPTIONS] [ARTIFACT_PATH]

Arguments:
  ARTIFACT_PATH        Optional path for metadata updates

Options:
  -s, --scanner SCANNER    Scanner results to use (trivy|grype)
  -c, --config FILE        Configuration file
  --bypass-token TOKEN     Emergency bypass token
  --bypass-reason REASON   Reason for bypass
```

**Example:**
```bash
./scripts/security/policy-gate.sh \
  --scanner trivy \
  --bypass-token emergency-123 \
  --bypass-reason "Critical production fix" \
  /path/to/artifact
```

#### integrate-gate.sh
Runs integrated scan and gate pipeline.

```bash
./scripts/security/integrate-gate.sh [OPTIONS] IMAGE [ARTIFACT_PATH]

Arguments:
  IMAGE                Container image to process
  ARTIFACT_PATH        Optional artifact path for metadata

Options:
  -s, --scanner SCANNER    Scanner to use (trivy|grype)
  -n, --notify            Send notifications
  --skip-scan             Skip scanning (use existing results)
  --skip-gate             Skip policy gate evaluation
```

**Example:**
```bash
./scripts/security/integrate-gate.sh \
  --scanner trivy \
  --notify \
  myapp:latest \
  /nexus/path/to/artifact
```

### CI/CD Scripts

#### simulate-ci.sh
Simulates the complete CI/CD pipeline locally.

```bash
./scripts/simulate-ci.sh [OPTIONS]

Options:
  --skip-build         Skip container build
  --skip-scan          Skip security scanning
  --skip-gate          Skip policy gate
  --image-tag TAG      Use specific image tag
```

**Example:**
```bash
./scripts/simulate-ci.sh --image-tag myapp:test
```

## Configuration Files

### .env File
Main configuration file for all scripts.

```bash
# Nexus Configuration
NEXUS_URL=http://localhost:8081
NEXUS_USERNAME=admin
NEXUS_PASSWORD=Aa1234567
NEXUS_DOCKER_REGISTRY=localhost:8082

# Security Gate Configuration
GATE_FAIL_ON_CRITICAL=true
GATE_FAIL_ON_HIGH=true
GATE_MAX_CRITICAL=0
GATE_MAX_HIGH=5
GATE_BYPASS_ENABLED=true

# Scanner Configuration
PRIMARY_SCANNER=trivy
SCANNER_TIMEOUT=300

# Reporting Configuration
REPORT_FORMATS=markdown,json
REPORT_RETENTION_DAYS=30
```

### Metadata JSON Format
Standard format for artifact metadata.

```json
{
  "build": {
    "name": "myapp",
    "number": "123",
    "version": "1.0.0",
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
      "timestamp": "2023-12-01T10:35:00Z",
      "scanner": "trivy",
      "vulnerabilities": {
        "critical": 0,
        "high": 2,
        "medium": 5,
        "low": 10
      }
    },
    "scan": {
      "sbom_path": "path/to/sbom.json",
      "results_path": "path/to/results.json"
    }
  }
}
```

## Error Codes

### Script Exit Codes
- `0`: Success
- `1`: Security gate failure or policy violation
- `2`: Configuration error
- `3`: Network/connectivity error
- `4`: Authentication error
- `5`: File not found error

### HTTP Status Codes
- `200`: Success
- `201`: Created
- `400`: Bad request (invalid parameters)
- `401`: Unauthorized (authentication failed)
- `403`: Forbidden (insufficient permissions)
- `404`: Not found (repository/artifact doesn't exist)
- `409`: Conflict (resource already exists)
- `500`: Internal server error

## Examples

### Complete Workflow Example
```bash
# 1. Create repositories
./scripts/api/create-repos.sh

# 2. Build and scan application
./scripts/simulate-ci.sh

# 3. Upload artifacts with metadata
./scripts/api/upload-artifact.sh \
  --build-name myapp \
  --build-number 123 \
  dist/myapp.jar

# 4. Query uploaded artifacts
./scripts/api/query-artifacts.sh \
  --build-name myapp \
  --format table

# 5. Run security pipeline
./scripts/security/integrate-gate.sh \
  localhost:8082/myapp:latest
```

### Emergency Bypass Example
```bash
# Set bypass environment variables
export GATE_BYPASS_TOKEN="emergency-$(date +%s)"
export GATE_BYPASS_REASON="Critical security patch deployment"

# Run with bypass
./scripts/security/policy-gate.sh --scanner trivy

# Check audit log
tail -f logs/audit/policy-gate-$(date +%Y%m%d).log
```

### Batch Processing Example
```bash
# Process multiple images
for image in app1:latest app2:latest app3:latest; do
  echo "Processing ${image}..."
  ./scripts/security/integrate-gate.sh "${image}" || echo "Failed: ${image}"
done
```

## Integration Examples

### GitHub Actions Integration
```yaml
- name: Run Security Pipeline
  run: |
    ./scripts/security/integrate-gate.sh \
      ${{ needs.build.outputs.image-tag }} \
      artifacts/${{ github.run_number }}
```

### Jenkins Integration
```groovy
pipeline {
  stages {
    stage('Security Gate') {
      steps {
        script {
          def result = sh(
            script: "./scripts/security/policy-gate.sh --scanner trivy",
            returnStatus: true
          )
          if (result != 0) {
            error("Security gate failed")
          }
        }
      }
    }
  }
}
```

### Slack Notification Integration
```bash
# In integrate-gate.sh
if [ "${GATE_STATUS}" = "FAIL" ]; then
  curl -X POST -H 'Content-type: application/json' \
    --data '{"text":"Security gate failed for '"${IMAGE_NAME}"'"}' \
    "${SLACK_WEBHOOK_URL}"
fi
```
EOF

    log_success "Created API reference: docs/api-reference.md"
}

create_troubleshooting_guide() {
    log_step "Creating troubleshooting guide..."
    
    cat > "${PROJECT_ROOT}/docs/troubleshooting.md" << 'EOF'
# Troubleshooting Guide

Common issues and solutions for the DevSecOps Lab.

## Environment Issues

### Docker Issues

#### Docker Desktop Not Starting
**Symptoms:**
- Docker commands fail with "Cannot connect to Docker daemon"
- WSL2 integration not working

**Solutions:**
```bash
# Restart Docker Desktop
# Windows: Right-click Docker Desktop → Restart

# Check WSL2 integration
wsl --list --verbose

# Reset Docker Desktop if needed
# Windows: Docker Desktop → Settings → Reset to factory defaults
```

#### Container Build Failures
**Symptoms:**
- `docker build` fails with context errors
- "COPY failed" or "ADD failed" errors

**Solutions:**
```bash
# Check build context
ls -la src/

# Verify Dockerfile location
find . -name "Dockerfile"

# Test build with verbose output
docker build --progress=plain -f src/Dockerfile -t test:latest .

# Check .dockerignore file
cat .dockerignore
```

### Nexus Repository Issues

#### Nexus Container Won't Start
**Symptoms:**
- Container exits immediately
- Port 8081 not accessible

**Solutions:**
```bash
# Check container logs
docker logs nexus

# Verify ports are available
netstat -an | grep 8081
netstat -an | grep 8082

# Remove and recreate container
docker rm -f nexus
docker run -d -p 8081:8081 -p 8082:8082 \
  --name nexus \
  -v nexus-data:/nexus-data \
  sonatype/nexus3:latest

# Wait for startup (2-3 minutes)
docker logs -f nexus
```

#### Authentication Failures
**Symptoms:**
- API calls return 401 Unauthorized
- Docker push/pull fails with authentication error

**Solutions:**
```bash
# Test basic authentication
curl -u admin:Aa1234567 http://localhost:8081/service/rest/v1/status

# Reset admin password if needed
docker exec -it nexus cat /nexus-data/admin.password

# Update .env file with correct credentials
nano .env
```

#### Repository Creation Fails
**Symptoms:**
- create-repos.sh fails with 400/409 errors
- Repositories not visible in UI

**Solutions:**
```bash
# Check if repositories already exist
curl -u admin:Aa1234567 \
  http://localhost:8081/service/rest/v1/repositories

# Force recreation
./scripts/api/create-repos.sh --force

# Check Nexus logs for errors
docker logs nexus | tail -50
```

## Security Scanning Issues

### Trivy Issues

#### Trivy Installation Fails
**Symptoms:**
- `trivy: command not found`
- Package installation errors

**Solutions:**
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy

# Alternative: Download binary
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
```

#### Trivy Database Update Fails
**Symptoms:**
- "Failed to download vulnerability DB" errors
- Scan results are outdated

**Solutions:**
```bash
# Clear Trivy cache
trivy clean --all

# Update database manually
trivy image --download-db-only

# Check network connectivity
curl -I https://github.com/aquasecurity/trivy-db/releases/latest

# Use offline mode if needed
trivy image --offline-scan myapp:latest
```

#### Scan Timeout Issues
**Symptoms:**
- Scans hang or timeout
- Large images fail to scan

**Solutions:**
```bash
# Increase timeout
export SCANNER_TIMEOUT=600

# Use specific scanner options
trivy image --timeout 10m myapp:latest

# Scan specific layers only
trivy image --skip-files "*.jar" myapp:latest
```

### Grype Issues

#### Grype Installation Fails
**Symptoms:**
- `grype: command not found`
- Installation script fails

**Solutions:**
```bash
# Install Grype
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin

# Verify installation
grype version

# Update if needed
grype update
```

## Policy Gate Issues

### Gate Configuration Issues

#### Policy Gate Always Fails
**Symptoms:**
- All scans fail security gate
- Even clean images are blocked

**Solutions:**
```bash
# Check current thresholds
grep GATE_ .env

# Temporarily relax thresholds for testing
export GATE_MAX_CRITICAL=1
export GATE_MAX_HIGH=10

# Check scan results format
cat scan-results/trivy-results.json | jq '.Results[].Vulnerabilities | group_by(.Severity)'

# Test with known clean image
./scripts/security/policy-gate.sh --scanner trivy
```

#### Policy Gate Always Passes
**Symptoms:**
- Vulnerable images pass security gate
- No policy violations detected

**Solutions:**
```bash
# Verify scan results exist
ls -la scan-results/

# Check vulnerability counts
jq -r '[.Results[]?.Vulnerabilities[]? | select(.Severity == "CRITICAL")] | length' scan-results/trivy-results.json

# Test policy logic manually
./scripts/security/policy-gate.sh --scanner trivy --verbose

# Check configuration
echo "GATE_FAIL_ON_CRITICAL: ${GATE_FAIL_ON_CRITICAL}"
echo "GATE_MAX_CRITICAL: ${GATE_MAX_CRITICAL}"
```

### Bypass Issues

#### Bypass Not Working
**Symptoms:**
- Emergency bypass ignored
- Gate still fails with bypass token

**Solutions:**
```bash
# Check bypass configuration
echo "GATE_BYPASS_ENABLED: ${GATE_BYPASS_ENABLED}"

# Set bypass variables correctly
export GATE_BYPASS_TOKEN="emergency-$(date +%s)"
export GATE_BYPASS_REASON="Critical production fix"

# Verify bypass in logs
tail -f logs/audit/policy-gate-$(date +%Y%m%d).log

# Test bypass manually
./scripts/security/policy-gate.sh \
  --bypass-token "test-123" \
  --bypass-reason "Testing bypass"
```

## CI/CD Pipeline Issues

### GitHub Actions Issues

#### Workflow Not Triggering
**Symptoms:**
- Push to main doesn't trigger workflow
- Workflow file not recognized

**Solutions:**
```bash
# Check workflow file location
ls -la .github/workflows/

# Validate YAML syntax
yamllint .github/workflows/ci-pipeline.yml

# Check GitHub Actions tab for errors
# Repository → Actions → View workflow runs

# Force trigger manually
# Repository → Actions → DevSecOps Pipeline → Run workflow
```

#### Secrets Not Available
**Symptoms:**
- Authentication failures in GitHub Actions
- Environment variables are empty

**Solutions:**
```bash
# Check secrets configuration
# Repository → Settings → Secrets and variables → Actions

# Required secrets:
# - NEXUS_URL
# - NEXUS_USERNAME  
# - NEXUS_PASSWORD
# - NEXUS_DOCKER_REGISTRY

# Test secrets in workflow
echo "NEXUS_URL: ${{ secrets.NEXUS_URL }}"
```

#### Build Context Issues in Actions
**Symptoms:**
- Docker build fails in GitHub Actions
- "COPY failed" errors in CI

**Solutions:**
```yaml
# Fix build context in workflow
- name: Build Container Image
  run: |
    docker build \
      --file ./src/Dockerfile \
      --tag "${IMAGE_TAG}" \
      .  # Use project root as context
```

### Local Simulation Issues

#### simulate-ci.sh Fails
**Symptoms:**
- Local CI simulation exits with errors
- Missing dependencies

**Solutions:**
```bash
# Check prerequisites
which docker
which npm
which jq

# Install missing tools
sudo apt-get install jq curl

# Run with debug output
bash -x ./scripts/simulate-ci.sh

# Check project structure
ls -la src/
ls -la scripts/security/
```

## Network and Connectivity Issues

### Nexus Connectivity

#### Cannot Reach Nexus from CI
**Symptoms:**
- Timeouts connecting to localhost:8081
- Network unreachable errors

**Solutions:**
```bash
# Test connectivity
curl -v http://localhost:8081/service/rest/v1/status

# Check if Nexus is running
docker ps | grep nexus

# Verify port mapping
docker port nexus

# Use host networking if needed (Linux)
docker run --network host sonatype/nexus3:latest
```

### Docker Registry Issues

#### Docker Push/Pull Fails
**Symptoms:**
- "unauthorized" errors
- "repository does not exist" errors

**Solutions:**
```bash
# Test Docker registry connectivity
curl -u admin:Aa1234567 http://localhost:8082/v2/_catalog

# Login to Docker registry
echo "Aa1234567" | docker login localhost:8082 -u admin --password-stdin

# Check repository exists
curl -u admin:Aa1234567 \
  http://localhost:8081/service/rest/v1/repositories | \
  jq '.[] | select(.name == "docker-local")'

# Create repository if missing
./scripts/api/create-repos.sh
```

## Performance Issues

### Slow Scans

#### Trivy Scans Take Too Long
**Symptoms:**
- Scans timeout after 5+ minutes
- High CPU/memory usage

**Solutions:**
```bash
# Increase resources for Docker
# Docker Desktop → Settings → Resources → Advanced

# Use parallel scanning
trivy image --parallel 4 myapp:latest

# Skip unnecessary files
trivy image --skip-files "*.pdf,*.doc" myapp:latest

# Use cached results
trivy image --cache-dir /tmp/trivy-cache myapp:latest
```

### Large Image Issues

#### Out of Disk Space
**Symptoms:**
- "no space left on device" errors
- Docker build fails

**Solutions:**
```bash
# Clean Docker system
docker system prune -a

# Remove unused images
docker image prune -a

# Check disk usage
df -h
docker system df

# Use multi-stage builds to reduce image size
# See src/Dockerfile for example
```

## Data and State Issues

### Lost Configuration

#### .env File Missing or Corrupted
**Symptoms:**
- Scripts fail with "variable not set" errors
- Default values used instead of custom config

**Solutions:**
```bash
# Recreate .env from template
cp .env.example .env

# Or regenerate with setup script
./setup-phase1.sh --config-only

# Verify configuration
source .env
echo "NEXUS_URL: ${NEXUS_URL}"
```

### Nexus Data Loss

#### Nexus Data Volume Issues
**Symptoms:**
- Repositories disappear after restart
- Configuration resets to defaults

**Solutions:**
```bash
# Check volume exists
docker volume ls | grep nexus-data

# Backup volume
docker run --rm -v nexus-data:/data -v $(pwd):/backup \
  alpine tar czf /backup/nexus-backup.tar.gz -C /data .

# Restore volume
docker run --rm -v nexus-data:/data -v $(pwd):/backup \
  alpine tar xzf /backup/nexus-backup.tar.gz -C /data

# Use bind mount for persistence
docker run -d -p 8081:8081 -p 8082:8082 \
  --name nexus \
  -v $(pwd)/nexus-data:/nexus-data \
  sonatype/nexus3:latest
```

## Getting Help

### Debug Information Collection

#### Collect System Information
```bash
# System info
uname -a
docker version
docker-compose version

# Project info
ls -la
cat .env | grep -v PASSWORD

# Container status
docker ps -a
docker logs nexus | tail -20

# Network info
netstat -an | grep -E "(8081|8082)"
```

#### Generate Debug Report
```bash
# Run debug script
./scripts/debug-info.sh > debug-report.txt

# Include in issue report
# - System information
# - Error messages
# - Configuration (sanitized)
# - Steps to reproduce
```

### Support Channels

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: Questions and community support
- **Documentation**: Check docs/ directory for detailed guides

### Common Commands Reference

```bash
# Quick health check
./scripts/health-check.sh

# Reset everything
./scripts/reset-lab.sh

# Run all tests
./scripts/test-integration.sh

# Generate reports
./scripts/generate-reports.sh
```
EOF

    log_success "Created troubleshooting guide: docs/troubleshooting.md"
}

create_final_documentation() {
    log_step "Creating final documentation files..."
    
    # Create architecture overview
    cat > "${PROJECT_ROOT}/docs/architecture.md" << 'EOF'
# Architecture Overview

## System Architecture

The DevSecOps Lab implements a comprehensive security-first CI/CD pipeline using enterprise-grade open-source tools.

### Core Components

#### 1. Repository Management
- **Nexus Repository OSS**: Central artifact repository
- **Docker Registry**: Container image storage (port 8082)
- **Generic Repository**: SBOM, reports, and metadata storage
- **Metadata System**: JSON companion files for build traceability

#### 2. Security Scanning
- **Trivy**: Primary vulnerability scanner
- **Grype**: Alternative vulnerability scanner
- **Syft**: Software Bill of Materials (SBOM) generation
- **Multi-format Support**: SPDX, CycloneDX

#### 3. Policy Engine
- **Configurable Thresholds**: Severity-based gates
- **Emergency Bypass**: Controlled override mechanism
- **Audit Trail**: Complete decision logging
- **Risk-based Decisions**: Intelligent pass/fail logic

#### 4. CI/CD Integration
- **GitHub Actions**: 6-stage security pipeline
- **Local Simulation**: Complete testing environment
- **Pull Request Integration**: Automated security comments
- **Notification System**: Slack, email, webhooks

### Data Flow

```
Developer Code → GitHub → CI/CD Pipeline → Security Gates → Nexus → Production
                              ↓
                    [Scan] → [Evaluate] → [Decide] → [Audit]
```

### Security Controls

#### Vulnerability Management
- **Zero Critical**: No critical vulnerabilities allowed
- **Limited High**: Maximum 5 high-severity vulnerabilities
- **Risk Assessment**: Weighted scoring system
- **Continuous Monitoring**: Scheduled scans

#### Compliance Features
- **SBOM Generation**: Complete software inventory
- **Audit Logging**: All security decisions recorded
- **Report Archival**: Historical vulnerability data
- **Traceability**: Code-to-production tracking

### Scalability Considerations

#### Horizontal Scaling
- **Multiple Scanners**: Parallel vulnerability detection
- **Distributed Storage**: Nexus clustering support
- **Load Balancing**: Multiple CI/CD runners
- **Caching**: Scan result and dependency caching

#### Performance Optimization
- **Incremental Scanning**: Only scan changed layers
- **Result Caching**: Reuse previous scan results
- **Parallel Processing**: Concurrent security checks
- **Resource Management**: Configurable timeouts and limits

### Integration Points

#### External Systems
- **SIEM Integration**: Security event forwarding
- **Ticketing Systems**: Automated issue creation
- **Monitoring Platforms**: Metrics and alerting
- **Compliance Tools**: Audit report generation

#### API Endpoints
- **REST APIs**: Programmatic access to all functions
- **Webhooks**: Event-driven integrations
- **GraphQL**: Flexible data querying
- **OpenAPI**: Complete API documentation
EOF

    # Create security configuration guide
    cat > "${PROJECT_ROOT}/docs/security-config.md" << 'EOF'
# Security Configuration Guide

## Policy Configuration

### Severity Thresholds

Configure vulnerability thresholds in `.env`:

```bash
# Critical vulnerabilities (zero tolerance)
GATE_FAIL_ON_CRITICAL=true
GATE_MAX_CRITICAL=0

# High severity vulnerabilities
GATE_FAIL_ON_HIGH=true
GATE_MAX_HIGH=5

# Medium severity vulnerabilities
GATE_FAIL_ON_MEDIUM=false
GATE_MAX_MEDIUM=20

# Low severity vulnerabilities
GATE_FAIL_ON_LOW=false
GATE_MAX_LOW=50
```

### Advanced Policy Rules

#### Risk-based Scoring
```bash
# Weighted vulnerability scoring
VULNERABILITY_WEIGHTS_CRITICAL=10
VULNERABILITY_WEIGHTS_HIGH=5
VULNERABILITY_WEIGHTS_MEDIUM=2
VULNERABILITY_WEIGHTS_LOW=1

# Maximum total risk score
MAX_RISK_SCORE=25
```

#### Package Policies
```bash
# Blacklisted packages (never allow)
BLACKLISTED_PACKAGES="malicious-package,deprecated-crypto"

# Whitelisted CVEs (known false positives)
WHITELISTED_CVES="CVE-2023-EXAMPLE-1,CVE-2023-EXAMPLE-2"

# Trusted base images
TRUSTED_BASE_IMAGES="alpine:3.18,ubuntu:22.04,node:18-alpine"
```

### Bypass Controls

#### Emergency Override
```bash
# Enable bypass mechanism
GATE_BYPASS_ENABLED=true

# Bypass authorization (set via CI secrets)
GATE_BYPASS_TOKEN=""

# Audit requirements
GATE_BYPASS_REASON_REQUIRED=true
GATE_BYPASS_APPROVAL_REQUIRED=false
```

#### Bypass Workflow
1. **Request**: Set bypass token and reason
2. **Approval**: Optional approval workflow
3. **Execution**: Override security gate
4. **Audit**: Log all bypass decisions
5. **Review**: Post-deployment security review

## Scanner Configuration

### Trivy Settings
```bash
# Primary scanner configuration
PRIMARY_SCANNER=trivy
TRIVY_TIMEOUT=300
TRIVY_CACHE_DIR=/tmp/trivy-cache

# Database updates
TRIVY_AUTO_UPDATE=true
TRIVY_UPDATE_INTERVAL=24h

# Scan options
TRIVY_SKIP_FILES="*.pdf,*.doc,*.ppt"
TRIVY_SKIP_DIRS="/tmp,/var/cache"
```

### Grype Settings
```bash
# Alternative scanner
GRYPE_TIMEOUT=300
GRYPE_DB_AUTO_UPDATE=true

# Output formats
GRYPE_OUTPUT_FORMAT=json
GRYPE_FAIL_ON_SEVERITY=high
```

### SBOM Configuration
```bash
# SBOM generation
SBOM_ENABLED=true
SBOM_FORMAT=spdx-json,cyclonedx-json

# SBOM storage
SBOM_UPLOAD_ENABLED=true
SBOM_RETENTION_DAYS=365
```

## Compliance Settings

### Audit Configuration
```bash
# Audit logging
AUDIT_ENABLED=true
AUDIT_LOG_LEVEL=INFO
AUDIT_RETENTION_DAYS=2555  # 7 years

# Audit events
AUDIT_SCAN_RESULTS=true
AUDIT_GATE_DECISIONS=true
AUDIT_BYPASS_USAGE=true
AUDIT_POLICY_CHANGES=true
```

### Reporting
```bash
# Report generation
REPORT_ENABLED=true
REPORT_FORMATS=markdown,json,pdf
REPORT_RETENTION_DAYS=365

# Report distribution
REPORT_EMAIL_ENABLED=false
REPORT_SLACK_ENABLED=false
REPORT_WEBHOOK_ENABLED=false
```

## Integration Security

### API Security
```bash
# Authentication
API_AUTH_REQUIRED=true
API_TOKEN_EXPIRY=3600

# Rate limiting
API_RATE_LIMIT=100
API_RATE_WINDOW=3600

# HTTPS enforcement
API_HTTPS_ONLY=true
API_TLS_VERSION=1.2
```

### Network Security
```bash
# Network policies
NEXUS_NETWORK_ISOLATION=true
SCANNER_NETWORK_ACCESS=restricted

# Firewall rules
ALLOW_INBOUND_PORTS=8081,8082
ALLOW_OUTBOUND_HOSTS=github.com,aquasec.com
```

## Monitoring and Alerting

### Security Metrics
```bash
# Metrics collection
METRICS_ENABLED=true
METRICS_ENDPOINT=/metrics
METRICS_RETENTION=30d

# Key metrics
- vulnerability_count_by_severity
- security_gate_decisions
- scan_duration_seconds
- policy_bypass_count
```

### Alert Configuration
```bash
# Alert thresholds
ALERT_CRITICAL_VULNS=1
ALERT_FAILED_SCANS=3
ALERT_BYPASS_USAGE=1

# Alert channels
ALERT_EMAIL=security@company.com
ALERT_SLACK=#security-alerts
ALERT_WEBHOOK=https://monitoring.company.com/webhook
```

## Best Practices

### Policy Management
1. **Start Restrictive**: Begin with strict policies
2. **Gradual Relaxation**: Adjust based on operational needs
3. **Regular Review**: Monthly policy effectiveness review
4. **Exception Tracking**: Monitor and review all bypasses

### Operational Security
1. **Least Privilege**: Minimal required permissions
2. **Secret Management**: Secure credential storage
3. **Network Segmentation**: Isolate security components
4. **Regular Updates**: Keep scanners and databases current

### Incident Response
1. **Automated Blocking**: Immediate response to critical findings
2. **Escalation Procedures**: Clear communication channels
3. **Forensic Logging**: Detailed audit trails
4. **Recovery Procedures**: Rollback and remediation plans
EOF

    log_success "Created final documentation files"
}

update_project_structure_doc() {
    log_step "Creating project structure documentation..."
    
    cat > "${PROJECT_ROOT}/docs/project-structure.md" << 'EOF'
# Project Structure

Complete overview of the DevSecOps Lab project organization.

```
devsecops-artifactory-lab/
├── README.md                           # Main project documentation
├── LICENSE                             # MIT License
├── .env                               # Environment configuration
├── .gitignore                         # Git ignore rules
│
├── setup-phase1.sh                    # Phase 1: Environment setup
├── setup-phase2.sh                    # Phase 2: Repository automation
├── setup-phase3.sh                    # Phase 3: Sample application
├── setup-phase4.sh                    # Phase 4: Security scanning
├── setup-phase5.sh                    # Phase 5: Policy gates
├── setup-phase6.sh                    # Phase 6: CI/CD pipeline
├── setup-phase7.sh                    # Phase 7: Documentation
├── setup-phase8.sh                    # Phase 8: Testing & validation
│
├── .github/
│   └── workflows/
│       ├── ci-pipeline.yml            # Main DevSecOps pipeline
│       ├── test-pipeline.yml          # Lightweight testing
│       └── security-scan.yml          # Scheduled security scans
│
├── src/                               # Sample application
│   ├── package.json                   # Node.js dependencies
│   ├── package-lock.json              # Dependency lock file
│   ├── Dockerfile                     # Multi-stage container build
│   ├── app.js                         # Express application
│   ├── routes/
│   │   ├── index.js                   # Main routes
│   │   ├── vulnerable.js              # Intentional vulnerabilities
│   │   └── admin.js                   # Admin endpoints
│   ├── public/                        # Static assets
│   └── tests/                         # Unit tests
│
├── scripts/
│   ├── simulate-ci.sh                 # Local CI/CD simulation
│   ├── health-check.sh                # System health validation
│   ├── reset-lab.sh                   # Reset to clean state
│   ├── test-integration.sh            # Integration testing
│   │
│   ├── api/                           # Nexus API automation
│   │   ├── create-repos.sh            # Repository creation
│   │   ├── upload-artifact.sh         # Artifact upload
│   │   ├── query-artifacts.sh         # Artifact queries
│   │   └── docker-operations.sh       # Docker registry ops
│   │
│   └── security/                      # Security automation
│       ├── scan.sh                    # Vulnerability scanning
│       ├── policy-gate.sh             # Security policy gates
│       └── integrate-gate.sh          # Integrated pipeline
│
├── policies/                          # Security policies
│   └── rego/
│       └── security-policy.rego       # OPA/Rego policies
│
├── docs/                              # Documentation
│   ├── architecture.md                # System architecture
│   ├── api-reference.md               # Complete API reference
│   ├── ci-cd-pipeline.md              # Pipeline documentation
│   ├── security-config.md             # Security configuration
│   ├── troubleshooting.md             # Troubleshooting guide
│   ├── project-structure.md           # This file
│   ├── github-secrets.md              # GitHub secrets setup
│   │
│   └── diagrams/
│       ├── architecture.svg           # Architecture diagram
│       └── pipeline-flow.svg          # Pipeline flow diagram
│
├── logs/                              # Log files
│   ├── audit/                         # Security audit logs
│   │   └── policy-gate-YYYYMMDD.log   # Daily gate decisions
│   ├── scan/                          # Scan execution logs
│   └── integration/                   # Integration test logs
│
├── reports/                           # Generated reports
│   ├── security/                      # Security scan reports
│   ├── policy/                        # Policy gate reports
│   ├── compliance/                    # Compliance reports
│   └── sbom/                          # Software Bill of Materials
│
├── scan-results/                      # Scanner output
│   ├── trivy-results.json             # Trivy scan results
│   ├── grype-results.json             # Grype scan results
│   ├── sbom-spdx.json                 # SPDX format SBOM
│   └── sbom-cyclonedx.json            # CycloneDX format SBOM
│
├── test/                              # Test files
│   ├── fixtures/                      # Test data
│   │   ├── trivy-vulnerable.json      # Mock vulnerable results
│   │   ├── trivy-clean.json           # Mock clean results
│   │   └── grype-vulnerable.json      # Mock Grype results
│   │
│   ├── scenarios/                     # Test scenarios
│   │   ├── test-gate-pass.sh          # Gate pass scenario
│   │   ├── test-gate-fail.sh          # Gate fail scenario
│   │   └── test-gate-bypass.sh        # Gate bypass scenario
│   │
│   └── integration/                   # Integration tests
│       ├── test-nexus-api.sh          # Nexus API tests
│       ├── test-security-scan.sh      # Scanner tests
│       └── test-policy-gate.sh        # Policy gate tests
│
├── terraform/                         # Infrastructure as Code
│   ├── main.tf                        # Main Terraform config
│   ├── variables.tf                   # Variable definitions
│   ├── outputs.tf                     # Output definitions
│   └── modules/                       # Terraform modules
│       ├── nexus/                     # Nexus deployment
│       └── security/                  # Security configuration
│
└── docker-compose.yml                 # Local development stack
```

## Key Directories

### `/src` - Sample Application
Contains the vulnerable Node.js application used for testing:
- **Intentional vulnerabilities** for security scanning
- **Multi-stage Dockerfile** with security labels
- **Express.js application** with REST API endpoints
- **Unit tests** for CI/CD pipeline validation

### `/scripts` - Automation Scripts
All automation and operational scripts:
- **API scripts**: Nexus repository management
- **Security scripts**: Scanning and policy enforcement
- **Utility scripts**: Health checks, testing, simulation

### `/docs` - Documentation
Comprehensive documentation for all aspects:
- **Architecture guides**: System design and data flow
- **API references**: Complete endpoint documentation
- **Configuration guides**: Security and operational settings
- **Troubleshooting**: Common issues and solutions

### `/.github/workflows` - CI/CD Pipelines
GitHub Actions workflows:
- **Main pipeline**: Complete 6-stage DevSecOps workflow
- **Test pipeline**: Lightweight validation
- **Security pipeline**: Scheduled vulnerability scans

### `/policies` - Security Policies
Policy definitions and rules:
- **OPA/Rego policies**: Advanced policy engine rules
- **Threshold configurations**: Vulnerability limits
- **Bypass procedures**: Emergency override rules

### `/logs` - Audit and Logging
All system logs and audit trails:
- **Audit logs**: Security decisions and policy changes
- **Scan logs**: Vulnerability scanning execution
- **Integration logs**: Test execution and results

### `/reports` - Generated Reports
All generated reports and documentation:
- **Security reports**: Vulnerability scan results
- **Policy reports**: Gate decisions and rationale
- **Compliance reports**: Audit and regulatory documentation
- **SBOM reports**: Software Bill of Materials

### `/test` - Testing Framework
Complete testing infrastructure:
- **Fixtures**: Mock data and test scenarios
- **Integration tests**: End-to-end validation
- **Unit tests**: Component-level testing

## File Naming Conventions

### Scripts
- **setup-phaseN.sh**: Phase setup scripts
- **test-*.sh**: Testing scripts
- ***-operations.sh**: Operational scripts

### Documentation
- ***.md**: Markdown documentation
- **diagrams/*.svg**: Architecture diagrams
- **api-*.md**: API documentation

### Configuration
- **.env**: Environment variables
- ***.yml**: YAML configuration files
- ***.json**: JSON configuration and data

### Reports
- **YYYYMMDD-HHMMSS**: Timestamp-based naming
- **policy-gate-report-*.md**: Policy gate reports
- **scan-results-*.json**: Scan result files

## Access Patterns

### Development Workflow
1. **Setup**: Run phase setup scripts
2. **Development**: Modify code in `/src`
3. **Testing**: Use `/scripts/simulate-ci.sh`
4. **Integration**: Run integration tests
5. **Documentation**: Update relevant docs

### Operational Workflow
1. **Monitoring**: Check `/logs` for issues
2. **Reports**: Review `/reports` for compliance
3. **Configuration**: Update `.env` and policies
4. **Maintenance**: Run health checks and cleanup

### Security Workflow
1. **Scanning**: Automated via CI/CD or manual
2. **Policy Evaluation**: Gate decisions in `/logs/audit`
3. **Reporting**: Security reports in `/reports/security`
4. **Compliance**: SBOM and audit documentation

## Integration Points

### External Systems
- **GitHub**: Source control and CI/CD
- **Nexus**: Artifact repository and registry
- **Docker**: Container runtime and registry
- **Slack/Email**: Notification systems

### Internal Components
- **Scripts**: Automation and operations
- **Policies**: Security rule enforcement
- **Reports**: Documentation and compliance
- **Logs**: Audit trails and debugging
EOF

    log_success "Created project structure documentation"
}

# =============================================================================
# VALIDATION FUNCTIONS
# =============================================================================

validate_phase7_setup() {
    log_step "Validating Phase 7 setup..."
    
    local validation_results=()
    
    # Check documentation files
    local required_docs=(
        "README.md"
        "docs/architecture.md"
        "docs/api-reference.md"
        "docs/troubleshooting.md"
        "docs/security-config.md"
        "docs/project-structure.md"
        "docs/diagrams/architecture.svg"
    )
    
    for doc in "${required_docs[@]}"; do
        if [[ -f "${PROJECT_ROOT}/${doc}" ]]; then
            validation_results+=("✅ ${doc}: Created")
        else
            validation_results+=("❌ ${doc}: Missing")
        fi
    done
    
    # Check previous phases
    local required_phases=(
        "scripts/security/scan.sh"
        "scripts/security/policy-gate.sh"
        ".github/workflows/ci-pipeline.yml"
    )
    
    for phase in "${required_phases[@]}"; do
        if [[ -f "${PROJECT_ROOT}/${phase}" ]]; then
            validation_results+=("✅ Previous phase: ${phase}")
        else
            validation_results+=("❌ Previous phase missing: ${phase}")
        fi
    done
    
    # Display validation results
    echo
    log_info "=== Phase 7 Validation Results ==="
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

Phase 7 Setup Script - Documentation & Reporting

OPTIONS:
    --docs-only         Only create documentation files
    --diagrams-only     Only create architecture diagrams
    -h, --help          Show this help message

EXAMPLES:
    $0                  # Full Phase 7 setup
    $0 --docs-only      # Only documentation
    $0 --diagrams-only  # Only diagrams

EOF
}

main() {
    local docs_only=false
    local diagrams_only=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --docs-only)
                docs_only=true
                shift
                ;;
            --diagrams-only)
                diagrams_only=true
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
    log_info "=== DevSecOps Lab - Phase 7 Setup ==="
    log_info "Documentation & Reporting"
    echo
    
    if [[ "${diagrams_only}" == "true" ]]; then
        create_architecture_diagram
        exit 0
    fi
    
    if [[ "${docs_only}" == "true" ]]; then
        create_comprehensive_readme
        create_api_reference
        create_troubleshooting_guide
        create_final_documentation
        update_project_structure_doc
        exit 0
    fi
    
    # Full setup process
    create_architecture_diagram
    create_comprehensive_readme
    create_api_reference
    create_troubleshooting_guide
    create_final_documentation
    update_project_structure_doc
    
    # Validate setup
    if validate_phase7_setup; then
        log_success "Phase 7 setup completed successfully!"
        
        echo
        log_info "=== Documentation Created ==="
        log_info "📋 README.md - Complete project overview"
        log_info "🏗️  docs/architecture.md - System architecture"
        log_info "📚 docs/api-reference.md - Complete API documentation"
        log_info "🔧 docs/troubleshooting.md - Problem resolution guide"
        log_info "🛡️  docs/security-config.md - Security configuration"
        log_info "📁 docs/project-structure.md - Project organization"
        log_info "🎨 docs/diagrams/architecture.svg - Visual architecture"
        echo
        
        log_info "=== Next Steps ==="
        log_info "1. Review all documentation for accuracy"
        log_info "2. Customize architecture diagram if needed"
        log_info "3. Add any project-specific documentation"
        log_info "4. Proceed to Phase 8: Testing & Validation"
        log_info "5. Consider creating a demo video or presentation"
        echo
        
        log_success "🎉 Phase 7 Complete! Your DevSecOps lab is now fully documented."
        
    else
        log_error "Phase 7 setup failed. Please review the validation results."
        exit 1
    fi
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
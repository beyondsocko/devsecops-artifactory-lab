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
curl -u admin:DevSecOps2024! \
  --upload-file artifact.jar \
  http://localhost:8081/repository/raw-hosted/com/example/artifact/1.0/artifact.jar
```

#### Upload with Metadata
```bash
# Upload artifact
curl -u admin:DevSecOps2024! \
  --upload-file artifact.jar \
  http://localhost:8081/repository/raw-hosted/path/artifact.jar

# Upload metadata companion file
curl -u admin:DevSecOps2024! \
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
NEXUS_PASSWORD=DevSecOps2024!
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

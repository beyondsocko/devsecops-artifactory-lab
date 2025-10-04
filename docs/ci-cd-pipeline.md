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

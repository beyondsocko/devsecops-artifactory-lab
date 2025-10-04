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

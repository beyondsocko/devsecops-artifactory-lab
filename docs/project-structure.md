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

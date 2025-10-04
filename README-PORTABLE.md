# DevSecOps Lab - Portable Edition

🛡️ **Enterprise-grade DevSecOps pipeline that runs anywhere with Docker**

## 🚀 One-Command Setup

```bash
# 1. Download the lab
git clone <your-repo-url>
cd devsecops-artifactory-lab

# 2. Start the lab
./quick-start.sh
```

**That's it!** Your complete DevSecOps lab is now running.

## 📋 What You Get Instantly

### Core Services
- **Nexus Repository OSS** - http://localhost:8081 (admin/Aa1234567)
- **Docker Registry** - localhost:8082 (for container images)
- **Security Tools** - Trivy, Grype, Syft (containerized or local)
- **Policy Gates** - Automated security decision engine

### Working Examples
- **Vulnerable Sample App** - Real Node.js application with intentional security issues
- **Complete Security Pipeline** - Scan → Evaluate → Block/Allow → Audit
- **SBOM Generation** - Software Bill of Materials for compliance
- **Audit Trails** - Complete logging of all security decisions

## 🎯 Quick Demo (5 minutes)

### 1. Verify Lab is Running
```bash
# Check services
docker-compose ps

# Test Nexus
curl -u admin:Aa1234567 http://localhost:8081/service/rest/v1/status
```

### 2. Run Security Scan
```bash
# Scan any Docker image
docker-compose exec security-scanner trivy image alpine:latest

# Or use local tools
./scripts/security/scan.sh alpine:latest
```

### 3. Test Policy Gates
```bash
# Test security policy enforcement
docker-compose exec security-scanner /app/scripts/security/policy-gate.sh

# Or use local scripts
./scripts/security/policy-gate.sh
```

### 4. Run Complete Pipeline
```bash
# Simulate full CI/CD pipeline
./scripts/simulate-ci.sh
```

## 🛡️ Security Features

### Automated Vulnerability Management
- **Zero Critical Policy** - No critical vulnerabilities allowed in production
- **Risk-Based Thresholds** - Configurable limits for High/Medium/Low severity
- **Multi-Scanner Validation** - Trivy (primary) + Grype (alternative)
- **SBOM Generation** - Complete software inventory (755 components tracked)

### Policy Enforcement
- **Automated Gates** - Pass/Fail decisions based on vulnerability severity
- **Emergency Bypass** - Controlled override with full audit trail
- **Metadata Tracking** - Complete build and security information
- **Compliance Ready** - Audit trails meet regulatory requirements

### Real-World Security Testing
- **Intentional Vulnerabilities** - Sample app with SQL injection, XSS, secrets
- **Container Security** - Base image and dependency scanning
- **Supply Chain Security** - Complete visibility from source to production

## 📊 Architecture

```
Developer Code → Docker Build → Security Scan → Policy Gate → Nexus Repository
                                      ↓              ↓              ↓
                                 [Trivy/Grype]  [Risk Eval]   [Secure Storage]
                                      ↓              ↓              ↓
                                  [SBOM Gen]     [Audit Log]   [Metadata Link]
```

## 🔧 Configuration

### Default Security Policies
```bash
GATE_FAIL_ON_CRITICAL=true    # Zero tolerance for critical vulnerabilities
GATE_MAX_HIGH=5               # Maximum 5 high-severity vulnerabilities
GATE_FAIL_ON_MEDIUM=false     # Allow medium-severity (configurable)
```

### Customize Policies
```bash
# Edit .env file to adjust thresholds
nano .env

# Restart services to apply changes
docker-compose restart
```

## 📚 Available Commands

### Service Management
```bash
# Start lab
./quick-start.sh

# Start with containerized scanner
./quick-start.sh --with-scanner

# Stop lab
docker-compose down

# Clean up everything
./quick-start.sh --clean
```

### Security Operations
```bash
# Scan container image
docker-compose exec security-scanner trivy image myapp:latest

# Run policy gate evaluation
docker-compose exec security-scanner /app/scripts/security/policy-gate.sh

# Complete security pipeline
docker-compose exec security-scanner /app/scripts/security/integrate-gate.sh myapp:latest
```

### Local Development
```bash
# All original scripts still work
./scripts/security/scan.sh myapp:latest
./scripts/security/policy-gate.sh
./scripts/simulate-ci.sh

# API operations
./scripts/api/create-repos.sh
./scripts/api/upload-artifact.sh myfile.jar
./scripts/api/query-artifacts.sh
```

## 🎯 Use Cases

### 1. Security Training & Education
- Demonstrate DevSecOps best practices
- Show automated security controls in action
- Practice vulnerability management workflows

### 2. Proof of Concept
- Validate security pipeline capabilities
- Demonstrate ROI of automated security
- Show integration possibilities

### 3. Development Environment
- Local security testing before CI/CD
- Policy development and tuning
- Security tool evaluation

### 4. Compliance Demonstration
- Complete audit trails and documentation
- SBOM generation for regulatory requirements
- Security control effectiveness proof

## 🚨 Troubleshooting

### Lab Won't Start
```bash
# Check Docker is running
docker ps

# Check port availability
netstat -an | grep -E "(8081|8082)"

# View service logs
docker-compose logs nexus
```

### Security Scanner Issues
```bash
# Rebuild scanner container
docker-compose build security-scanner

# Use local tools instead
./scripts/security/scan.sh alpine:latest

# Check scanner logs
docker-compose logs security-scanner
```

### Nexus Issues
```bash
# Reset Nexus data
docker-compose down -v
docker-compose up -d nexus

# Check admin password
docker-compose exec nexus cat /nexus-data/admin.password
```

## 📦 What's Included

### Complete DevSecOps Implementation
- **8 Development Phases** - From environment setup to final validation
- **Security-First Design** - Every component includes security controls
- **Enterprise Architecture** - Production-ready design and implementation
- **Comprehensive Testing** - End-to-end validation and performance benchmarks

### Professional Documentation
- **Architecture Diagrams** - Visual system overview and data flow
- **API Reference** - Complete endpoint and script documentation
- **Troubleshooting Guides** - Common issues and step-by-step solutions
- **Security Configuration** - Policy settings and compliance features

### Real-World Examples
- **Vulnerable Application** - Intentional security issues for testing
- **Security Scanning** - Multiple tools and validation approaches
- **Policy Enforcement** - Risk-based decision making with audit trails
- **Incident Response** - Complete traceability and rollback capabilities

## 🏆 Success Metrics

After running this lab, you'll understand:

- ✅ **Security-First CI/CD** - How to integrate security throughout the pipeline
- ✅ **Automated Risk Management** - Policy-based security decisions
- ✅ **Supply Chain Security** - Complete visibility and control
- ✅ **Compliance Automation** - Audit trails and regulatory compliance
- ✅ **Enterprise DevSecOps** - Production-ready security practices

## 🎉 Ready to Start?

```bash
# Clone and run
git clone <your-repo-url>
cd devsecops-artifactory-lab
./quick-start.sh

# Access your lab
# Nexus: http://localhost:8081 (admin/Aa1234567)
# Documentation: All files in docs/ directory
# Reports: Generated in reports/ directory
```

---

**Built with ❤️ for DevSecOps practitioners**

*This lab demonstrates enterprise-grade security practices using 100% free and open-source tools.*
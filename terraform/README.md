# DevSecOps Lab - Terraform Infrastructure

This directory contains Infrastructure as Code (IaC) configurations for deploying the DevSecOps lab environment using Terraform.

## 🏗️ Architecture Overview

The Terraform configuration deploys:

- **Nexus Repository OSS**: Artifact repository with Docker registry
- **Security Tools**: Trivy scanner for vulnerability assessment  
- **Network Infrastructure**: Isolated Docker networks
- **Persistent Storage**: Volumes for data persistence

## 📁 File Structure & Purpose

### Core Configuration Files

| File | Purpose | Description |
|------|---------|-------------|
| `main.tf` | **Provider Setup** | Terraform version requirements, provider configurations, and global variables |
| `variables.tf` | **Input Variables** | Customizable parameters for flexible deployments |
| `outputs.tf` | **Output Values** | Connection URLs, resource IDs, and deployment information |

### Infrastructure Components

| File | Purpose | Description |
|------|---------|-------------|
| `network.tf` | **Network Layer** | Docker networks for service isolation and communication |
| `nexus.tf` | **Repository Service** | Nexus Repository OSS container and configuration |
| `security-tools.tf` | **Security Layer** | Trivy scanner and vulnerability database setup |

### Configuration Files

| File | Purpose | Description |
|------|---------|-------------|
| `terraform.tfvars.example` | **Configuration Template** | Example values for customization |
| `README.md` | **Documentation** | This file - usage instructions and explanations |

## 🚀 Quick Start

### 1. Initialize Terraform
```bash
cd terraform
terraform init
```

### 2. Review Configuration
```bash
# Copy example variables
cp terraform.tfvars.example terraform.tfvars

# Edit variables as needed
nano terraform.tfvars

# Review planned changes
terraform plan
```

### 3. Deploy Infrastructure
```bash
# Deploy all resources
terraform apply

# Auto-approve (for automation)
terraform apply -auto-approve
```

### 4. Access Services
```bash
# Get connection information
terraform output

# Access Nexus web interface
open http://localhost:8081

# Login: admin / Aa1234567 (or your configured password)
```

## 🔧 Customization Options

### Environment Variables

```hcl
# Development Environment
project_environment = "development"
nexus_memory = 1024
enable_security_scanning = false

# Production Environment  
project_environment = "production"
nexus_memory = 4096
enable_security_scanning = true
```

### Port Configuration

```hcl
# Custom ports to avoid conflicts
nexus_web_port = 9081
nexus_registry_port = 9082
```

### Security Configuration

```hcl
# Enable/disable security tools
enable_security_scanning = true

# Custom admin password
nexus_admin_password = "your-secure-password"
```

## 📊 Infrastructure Components

### Nexus Repository
- **Web Interface**: Port 8081
- **Docker Registry**: Port 8082  
- **Persistent Storage**: Docker volume
- **Health Checks**: Automated monitoring
- **API Access**: REST API for automation

### Security Tools
- **Trivy Scanner**: Vulnerability assessment
- **Database Cache**: Pre-downloaded vulnerability DB
- **Docker Integration**: Direct image scanning
- **Network Isolation**: Dedicated security network

### Networking
- **Main Network**: Service communication
- **Security Network**: Isolated scanning environment
- **Port Mapping**: Host to container access
- **DNS Resolution**: Container name resolution

## 🛡️ Security Features

### Network Security
- Isolated Docker networks
- Controlled port exposure
- Container-to-container communication

### Access Control
- Configurable admin credentials
- Health check endpoints
- API authentication

### Vulnerability Management
- Pre-configured Trivy scanner
- Automated database updates
- Container image assessment

## 🔍 Monitoring & Management

### Health Checks
```bash
# Check Nexus status
curl http://localhost:8081/service/rest/v1/status

# View container logs
docker logs devsecops-lab-nexus

# Monitor resource usage
docker stats
```

### Terraform Management
```bash
# View current state
terraform show

# Update infrastructure
terraform apply

# Destroy infrastructure
terraform destroy
```

## 🎯 Integration with DevSecOps Pipeline

This Terraform configuration integrates with the broader DevSecOps pipeline:

1. **Repository Creation**: Automated via `null_resource` provisioners
2. **Security Scanning**: Pre-configured Trivy integration
3. **CI/CD Integration**: Outputs provide connection details
4. **Monitoring**: Health checks and logging integration

## 🔄 Lifecycle Management

### Deployment
- Idempotent operations
- Dependency management
- Error handling and rollback

### Updates
- Version-controlled infrastructure
- Gradual rollout capabilities
- Configuration drift detection

### Cleanup
- Complete resource cleanup
- Volume data preservation options
- Network cleanup automation

## 📚 Advanced Usage

### Multi-Environment Deployment
```bash
# Development environment
terraform workspace new development
terraform apply -var="project_environment=development"

# Production environment  
terraform workspace new production
terraform apply -var="project_environment=production"
```

### Integration with CI/CD
```yaml
# GitHub Actions example
- name: Deploy Infrastructure
  run: |
    cd terraform
    terraform init
    terraform apply -auto-approve
```

### Backup and Recovery
```bash
# Backup Terraform state
terraform state pull > backup.tfstate

# Export Nexus data
docker run --rm -v nexus-data:/data -v $(pwd):/backup alpine tar czf /backup/nexus-backup.tar.gz /data
```

## 🤝 Contributing

When modifying the Terraform configuration:

1. **Test Changes**: Use `terraform plan` before applying
2. **Document Updates**: Update this README for new features
3. **Version Control**: Commit infrastructure changes with descriptive messages
4. **Validation**: Ensure configurations work across environments

## 📞 Support

For issues with the Terraform configuration:

1. Check `terraform plan` output for errors
2. Review Docker container logs
3. Verify network connectivity
4. Consult Terraform and Docker documentation

---

**This Infrastructure as Code approach ensures:**
- ✅ **Reproducible Deployments**: Consistent environments across teams
- ✅ **Version Control**: Infrastructure changes tracked in Git
- ✅ **Automation Ready**: CI/CD pipeline integration
- ✅ **Scalable Architecture**: Easy to extend and modify
- ✅ **Documentation**: Self-documenting infrastructure code

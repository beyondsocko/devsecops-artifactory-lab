# Production Security Guide

## 🚨 Converting Demo Lab to Production

This guide helps you secure the DevSecOps lab for production use.

### ⚠️ Critical Security Changes Required

#### 1. Change All Default Passwords

**Files containing `DevSecOps2024!` that need updates:**
```bash
# Configuration files
terraform/variables.tf
terraform/terraform.tfvars.example
scripts/security/policy-config.env
docker-compose.yml
.env (create from .env.example)

# Update with secure passwords
export NEXUS_ADMIN_PASSWORD="$(openssl rand -base64 32)"
```

#### 2. Secure JWT Secret

**Update in:**
```bash
# Application files
src/.env.example → .env
export JWT_SECRET="$(openssl rand -base64 64)"
```

#### 3. Environment Variable Strategy

**Recommended approach:**
```bash
# Create production .env file
cp .env.example .env

# Update with secure values
NEXUS_PASSWORD="${SECURE_NEXUS_PASSWORD}"
JWT_SECRET="${SECURE_JWT_SECRET}"
```

#### 4. Secrets Management Integration

**For production environments:**
- Use HashiCorp Vault
- Use Kubernetes secrets
- Use cloud provider secret managers (AWS Secrets Manager, Azure Key Vault)
- Use CI/CD secret management (GitHub Secrets, GitLab CI Variables)

### 🔒 Production Deployment Checklist

- [ ] Change all default passwords
- [ ] Update JWT secrets
- [ ] Enable HTTPS/TLS
- [ ] Configure proper authentication
- [ ] Set up secrets management
- [ ] Enable audit logging
- [ ] Configure network security
- [ ] Remove demo/test data
- [ ] Enable monitoring and alerting
- [ ] Review all configuration files for hardcoded secrets

### 🎯 Why Demo Credentials Exist

**Educational Benefits:**
- ✅ Zero-configuration setup for learners
- ✅ Consistent experience across all users
- ✅ Focus on DevSecOps concepts, not credential management
- ✅ Immediate hands-on experience

**Security Trade-off:**
- ❌ Not production-ready by design
- ❌ Requires manual security hardening
- ❌ Educational warning needed

This is a **conscious design decision** for maximum learning accessibility.

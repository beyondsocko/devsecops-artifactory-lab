# Contributing to DevSecOps Lab

Thank you for your interest in contributing to this DevSecOps laboratory! This project demonstrates enterprise-grade security practices and welcomes contributions from the community.

## 🎯 How to Contribute

### Types of Contributions Welcome
- 🐛 **Bug fixes** - Issues with setup, scripts, or documentation
- ✨ **Feature enhancements** - New security tools, integrations, or capabilities
- 📚 **Documentation** - Improvements to guides, tutorials, or API docs
- 🔒 **Security improvements** - Better practices, additional scanners, or policy enhancements
- 🧪 **Testing** - Additional test cases, validation scripts, or benchmarks
- 🌐 **Platform support** - Windows, macOS, or Linux compatibility improvements

### Getting Started

1. **Fork the repository**
2. **Clone your fork:**
   ```bash
   git clone https://github.com/YOUR_USERNAME/devsecops-artifactory-lab.git
   cd devsecops-artifactory-lab
   ```
3. **Set up the development environment:**
   ```bash
   ./quick-start.sh --test-only
   ```
4. **Create a feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```

### Development Workflow

#### Before Making Changes
1. **Run the test suite:**
   ```bash
   ./test.sh
   ```
2. **Verify the lab setup:**
   ```bash
   ./quick-start.sh --test-only
   ```

#### Making Changes
1. **Follow existing code style** and patterns
2. **Update documentation** for any new features
3. **Add tests** for new functionality
4. **Test your changes** thoroughly:
   ```bash
   # Test individual components
   ./scripts/security/scan.sh alpine:latest
   ./scripts/security/policy-gate.sh
   
   # Test full pipeline
   ./scripts/simulate-ci.sh
   ```

#### Submitting Changes
1. **Commit with descriptive messages:**
   ```bash
   git commit -m "feat: add support for Snyk scanner integration
   
   - Added Snyk installation to scanner.Dockerfile
   - Updated entrypoint.sh to display Snyk version
   - Added Snyk scanning option to security scripts
   - Updated documentation with Snyk usage examples"
   ```
2. **Push to your fork:**
   ```bash
   git push origin feature/your-feature-name
   ```
3. **Create a Pull Request** with:
   - Clear description of changes
   - Screenshots/logs if applicable
   - Test results
   - Documentation updates

## 📋 Contribution Guidelines

### Code Style
- **Shell scripts:** Follow existing patterns, use `set -euo pipefail`
- **Docker:** Multi-stage builds, minimal layers, security best practices
- **Documentation:** Clear, concise, with examples
- **YAML:** Consistent indentation (2 spaces)

### Security Considerations
- **Never commit secrets** or real credentials
- **Use demo/example credentials** only (current: admin/Aa1234567)
- **Validate security tools** before adding them
- **Test security policies** thoroughly

### Testing Requirements
All contributions should include:
- **Unit tests** for new scripts
- **Integration tests** for new features
- **Documentation updates**
- **Validation that existing tests pass**

### Documentation Standards
- **Update README.md** for major features
- **Add API documentation** for new endpoints
- **Include troubleshooting** for common issues
- **Provide examples** for new functionality

## 🧪 Testing Your Contributions

### Local Testing
```bash
# Full test suite
./test.sh

# Quick validation
./quick-start.sh --test-only

# Security pipeline test
./scripts/simulate-ci.sh

# Individual component tests
docker-compose exec security-scanner trivy image alpine:latest
```

### Integration Testing
```bash
# Test with fresh environment
./quick-start.sh --clean
./quick-start.sh
./quick-start.sh --test-only
```

## 🐛 Reporting Issues

### Bug Reports
Please include:
- **Environment details** (OS, Docker version, etc.)
- **Steps to reproduce**
- **Expected vs actual behavior**
- **Logs and error messages**
- **Screenshots if applicable**

### Feature Requests
Please include:
- **Use case description**
- **Proposed solution**
- **Alternative approaches considered**
- **Impact on existing functionality**

## 🏆 Recognition

Contributors will be:
- **Listed in CONTRIBUTORS.md**
- **Mentioned in release notes**
- **Credited in documentation**

## 📞 Getting Help

- **Issues:** Use GitHub Issues for bugs and feature requests
- **Discussions:** Use GitHub Discussions for questions and ideas
- **Security:** Email maintainer privately for security issues

## 🎯 Priority Areas

We're especially interested in contributions for:

### High Priority
- **Additional security scanners** (Snyk, Clair, etc.)
- **Policy engine enhancements** (OPA policies, custom rules)
- **Platform compatibility** (Windows, macOS improvements)
- **Performance optimizations**

### Medium Priority  
- **Additional repository formats** (npm, PyPI, etc.)
- **Monitoring and alerting** integrations
- **Advanced reporting** features
- **UI/Dashboard** improvements

### Low Priority
- **Additional sample applications**
- **Alternative container runtimes**
- **Cloud deployment** guides

## 🚀 Development Environment

### Prerequisites
- Docker Desktop with WSL2 (Windows) or Docker (Linux/Mac)
- Node.js 18+ (for sample application)
- Git
- 8GB RAM, 20GB disk space

### Quick Setup
```bash
# Clone and setup
git clone https://github.com/YOUR_USERNAME/devsecops-artifactory-lab.git
cd devsecops-artifactory-lab

# Start development environment
./quick-start.sh

# Verify everything works
./quick-start.sh --test-only
```

## 📜 License

By contributing, you agree that your contributions will be licensed under the same license as the project (Apache 2.0).

---

**Thank you for contributing to the DevSecOps community!** 🛡️

Your contributions help others learn and implement security-first development practices.

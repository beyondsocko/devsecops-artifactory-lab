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
curl -u admin:DevSecOps2024! http://localhost:8081/service/rest/v1/status

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
curl -u admin:DevSecOps2024! \
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
curl -u admin:DevSecOps2024! http://localhost:8082/v2/_catalog

# Login to Docker registry
echo "DevSecOps2024!" | docker login localhost:8082 -u admin --password-stdin

# Check repository exists
curl -u admin:DevSecOps2024! \
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

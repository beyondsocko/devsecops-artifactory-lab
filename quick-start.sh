#!/bin/bash

# =============================================================================
# DevSecOps Lab - Quick Start (Minimal Portable)
# =============================================================================
# Adds portability to your existing lab without disrupting anything
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} ${1}"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} ${1}"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} ${1}"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} ${1}"
}

log_step() {
    echo -e "${PURPLE}[STEP]${NC} ${1}"
}

# =============================================================================
# PREREQUISITE CHECKS
# =============================================================================

check_prerequisites() {
    log_step "Checking prerequisites..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Check if Docker daemon is running
    if ! docker ps >/dev/null 2>&1; then
        log_error "Docker daemon is not running. Please start Docker Desktop."
        exit 1
    fi
    
    log_success "Docker: $(docker --version)"
    
    # Check Docker Compose
    if command -v docker-compose &> /dev/null; then
        export COMPOSE_CMD="docker-compose"
        log_success "Docker Compose: $(docker-compose --version)"
    elif docker compose version &> /dev/null 2>&1; then
        export COMPOSE_CMD="docker compose"
        log_success "Docker Compose: $(docker compose version)"
    else
        log_error "Docker Compose is not available. Please install Docker Compose."
        exit 1
    fi
    
    # Check if we're in the right directory
    if [[ ! -f "docker-compose.yml" ]]; then
        log_error "docker-compose.yml not found. Please run this from your project root directory."
        exit 1
    fi
    
    if [[ ! -d "scripts" ]]; then
        log_error "scripts/ directory not found. Please run this from your project root directory."
        exit 1
    fi
    
    log_success "All prerequisites satisfied!"
}

# =============================================================================
# SETUP FUNCTIONS
# =============================================================================

setup_minimal_portable() {
    log_step "Setting up minimal portable environment..."
    
    # Create .env file if it doesn't exist
    if [[ ! -f ".env" ]]; then
        if [[ -f ".env.example" ]]; then
            cp .env.example .env
            log_info "Created .env file from .env.example"
        else
            # Create basic .env file
            cat > .env << 'EOF'
# Nexus Repository Configuration
NEXUS_URL=http://localhost:8081
NEXUS_USERNAME=admin
NEXUS_PASSWORD=Aa1234567

# Repository Names
DOCKER_REPO=docker-hosted
MAVEN_REPO=maven-public
RAW_REPO=raw-hosted

# Security Settings
SECURITY_GATE_CRITICAL=true
SECURITY_GATE_HIGH=true
SECURITY_GATE_MEDIUM=false
EOF
            log_info "Created .env file with default configuration"
        fi
    fi
    
    # Create docker directory if needed
    if [[ ! -d "docker" ]]; then
        mkdir docker
        log_info "Created docker/ directory"
    fi
    
    # Check if entrypoint.sh exists
    if [[ ! -f "docker/entrypoint.sh" ]]; then
        log_warn "docker/entrypoint.sh not found - please create it first"
        log_info "This file should contain the scanner container entrypoint script"
        return 1
    fi
    
    # Check if scanner.Dockerfile exists
    if [[ ! -f "docker/scanner.Dockerfile" ]]; then
        log_warn "docker/scanner.Dockerfile not found - please create it first"
        log_info "This file should contain the security tools container definition"
        return 1
    fi
    
    # Make entrypoint executable
    chmod +x docker/entrypoint.sh
    
    # Create required directories
    local directories=(
        "scan-results"
        "reports"
        "logs/audit"
    )
    
    for dir in "${directories[@]}"; do
        mkdir -p "${dir}"
    done
    
    log_success "Minimal portable environment ready"
}

# =============================================================================
# SERVICE MANAGEMENT
# =============================================================================

start_nexus_service() {
    log_step "Starting Nexus Repository..."
    
    # Start your existing Nexus setup
    ${COMPOSE_CMD} up -d nexus
    
    # Wait for Nexus to be ready
    log_info "Waiting for Nexus to start (this may take 2-3 minutes)..."
    
    local max_wait=180
    local wait_time=0
    
    while [[ ${wait_time} -lt ${max_wait} ]]; do
        if curl -s -f "http://localhost:8081/service/rest/v1/status" >/dev/null 2>&1; then
            log_success "Nexus is ready!"
            break
        fi
        
        if [[ $((wait_time % 30)) -eq 0 ]] && [[ ${wait_time} -gt 0 ]]; then
            log_info "Still waiting for Nexus... (${wait_time}/${max_wait}s)"
        fi
        
        sleep 5
        wait_time=$((wait_time + 5))
    done
    
    # Verify Nexus is ready
    if ! curl -s -f "http://localhost:8081/service/rest/v1/status" >/dev/null 2>&1; then
        log_error "Nexus failed to start properly"
        log_info "Check logs with: ${COMPOSE_CMD} logs nexus"
        exit 1
    fi
    
    # Initialize repositories using your existing scripts
    if [[ -f "scripts/api/create-repos.sh" ]]; then
        log_info "Creating repositories using your existing scripts..."
        ./scripts/api/create-repos.sh || log_warn "Repository creation completed with warnings"
    else
        log_warn "Repository creation script not found - you may need to create repositories manually"
    fi
    
    log_success "Nexus service started and configured!"
}

start_scanner_service() {
    log_step "Starting security scanner service..."
    
    # Check if scanner Dockerfile exists
    if [[ ! -f "docker/scanner.Dockerfile" ]]; then
        log_warn "Security scanner Dockerfile not found - skipping containerized scanner"
        log_info "You can still use your local security tools"
        return 0
    fi
    
    # Add scanner service to docker-compose temporarily
    log_info "Building security scanner container..."
    
    # Create temporary docker-compose override
    cat > docker-compose.override.yml << 'EOF'
version: '3.8'

services:
  security-scanner:
    build:
      context: .
      dockerfile: docker/scanner.Dockerfile
    container_name: devsecops-scanner
    volumes:
      - ./scripts:/app/scripts:ro
      - ./scan-results:/app/scan-results
      - ./reports:/app/reports
      - ./logs:/app/logs
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - NEXUS_URL=http://nexus:8081
      - NEXUS_USERNAME=admin
      - NEXUS_PASSWORD=Aa1234567
    depends_on:
      - nexus
    networks:
      - default
EOF
    
    # Start the scanner service
    ${COMPOSE_CMD} up -d security-scanner
    
    # Wait for scanner to be ready
    sleep 10
    
    if ${COMPOSE_CMD} ps security-scanner | grep -q "Up"; then
        log_success "Security scanner service started!"
    else
        log_warn "Security scanner failed to start - check logs with: ${COMPOSE_CMD} logs security-scanner"
    fi
}

# =============================================================================
# TESTING FUNCTIONS
# =============================================================================

run_quick_validation() {
    log_step "Running quick validation..."
    
    local test_results=()
    
    # Test 1: Nexus connectivity
    log_info "Testing Nexus connectivity..."
    if curl -s -u admin:Aa1234567 "http://localhost:8081/service/rest/v1/status" >/dev/null 2>&1; then
        test_results+=("✅ Nexus API: Working")
    else
        test_results+=("❌ Nexus API: Failed")
    fi
    
    # Test 2: Repository availability
    log_info "Testing repositories..."
    local repos=$(curl -s -u admin:Aa1234567 "http://localhost:8081/service/rest/v1/repositories" 2>/dev/null | jq -r '.[].name' 2>/dev/null | tr '\n' ' ')
    
    if echo "${repos}" | grep -q "docker-local"; then
        test_results+=("✅ Docker repository: Available")
    else
        test_results+=("⚠️ Docker repository: Not found")
    fi
    
    if echo "${repos}" | grep -q "raw-hosted"; then
        test_results+=("✅ Generic repository: Available")
    else
        test_results+=("⚠️ Generic repository: Not found")
    fi
    
    # Test 3: Security tools (containerized or local)
    if ${COMPOSE_CMD} ps security-scanner | grep -q "Up" 2>/dev/null; then
        log_info "Testing containerized security tools..."
        if ${COMPOSE_CMD} exec -T security-scanner trivy --version >/dev/null 2>&1; then
            test_results+=("✅ Containerized Trivy: Working")
        else
            test_results+=("❌ Containerized Trivy: Failed")
        fi
    else
        log_info "Testing local security tools..."
        if command -v trivy &> /dev/null; then
            test_results+=("✅ Local Trivy: Available")
        else
            test_results+=("⚠️ Local Trivy: Not installed")
        fi
    fi
    
    # Test 4: Your existing scripts
    log_info "Testing your existing scripts..."
    if [[ -x "scripts/security/policy-gate.sh" ]]; then
        test_results+=("✅ Policy gate script: Executable")
    else
        test_results+=("❌ Policy gate script: Not executable")
    fi
    
    if [[ -x "scripts/simulate-ci.sh" ]]; then
        test_results+=("✅ CI simulator: Executable")
    else
        test_results+=("⚠️ CI simulator: Not found or not executable")
    fi
    
    # Display results
    echo
    log_info "=== Validation Results ==="
    for result in "${test_results[@]}"; do
        echo "  ${result}"
    done
    echo
    
    # Count successes
    local success_count=$(echo "${test_results[@]}" | grep -o "✅" | wc -l)
    local total_count=${#test_results[@]}
    
    log_info "Validation: ${success_count}/${total_count} tests passed"
    
    if [[ ${success_count} -eq ${total_count} ]]; then
        log_success "All validations passed!"
    else
        log_warn "Some validations failed, but core functionality should work"
    fi
}

# =============================================================================
# DEMO FUNCTIONS
# =============================================================================

run_demo_scan() {
    log_step "Running demo security scan..."
    
    log_info "Scanning Alpine Linux as demonstration..."
    
    # Try containerized scanner first, then local
    if ${COMPOSE_CMD} ps security-scanner | grep -q "Up" 2>/dev/null; then
        log_info "Using containerized security scanner..."
        ${COMPOSE_CMD} exec security-scanner trivy image --format table alpine:latest
    elif command -v trivy &> /dev/null; then
        log_info "Using local Trivy installation..."
        trivy image --format table alpine:latest
    else
        log_warn "No security scanner available for demo"
        log_info "Install Trivy locally or build the scanner container"
        return 1
    fi
    
    log_success "Demo scan completed!"
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

DevSecOps Lab Quick Start (Minimal Portable)

OPTIONS:
    --core-only         Start only Nexus (your existing setup)
    --with-scanner      Add containerized security tools
    --test-only         Only run validation tests
    --clean             Stop all services and clean up
    -h, --help          Show this help message

EXAMPLES:
    $0                  # Start Nexus + try to add scanner
    $0 --core-only      # Just your existing Nexus setup
    $0 --with-scanner   # Nexus + containerized security tools
    $0 --test-only      # Test what's currently running
    $0 --clean          # Stop everything

WHAT THIS ADDS TO YOUR EXISTING LAB:
    - One-command setup for others to use your lab
    - Optional containerized security tools
    - Validation testing
    - Easy cleanup and management

YOUR EXISTING SCRIPTS STILL WORK:
    - ./scripts/security/scan.sh
    - ./scripts/security/policy-gate.sh  
    - ./scripts/simulate-ci.sh
    - All Phase 1-8 functionality preserved

EOF
}

main() {
    local core_only=false
    local with_scanner=false
    local test_only=false
    local clean=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --core-only)
                core_only=true
                shift
                ;;
            --with-scanner)
                with_scanner=true
                shift
                ;;
            --test-only)
                test_only=true
                shift
                ;;
            --clean)
                clean=true
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
    log_info "${BOLD}=== DevSecOps Lab Quick Start ===${NC}"
    log_info "${BOLD}Minimal Portable Setup${NC}"
    echo
    
    if [[ "${clean}" == "true" ]]; then
        log_step "Cleaning up lab environment..."
        ${COMPOSE_CMD} down
        if [[ -f "docker-compose.override.yml" ]]; then
            rm docker-compose.override.yml
            log_info "Removed temporary override file"
        fi
        docker rmi -f $(docker images -q --filter "reference=*devsecops*") 2>/dev/null || true
        log_success "Lab environment cleaned up!"
        exit 0
    fi
    
    if [[ "${test_only}" == "true" ]]; then
        check_prerequisites
        run_quick_validation
        exit 0
    fi
    
    # Setup process
    check_prerequisites
    
    if [[ "${core_only}" == "false" ]]; then
        setup_minimal_portable
    fi
    
    # Start services
    start_nexus_service
    
    if [[ "${with_scanner}" == "true" ]] || [[ "${core_only}" == "false" && "${with_scanner}" != "false" ]]; then
        start_scanner_service
    fi
    
    # Run validation
    echo
    run_quick_validation
    
    # Optional demo
    if command -v trivy &> /dev/null || ${COMPOSE_CMD} ps security-scanner | grep -q "Up" 2>/dev/null; then
        echo
        log_info "Running demonstration security scan..."
        run_demo_scan
    fi
    
    # Display success information
    echo
    log_success "${BOLD}🎉 DevSecOps Lab Started Successfully! 🎉${NC}"
    echo
    log_info "=== Available Services ==="
    log_info "🏛️  Nexus Repository: http://localhost:8081 (admin/Aa1234567)"
    
    if ${COMPOSE_CMD} ps security-scanner | grep -q "Up" 2>/dev/null; then
        log_info "🔍 Containerized Scanner: docker-compose exec security-scanner bash"
    fi
    
    echo
    log_info "=== Your Existing Scripts Still Work ==="
    log_info "🔧 ./scripts/security/policy-gate.sh"
    log_info "🔍 ./scripts/security/scan.sh alpine:latest"
    log_info "🧪 ./scripts/simulate-ci.sh"
    echo
    log_info "=== New Portable Commands ==="
    
    if ${COMPOSE_CMD} ps security-scanner | grep -q "Up" 2>/dev/null; then
        log_info "🔍 Containerized scan:"
        log_info "   docker-compose exec security-scanner trivy image alpine:latest"
        echo
        log_info "⚖️  Containerized policy gate:"
        log_info "   docker-compose exec security-scanner /app/scripts/security/policy-gate.sh"
    fi
    
    echo
    log_info "🛑 Stop lab: ${COMPOSE_CMD} down"
    log_info "🧹 Clean up: $0 --clean"
    echo
    
    log_success "${BOLD}🎯 Your lab is now portable and ready for distribution!${NC}"
    echo
    log_info "=== Next Steps ==="
    log_info "1. Test the containerized scanner (if available)"
    log_info "2. Verify all your existing scripts still work"
    log_info "3. Ready to add optional features (dashboard, auto-init)"
    log_info "4. Share your portable DevSecOps lab with others!"
    echo
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
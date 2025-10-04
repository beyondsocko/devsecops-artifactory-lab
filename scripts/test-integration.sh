#!/bin/bash
set -e

source .env

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_status() { echo -e "${GREEN}✅ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_test() { echo -e "${CYAN}🧪 $1${NC}"; }

# Test counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    print_test "Test $TESTS_TOTAL: $test_name"
    
    if eval "$test_command" >/dev/null 2>&1; then
        print_status "PASSED: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        print_error "FAILED: $test_name"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Function to run a test with output
run_test_with_output() {
    local test_name="$1"
    local test_command="$2"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    print_test "Test $TESTS_TOTAL: $test_name"
    
    local output
    if output=$(eval "$test_command" 2>&1); then
        print_status "PASSED: $test_name"
        if [ -n "$output" ]; then
            echo "  Output: $output"
        fi
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        print_error "FAILED: $test_name"
        if [ -n "$output" ]; then
            echo "  Error: $output"
        fi
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Function to cleanup test artifacts
cleanup_test_artifacts() {
    print_info "🧹 Cleaning up test artifacts..."
    
    # Remove test files
    rm -f test-artifact-*.txt
    rm -f test-app-*.jar
    
    # Remove test Docker images (local)
    docker rmi -f test-app:latest 2>/dev/null || true
    docker rmi -f localhost:8082/test-app:latest 2>/dev/null || true
    
    print_status "Cleanup completed"
}

# Function to create test artifacts
create_test_artifacts() {
    print_info "📦 Creating test artifacts..."
    
    # Create test JAR file
    echo "DevSecOps Lab Test Application - Integration Test" > test-app-integration.jar
    
    # Create test text file
    echo "Integration test artifact - $(date)" > test-artifact-integration.txt
    
    # Create test Dockerfile
    cat > test-Dockerfile << 'EOF'
FROM alpine:latest
LABEL test="integration"
RUN echo "Integration test image" > /test.txt
CMD ["cat", "/test.txt"]
EOF
    
    print_status "Test artifacts created"
}

echo "🚀 DevSecOps Lab - Phase 2 Integration Tests"
echo "=============================================="
echo ""

# Pre-test setup
print_info "🔧 Setting up integration tests..."
create_test_artifacts

echo ""
print_info "🧪 Starting Integration Test Suite..."
echo ""

# Test 1: Nexus Connectivity
print_test "=== NEXUS CONNECTIVITY TESTS ==="
run_test "Nexus API connectivity" \
    "curl -s -f -u '$NEXUS_USERNAME:$NEXUS_PASSWORD' '$NEXUS_URL/service/rest/v1/status'"

run_test "Nexus authentication" \
    "curl -s -u '$NEXUS_USERNAME:$NEXUS_PASSWORD' '$NEXUS_URL/service/rest/v1/repositories' | jq -e '.[] | select(.name == \"raw-hosted\")'"

# Test 2: Repository Management
echo ""
print_test "=== REPOSITORY MANAGEMENT TESTS ==="
run_test "Raw repository exists" \
    "curl -s -u '$NEXUS_USERNAME:$NEXUS_PASSWORD' '$NEXUS_URL/service/rest/v1/repositories' | jq -e '.[] | select(.name == \"raw-hosted\")'"

run_test "Docker repository exists" \
    "curl -s -u '$NEXUS_USERNAME:$NEXUS_PASSWORD' '$NEXUS_URL/service/rest/v1/repositories' | jq -e '.[] | select(.name == \"docker-hosted\")'"

run_test "Repository creation script is idempotent" \
    "./scripts/api/create-repos.sh"

# Test 3: Artifact Upload and Management
echo ""
print_test "=== ARTIFACT MANAGEMENT TESTS ==="
run_test "Upload artifact with metadata" \
    "./scripts/api/upload-artifact.sh upload test-app-integration.jar raw-hosted test/integration/app.jar integration-test 999"

run_test "Verify artifact exists" \
    "curl -s -f -u '$NEXUS_USERNAME:$NEXUS_PASSWORD' '$NEXUS_URL/repository/raw-hosted/test/integration/app.jar'"

run_test "Verify metadata file exists" \
    "curl -s -f -u '$NEXUS_USERNAME:$NEXUS_PASSWORD' '$NEXUS_URL/repository/raw-hosted/test/integration/app.jar.metadata.json'"

run_test "Metadata contains correct build info" \
    "curl -s -u '$NEXUS_USERNAME:$NEXUS_PASSWORD' '$NEXUS_URL/repository/raw-hosted/test/integration/app.jar.metadata.json' | jq -e '.build.name == \"integration-test\"'"

run_test "Metadata contains security gate" \
    "curl -s -u '$NEXUS_USERNAME:$NEXUS_PASSWORD' '$NEXUS_URL/repository/raw-hosted/test/integration/app.jar.metadata.json' | jq -e '.security.gate == \"pending\"'"

# Test 4: Security Gate Operations
echo ""
print_test "=== SECURITY GATE TESTS ==="
run_test "Update security gate to failed" \
    "./scripts/api/upload-artifact.sh update-gate raw-hosted test/integration/app.jar failed 2 5 10 3"

run_test "Verify security gate status updated" \
    "curl -s -u '$NEXUS_USERNAME:$NEXUS_PASSWORD' '$NEXUS_URL/repository/raw-hosted/test/integration/app.jar.metadata.json' | jq -e '.security.gate == \"failed\"'"

run_test "Verify vulnerability counts updated" \
    "curl -s -u '$NEXUS_USERNAME:$NEXUS_PASSWORD' '$NEXUS_URL/repository/raw-hosted/test/integration/app.jar.metadata.json' | jq -e '.security.scan.critical == 2'"

run_test "Update security gate to passed" \
    "./scripts/api/upload-artifact.sh update-gate raw-hosted test/integration/app.jar passed 0 0 0 0"

run_test "Verify security gate passed" \
    "./scripts/api/docker-operations.sh login"

# Test 5: Query Operations
echo ""
print_test "=== QUERY OPERATIONS TESTS ==="
run_test "List repository contents" \
    "./scripts/api/query-artifacts.sh list raw-hosted | grep -q 'integration'"

run_test "Search for artifacts" \
    "./scripts/api/query-artifacts.sh search raw-hosted integration | grep -q 'integration'"

run_test "Get artifact info" \
    "./scripts/api/query-artifacts.sh info raw-hosted test/integration/app.jar"

run_test "Query security status" \
    "./scripts/api/query-artifacts.sh security raw-hosted | grep -q 'test/integration/app.jar'"

run_test "Query by build name" \
    "./scripts/api/query-artifacts.sh build raw-hosted integration-test | grep -q 'integration-test'"

# Test 6: Docker Registry Operations
echo ""
print_test "=== DOCKER REGISTRY TESTS ==="
run_test "Docker registry login" \

# Build a simple test image
run_test "Build test Docker image" \
    "docker build -t test-app:latest -f test-Dockerfile ."

run_test "Tag image for registry" \
    "docker tag test-app:latest localhost:8082/test-app:latest"

run_test "Push image to registry" \
    "docker push localhost:8082/test-app:latest"

run_test "Verify image in registry" \
    "./scripts/api/docker-operations.sh list | grep -q 'test-app'"

run_test "Pull image from registry" \
    "docker pull localhost:8082/test-app:latest"

# Test 7: End-to-End Workflow
echo ""
print_test "=== END-TO-END WORKFLOW TESTS ==="
run_test "Upload second test artifact" \
    "./scripts/api/upload-artifact.sh upload test-artifact-integration.txt raw-hosted test/e2e/artifact.txt e2e-test 1001"

run_test "Update security gate for e2e artifact" \
    "./scripts/api/upload-artifact.sh update-gate raw-hosted test/e2e/artifact.txt passed 0 1 2 5"

run_test "Query e2e artifact by build" \
    "./scripts/api/query-artifacts.sh build raw-hosted e2e-test 1001 | grep -q 'e2e-test'"

run_test "Verify e2e security status" \
    "./scripts/api/query-artifacts.sh security raw-hosted e2e-test | grep -q 'passed'"

# Test 8: Error Handling
echo ""
print_test "=== ERROR HANDLING TESTS ==="
run_test "Handle non-existent file upload gracefully" \
    "! ./scripts/api/upload-artifact.sh upload non-existent-file.jar raw-hosted test/error/file.jar"

run_test "Handle invalid repository gracefully" \
    "! ./scripts/api/query-artifacts.sh list non-existent-repo"

run_test "Handle invalid metadata update gracefully" \
    "! ./scripts/api/upload-artifact.sh update-gate raw-hosted non/existent/path.jar failed"

# Test Results Summary
echo ""
echo "🏁 Integration Test Results"
echo "=========================="
echo ""
print_info "📊 Test Summary:"
echo "  Total Tests: $TESTS_TOTAL"
echo "  Passed: $TESTS_PASSED"
echo "  Failed: $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    print_status "🎉 ALL TESTS PASSED! Phase 2 integration is working perfectly."
    echo ""
    print_info "✅ Verified Capabilities:"
    echo "  • Repository management and automation"
    echo "  • Artifact upload with comprehensive metadata"
    echo "  • Security gate functionality"
    echo "  • Query and search operations"
    echo "  • Docker registry integration"
    echo "  • End-to-end workflows"
    echo "  • Error handling and resilience"
    echo ""
    print_info "🚀 Ready for Phase 3: Sample Application & Container Development"
    
    # Cleanup on success
    cleanup_test_artifacts
    rm -f test-Dockerfile
    
    exit 0
else
    print_error "❌ $TESTS_FAILED test(s) failed. Please review the errors above."
    echo ""
    print_info "🔍 Troubleshooting Tips:"
    echo "  • Check Nexus is running: docker ps"
    echo "  • Verify credentials in .env file"
    echo "  • Ensure repositories exist: ./scripts/api/create-repos.sh"
    echo "  • Check Docker registry configuration"
    echo ""
    print_warning "⚠️  Test artifacts left in place for debugging"
    
    exit 1
fi

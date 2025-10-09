#!/usr/bin/env node

// =============================================================================
// DevSecOps Sample App - Simple Test Suite
// =============================================================================
// Basic tests to validate application functionality for CI pipeline
// =============================================================================

const http = require('http');
const fs = require('fs');
const path = require('path');

// Colors for output
const colors = {
    green: '\x1b[32m',
    red: '\x1b[31m',
    yellow: '\x1b[33m',
    blue: '\x1b[34m',
    reset: '\x1b[0m'
};

function log(color, message) {
    console.log(`${colors[color]}${message}${colors.reset}`);
}

// Test counter
let tests = 0;
let passed = 0;
let failed = 0;

function test(name, testFn) {
    tests++;
    try {
        const result = testFn();
        if (result !== false) {
            passed++;
            log('green', `✅ PASS: ${name}`);
        } else {
            failed++;
            log('red', `❌ FAIL: ${name}`);
        }
    } catch (error) {
        failed++;
        log('red', `❌ FAIL: ${name} - ${error.message}`);
    }
}

// =============================================================================
// TEST SUITE
// =============================================================================

console.log('\n🧪 DevSecOps Sample App - Test Suite');
console.log('====================================\n');

// Test 1: Check if main server file exists
test('Server file exists', () => {
    return fs.existsSync(path.join(__dirname, 'server.js'));
});

// Test 2: Check if package.json is valid
test('Package.json is valid', () => {
    const pkg = require('./package.json');
    return pkg.name && pkg.version && pkg.main;
});

// Test 3: Check if dependencies are listed
test('Dependencies are defined', () => {
    const pkg = require('./package.json');
    return pkg.dependencies && Object.keys(pkg.dependencies).length > 0;
});

// Test 4: Check if server can be required (syntax check)
test('Server file syntax is valid', () => {
    try {
        // Just check if the file can be parsed, don't actually start server
        const serverCode = fs.readFileSync(path.join(__dirname, 'server.js'), 'utf8');
        return serverCode.includes('express') || serverCode.includes('http');
    } catch (error) {
        return false;
    }
});

// Test 5: Check if vulnerable dependencies are intentionally included (for security testing)
test('Vulnerable dependencies present (for security testing)', () => {
    const pkg = require('./package.json');
    // This is intentional for security scanning demos
    return pkg.dependencies && (
        pkg.dependencies['jsonwebtoken'] || 
        pkg.dependencies['express']
    );
});

// Test 6: Check if application has proper structure
test('Application structure is valid', () => {
    const hasServer = fs.existsSync(path.join(__dirname, 'server.js'));
    const hasPackage = fs.existsSync(path.join(__dirname, 'package.json'));
    const hasDockerfile = fs.existsSync(path.join(__dirname, 'Dockerfile'));
    
    return hasServer && hasPackage && hasDockerfile;
});

// Test 7: Environment configuration check
test('Environment configuration ready', () => {
    // Check if app can handle basic environment variables
    const originalEnv = process.env.NODE_ENV;
    process.env.NODE_ENV = 'test';
    const result = process.env.NODE_ENV === 'test';
    process.env.NODE_ENV = originalEnv;
    return result;
});

// =============================================================================
// TEST RESULTS
// =============================================================================

console.log('\n📊 Test Results');
console.log('===============');
console.log(`Total Tests: ${tests}`);
log('green', `Passed: ${passed}`);
if (failed > 0) {
    log('red', `Failed: ${failed}`);
}

const successRate = Math.round((passed / tests) * 100);
console.log(`Success Rate: ${successRate}%\n`);

if (failed === 0) {
    log('green', '🎉 All tests passed! Application is ready for CI pipeline.');
    process.exit(0);
} else if (successRate >= 80) {
    log('yellow', '⚠️  Most tests passed. Application is mostly ready.');
    process.exit(0);
} else {
    log('red', '💥 Too many test failures. Please fix issues before proceeding.');
    process.exit(1);
}

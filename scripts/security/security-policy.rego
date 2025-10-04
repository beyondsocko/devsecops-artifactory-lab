# =============================================================================
# DevSecOps Security Policy - OPA/Rego Implementation
# =============================================================================
# Advanced policy engine for complex security gate decisions
# Optional enhancement to the basic severity threshold approach
# =============================================================================

package devsecops.security

import rego.v1

# =============================================================================
# POLICY CONFIGURATION
# =============================================================================

# Default severity thresholds
default_thresholds := {
    "critical": 0,
    "high": 5,
    "medium": 20,
    "low": 50
}

# Whitelisted CVEs (known false positives or accepted risks)
whitelisted_cves := {
    "CVE-2023-EXAMPLE-1",
    "CVE-2023-EXAMPLE-2"
}

# Blacklisted packages (never allow these)
blacklisted_packages := {
    "malicious-package",
    "deprecated-crypto-lib"
}

# Trusted base images
trusted_base_images := {
    "alpine:3.18",
    "ubuntu:22.04",
    "node:18-alpine",
    "python:3.11-slim"
}

# =============================================================================
# MAIN POLICY DECISION
# =============================================================================

# Main policy decision - determines if deployment should be allowed
default allow := false

# Allow deployment if all conditions are met
allow if {
    not has_critical_violations
    not has_high_violations
    not has_blacklisted_packages
    not exceeds_vulnerability_budget
    has_valid_base_image
}

# Allow with bypass if bypass conditions are met
allow if {
    has_valid_bypass
}

# =============================================================================
# VULNERABILITY ASSESSMENT RULES
# =============================================================================

# Check for critical vulnerability violations
has_critical_violations if {
    input.vulnerabilities.critical > default_thresholds.critical
    input.policy.fail_on_critical == true
}

# Check for high vulnerability violations
has_high_violations if {
    input.vulnerabilities.high > default_thresholds.high
    input.policy.fail_on_high == true
}

# Check if vulnerability budget is exceeded
exceeds_vulnerability_budget if {
    total_weighted_score > input.policy.max_vulnerability_score
}

# Calculate weighted vulnerability score
total_weighted_score := score if {
    critical_weight := 10
    high_weight := 5
    medium_weight := 2
    low_weight := 1
    
    score := (input.vulnerabilities.critical * critical_weight) +
             (input.vulnerabilities.high * high_weight) +
             (input.vulnerabilities.medium * medium_weight) +
             (input.vulnerabilities.low * low_weight)
}

# =============================================================================
# PACKAGE AND DEPENDENCY RULES
# =============================================================================

# Check for blacklisted packages
has_blacklisted_packages if {
    some package in input.packages
    package.name in blacklisted_packages
}

# Check for vulnerable dependencies
has_vulnerable_dependencies if {
    some package in input.packages
    some vuln in package.vulnerabilities
    vuln.severity in {"CRITICAL", "HIGH"}
    not vuln.cve in whitelisted_cves
}

# =============================================================================
# BASE IMAGE VALIDATION
# =============================================================================

# Validate base image is from trusted source
has_valid_base_image if {
    input.image.base_image in trusted_base_images
}

has_valid_base_image if {
    # Allow if base image is from trusted registry
    startswith(input.image.base_image, "registry.company.com/")
}

has_valid_base_image if {
    # Allow if image has valid signature
    input.image.signed == true
    input.image.signature_valid == true
}

# =============================================================================
# BYPASS MECHANISM
# =============================================================================

# Check for valid bypass conditions
has_valid_bypass if {
    input.bypass.enabled == true
    input.bypass.token != ""
    input.bypass.reason != ""
    is_authorized_bypass_user
}

# Check if bypass user is authorized
is_authorized_bypass_user if {
    input.bypass.user in {"security-team", "devops-lead", "emergency-user"}
}

# =============================================================================
# TIME-BASED RULES
# =============================================================================

# Allow deployment during maintenance windows
is_maintenance_window if {
    # Parse current time
    now := time.now_ns()
    
    # Define maintenance window (example: weekends)
    weekday := time.weekday(now)
    weekday in {0, 6}  # Sunday = 0, Saturday = 6
}

# Emergency deployment allowed outside business hours
is_emergency_deployment if {
    input.deployment.emergency == true
    not is_business_hours
}

is_business_hours if {
    now := time.now_ns()
    hour := time.clock(now)[0]
    hour >= 9
    hour <= 17
}

# =============================================================================
# COMPLIANCE RULES
# =============================================================================

# Check compliance requirements
meets_compliance_requirements if {
    has_required_labels
    has_sbom
    has_security_scan
    not has_secrets_in_image
}

# Required labels for compliance
has_required_labels if {
    required_labels := {"version", "maintainer", "security.scan.date"}
    every label in required_labels {
        label in object.keys(input.image.labels)
    }
}

# SBOM requirement
has_sbom if {
    input.sbom.present == true
    input.sbom.format in {"spdx", "cyclonedx"}
}

# Security scan requirement
has_security_scan if {
    input.scan.completed == true
    input.scan.timestamp != ""
    scan_age_hours < 24
}

scan_age_hours := hours if {
    now := time.now_ns()
    scan_time := time.parse_rfc3339_ns(input.scan.timestamp)
    diff_ns := now - scan_time
    hours := diff_ns / 1000000000 / 3600
}

# Check for secrets in image
has_secrets_in_image if {
    some secret in input.secrets
    secret.confidence > 0.8
}

# =============================================================================
# RISK ASSESSMENT
# =============================================================================

# Calculate overall risk score
risk_score := score if {
    vulnerability_risk := total_weighted_score * 0.4
    package_risk := count_risky_packages * 0.3
    compliance_risk := compliance_violations * 0.2
    base_image_risk := base_image_risk_score * 0.1
    
    score := vulnerability_risk + package_risk + compliance_risk + base_image_risk
}

count_risky_packages := count if {
    risky_packages := [package | 
        some package in input.packages
        package.risk_score > 7
    ]
    count := count(risky_packages)
}

compliance_violations := count if {
    violations := [violation |
        not has_required_labels; violation := "missing_labels"
        not has_sbom; violation := "missing_sbom"
        not has_security_scan; violation := "missing_scan"
        has_secrets_in_image; violation := "secrets_detected"
    ]
    count := count(violations)
}

base_image_risk_score := 10 if {
    not has_valid_base_image
} else := 0

# =============================================================================
# POLICY VIOLATIONS
# =============================================================================

# Collect all policy violations
violations contains violation if {
    has_critical_violations
    violation := {
        "type": "critical_vulnerabilities",
        "message": sprintf("Critical vulnerabilities (%d) exceed threshold (%d)", [
            input.vulnerabilities.critical,
            default_thresholds.critical
        ]),
        "severity": "critical"
    }
}

violations contains violation if {
    has_high_violations
    violation := {
        "type": "high_vulnerabilities", 
        "message": sprintf("High vulnerabilities (%d) exceed threshold (%d)", [
            input.vulnerabilities.high,
            default_thresholds.high
        ]),
        "severity": "high"
    }
}

violations contains violation if {
    has_blacklisted_packages
    violation := {
        "type": "blacklisted_packages",
        "message": "Image contains blacklisted packages",
        "severity": "critical"
    }
}

violations contains violation if {
    not has_valid_base_image
    violation := {
        "type": "untrusted_base_image",
        "message": sprintf("Base image '%s' is not from trusted source", [input.image.base_image]),
        "severity": "medium"
    }
}

violations contains violation if {
    has_secrets_in_image
    violation := {
        "type": "secrets_detected",
        "message": "Secrets detected in image",
        "severity": "high"
    }
}

# =============================================================================
# RECOMMENDATIONS
# =============================================================================

# Generate recommendations for remediation
recommendations contains recommendation if {
    has_critical_violations
    recommendation := {
        "type": "vulnerability_remediation",
        "message": "Update packages to fix critical vulnerabilities",
        "priority": "high",
        "actions": [
            "Run 'npm audit fix' or equivalent",
            "Update base image to latest version",
            "Review and update vulnerable dependencies"
        ]
    }
}

recommendations contains recommendation if {
    not has_valid_base_image
    recommendation := {
        "type": "base_image_update",
        "message": "Use a trusted base image",
        "priority": "medium",
        "actions": [
            "Switch to official base images",
            "Use minimal base images (alpine, distroless)",
            "Implement image signing"
        ]
    }
}

recommendations contains recommendation if {
    not has_sbom
    recommendation := {
        "type": "sbom_generation",
        "message": "Generate and include SBOM",
        "priority": "low",
        "actions": [
            "Use Syft to generate SBOM",
            "Include SBOM in CI/CD pipeline",
            "Store SBOM alongside artifacts"
        ]
    }
}

# =============================================================================
# POLICY RESULT
# =============================================================================

# Final policy result
result := {
    "allow": allow,
    "risk_score": risk_score,
    "violations": violations,
    "recommendations": recommendations,
    "metadata": {
        "policy_version": "1.0.0",
        "evaluation_time": time.now_ns(),
        "total_vulnerabilities": input.vulnerabilities.critical + 
                                input.vulnerabilities.high + 
                                input.vulnerabilities.medium + 
                                input.vulnerabilities.low
    }
}
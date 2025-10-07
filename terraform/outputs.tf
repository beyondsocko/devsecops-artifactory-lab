# =============================================================================
# TERRAFORM OUTPUTS
# =============================================================================
# Purpose: Exposes important infrastructure information for external use
# Provides connection details, URLs, and resource identifiers

# Nexus Repository Information
output "nexus_info" {
  description = "Nexus Repository connection information"
  value = {
    container_name = docker_container.nexus.name
    container_id   = docker_container.nexus.id
    web_url        = "http://localhost:${var.nexus_web_port}"
    registry_url   = "localhost:${var.nexus_registry_port}"
    admin_user     = "admin"
    data_volume    = docker_volume.nexus_data.name
    network        = docker_network.devsecops_network.name
    status         = "running"
  }
}

# Network Information
output "network_details" {
  description = "Docker network configuration"
  value = {
    main_network = {
      id     = docker_network.devsecops_network.id
      name   = docker_network.devsecops_network.name
      driver = docker_network.devsecops_network.driver
      subnet = "172.20.0.0/16"
    }
    security_network = var.enable_security_scanning ? {
      id   = docker_network.security_network[0].id
      name = docker_network.security_network[0].name
    } : null
  }
}

# Security Tools Information
output "security_tools" {
  description = "Security scanning tools information"
  value = var.enable_security_scanning ? {
    enabled           = true
    scanner_container = docker_container.security_scanner[0].name
    trivy_cache       = docker_volume.trivy_cache[0].name
    tools_available   = ["trivy", "grype", "syft"]
    scan_command      = "docker exec ${docker_container.security_scanner[0].name} trivy image"
    message           = "Security scanning tools are enabled and ready"
  } : {
    enabled           = false
    scanner_container = null
    trivy_cache       = null
    tools_available   = []
    scan_command      = null
    message           = "Security scanning tools are disabled"
  }
}

# Connection URLs
output "service_urls" {
  description = "Service connection URLs"
  value = {
    nexus_web      = "http://localhost:${var.nexus_web_port}"
    nexus_registry = "http://localhost:${var.nexus_registry_port}"
    health_check   = "http://localhost:${var.nexus_web_port}/service/rest/v1/status"
    api_base       = "http://localhost:${var.nexus_web_port}/service/rest/v1"
  }
}

# Infrastructure Summary
output "infrastructure_summary" {
  description = "Complete infrastructure deployment summary"
  value = {
    project_name    = local.project_name
    environment     = local.environment
    managed_by      = "terraform"
    deployment_time = timestamp()
    
    services = {
      nexus_repository = {
        status = "deployed"
        ports  = "${var.nexus_web_port}, ${var.nexus_registry_port}"
      }
      security_scanning = {
        status  = var.enable_security_scanning ? "deployed" : "disabled"
        tools   = var.enable_security_scanning ? "trivy, grype, syft" : "none"
      }
    }
    
    volumes = {
      nexus_data    = docker_volume.nexus_data.name
      trivy_cache   = var.enable_security_scanning ? docker_volume.trivy_cache[0].name : "not created"
    }
    
    networks = {
      main_network = docker_network.devsecops_network.name
      security_net = var.enable_security_scanning ? docker_network.security_network[0].name : "not created"
    }
  }
}

# Quick Start Commands
output "quick_start_commands" {
  description = "Commands to interact with deployed infrastructure"
  value = {
    nexus_login    = "curl -u admin:${var.nexus_admin_password} http://localhost:${var.nexus_web_port}/service/rest/v1/status"
    docker_login   = "echo '${var.nexus_admin_password}' | docker login localhost:${var.nexus_registry_port} -u admin --password-stdin"
    scan_image     = var.enable_security_scanning ? "docker exec ${docker_container.security_scanner[0].name} trivy image <image-name>" : "Security scanning not enabled"
    view_logs      = "docker logs ${docker_container.nexus.name}"
    stop_services  = "terraform destroy"
  }
  
  sensitive = true
}

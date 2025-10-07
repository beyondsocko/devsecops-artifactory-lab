# =============================================================================
# NETWORK CONFIGURATION
# =============================================================================
# Purpose: Creates isolated Docker network for secure service communication
# Enables container-to-container communication while isolating from host network

# Custom Docker Network
# Creates a bridge network for DevSecOps services
resource "docker_network" "devsecops_network" {
  name = local.network_name
  
  # Bridge driver for container communication
  driver = "bridge"
  
  # Enable IPv6 support
  ipv6 = false
  
  # Network configuration
  ipam_config {
    subnet  = "172.25.0.0/16"
    gateway = "172.25.0.1"
  }
  
  # Labels for identification and management
  labels {
    label = "project"
    value = local.project_name
  }
  
  labels {
    label = "environment" 
    value = local.environment
  }
  
  labels {
    label = "managed_by"
    value = "terraform"
  }
  
  labels {
    label = "purpose"
    value = "devsecops-container-network"
  }
}

# Network Outputs for Reference
# Other resources can reference this network
output "network_info" {
  description = "Docker network information"
  value = {
    id     = docker_network.devsecops_network.id
    name   = docker_network.devsecops_network.name
    driver = docker_network.devsecops_network.driver
    subnet = "172.25.0.0/16"
  }
}

# =============================================================================
# MAIN TERRAFORM CONFIGURATION
# =============================================================================
# Purpose: Defines Terraform version requirements and provider configurations
# This file establishes the foundation for Infrastructure as Code (IaC)

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

# Docker Provider Configuration
# Connects Terraform to Docker daemon for container management
provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# Local Variables
# Centralized configuration values for reusability
locals {
  project_name = "devsecops-lab"
  environment  = "development"
  
  # Nexus Configuration
  nexus_version = "latest"
  nexus_ports = {
    web      = 8081
    registry = 8082
  }
  
  # Network Configuration  
  network_name = "${local.project_name}-network"
  
  # Common Labels
  common_labels = {
    project     = local.project_name
    environment = local.environment
    managed_by  = "terraform"
    purpose     = "devsecops-pipeline"
  }
}

# =============================================================================
# TERRAFORM VARIABLES DEFINITION
# =============================================================================
# Purpose: Defines input variables for flexible and reusable infrastructure
# Allows customization without modifying the main configuration

variable "nexus_admin_password" {
  description = "Admin password for Nexus Repository"
  type        = string
  default     = "Aa1234567"
  sensitive   = true
}

variable "nexus_web_port" {
  description = "External port for Nexus web interface"
  type        = number
  default     = 8081
  
  validation {
    condition     = var.nexus_web_port > 1024 && var.nexus_web_port < 65536
    error_message = "Nexus web port must be between 1024 and 65535."
  }
}

variable "nexus_registry_port" {
  description = "External port for Nexus Docker registry"
  type        = number
  default     = 8082
  
  validation {
    condition     = var.nexus_registry_port > 1024 && var.nexus_registry_port < 65536
    error_message = "Nexus registry port must be between 1024 and 65535."
  }
}

variable "nexus_memory" {
  description = "Memory limit for Nexus container (in MB)"
  type        = number
  default     = 2048
}

variable "enable_security_scanning" {
  description = "Enable security scanning tools deployment"
  type        = bool
  default     = true
}

variable "project_environment" {
  description = "Environment name (development, staging, production)"
  type        = string
  default     = "development"
  
  validation {
    condition     = contains(["development", "staging", "production"], var.project_environment)
    error_message = "Environment must be one of: development, staging, production."
  }
}

variable "auto_start_containers" {
  description = "Automatically start containers on system boot"
  type        = bool
  default     = true
}

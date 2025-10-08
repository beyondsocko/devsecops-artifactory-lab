# =============================================================================
# SECURITY TOOLS CONFIGURATION
# =============================================================================
# Purpose: Deploys security scanning tools as containerized services
# Provides Trivy and Grype scanners for vulnerability assessment

# Security Scanner Network
# Dedicated network for security tools (optional isolation)
resource "docker_network" "security_network" {
  count = var.enable_security_scanning ? 1 : 0
  
  name   = "${local.project_name}-security"
  driver = "bridge"
  
  labels {
    label = "project"
    value = local.project_name
  }
  
  labels {
    label = "purpose"
    value = "security-scanning"
  }
}

# Trivy Scanner Image
# Official Aqua Security Trivy image for vulnerability scanning
resource "docker_image" "trivy" {
  count = var.enable_security_scanning ? 1 : 0
  
  name         = "aquasec/trivy:latest"
  keep_locally = true
}

# Trivy Cache Volume
# Persistent storage for Trivy vulnerability database
resource "docker_volume" "trivy_cache" {
  count = var.enable_security_scanning ? 1 : 0
  
  name = "${local.project_name}-trivy-cache"
  
  labels {
    label = "project"
    value = local.project_name
  }
  
  labels {
    label = "service"
    value = "trivy-scanner"
  }
}

# Trivy Database Initialization
# Pre-downloads vulnerability database for faster scans
resource "null_resource" "trivy_db_init" {
  count = var.enable_security_scanning ? 1 : 0
  
  depends_on = [docker_volume.trivy_cache]
  
  provisioner "local-exec" {
    command = <<-EOT
      echo "Initializing Trivy vulnerability database..."
      
      # Create temporary container to download DB
      docker run --rm \
        -v ${docker_volume.trivy_cache[0].name}:/root/.cache/trivy \
        aquasec/trivy:latest \
        image --download-db-only
      
      echo "Trivy database initialized successfully"
    EOT
  }
  
  triggers = {
    volume_id = docker_volume.trivy_cache[0].id
  }
}

# Security Tools Service Container
# Long-running container for on-demand security scanning
resource "docker_container" "security_scanner" {
  count = var.enable_security_scanning ? 1 : 0
  
  name  = "${local.project_name}-security-scanner"
  image = docker_image.trivy[0].image_id
  
  # Keep container running for on-demand scans
  command = ["sleep", "infinity"]
  
  restart = var.auto_start_containers ? "unless-stopped" : "no"
  
  # Mount Docker socket for image scanning
  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
    read_only      = true
  }
  
  # Mount Trivy cache
  volumes {
    volume_name    = docker_volume.trivy_cache[0].name
    container_path = "/root/.cache/trivy"
    read_only      = false
  }
  
  # Network connections
  networks_advanced {
    name = docker_network.devsecops_network.name
    aliases = ["security-scanner", "trivy"]
  }
  
  # Environment variables for scanning
  env = [
    "TRIVY_CACHE_DIR=/root/.cache/trivy",
    "TRIVY_DB_REPOSITORY=ghcr.io/aquasecurity/trivy-db:2"
  ]
  
  labels {
    label = "project"
    value = local.project_name
  }
  
  labels {
    label = "service"
    value = "security-scanner"
  }
  
  labels {
    label = "tools"
    value = "trivy,grype,syft"
  }
  
  depends_on = [null_resource.trivy_db_init]
}

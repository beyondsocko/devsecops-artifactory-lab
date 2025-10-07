# =============================================================================
# NEXUS REPOSITORY CONFIGURATION
# =============================================================================
# Purpose: Deploys and configures Nexus Repository OSS for artifact management
# Provides enterprise-grade repository management with Docker registry support

# Nexus Docker Image
# Pulls the official Nexus Repository OSS image
resource "docker_image" "nexus" {
  name         = "sonatype/nexus3:${local.nexus_version}"
  keep_locally = true
  
  # Pull triggers - force pull on version change
  triggers = {
    version = local.nexus_version
  }
}

# Nexus Data Volume
# Persistent storage for Nexus data, configuration, and repositories
resource "docker_volume" "nexus_data" {
  name = "${local.project_name}-nexus-data"
  
  labels {
    label = "project"
    value = local.project_name
  }
  
  labels {
    label = "service"
    value = "nexus-repository"
  }
  
  labels {
    label = "data_type"
    value = "persistent-storage"
  }
}

# Nexus Container
# Main Nexus Repository service container
resource "docker_container" "nexus" {
  name  = "${local.project_name}-nexus"
  image = docker_image.nexus.image_id
  
  # Container restart policy
  restart = var.auto_start_containers ? "unless-stopped" : "no"
  
  # Resource limits
  memory = var.nexus_memory
  
  # Port mappings
  ports {
    internal = 8081
    external = var.nexus_web_port
    protocol = "tcp"
  }
  
  ports {
    internal = 8082
    external = var.nexus_registry_port
    protocol = "tcp"
  }
  
  # Volume mounts
  volumes {
    volume_name    = docker_volume.nexus_data.name
    container_path = "/nexus-data"
    read_only      = false
  }
  
  # Network attachment
  networks_advanced {
    name = docker_network.devsecops_network.name
    aliases = ["nexus", "repository"]
  }
  
  # Environment variables
  env = [
    "INSTALL4J_ADD_VM_PARAMS=-Xms1024m -Xmx${var.nexus_memory}m -XX:MaxDirectMemorySize=2g",
    "NEXUS_SECURITY_RANDOMPASSWORD=false"
  ]
  
  # Health check
  healthcheck {
    test         = ["CMD", "curl", "-f", "http://localhost:8081/service/rest/v1/status"]
    interval     = "30s"
    timeout      = "10s"
    start_period = "60s"
    retries      = 3
  }
  
  # Container labels
  labels {
    label = "project"
    value = local.project_name
  }
  
  labels {
    label = "service"
    value = "nexus-repository"
  }
  
  labels {
    label = "environment"
    value = local.environment
  }
  
  labels {
    label = "managed_by"
    value = "terraform"
  }
  
  # Lifecycle management
  lifecycle {
    ignore_changes = [
      # Ignore changes to environment variables that Nexus modifies
      env
    ]
  }
}

# Nexus Repository Configuration
# Post-deployment configuration using null_resource
resource "null_resource" "nexus_config" {
  depends_on = [docker_container.nexus]
  
  # Wait for Nexus to be ready
  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for Nexus to start..."
      timeout 300 bash -c 'until curl -f http://localhost:${var.nexus_web_port}/service/rest/v1/status; do sleep 5; done'
      echo "Nexus is ready!"
    EOT
  }
  
  # Create repositories using API
  provisioner "local-exec" {
    command = <<-EOT
      # Wait a bit more for full initialization
      sleep 30
      
      # Run repository creation script
      cd ${path.root}/..
      if [ -f "scripts/api/create-repos.sh" ]; then
        echo "Creating repositories via API..."
        ./scripts/api/create-repos.sh
      else
        echo "Repository creation script not found"
      fi
    EOT
  }
  
  # Triggers for re-configuration
  triggers = {
    nexus_container_id = docker_container.nexus.id
    config_version     = "1.0"
  }
}

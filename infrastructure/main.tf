terraform {
  required_version = ">= 1.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }

  # Backend configuration for state management
  backend "s3" {
    # Configure this for your state backend
    # For now, using local state
  }
}

provider "digitalocean" {
  token = var.do_token
}

# Get available Kubernetes versions (no prefix to see all available)
data "digitalocean_kubernetes_versions" "auth_stack" {
}

# Kubernetes cluster with enhanced configuration
resource "digitalocean_kubernetes_cluster" "auth_stack" {
  name    = var.cluster_name
  region  = var.region
  version = data.digitalocean_kubernetes_versions.auth_stack.latest_version

  # Main node pool
  node_pool {
    name       = "worker-pool"
    size       = var.node_size
    node_count = var.node_count

    # Auto-scaling configuration
    auto_scale = var.auto_scale
    min_nodes  = var.min_nodes
    max_nodes  = var.max_nodes

    # Node labels for workload scheduling
    labels = {
      environment = terraform.workspace
      node-type   = "worker"
    }

    # Taints for dedicated workloads (optional)
    # taint {
    #   key    = "workload-type"
    #   value  = "general"
    #   effect = "NoSchedule"
    # }
  }

  # Maintenance window for updates
  maintenance_policy {
    start_time = var.maintenance_window
    day        = "sunday"
  }

  # Cluster tags
  tags = var.tags

  # Enable cluster monitoring
  ha = var.enable_ha
}

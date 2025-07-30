terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

# Get available Kubernetes versions (no prefix to see all available)
data "digitalocean_kubernetes_versions" "auth_stack" {
}

# Simple Kubernetes cluster - use the latest available version
resource "digitalocean_kubernetes_cluster" "auth_stack" {
  name    = var.cluster_name
  region  = var.region
  version = data.digitalocean_kubernetes_versions.auth_stack.latest_version

  node_pool {
    name       = "worker-pool"
    size       = var.node_size
    node_count = var.node_count
  }

  tags = ["auth-stack", "production", "k8s"]
}

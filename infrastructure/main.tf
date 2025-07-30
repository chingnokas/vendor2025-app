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

# Get available Kubernetes versions
data "digitalocean_kubernetes_versions" "auth_stack" {
  version_prefix = "1.28."
}

# Simple Kubernetes cluster without VPC first
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

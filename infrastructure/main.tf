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

# Get the latest available Kubernetes version
data "digitalocean_kubernetes_versions" "auth_stack" {
  version_prefix = "1.29."
}

# Kubernetes cluster
resource "digitalocean_kubernetes_cluster" "auth_stack" {
  name     = var.cluster_name
  region   = var.region
  version  = data.digitalocean_kubernetes_versions.auth_stack.latest_version
  vpc_uuid = digitalocean_vpc.auth_stack_vpc.id

  node_pool {
    name       = "worker-pool"
    size       = var.node_size
    node_count = var.node_count
    auto_scale = true
    min_nodes  = 2
    max_nodes  = 5
  }

  tags = ["auth-stack", "production", "k8s"]
}

resource "digitalocean_loadbalancer" "auth_stack_lb" {
  name   = "auth-stack-lb"
  region = "nyc1"

  forwarding_rule {
    entry_protocol  = "http"
    entry_port      = 80
    target_protocol = "http"
    target_port     = 80
  }

  forwarding_rule {
    entry_protocol  = "https"
    entry_port      = 443
    target_protocol = "http"
    target_port     = 80
    tls_passthrough = false
  }

  healthcheck {
    protocol = "http"
    port     = 80
    path     = "/"
  }

  depends_on = [digitalocean_kubernetes_cluster.auth_stack]
}

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

resource "digitalocean_kubernetes_cluster" "auth_stack" {
  name    = "auth-stack-cluster"
  region  = "nyc1"
  version = "1.28.2-do.0"

  node_pool {
    name       = "worker-pool"
    size       = "s-2vcpu-2gb"
    node_count = 2
  }

  tags = ["auth-stack", "production"]
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
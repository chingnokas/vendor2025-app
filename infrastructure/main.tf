terraform {
  required_version = ">= 1.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.40"
    }
  }

  # Remote state backend for production use
  # Uncomment and configure for production deployments
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "auth-stack/terraform.tfstate"
  #   region = "us-east-1"
  # }
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
      managed-by  = "opentofu"
      project     = "auth-stack"
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
  tags = concat(var.tags, ["managed-by-opentofu", "project-auth-stack"])

  # Enable cluster monitoring and high availability
  ha            = var.enable_ha
  surge_upgrade = true
  auto_upgrade  = true

  # Destroy protection for production
  lifecycle {
    prevent_destroy = false # Set to true for production
  }
}

# Additional node pool for monitoring workloads (optional)
resource "digitalocean_kubernetes_node_pool" "monitoring_pool" {
  count = var.create_monitoring_pool ? 1 : 0

  cluster_id = digitalocean_kubernetes_cluster.auth_stack.id
  name       = "monitoring-pool"
  size       = var.monitoring_node_size
  node_count = var.monitoring_node_count

  auto_scale = true
  min_nodes  = 1
  max_nodes  = 3

  labels = {
    environment = terraform.workspace
    node-type   = "monitoring"
    managed-by  = "opentofu"
    project     = "auth-stack"
  }

  taint {
    key    = "workload-type"
    value  = "monitoring"
    effect = "NoSchedule"
  }

  tags = concat(var.tags, ["monitoring", "node-pool"])

  depends_on = [digitalocean_kubernetes_cluster.auth_stack]

  lifecycle {
    create_before_destroy = true
  }
}

# VPC for the cluster (optional but recommended)
resource "digitalocean_vpc" "auth_stack_vpc" {
  count = var.create_vpc ? 1 : 0

  name     = "${var.cluster_name}-vpc"
  region   = var.region
  ip_range = var.vpc_ip_range
}

# Firewall rules for the cluster
resource "digitalocean_firewall" "auth_stack_firewall" {
  count = var.create_firewall ? 1 : 0

  name = "${var.cluster_name}-firewall"

  # Apply firewall to cluster nodes using node pool tags
  tags = concat(var.tags, ["k8s:${digitalocean_kubernetes_cluster.auth_stack.id}"])

  # Allow HTTP/HTTPS traffic
  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # Allow SSH access (restrict source_addresses in production)
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = var.ssh_allowed_ips
  }

  # Allow Kubernetes API server access
  inbound_rule {
    protocol         = "tcp"
    port_range       = "6443"
    source_addresses = var.ssh_allowed_ips
  }

  # Allow all outbound traffic
  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  depends_on = [digitalocean_kubernetes_cluster.auth_stack]
}

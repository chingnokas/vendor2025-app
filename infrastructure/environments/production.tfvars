# Production Environment Configuration
cluster_name = "auth-stack-production"
region = "nyc1"
node_count = 3
node_size = "s-4vcpu-8gb"

# Tags for production environment
tags = ["auth-stack", "production", "k8s", "high-availability"]

# High availability for production
auto_scale = true
min_nodes = 2
max_nodes = 10
enable_ha = true

# Dedicated monitoring pool for production
create_monitoring_pool = true
monitoring_node_size = "s-2vcpu-4gb"
monitoring_node_count = 2

# Network configuration for production
create_vpc = true
vpc_ip_range = "10.20.0.0/16"

# Enhanced security for production
create_firewall = true
ssh_allowed_ips = ["YOUR_OFFICE_IP/32"]  # Replace with your actual IP

# Maintenance window
maintenance_window = "04:00"

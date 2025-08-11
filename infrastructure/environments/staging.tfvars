# Staging Environment Configuration
cluster_name = "auth-stack-staging"
region       = "nyc1"
node_count   = 2
node_size    = "s-2vcpu-4gb"

# Tags for staging environment
tags = ["auth-stack", "staging", "k8s", "ci-cd"]

# Cost optimization for staging
auto_scale = true
min_nodes  = 1
max_nodes  = 3

# High availability (disabled for cost savings in staging)
enable_ha = false

# Monitoring pool (disabled for cost savings in staging)
create_monitoring_pool = false
monitoring_node_size   = "s-2vcpu-2gb"
monitoring_node_count  = 1

# Network configuration
create_vpc   = false
vpc_ip_range = "10.10.0.0/16"

# Security configuration
create_firewall = true
ssh_allowed_ips = ["0.0.0.0/0"] # Restrict in production

# Maintenance window
maintenance_window = "04:00"

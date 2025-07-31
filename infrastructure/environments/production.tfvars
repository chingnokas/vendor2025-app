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

# Production-specific settings
enable_monitoring = true
enable_backup = true
maintenance_window = "sunday:04:00"

# Staging Environment Configuration
cluster_name = "auth-stack-staging"
region = "nyc1"
node_count = 2
node_size = "s-2vcpu-4gb"

# Tags for staging environment
tags = ["auth-stack", "staging", "k8s", "ci-cd"]

# Cost optimization for staging
auto_scale = true
min_nodes = 1
max_nodes = 3

output "cluster_id" {
  description = "Kubernetes cluster ID"
  value       = digitalocean_kubernetes_cluster.auth_stack.id
}

output "cluster_name" {
  description = "Kubernetes cluster name"
  value       = digitalocean_kubernetes_cluster.auth_stack.name
}

output "cluster_endpoint" {
  description = "Kubernetes cluster endpoint"
  value       = digitalocean_kubernetes_cluster.auth_stack.endpoint
}

output "cluster_region" {
  description = "Kubernetes cluster region"
  value       = digitalocean_kubernetes_cluster.auth_stack.region
}

output "node_count" {
  description = "Number of worker nodes"
  value       = digitalocean_kubernetes_cluster.auth_stack.node_pool[0].node_count
}

output "kubeconfig" {
  description = "Kubernetes config file contents"
  value       = digitalocean_kubernetes_cluster.auth_stack.kube_config[0].raw_config
  sensitive   = true
}

output "cluster_status" {
  description = "The status of the Kubernetes cluster"
  value       = digitalocean_kubernetes_cluster.auth_stack.status
}

output "cluster_version" {
  description = "The Kubernetes version of the cluster"
  value       = digitalocean_kubernetes_cluster.auth_stack.version
}

output "node_pool_id" {
  description = "The ID of the default node pool"
  value       = digitalocean_kubernetes_cluster.auth_stack.node_pool[0].id
}

output "cluster_urn" {
  description = "The uniform resource name (URN) of the Kubernetes cluster"
  value       = digitalocean_kubernetes_cluster.auth_stack.urn
}

output "cluster_ipv4" {
  description = "The public IPv4 address of the Kubernetes cluster"
  value       = digitalocean_kubernetes_cluster.auth_stack.ipv4_address
}

output "cluster_ca_certificate" {
  description = "The cluster CA certificate"
  value       = digitalocean_kubernetes_cluster.auth_stack.kube_config[0].cluster_ca_certificate
  sensitive   = true
}

output "client_certificate" {
  description = "The client certificate for cluster access"
  value       = digitalocean_kubernetes_cluster.auth_stack.kube_config[0].client_certificate
  sensitive   = true
}

output "client_key" {
  description = "The client key for cluster access"
  value       = digitalocean_kubernetes_cluster.auth_stack.kube_config[0].client_key
  sensitive   = true
}

output "token" {
  description = "The token for cluster access"
  value       = digitalocean_kubernetes_cluster.auth_stack.kube_config[0].token
  sensitive   = true
}

output "environment" {
  description = "The deployment environment"
  value       = terraform.workspace
}

output "tags" {
  description = "The tags applied to the cluster"
  value       = digitalocean_kubernetes_cluster.auth_stack.tags
}

output "node_size" {
  description = "The size of nodes in the cluster"
  value       = digitalocean_kubernetes_cluster.auth_stack.node_pool[0].size
}

output "auto_scale_enabled" {
  description = "Whether auto-scaling is enabled"
  value       = digitalocean_kubernetes_cluster.auth_stack.node_pool[0].auto_scale
}

output "min_nodes" {
  description = "The minimum number of nodes when auto-scaling"
  value       = digitalocean_kubernetes_cluster.auth_stack.node_pool[0].min_nodes
}

output "max_nodes" {
  description = "The maximum number of nodes when auto-scaling"
  value       = digitalocean_kubernetes_cluster.auth_stack.node_pool[0].max_nodes
}
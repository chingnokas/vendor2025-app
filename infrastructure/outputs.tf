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
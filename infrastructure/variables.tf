variable "do_token" {
  description = "Digital Ocean API token"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "Digital Ocean region"
  type        = string
  default     = "nyc1"
}

variable "cluster_name" {
  description = "Kubernetes cluster name"
  type        = string
  default     = "auth-stack-cluster"
}

variable "node_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}

variable "node_size" {
  description = "Size of worker nodes"
  type        = string
  default     = "s-2vcpu-2gb"
}
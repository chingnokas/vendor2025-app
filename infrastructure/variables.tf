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
  default     = "s-2vcpu-4gb"  # Upgraded from s-2vcpu-2gb
}

variable "auto_scale" {
  description = "Enable auto-scaling for the node pool"
  type        = bool
  default     = false
}

variable "min_nodes" {
  description = "Minimum number of nodes when auto-scaling is enabled"
  type        = number
  default     = 1
}

variable "max_nodes" {
  description = "Maximum number of nodes when auto-scaling is enabled"
  type        = number
  default     = 5
}

variable "maintenance_window" {
  description = "Maintenance window start time (HH:MM format)"
  type        = string
  default     = "04:00"
}

variable "tags" {
  description = "Tags to apply to the cluster"
  type        = list(string)
  default     = ["auth-stack", "k8s"]
}

variable "enable_ha" {
  description = "Enable high availability for the cluster"
  type        = bool
  default     = false
}

variable "create_monitoring_pool" {
  description = "Create a dedicated node pool for monitoring workloads"
  type        = bool
  default     = false
}

variable "monitoring_node_size" {
  description = "Size of monitoring nodes"
  type        = string
  default     = "s-2vcpu-4gb"
}

variable "monitoring_node_count" {
  description = "Number of monitoring nodes"
  type        = number
  default     = 1
}

variable "create_vpc" {
  description = "Create a VPC for the cluster"
  type        = bool
  default     = false
}

variable "vpc_ip_range" {
  description = "IP range for the VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "create_firewall" {
  description = "Create firewall rules for the cluster"
  type        = bool
  default     = true
}

variable "ssh_allowed_ips" {
  description = "List of IP addresses allowed to SSH to nodes"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Restrict this in production
}
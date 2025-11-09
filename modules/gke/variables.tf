variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "airtrafik"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-west1"
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "subnet_name" {
  description = "Name of the subnet for GKE"
  type        = string
}

variable "kubernetes_version_prefix" {
  description = "Kubernetes version prefix"
  type        = string
  default     = "1.29."
}

variable "authorized_networks" {
  description = "List of authorized networks for master access"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}

variable "binary_authorization_mode" {
  description = "Binary authorization mode"
  type        = string
  default     = "PROJECT_SINGLETON_POLICY_ENFORCE"
}

variable "enable_cluster_autoscaling" {
  description = "Enable cluster autoscaling"
  type        = bool
  default     = false
}

variable "autoscaling_min_cpu" {
  description = "Minimum CPU for cluster autoscaling"
  type        = number
  default     = 2
}

variable "autoscaling_max_cpu" {
  description = "Maximum CPU for cluster autoscaling"
  type        = number
  default     = 100
}

variable "autoscaling_min_memory" {
  description = "Minimum memory for cluster autoscaling"
  type        = number
  default     = 4
}

variable "autoscaling_max_memory" {
  description = "Maximum memory for cluster autoscaling"
  type        = number
  default     = 1000
}

variable "maintenance_start_time" {
  description = "Daily maintenance window start time"
  type        = string
  default     = "03:00"
}

variable "system_node_count" {
  description = "Initial node count for system pool"
  type        = number
  default     = 1
}

variable "system_preemptible" {
  description = "Use preemptible nodes for system pool"
  type        = bool
  default     = false
}

variable "system_machine_type" {
  description = "Machine type for system node pool"
  type        = string
  default     = "n2-standard-2"
}

variable "system_disk_size_gb" {
  description = "Disk size for system nodes"
  type        = number
  default     = 50
}

variable "system_min_nodes" {
  description = "Minimum nodes for system pool"
  type        = number
  default     = 1
}

variable "system_max_nodes" {
  description = "Maximum nodes for system pool"
  type        = number
  default     = 3
}

variable "app_node_count" {
  description = "Initial node count for app pool"
  type        = number
  default     = 2
}

variable "app_preemptible" {
  description = "Use preemptible nodes for app pool"
  type        = bool
  default     = false
}

variable "app_machine_type" {
  description = "Machine type for app node pool"
  type        = string
  default     = "n2-standard-4"
}

variable "app_disk_size_gb" {
  description = "Disk size for app nodes"
  type        = number
  default     = 100
}

variable "app_min_nodes" {
  description = "Minimum nodes for app pool"
  type        = number
  default     = 2
}

variable "app_max_nodes" {
  description = "Maximum nodes for app pool"
  type        = number
  default     = 6
}

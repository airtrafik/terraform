variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "airtrafik"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-west1"
}

variable "gke_subnet_cidr" {
  description = "CIDR range for GKE subnet"
  type        = string
  default     = "10.0.0.0/20"
}

variable "gke_pods_cidr" {
  description = "CIDR range for GKE pods"
  type        = string
  default     = "10.4.0.0/14"
}

variable "gke_services_cidr" {
  description = "CIDR range for GKE services"
  type        = string
  default     = "10.8.0.0/20"
}

variable "db_subnet_cidr" {
  description = "CIDR range for database subnet"
  type        = string
  default     = "10.0.16.0/24"
}

variable "valkey_subnet_cidr" {
  description = "CIDR range for Valkey subnet"
  type        = string
  default     = "10.0.17.0/24"
}

variable "kubernetes_version_prefix" {
  description = "Kubernetes version prefix"
  type        = string
  default     = "1.29."
}

variable "authorized_networks" {
  description = "List of authorized networks for GKE master access"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}

variable "gke_system_machine_type" {
  description = "Machine type for GKE system pool"
  type        = string
  default     = "n2-standard-2"
}

variable "gke_system_min_nodes" {
  description = "Minimum nodes for GKE system pool"
  type        = number
  default     = 1
}

variable "gke_system_max_nodes" {
  description = "Maximum nodes for GKE system pool"
  type        = number
  default     = 3
}

variable "gke_app_machine_type" {
  description = "Machine type for GKE app pool"
  type        = string
  default     = "n2-standard-2"
}

variable "gke_app_min_nodes" {
  description = "Minimum nodes for GKE app pool"
  type        = number
  default     = 1
}

variable "gke_app_max_nodes" {
  description = "Maximum nodes for GKE app pool"
  type        = number
  default     = 3
}

variable "gke_preemptible" {
  description = "Use preemptible nodes for cost savings"
  type        = bool
  default     = true
}

variable "postgres_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "POSTGRES_15"
}

variable "db_tier" {
  description = "Cloud SQL instance tier"
  type        = string
  default     = "db-f1-micro"
}

variable "db_high_availability" {
  description = "Enable high availability for database"
  type        = bool
  default     = false
}

variable "db_disk_size" {
  description = "Database disk size in GB"
  type        = number
  default     = 10
}

variable "valkey_tier" {
  description = "Memorystore tier"
  type        = string
  default     = "BASIC"
}

variable "valkey_memory_size" {
  description = "Valkey memory size in GB"
  type        = number
  default     = 1
}

variable "valkey_version" {
  description = "Valkey/Redis version"
  type        = string
  default     = "REDIS_7_2"
}

variable "create_state_bucket" {
  description = "Create terraform state bucket (only on first run)"
  type        = bool
  default     = false
}
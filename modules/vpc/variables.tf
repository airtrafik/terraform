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
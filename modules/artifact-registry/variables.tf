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

variable "untagged_retention_days" {
  description = "Number of days to retain untagged images"
  type        = number
  default     = 7
}

variable "dev_retention_days" {
  description = "Number of days to retain dev/test tagged images"
  type        = number
  default     = 30
}

variable "immutable_tags" {
  description = "Make tags immutable once created"
  type        = bool
  default     = false
}

variable "gke_service_account" {
  description = "GKE service account email for pulling images"
  type        = string
}

variable "ci_service_account" {
  description = "CI service account email for pushing images"
  type        = string
  default     = ""
}
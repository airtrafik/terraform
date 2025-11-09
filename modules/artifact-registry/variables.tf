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

variable "repositories" {
  description = "Map of repository configurations for different services"
  type = map(object({
    description             = string
    untagged_retention_days = optional(number, 14)
    dev_retention_days      = optional(number, 60)
    immutable_tags          = optional(bool, true)
  }))
}

variable "gke_service_accounts" {
  description = "List of GKE service account emails (from all environments) for pulling images"
  type        = list(string)
}

variable "ci_service_accounts" {
  description = "List of CI service account emails (from all environments) for pushing images"
  type        = list(string)
  default     = []
}
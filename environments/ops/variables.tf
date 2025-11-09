variable "project_id" {
  description = "GCP project ID for hosting shared resources (typically prod project)"
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

# Service account emails from all environments for IAM bindings
variable "dev_gke_service_account" {
  description = "Dev GKE service account email for pulling images"
  type        = string
}

variable "staging_gke_service_account" {
  description = "Staging GKE service account email for pulling images"
  type        = string
}

variable "prod_gke_service_account" {
  description = "Production GKE service account email for pulling images"
  type        = string
}

variable "dev_ci_service_account" {
  description = "Dev CI service account email for pushing images"
  type        = string
  default     = ""
}

variable "staging_ci_service_account" {
  description = "Staging CI service account email for pushing images"
  type        = string
  default     = ""
}

variable "prod_ci_service_account" {
  description = "Production CI service account email for pushing images"
  type        = string
  default     = ""
}

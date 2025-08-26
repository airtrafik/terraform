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

variable "gke_workload_roles" {
  description = "IAM roles to assign to GKE workload service account"
  type        = list(string)
  default = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/cloudtrace.agent",
    "roles/secretmanager.secretAccessor"
  ]
}

variable "ci_cd_roles" {
  description = "IAM roles to assign to CI/CD service account"
  type        = list(string)
  default = [
    "roles/container.developer",
    "roles/artifactregistry.writer",
    "roles/cloudbuild.builds.builder",
    "roles/source.writer"
  ]
}

variable "workload_identity_namespaces" {
  description = "Kubernetes namespaces and service accounts for workload identity"
  type        = map(string)
  default = {
    "default"           = "default"
    "airtrafik-backend" = "backend-sa"
  }
}

variable "create_ci_service_account" {
  description = "Create CI/CD service account"
  type        = bool
  default     = true
}

variable "create_ci_key" {
  description = "Create and store CI/CD service account key"
  type        = bool
  default     = false
}
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

variable "force_destroy" {
  description = "Force destroy buckets even if they contain objects"
  type        = bool
  default     = false
}

variable "storage_class" {
  description = "Storage class for uploads bucket"
  type        = string
  default     = "STANDARD"
}

variable "backup_storage_class" {
  description = "Storage class for backup bucket"
  type        = string
  default     = "NEARLINE"
}

variable "enable_versioning" {
  description = "Enable versioning for uploads bucket"
  type        = bool
  default     = false
}

variable "uploads_retention_days" {
  description = "Number of days to retain uploads"
  type        = number
  default     = 90
}

variable "version_retention_count" {
  description = "Number of versions to retain"
  type        = number
  default     = 3
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 365
}

variable "backup_archive_after_days" {
  description = "Archive backups after this many days"
  type        = number
  default     = 30
}

variable "cors_origins" {
  description = "CORS allowed origins for uploads bucket"
  type        = list(string)
  default     = ["*"]
}

variable "create_state_bucket" {
  description = "Create terraform state bucket (only needed once per project)"
  type        = bool
  default     = false
}

variable "gke_service_account" {
  description = "GKE service account email for bucket access"
  type        = string
}

variable "sql_service_account" {
  description = "Cloud SQL service account email for backup access"
  type        = string
}
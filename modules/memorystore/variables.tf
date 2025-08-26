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

variable "vpc_id" {
  description = "VPC ID for the Valkey instance"
  type        = string
}

variable "tier" {
  description = "Service tier (BASIC or STANDARD_HA)"
  type        = string
  default     = "BASIC"
}

variable "memory_size_gb" {
  description = "Memory size in GB"
  type        = number
  default     = 1
}

variable "valkey_version" {
  description = "Valkey/Redis version"
  type        = string
  default     = "REDIS_7_2"
}

variable "auth_enabled" {
  description = "Enable AUTH for the instance"
  type        = bool
  default     = true
}

variable "redis_configs" {
  description = "Redis configuration parameters"
  type        = map(string)
  default = {
    "maxmemory-policy" = "allkeys-lru"
    "timeout"          = "300"
    "tcp-keepalive"    = "60"
  }
}

variable "prevent_destroy" {
  description = "Prevent destruction of the instance"
  type        = bool
  default     = false
}
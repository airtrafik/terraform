output "host" {
  description = "The IP address of the Valkey instance"
  value       = google_redis_instance.valkey.host
}

output "port" {
  description = "The port of the Valkey instance"
  value       = google_redis_instance.valkey.port
}

output "auth_string" {
  description = "AUTH string for the Valkey instance"
  value       = google_redis_instance.valkey.auth_string
  sensitive   = true
}

output "memory_size_gb" {
  description = "Memory size of the instance in GB"
  value       = google_redis_instance.valkey.memory_size_gb
}

output "valkey_config_secret_id" {
  description = "The Secret Manager secret ID containing Valkey configuration"
  value       = google_secret_manager_secret.valkey_config.secret_id
}

output "valkey_config_secret_version" {
  description = "The Secret Manager secret version containing Valkey configuration"
  value       = google_secret_manager_secret_version.valkey_config.name
}
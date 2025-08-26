output "gke_cluster_name" {
  description = "GKE cluster name"
  value       = module.gke.cluster_name
}

output "gke_cluster_endpoint" {
  description = "GKE cluster endpoint"
  value       = module.gke.cluster_endpoint
  sensitive   = true
}

output "gke_cluster_ca_certificate" {
  description = "GKE cluster CA certificate"
  value       = module.gke.cluster_ca_certificate
  sensitive   = true
}

output "cloudsql_instance_name" {
  description = "Cloud SQL instance name"
  value       = module.cloudsql.instance_name
}

output "cloudsql_connection_name" {
  description = "Cloud SQL connection name for proxy"
  value       = module.cloudsql.instance_connection_name
}

output "cloudsql_private_ip" {
  description = "Cloud SQL private IP address"
  value       = module.cloudsql.private_ip_address
}

output "valkey_host" {
  description = "Valkey instance host"
  value       = module.memorystore.host
}

output "valkey_port" {
  description = "Valkey instance port"
  value       = module.memorystore.port
}

output "artifact_registry_url" {
  description = "Artifact Registry URL for docker images"
  value       = module.artifact_registry.repository_url
}

output "uploads_bucket_name" {
  description = "GCS uploads bucket name"
  value       = module.gcs.uploads_bucket_name
}

output "backups_bucket_name" {
  description = "GCS backups bucket name"
  value       = module.gcs.backups_bucket_name
}

output "gke_workload_sa_email" {
  description = "GKE workload service account email"
  value       = module.iam.gke_workload_sa_email
}

output "cloudsql_proxy_sa_email" {
  description = "Cloud SQL proxy service account email"
  value       = module.iam.cloudsql_proxy_sa_email
}

output "gcs_access_sa_email" {
  description = "GCS access service account email"
  value       = module.iam.gcs_access_sa_email
}

output "database_password_secret_id" {
  description = "Secret Manager secret ID for database password"
  value       = module.cloudsql.database_password_secret_id
}

output "valkey_config_secret_id" {
  description = "Secret Manager secret ID for Valkey configuration"
  value       = module.memorystore.valkey_config_secret_id
}
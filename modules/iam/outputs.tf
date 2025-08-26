output "gke_workload_sa_email" {
  description = "Email of the GKE workload service account"
  value       = google_service_account.gke_workload.email
}

output "cloudsql_proxy_sa_email" {
  description = "Email of the Cloud SQL proxy service account"
  value       = google_service_account.cloudsql_proxy.email
}

output "gcs_access_sa_email" {
  description = "Email of the GCS access service account"
  value       = google_service_account.gcs_access.email
}

output "ci_cd_sa_email" {
  description = "Email of the CI/CD service account"
  value       = var.create_ci_service_account ? google_service_account.ci_cd[0].email : ""
}

output "ci_cd_key_secret_id" {
  description = "Secret Manager secret ID for CI/CD key"
  value       = var.create_ci_service_account && var.create_ci_key ? google_secret_manager_secret.ci_cd_key[0].secret_id : ""
}
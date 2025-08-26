output "repository_id" {
  description = "The repository ID"
  value       = google_artifact_registry_repository.docker.repository_id
}

output "repository_name" {
  description = "The repository name"
  value       = google_artifact_registry_repository.docker.name
}

output "repository_url" {
  description = "The repository URL for docker images"
  value       = "${var.region}-docker.pkg.dev/${data.google_project.current.project_id}/${google_artifact_registry_repository.docker.repository_id}"
}

data "google_project" "current" {}
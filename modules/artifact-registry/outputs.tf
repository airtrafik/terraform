output "registry_base_url" {
  description = "Base URL for artifact registry in format: {region}-docker.pkg.dev/{project_id}"
  value       = "${var.region}-docker.pkg.dev/${data.google_project.current.project_id}"
}

output "repositories" {
  description = "Map of repository names to their full URLs"
  value = {
    for name, repo in google_artifact_registry_repository.docker :
    name => "${var.region}-docker.pkg.dev/${data.google_project.current.project_id}/${repo.repository_id}"
  }
}

output "repository_ids" {
  description = "Map of service names to repository IDs"
  value = {
    for name, repo in google_artifact_registry_repository.docker :
    name => repo.repository_id
  }
}

output "repository_names" {
  description = "Map of service names to full repository resource names"
  value = {
    for name, repo in google_artifact_registry_repository.docker :
    name => repo.name
  }
}
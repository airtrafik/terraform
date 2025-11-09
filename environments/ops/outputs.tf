output "artifact_registry_region" {
  description = "Region where artifact registries are located"
  value       = var.region
}

output "artifact_registry_project_id" {
  description = "Project ID where artifact registries are hosted"
  value       = var.project_id
}

output "registry_base_url" {
  description = "Base URL for artifact registry"
  value       = module.artifact_registry.registry_base_url
}

output "repositories" {
  description = "Map of repository names to their full URLs"
  value       = module.artifact_registry.repositories
}

# Individual repository URLs for easy reference
output "api_repository_url" {
  description = "Full URL for API service repository"
  value       = module.artifact_registry.repositories["api"]
}

output "frontend_repository_url" {
  description = "Full URL for frontend repository"
  value       = module.artifact_registry.repositories["frontend"]
}

output "worker_repository_url" {
  description = "Full URL for worker repository"
  value       = module.artifact_registry.repositories["worker"]
}

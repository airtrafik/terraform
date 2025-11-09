data "google_project" "current" {}

# Generate repositories map from simple service list with defaults
locals {
  repositories = {
    for service in var.services : service => {
      description             = "${title(service)} service Docker images"
      untagged_retention_days = var.repository_config.untagged_retention_days
      dev_retention_days      = var.repository_config.dev_retention_days
      immutable_tags          = var.repository_config.immutable_tags
    }
  }
}

# Create one repository per service (e.g., api, frontend, worker)
# Repository naming: {project_name}-{service} (no environment suffix)
# This allows the same image to be promoted through dev -> staging -> prod
resource "google_artifact_registry_repository" "docker" {
  for_each = local.repositories

  location      = var.region
  repository_id = "${var.project_name}-${each.key}"
  description   = each.value.description
  format        = "DOCKER"

  # Keep tagged releases indefinitely
  cleanup_policies {
    id     = "keep-tagged-release"
    action = "KEEP"
    condition {
      tag_state    = "TAGGED"
      tag_prefixes = ["v", "release", "prod"]
    }
  }

  # Delete untagged images after retention period
  cleanup_policies {
    id     = "delete-untagged"
    action = "DELETE"
    condition {
      tag_state  = "UNTAGGED"
      older_than = "${each.value.untagged_retention_days * 24 * 60 * 60}s"
    }
  }

  # Delete old dev/test tagged images
  cleanup_policies {
    id     = "delete-old-dev"
    action = "DELETE"
    condition {
      tag_state    = "TAGGED"
      tag_prefixes = ["dev", "test", "feature"]
      older_than   = "${each.value.dev_retention_days * 24 * 60 * 60}s"
    }
  }

  docker_config {
    immutable_tags = each.value.immutable_tags
  }

  labels = {
    service = each.key
    project = var.project_name
  }
}

# Grant read access to ALL GKE service accounts from all environments
# This allows any environment to pull from these shared registries
resource "google_artifact_registry_repository_iam_member" "gke_pull" {
  for_each = {
    for pair in setproduct(keys(local.repositories), var.gke_service_accounts) :
    "${pair[0]}-${element(split("@", pair[1]), 0)}" => {
      repo = pair[0]
      sa   = pair[1]
    }
    if pair[1] != ""
  }

  location   = var.region
  repository = google_artifact_registry_repository.docker[each.value.repo].name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${each.value.sa}"
}

# Grant write access to CI service accounts from all environments
# This allows CI pipelines to push images to the shared registries
resource "google_artifact_registry_repository_iam_member" "ci_push" {
  for_each = {
    for pair in setproduct(keys(local.repositories), var.ci_service_accounts) :
    "${pair[0]}-${element(split("@", pair[1]), 0)}" => {
      repo = pair[0]
      sa   = pair[1]
    }
    if pair[1] != ""
  }

  location   = var.region
  repository = google_artifact_registry_repository.docker[each.value.repo].name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${each.value.sa}"
}
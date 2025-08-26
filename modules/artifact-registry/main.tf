resource "google_artifact_registry_repository" "docker" {
  location      = var.region
  repository_id = "${var.project_name}-images-${var.environment}"
  description   = "Docker repository for ${var.project_name} ${var.environment} environment"
  format        = "DOCKER"

  cleanup_policies {
    id     = "keep-tagged-release"
    action = "KEEP"
    condition {
      tag_state    = "TAGGED"
      tag_prefixes = ["v", "release"]
    }
  }

  cleanup_policies {
    id     = "delete-untagged"
    action = "DELETE"
    condition {
      tag_state = "UNTAGGED"
      older_than = "${var.untagged_retention_days * 24 * 60 * 60}s"
    }
  }

  cleanup_policies {
    id     = "delete-old-dev"
    action = "DELETE"
    condition {
      tag_state    = "TAGGED"
      tag_prefixes = ["dev", "test"]
      older_than   = "${var.dev_retention_days * 24 * 60 * 60}s"
    }
  }

  docker_config {
    immutable_tags = var.immutable_tags
  }

  labels = {
    environment = var.environment
    project     = var.project_name
  }
}

resource "google_artifact_registry_repository_iam_member" "gke_pull" {
  location   = google_artifact_registry_repository.docker.location
  repository = google_artifact_registry_repository.docker.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${var.gke_service_account}"
}

resource "google_artifact_registry_repository_iam_member" "ci_push" {
  count      = var.ci_service_account != "" ? 1 : 0
  location   = google_artifact_registry_repository.docker.location
  repository = google_artifact_registry_repository.docker.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${var.ci_service_account}"
}
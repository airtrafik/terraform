resource "google_storage_bucket" "uploads" {
  name          = "${var.project_name}-uploads-${var.environment}"
  location      = var.region
  force_destroy = var.force_destroy
  storage_class = var.storage_class

  uniform_bucket_level_access = true

  versioning {
    enabled = var.enable_versioning
  }

  lifecycle_rule {
    condition {
      age = var.uploads_retention_days
    }
    action {
      type = "Delete"
    }
  }

  lifecycle_rule {
    condition {
      num_newer_versions = var.version_retention_count
      with_state         = "ARCHIVED"
    }
    action {
      type = "Delete"
    }
  }

  cors {
    origin          = var.cors_origins
    method          = ["GET", "POST", "PUT", "DELETE", "HEAD"]
    response_header = ["*"]
    max_age_seconds = 3600
  }

  labels = {
    environment = var.environment
    project     = var.project_name
    purpose     = "uploads"
  }
}

resource "google_storage_bucket" "backups" {
  name          = "${var.project_name}-backups-${var.environment}"
  location      = var.region
  force_destroy = false
  storage_class = var.backup_storage_class

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = var.backup_retention_days
    }
    action {
      type = "Delete"
    }
  }

  lifecycle_rule {
    condition {
      age           = var.backup_archive_after_days
    }
    action {
      type          = "SetStorageClass"
      storage_class = "ARCHIVE"
    }
  }

  labels = {
    environment = var.environment
    project     = var.project_name
    purpose     = "backups"
  }
}

resource "google_storage_bucket" "terraform_state" {
  count = var.create_state_bucket ? 1 : 0

  name          = "${var.project_name}-terraform-state"
  location      = var.region
  force_destroy = false
  storage_class = "STANDARD"

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      num_newer_versions = 10
    }
    action {
      type = "Delete"
    }
  }

  labels = {
    project = var.project_name
    purpose = "terraform-state"
  }
}

resource "google_storage_bucket_iam_member" "uploads_gke_access" {
  bucket = google_storage_bucket.uploads.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.gke_service_account}"
}

resource "google_storage_bucket_iam_member" "backups_sql_access" {
  bucket = google_storage_bucket.backups.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.sql_service_account}"
}

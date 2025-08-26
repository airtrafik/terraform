resource "google_redis_instance" "valkey" {
  name               = "${var.project_name}-valkey-${var.environment}"
  tier               = var.tier
  memory_size_gb     = var.memory_size_gb
  region             = var.region
  redis_version      = var.valkey_version
  display_name       = "${var.project_name} Valkey ${var.environment}"
  authorized_network = var.vpc_id

  location_id             = var.tier == "STANDARD_HA" ? null : "${var.region}-a"
  alternative_location_id = var.tier == "STANDARD_HA" ? "${var.region}-b" : null

  auth_enabled = var.auth_enabled

  redis_configs = var.redis_configs

  maintenance_policy {
    weekly_maintenance_window {
      day = "SUNDAY"
      start_time {
        hours   = 3
        minutes = 0
        seconds = 0
        nanos   = 0
      }
    }
  }

  labels = {
    environment = var.environment
    project     = var.project_name
    service     = "valkey"
  }

  lifecycle {
    prevent_destroy = var.prevent_destroy
  }
}

resource "random_password" "valkey_auth" {
  count   = var.auth_enabled ? 1 : 0
  length  = 32
  special = false
}

resource "google_secret_manager_secret" "valkey_config" {
  secret_id = "${var.project_name}-valkey-config-${var.environment}"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "valkey_config" {
  secret = google_secret_manager_secret.valkey_config.id

  secret_data = jsonencode({
    host        = google_redis_instance.valkey.host
    port        = google_redis_instance.valkey.port
    auth_string = var.auth_enabled ? google_redis_instance.valkey.auth_string : ""
    redis_uri   = var.auth_enabled ? "redis://:${google_redis_instance.valkey.auth_string}@${google_redis_instance.valkey.host}:${google_redis_instance.valkey.port}" : "redis://${google_redis_instance.valkey.host}:${google_redis_instance.valkey.port}"
  })
}
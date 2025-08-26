data "google_container_engine_versions" "gke_version" {
  location       = var.region
  version_prefix = var.kubernetes_version_prefix
}

resource "google_container_cluster" "primary" {
  name     = "${var.project_name}-gke-${var.environment}"
  location = var.region

  min_master_version = data.google_container_engine_versions.gke_version.latest_master_version
  node_version       = data.google_container_engine_versions.gke_version.latest_node_version

  network    = var.vpc_name
  subnetwork = var.subnet_name

  initial_node_count       = 1
  remove_default_node_pool = true

  ip_allocation_policy {
    cluster_secondary_range_name  = "gke-pods"
    services_secondary_range_name = "gke-services"
  }

  private_cluster_config {
    enable_private_endpoint = false
    enable_private_nodes    = true
    master_ipv4_cidr_block  = "172.16.0.0/28"

    master_global_access_config {
      enabled = true
    }
  }

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.authorized_networks
      content {
        cidr_block   = cidr_blocks.value.cidr_block
        display_name = cidr_blocks.value.display_name
      }
    }
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  network_policy {
    enabled  = true
    provider = "CALICO"
  }

  binary_authorization {
    evaluation_mode = var.binary_authorization_mode
  }

  addons_config {
    horizontal_pod_autoscaling {
      disabled = false
    }

    http_load_balancing {
      disabled = false
    }

    network_policy_config {
      disabled = false
    }

    gce_persistent_disk_csi_driver_config {
      enabled = true
    }
  }

  cluster_autoscaling {
    enabled = var.enable_cluster_autoscaling

    dynamic "resource_limits" {
      for_each = var.enable_cluster_autoscaling ? [1] : []
      content {
        resource_type = "cpu"
        minimum       = var.autoscaling_min_cpu
        maximum       = var.autoscaling_max_cpu
      }
    }

    dynamic "resource_limits" {
      for_each = var.enable_cluster_autoscaling ? [1] : []
      content {
        resource_type = "memory"
        minimum       = var.autoscaling_min_memory
        maximum       = var.autoscaling_max_memory
      }
    }
  }

  maintenance_policy {
    daily_maintenance_window {
      start_time = var.maintenance_start_time
    }
  }

  resource_labels = {
    environment = var.environment
    project     = var.project_name
  }

  lifecycle {
    ignore_changes = [initial_node_count]
  }
}

resource "google_container_node_pool" "system_pool" {
  name       = "${var.project_name}-system-pool-${var.environment}"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = var.system_node_count

  node_config {
    preemptible  = var.system_preemptible
    machine_type = var.system_machine_type
    disk_size_gb = var.system_disk_size_gb
    disk_type    = "pd-standard"

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = {
      pool        = "system"
      environment = var.environment
    }

    tags = ["gke-node", "gke-${var.project_name}-${var.environment}"]

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }

  autoscaling {
    min_node_count = var.system_min_nodes
    max_node_count = var.system_max_nodes
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

resource "google_container_node_pool" "app_pool" {
  name     = "${var.project_name}-app-pool-${var.environment}"
  location = var.region
  cluster  = google_container_cluster.primary.name

  initial_node_count = var.app_node_count

  node_config {
    preemptible  = var.app_preemptible
    machine_type = var.app_machine_type
    disk_size_gb = var.app_disk_size_gb
    disk_type    = "pd-ssd"

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = {
      pool        = "application"
      environment = var.environment
    }

    tags = ["gke-node", "gke-${var.project_name}-${var.environment}"]

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    taint {
      key    = "workload"
      value  = "application"
      effect = "NO_SCHEDULE"
    }
  }

  autoscaling {
    min_node_count = var.app_min_nodes
    max_node_count = var.app_max_nodes
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}
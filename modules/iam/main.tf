resource "google_service_account" "gke_workload" {
  account_id   = "${var.project_name}-gke-workload-${var.environment}"
  display_name = "GKE Workload Identity Service Account for ${var.environment}"
  description  = "Service account for GKE workload identity binding"
}

resource "google_service_account" "cloudsql_proxy" {
  account_id   = "${var.project_name}-cloudsql-proxy-${var.environment}"
  display_name = "Cloud SQL Proxy Service Account for ${var.environment}"
  description  = "Service account for Cloud SQL proxy authentication"
}

resource "google_service_account" "gcs_access" {
  account_id   = "${var.project_name}-gcs-access-${var.environment}"
  display_name = "GCS Access Service Account for ${var.environment}"
  description  = "Service account for Google Cloud Storage access"
}

resource "google_service_account" "ci_cd" {
  count        = var.create_ci_service_account ? 1 : 0
  account_id   = "${var.project_name}-ci-cd-${var.environment}"
  display_name = "CI/CD Service Account for ${var.environment}"
  description  = "Service account for CI/CD pipelines"
}

resource "google_project_iam_member" "gke_workload_bindings" {
  for_each = toset(var.gke_workload_roles)
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.gke_workload.email}"
}

resource "google_project_iam_member" "cloudsql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.cloudsql_proxy.email}"
}

resource "google_project_iam_member" "gcs_object_admin" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.gcs_access.email}"
}

resource "google_project_iam_member" "ci_cd_bindings" {
  for_each = var.create_ci_service_account ? toset(var.ci_cd_roles) : toset([])
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.ci_cd[0].email}"
}

resource "google_service_account_iam_binding" "workload_identity_binding" {
  for_each = var.workload_identity_namespaces

  service_account_id = google_service_account.gke_workload.name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "serviceAccount:${var.project_id}.svc.id.goog[${each.key}/${each.value}]"
  ]
}

resource "google_service_account_key" "ci_cd_key" {
  count              = var.create_ci_service_account && var.create_ci_key ? 1 : 0
  service_account_id = google_service_account.ci_cd[0].name
  public_key_type    = "TYPE_X509_PEM_FILE"
  private_key_type   = "TYPE_GOOGLE_CREDENTIALS_FILE"
}

resource "google_secret_manager_secret" "ci_cd_key" {
  count     = var.create_ci_service_account && var.create_ci_key ? 1 : 0
  secret_id = "${var.project_name}-ci-cd-key-${var.environment}"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "ci_cd_key" {
  count       = var.create_ci_service_account && var.create_ci_key ? 1 : 0
  secret      = google_secret_manager_secret.ci_cd_key[0].id
  secret_data = base64decode(google_service_account_key.ci_cd_key[0].private_key)
}
terraform {
  required_version = ">= 1.5.0"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# Centralized artifact registries for all environments
# Images built once and promoted through dev -> staging -> prod
module "artifact_registry" {
  source = "../../modules/artifact-registry"

  project_name = var.project_name
  region       = var.region

  # Pass service accounts from ALL environments for cross-project IAM
  gke_service_accounts = compact([
    var.dev_gke_service_account,
    var.staging_gke_service_account,
    var.prod_gke_service_account,
  ])

  ci_service_accounts = compact([
    var.dev_ci_service_account,
    var.staging_ci_service_account,
    var.prod_ci_service_account,
  ])

  # Define your application services here
  # To add a new service, simply add a new entry to this map
  repositories = {
    api = {
      description             = "API service Docker images"
      untagged_retention_days = 14
      dev_retention_days      = 60
      immutable_tags          = true
    }
    frontend = {
      description             = "Frontend application Docker images"
      untagged_retention_days = 14
      dev_retention_days      = 60
      immutable_tags          = true
    }
    worker = {
      description             = "Background worker Docker images"
      untagged_retention_days = 14
      dev_retention_days      = 60
      immutable_tags          = true
    }
  }
}

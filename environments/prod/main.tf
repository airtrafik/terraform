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

locals {
  environment = "prod"
}

module "vpc" {
  source = "../../modules/vpc"

  project_name       = var.project_name
  environment        = local.environment
  region             = var.region
  gke_subnet_cidr    = var.gke_subnet_cidr
  gke_pods_cidr      = var.gke_pods_cidr
  gke_services_cidr  = var.gke_services_cidr
  db_subnet_cidr     = var.db_subnet_cidr
  valkey_subnet_cidr = var.valkey_subnet_cidr
}

module "iam" {
  source = "../../modules/iam"

  project_id                = var.project_id
  project_name              = var.project_name
  environment               = local.environment
  create_ci_service_account = true
  create_ci_key             = false
}

module "gke" {
  source = "../../modules/gke"

  project_id                 = var.project_id
  project_name               = var.project_name
  environment                = local.environment
  region                     = var.region
  vpc_name                   = module.vpc.vpc_name
  subnet_name                = module.vpc.gke_subnet_name
  kubernetes_version_prefix  = var.kubernetes_version_prefix
  authorized_networks        = var.authorized_networks
  enable_cluster_autoscaling = true
  maintenance_start_time     = "03:00"

  system_machine_type = var.gke_system_machine_type
  system_min_nodes    = var.gke_system_min_nodes
  system_max_nodes    = var.gke_system_max_nodes
  system_preemptible  = var.gke_preemptible

  app_machine_type = var.gke_app_machine_type
  app_min_nodes    = var.gke_app_min_nodes
  app_max_nodes    = var.gke_app_max_nodes
  app_preemptible  = var.gke_preemptible
}

module "cloudsql" {
  source = "../../modules/cloudsql"

  project_name               = var.project_name
  environment                = local.environment
  region                     = var.region
  vpc_id                     = module.vpc.vpc_id
  private_service_connection = module.vpc.private_service_connection
  postgres_version           = var.postgres_version
  instance_tier              = var.db_tier
  high_availability          = var.db_high_availability
  disk_size                  = var.db_disk_size
  disk_type                  = "PD_SSD"
  backup_enabled             = true
  point_in_time_recovery     = true
  deletion_protection        = true
  require_ssl                = true
}

module "memorystore" {
  source = "../../modules/memorystore"

  project_name    = var.project_name
  environment     = local.environment
  region          = var.region
  vpc_id          = module.vpc.vpc_id
  tier            = var.valkey_tier
  memory_size_gb  = var.valkey_memory_size
  valkey_version  = var.valkey_version
  auth_enabled    = true
  prevent_destroy = true
}

module "artifact_registry" {
  source = "../../modules/artifact-registry"

  project_name            = var.project_name
  environment             = local.environment
  region                  = var.region
  gke_service_account     = module.iam.gke_workload_sa_email
  ci_service_account      = module.iam.ci_cd_sa_email
  untagged_retention_days = 14
  dev_retention_days      = 60
  immutable_tags          = true
}

module "gcs" {
  source = "../../modules/gcs"

  project_name              = var.project_name
  environment               = local.environment
  region                    = var.region
  force_destroy             = false
  enable_versioning         = true
  uploads_retention_days    = 90
  backup_retention_days     = 365
  backup_archive_after_days = 60
  create_state_bucket       = var.create_state_bucket
  gke_service_account       = module.iam.gke_workload_sa_email
  sql_service_account       = module.iam.cloudsql_proxy_sa_email
  cors_origins              = ["https://airtrafik.com", "https://www.airtrafik.com"]
}
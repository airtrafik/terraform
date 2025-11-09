# Operational infrastructure hosted in airtrafik-ops project
# This includes Terraform state, shared artifact registries, and CI/CD infrastructure
project_id = "airtrafik-ops"

# List of services to create artifact repositories for
# To add a new service, simply add its name to this list
services = [
  "api",
  "frontend",
  "worker"
]

# Service account emails from environment-specific deployments
# Update these after deploying dev/staging/prod environments
dev_gke_service_account     = ""
staging_gke_service_account = ""
prod_gke_service_account    = ""

dev_ci_service_account     = ""
staging_ci_service_account = ""
prod_ci_service_account    = ""

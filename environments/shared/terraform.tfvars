# Shared infrastructure hosted in ops project
# airtrafik-ops is used for operational items like consolidated telemetry,
# deployment infrastructure, and shared artifact registries
project_id = "airtrafik-ops"

# These service account emails will be provided by the environment-specific deployments
# Update these after deploying dev/staging/prod environments
dev_gke_service_account     = ""
staging_gke_service_account = ""
prod_gke_service_account    = ""

dev_ci_service_account     = ""
staging_ci_service_account = ""
prod_ci_service_account    = ""

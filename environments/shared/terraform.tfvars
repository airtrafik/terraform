# Shared infrastructure hosted in production project
# (Alternative: Create a separate airtrafik-shared project)
project_id = "airtrafik-prod"

# These service account emails will be provided by the environment-specific deployments
# Update these after deploying dev/staging/prod environments
dev_gke_service_account     = ""
staging_gke_service_account = ""
prod_gke_service_account    = ""

dev_ci_service_account     = ""
staging_ci_service_account = ""
prod_ci_service_account    = ""

# Artifact Registry Deployment Workflow

This document explains the refactored artifact registry architecture and deployment workflow.

## Architecture Overview

The artifact registry has been refactored to follow best practices:

### ✅ Build Once, Deploy Many
- **Single shared registries** for all environments (hosted in production project)
- Images are built **once** and **promoted** through environments
- No environment-specific image rebuilds

### ✅ Service-Based Repositories
- One Docker repository **per service** (not per environment)
- Easy to add new services by updating a single configuration
- Current services: `api`, `frontend`, `worker`

### Repository Structure

```
us-west1-docker.pkg.dev/airtrafik-ops/
├── airtrafik-api/        # API service images
├── airtrafik-frontend/   # Frontend images
└── airtrafik-worker/     # Worker images
```

**No environment suffix!** Same image progresses through all environments.

## Deployment Order

Since nothing has been deployed yet, follow this exact order:

### 1. Deploy Each Environment's IAM & Infrastructure (dev, staging, prod)

First, deploy the environment-specific resources to create service accounts:

```bash
# Deploy dev environment
cd environments/dev
terraform init
terraform plan
terraform apply

# Note the service account emails from outputs:
terraform output gke_workload_sa_email
terraform output ci_cd_sa_email
```

Repeat for staging and prod:

```bash
cd ../staging
terraform init && terraform apply

cd ../prod
terraform init && terraform apply
```

### 2. Update Shared Configuration with Service Accounts

After deploying all three environments, update `environments/ops/terraform.tfvars` with the service account emails:

```hcl
# Update these with actual values from step 1
dev_gke_service_account     = "gke-workload@airtrafik-dev.iam.gserviceaccount.com"
staging_gke_service_account = "gke-workload@airtrafik-staging.iam.gserviceaccount.com"
prod_gke_service_account    = "gke-workload@airtrafik-prod.iam.gserviceaccount.com"

dev_ci_service_account     = "ci-cd@airtrafik-dev.iam.gserviceaccount.com"
staging_ci_service_account = "ci-cd@airtrafik-staging.iam.gserviceaccount.com"
prod_ci_service_account    = "ci-cd@airtrafik-prod.iam.gserviceaccount.com"
```

### 3. Deploy Shared Artifact Registries

Now deploy the shared registries with cross-project IAM:

```bash
cd environments/ops
terraform init
terraform plan
terraform apply
```

This creates:
- `airtrafik-api` repository
- `airtrafik-frontend` repository
- `airtrafik-worker` repository
- IAM bindings for all environment service accounts

### 4. Verify Registry Access

Check that registries were created:

```bash
gcloud artifacts repositories list \
  --project=airtrafik-ops \
  --location=us-west1
```

Verify IAM permissions:

```bash
gcloud artifacts repositories get-iam-policy airtrafik-api \
  --project=airtrafik-ops \
  --location=us-west1
```

You should see service accounts from all three environments with appropriate roles.

## CI/CD Image Workflow

### Building Images

Your CI pipeline should build images **once** and tag appropriately:

```bash
# Example: Building API service
IMAGE_NAME="us-west1-docker.pkg.dev/airtrafik-ops/airtrafik-api"
GIT_SHA=$(git rev-parse --short HEAD)

# Build and push with SHA tag
docker build -t ${IMAGE_NAME}:${GIT_SHA} .
docker push ${IMAGE_NAME}:${GIT_SHA}

# Also tag with branch/environment for convenience
docker tag ${IMAGE_NAME}:${GIT_SHA} ${IMAGE_NAME}:dev-latest
docker push ${IMAGE_NAME}:dev-latest
```

### Promoting Through Environments

Use the **same SHA** across environments:

```bash
# Dev deployment (already has :dev-latest from build)
kubectl set image deployment/api \
  api=us-west1-docker.pkg.dev/airtrafik-ops/airtrafik-api:abc123

# After testing in dev, promote to staging (same image!)
docker tag us-west1-docker.pkg.dev/airtrafik-ops/airtrafik-api:abc123 \
           us-west1-docker.pkg.dev/airtrafik-ops/airtrafik-api:staging-latest
docker push us-west1-docker.pkg.dev/airtrafik-ops/airtrafik-api:staging-latest

# Deploy to staging
kubectl --context=staging set image deployment/api \
  api=us-west1-docker.pkg.dev/airtrafik-ops/airtrafik-api:abc123

# After validation, promote to prod
docker tag us-west1-docker.pkg.dev/airtrafik-ops/airtrafik-api:abc123 \
           us-west1-docker.pkg.dev/airtrafik-ops/airtrafik-api:v1.2.3
docker push us-west1-docker.pkg.dev/airtrafik-ops/airtrafik-api:v1.2.3

# Deploy to prod
kubectl --context=prod set image deployment/api \
  api=us-west1-docker.pkg.dev/airtrafik-ops/airtrafik-api:v1.2.3
```

### Recommended Tagging Strategy

- `{git-sha}` - Immutable reference (e.g., `abc123`)
- `dev-latest` - Latest build on main branch
- `staging-{date}` - Promoted to staging (e.g., `staging-2024-01-15`)
- `v{semver}` - Production releases (e.g., `v1.2.3`)
- `prod` - Current production version

## Adding a New Service

To add a new service (e.g., `scheduler`):

1. Edit `environments/ops/main.tf`
2. Add to the `repositories` map:

```hcl
repositories = {
  api = { ... }
  frontend = { ... }
  worker = { ... }
  scheduler = {  # NEW SERVICE
    description             = "Task scheduler Docker images"
    untagged_retention_days = 14
    dev_retention_days      = 60
    immutable_tags          = true
  }
}
```

3. Update outputs in `environments/ops/outputs.tf`:

```hcl
output "scheduler_repository_url" {
  description = "Full URL for scheduler repository"
  value       = module.artifact_registry.repositories["scheduler"]
}
```

4. Apply the changes:

```bash
cd environments/ops
terraform plan
terraform apply
```

5. Reference the new repository in environment outputs:

Update `environments/{dev,staging,prod}/outputs.tf`:

```hcl
output "scheduler_repository_url" {
  description = "Scheduler Docker repository URL"
  value       = try(data.terraform_remote_state.shared.outputs.scheduler_repository_url, "")
}
```

That's it! The new repository will automatically have IAM permissions for all environments.

## Image Retention & Cleanup Policies

Configured in `modules/artifact-registry/main.tf`:

### Keep Forever
- Tags starting with: `v`, `release`, `prod`
- These are never deleted

### Delete After 60 Days
- Tags starting with: `dev`, `test`, `feature`
- Keeps dev images from cluttering registry

### Delete After 14 Days
- Untagged images (dangling layers)
- Reduces storage costs

## Security & IAM

### Cross-Project Permissions

The shared registries in `airtrafik-ops` grant:

- **Reader access** to GKE service accounts from all environments (for pulling images)
- **Writer access** to CI service accounts from all environments (for pushing images)

### Service Account Usage

Each environment's GKE cluster uses Workload Identity:

```yaml
# Example Kubernetes deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
spec:
  template:
    spec:
      serviceAccountName: api-service-account  # Mapped to GKE SA via Workload Identity
      containers:
      - name: api
        image: us-west1-docker.pkg.dev/airtrafik-ops/airtrafik-api:v1.2.3
```

The GKE service account automatically has permission to pull from shared registries.

## Cost Optimization

### Single Registry Set
- **Before**: 3 environments × 1 registry = 3 registries
- **After**: 1 shared registry set = 3 repositories total
- **Savings**: ~66% reduction in registry resources

### Reduced Storage
- No duplicate images across environments
- Same image layers shared across all deployments
- Cleanup policies remove old dev/test images

## Troubleshooting

### Cannot Pull Images

Check IAM permissions:

```bash
gcloud artifacts repositories get-iam-policy airtrafik-api \
  --project=airtrafik-ops \
  --location=us-west1
```

Ensure your environment's GKE service account is listed with `roles/artifactregistry.reader`.

### Cannot Push Images

Check CI service account has write permissions:

```bash
gcloud artifacts repositories get-iam-policy airtrafik-api \
  --project=airtrafik-ops \
  --location=us-west1 \
  | grep "roles/artifactregistry.writer"
```

### Registry Not Found

Ensure ops environment is deployed:

```bash
cd environments/ops
terraform output
```

If empty, run `terraform apply`.

## Migration Notes

Since nothing has been deployed yet, there's no migration needed! You're starting with the correct architecture from day one.

## Summary

✅ **Shared registries** - One set for all environments
✅ **Build once** - Same image deployed everywhere
✅ **Easy to extend** - Add services in one place
✅ **Cost effective** - No duplicate images
✅ **Best practices** - Industry-standard CI/CD workflow

Repository URLs:
- API: `us-west1-docker.pkg.dev/airtrafik-ops/airtrafik-api`
- Frontend: `us-west1-docker.pkg.dev/airtrafik-ops/airtrafik-frontend`
- Worker: `us-west1-docker.pkg.dev/airtrafik-ops/airtrafik-worker`

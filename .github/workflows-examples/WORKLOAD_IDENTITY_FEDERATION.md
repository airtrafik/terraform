# Workload Identity Federation for GitHub Actions

This guide shows how to set up Workload Identity Federation (WIF) to authenticate GitHub Actions to Google Cloud without using service account keys.

## Why Use Workload Identity Federation?

**Security Benefits:**
- ✅ No long-lived service account keys to manage
- ✅ Automatic credential rotation
- ✅ Reduced risk of credential theft
- ✅ Better audit trail in Cloud Logging
- ✅ Follows Google Cloud best practices

**vs. Service Account Keys:**
- ❌ Keys can be stolen if leaked
- ❌ Keys must be manually rotated
- ❌ Keys are long-lived credentials
- ❌ Difficult to audit key usage

## Architecture

```
GitHub Actions Workflow
    ↓
GitHub OIDC Token
    ↓
Workload Identity Pool
    ↓
Workload Identity Provider
    ↓
Service Account Impersonation
    ↓
GCP Resources (Artifact Registry, GKE)
```

## Setup Instructions

### Option 1: Manual Setup (Quick Start)

#### Step 1: Create Workload Identity Pool

```bash
# Set variables
export PROJECT_ID="airtrafik-prod"  # Change to your project
export POOL_NAME="github-actions-pool"
export PROVIDER_NAME="github-provider"
export REPO="your-org/your-repo"  # e.g., "airtrafik/api-service"

# Create workload identity pool
gcloud iam workload-identity-pools create ${POOL_NAME} \
  --project=${PROJECT_ID} \
  --location=global \
  --display-name="GitHub Actions Pool"

# Get the pool ID
export POOL_ID=$(gcloud iam workload-identity-pools describe ${POOL_NAME} \
  --project=${PROJECT_ID} \
  --location=global \
  --format="value(name)")

echo "Pool ID: ${POOL_ID}"
```

#### Step 2: Create Workload Identity Provider

```bash
# Create the provider for GitHub Actions
gcloud iam workload-identity-pools providers create-oidc ${PROVIDER_NAME} \
  --project=${PROJECT_ID} \
  --location=global \
  --workload-identity-pool=${POOL_NAME} \
  --display-name="GitHub Provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" \
  --issuer-uri="https://token.actions.githubusercontent.com"

# Get the provider resource name
export PROVIDER_ID=$(gcloud iam workload-identity-pools providers describe ${PROVIDER_NAME} \
  --project=${PROJECT_ID} \
  --location=global \
  --workload-identity-pool=${POOL_NAME} \
  --format="value(name)")

echo "Provider ID: ${PROVIDER_ID}"
```

#### Step 3: Grant Service Account Access

```bash
# Get the CI service account email
export SA_EMAIL=$(cd ../environments/prod && terraform output -raw ci_cd_sa_email)

echo "Service Account: ${SA_EMAIL}"

# Allow the GitHub repo to impersonate the service account
gcloud iam service-accounts add-iam-policy-binding ${SA_EMAIL} \
  --project=${PROJECT_ID} \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/${POOL_ID}/attribute.repository/${REPO}"
```

#### Step 4: Get Configuration for GitHub

```bash
# Print the values needed for GitHub secrets
echo "================================"
echo "Add these to your GitHub secrets:"
echo "================================"
echo ""
echo "WIF_PROVIDER:"
echo "${PROVIDER_ID}"
echo ""
echo "WIF_SERVICE_ACCOUNT:"
echo "${SA_EMAIL}"
echo ""
```

#### Step 5: Update GitHub Repository Secrets

1. Go to your GitHub repository
2. Navigate to: Settings → Secrets and variables → Actions
3. Add new secrets:
   - `WIF_PROVIDER`: The provider ID from step 4
   - `WIF_SERVICE_ACCOUNT`: The service account email from step 4

#### Step 6: Update Workflow File

In your `.github/workflows/*.yml` file, replace the service account key authentication:

```yaml
# OLD (Service Account Key)
- name: Authenticate to Google Cloud
  uses: google-github-actions/auth@v2
  with:
    credentials_json: ${{ secrets.GCP_SA_KEY }}

# NEW (Workload Identity Federation)
- name: Authenticate to Google Cloud
  uses: google-github-actions/auth@v2
  with:
    workload_identity_provider: ${{ secrets.WIF_PROVIDER }}
    service_account: ${{ secrets.WIF_SERVICE_ACCOUNT }}
```

### Option 2: Terraform Module (Recommended for Production)

Create a Terraform module to manage Workload Identity Federation:

#### Create Module File

`modules/github-wif/main.tf`:

```hcl
resource "google_iam_workload_identity_pool" "github" {
  project                   = var.project_id
  workload_identity_pool_id = var.pool_id
  display_name              = var.pool_display_name
  description               = "Workload Identity Pool for GitHub Actions"
}

resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = var.provider_id
  display_name                       = var.provider_display_name
  description                        = "OIDC provider for GitHub Actions"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account_iam_member" "workload_identity_binding" {
  for_each = toset(var.github_repositories)

  service_account_id = var.service_account_email
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${each.value}"
}
```

`modules/github-wif/variables.tf`:

```hcl
variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "pool_id" {
  description = "Workload Identity Pool ID"
  type        = string
  default     = "github-actions-pool"
}

variable "pool_display_name" {
  description = "Display name for the pool"
  type        = string
  default     = "GitHub Actions"
}

variable "provider_id" {
  description = "Workload Identity Provider ID"
  type        = string
  default     = "github-provider"
}

variable "provider_display_name" {
  description = "Display name for the provider"
  type        = string
  default     = "GitHub OIDC Provider"
}

variable "service_account_email" {
  description = "Service account email to grant access to"
  type        = string
}

variable "github_repositories" {
  description = "List of GitHub repositories (format: org/repo)"
  type        = list(string)
}
```

`modules/github-wif/outputs.tf`:

```hcl
output "provider_name" {
  description = "Full provider name for GitHub secrets"
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "workload_identity_pool_id" {
  description = "Workload Identity Pool ID"
  value       = google_iam_workload_identity_pool.github.workload_identity_pool_id
}
```

#### Use in Environment Configuration

Add to `environments/prod/main.tf` (or create `environments/shared/github-wif.tf`):

```hcl
module "github_wif" {
  source = "../../modules/github-wif"

  project_id            = var.project_id
  service_account_email = module.iam.ci_cd_sa_email

  github_repositories = [
    "airtrafik/api-service",
    "airtrafik/frontend-app",
    "airtrafik/worker-service"
  ]
}

output "github_wif_provider" {
  description = "Workload Identity Provider for GitHub Actions"
  value       = module.github_wif.provider_name
  sensitive   = false
}
```

## Testing Workload Identity Federation

### Test Authentication

Create a test workflow in your repository:

```yaml
name: Test WIF Authentication

on:
  workflow_dispatch:

jobs:
  test:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write  # Required for OIDC

    steps:
      - name: Authenticate to Google Cloud
        uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: ${{ secrets.WIF_PROVIDER }}
          service_account: ${{ secrets.WIF_SERVICE_ACCOUNT }}

      - name: Test GCP Access
        run: |
          gcloud config list
          gcloud projects describe airtrafik-prod
          gcloud artifacts repositories list --project=airtrafik-prod --location=us-west1
```

Run the workflow manually and verify it completes successfully.

## Security Best Practices

### 1. Limit Repository Access

Only grant access to specific repositories:

```bash
# Specific repo
--member="principalSet://iam.googleapis.com/${POOL_ID}/attribute.repository/airtrafik/api-service"

# Specific org (all repos)
--member="principalSet://iam.googleapis.com/${POOL_ID}/attribute.repository_owner/airtrafik"
```

### 2. Add Branch Conditions

Restrict to specific branches:

```bash
# Only main branch
--attribute-condition="assertion.sub.startsWith('repo:airtrafik/api-service:ref:refs/heads/main')"

# Only tags
--attribute-condition="assertion.sub.startsWith('repo:airtrafik/api-service:ref:refs/tags/')"
```

### 3. Use Separate Pools per Environment

Create different pools for dev/staging/prod:

```bash
# Dev pool - more permissive
gcloud iam workload-identity-pools create github-actions-dev

# Prod pool - restricted
gcloud iam workload-identity-pools create github-actions-prod \
  --attribute-condition="assertion.ref=='refs/heads/main'"
```

### 4. Audit Access

Monitor usage in Cloud Logging:

```bash
# View authentication logs
gcloud logging read "resource.type=iam_service_account AND protoPayload.authenticationInfo.principalEmail=${SA_EMAIL}" \
  --limit 50 \
  --format json
```

## Troubleshooting

### Error: "Failed to generate Google Cloud access token"

**Cause:** Workflow doesn't have `id-token: write` permission

**Fix:** Add to workflow:
```yaml
permissions:
  contents: read
  id-token: write
```

### Error: "Permission denied on service account"

**Cause:** Service account doesn't have workloadIdentityUser binding

**Fix:** Re-run step 3 to grant access

### Error: "Invalid identity token"

**Cause:** Repository name mismatch

**Fix:** Verify repository name in the binding:
```bash
gcloud iam service-accounts get-iam-policy ${SA_EMAIL}
```

### Error: "Workload identity pool does not exist"

**Cause:** Pool not created or wrong project

**Fix:** Verify pool exists:
```bash
gcloud iam workload-identity-pools list --project=${PROJECT_ID} --location=global
```

## Migration from Service Account Keys

If you're currently using service account keys:

1. Set up WIF (follow steps above)
2. Test WIF with a non-critical workflow
3. Update all workflows to use WIF
4. Delete service account keys:
   ```bash
   gcloud iam service-accounts keys list --iam-account=${SA_EMAIL}
   gcloud iam service-accounts keys delete KEY_ID --iam-account=${SA_EMAIL}
   ```
5. Remove `GCP_SA_KEY` from GitHub secrets

## Resources

- [Google Cloud Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation)
- [GitHub OIDC Documentation](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
- [google-github-actions/auth](https://github.com/google-github-actions/auth)

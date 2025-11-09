# GitHub Actions CI/CD Guide

Complete guide for setting up GitHub Actions with the AirTrafik infrastructure.

## Overview

This infrastructure is designed to work with **GitHub Actions** for CI/CD. Each service repository builds Docker images and pushes them to the **shared Artifact Registry**, then deploys to GKE.

### Architecture

```
Service Repository (GitHub)
    ↓
GitHub Actions Workflow
    ↓
Build Docker Image
    ↓
Push to Shared Registry (airtrafik-ops)
    ├─ airtrafik-api
    ├─ airtrafik-frontend
    └─ airtrafik-worker
    ↓
Deploy to GKE
    ├─ dev (auto on main)
    ├─ staging (auto on tag)
    └─ prod (manual approval)
```

## Quick Start

### 1. Get Workflow Examples

Workflow templates are in `.github/workflows-examples/`:

- **build-and-push.yml** - Build and push images
- **deploy-to-gke.yml** - Deploy to GKE
- **full-cicd.yml** - Complete CI/CD pipeline

Copy the appropriate workflow to your service repository at `.github/workflows/`.

### 2. Set Up Authentication

Choose one:

**Option A: Service Account Key** (Simpler, less secure)
```bash
# Get the service account email
cd environments/dev
terraform output ci_cd_sa_email

# Create key
gcloud iam service-accounts keys create key.json \
  --iam-account=<email-from-output>

# Add to GitHub secrets as GCP_SA_KEY (base64 encoded)
base64 key.json | gh secret set GCP_SA_KEY
```

**Option B: Workload Identity Federation** (Recommended)

See `.github/workflows-examples/WORKLOAD_IDENTITY_FEDERATION.md` for setup.

### 3. Update Workflow Configuration

Edit the copied workflow file:

```yaml
env:
  SERVICE_NAME: api  # Change to your service: frontend, worker, etc.
```

### 4. Test the Workflow

```bash
git add .github/workflows/
git commit -m "Add GitHub Actions workflow"
git push origin main
```

Check the Actions tab in GitHub to see the workflow run.

## Authentication Options

### Service Account Key (Quick Setup)

**Pros:**
- Simple to set up
- Works immediately
- No additional GCP configuration

**Cons:**
- Security risk if leaked
- Manual rotation required
- Long-lived credentials

**Setup:**

1. Create service account key:
   ```bash
   gcloud iam service-accounts keys create key.json \
     --iam-account=$(cd environments/dev && terraform output -raw ci_cd_sa_email)

   base64 -w 0 key.json > key.json.b64
   ```

2. Add to GitHub secrets:
   - Secret name: `GCP_SA_KEY`
   - Value: Contents of `key.json.b64`

3. Delete local files:
   ```bash
   rm key.json key.json.b64
   ```

4. Use in workflow:
   ```yaml
   - uses: google-github-actions/auth@v2
     with:
       credentials_json: ${{ secrets.GCP_SA_KEY }}
   ```

### Workload Identity Federation (Production Setup)

**Pros:**
- No long-lived keys
- Automatic rotation
- Better security
- Audit trail

**Cons:**
- More complex setup
- Requires additional GCP resources

**Setup:**

See `.github/workflows-examples/WORKLOAD_IDENTITY_FEDERATION.md` for detailed instructions.

## Workflow Configuration

### Service Name

Update the `SERVICE_NAME` to match your repository:

```yaml
env:
  SERVICE_NAME: api  # Must match Artifact Registry repository
```

Available services (from `environments/ops/main.tf`):
- `api`
- `frontend`
- `worker`

### Adding a New Service

If you're creating a new service not in the list:

1. Update `environments/ops/terraform.tfvars`:
   ```hcl
   services = [
     "api",
     "frontend",
     "worker",
     "new-service"  # ADD THIS - just one line!
   ]
   ```

2. Apply changes:
   ```bash
   cd environments/ops
   terraform apply
   ```

3. Use the new service name in your workflow:
   ```yaml
   env:
     SERVICE_NAME: new-service
   ```

The repository will be automatically created with sensible defaults.

## Image Tagging Strategy

The workflows automatically tag images based on the git ref:

### Main Branch
```
Commit to main
  ↓
Tags: {git-sha}, dev-latest
  ↓
Auto-deploy to dev
```

### Version Tag
```
Create tag v1.2.3
  ↓
Tags: {git-sha}, v1.2.3
  ↓
Auto-deploy to staging
  ↓
Manual approval
  ↓
Deploy to prod
  ↓
Additional tag: prod
```

### Feature Branch
```
Commit to feature/new-thing
  ↓
Tags: {git-sha}, feature-new-thing
  ↓
Available for manual deployment
```

## Deployment Workflow

### Development Deployment

**Trigger:** Push to `main` branch

```yaml
on:
  push:
    branches:
      - main
```

**Flow:**
1. Run tests
2. Build image with tags: `{sha}`, `dev-latest`
3. Push to Artifact Registry
4. Auto-deploy to dev environment

### Staging Deployment

**Trigger:** Create version tag (e.g., `v1.2.3`)

```yaml
on:
  push:
    tags:
      - 'v*'
```

**Flow:**
1. Run tests
2. Build image with tags: `{sha}`, `v1.2.3`
3. Push to Artifact Registry
4. Auto-deploy to staging environment

### Production Deployment

**Trigger:** Manual approval after staging deployment

**Flow:**
1. Previous: Staging deployment succeeded
2. Manual approval in GitHub
3. Deploy same image from staging
4. Tag image with `prod`

**Setup GitHub Environment Protection:**

1. Go to repository Settings → Environments
2. Create `production` environment
3. Add required reviewers
4. Add deployment branch rule: `v*`

## Example Workflows

### Simple Build and Push

For services that don't need automated deployment:

```yaml
name: Build Image

on:
  push:
    branches: [main]

env:
  SERVICE_NAME: api

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: google-github-actions/auth@v2
        with:
          credentials_json: ${{ secrets.GCP_SA_KEY }}
      - uses: google-github-actions/setup-gcloud@v2
      - run: |
          gcloud auth configure-docker us-west1-docker.pkg.dev
          docker build -t us-west1-docker.pkg.dev/airtrafik-ops/airtrafik-${{ env.SERVICE_NAME }}:$(git rev-parse --short HEAD) .
          docker push us-west1-docker.pkg.dev/airtrafik-ops/airtrafik-${{ env.SERVICE_NAME }}:$(git rev-parse --short HEAD)
```

### Full CI/CD Pipeline

See `.github/workflows-examples/full-cicd.yml` for a complete example with:
- Testing
- Building
- Multi-environment deployment
- Manual approval for production

## Environment Variables and Secrets

### Required Secrets

Add to repository Settings → Secrets and variables → Actions:

**For Service Account Key:**
- `GCP_SA_KEY` - Base64-encoded service account key JSON

**For Workload Identity Federation:**
- `WIF_PROVIDER` - Workload Identity Provider resource name
- `WIF_SERVICE_ACCOUNT` - Service account email

### Optional Secrets

Add environment-specific variables:

```yaml
- name: Deploy
  env:
    DATABASE_URL: ${{ secrets.DATABASE_URL }}
    REDIS_URL: ${{ secrets.REDIS_URL }}
    API_KEY: ${{ secrets.API_KEY }}
```

### Environment Variables from Terraform

Get values from Terraform outputs:

```bash
cd environments/dev
terraform output -json > outputs.json
```

Use in your application configuration:
- `cloudsql_connection_name` - Database connection
- `valkey_host` - Redis cache host
- `api_repository_url` - Docker image URL

## Deployment Commands

### Manual Deployment

Deploy a specific image to an environment:

```bash
# Get credentials
gcloud container clusters get-credentials airtrafik-gke-dev \
  --region=us-west1 \
  --project=airtrafik-dev

# Deploy image
kubectl set image deployment/api \
  api=us-west1-docker.pkg.dev/airtrafik-ops/airtrafik-api:abc123 \
  -n default

# Watch rollout
kubectl rollout status deployment/api -n default
```

### Rollback Deployment

```bash
# Rollback to previous version
kubectl rollout undo deployment/api -n default

# Rollback to specific revision
kubectl rollout undo deployment/api --to-revision=2 -n default
```

### View Deployment History

```bash
kubectl rollout history deployment/api -n default
```

## Monitoring Deployments

### Check Pod Status

```bash
kubectl get pods -l app=api -n default
kubectl describe pod <pod-name> -n default
kubectl logs <pod-name> -n default
```

### Check Deployment Status

```bash
kubectl get deployment api -n default
kubectl describe deployment api -n default
```

### Check Events

```bash
kubectl get events -n default --sort-by='.lastTimestamp'
```

## Troubleshooting

### Build Fails: "Authentication failed"

**Cause:** Invalid or missing GCP credentials

**Fix:**
1. Verify `GCP_SA_KEY` secret is set correctly
2. Check secret is base64-encoded
3. Verify service account has `artifactregistry.writer` role

```bash
# Check service account roles
gcloud projects get-iam-policy airtrafik-prod \
  --flatten="bindings[].members" \
  --filter="bindings.members:<sa-email>"
```

### Push Fails: "Permission denied"

**Cause:** Service account doesn't have access to registry

**Fix:**
```bash
# Grant access
gcloud artifacts repositories add-iam-policy-binding airtrafik-api \
  --project=airtrafik-ops \
  --location=us-west1 \
  --member="serviceAccount:<sa-email>" \
  --role="roles/artifactregistry.writer"
```

### Deploy Fails: "deployment not found"

**Cause:** Kubernetes deployment doesn't exist yet

**Fix:** Create the deployment first:
```bash
kubectl create deployment api \
  --image=us-west1-docker.pkg.dev/airtrafik-ops/airtrafik-api:latest \
  -n default
```

Or use Helm charts (recommended).

### Rollout Timeout

**Cause:** New pods failing to start

**Fix:**
```bash
# Check pod events
kubectl describe pod <pod-name> -n default

# Check logs
kubectl logs <pod-name> -n default

# Common issues:
# - Image pull errors
# - Application startup errors
# - Health check failures
```

## Best Practices

### 1. Use Workload Identity Federation

More secure than service account keys.

### 2. Implement Environment Protection

Require manual approval for production deployments.

### 3. Tag Releases Properly

Use semantic versioning for tags:
```bash
git tag -a v1.2.3 -m "Release version 1.2.3"
git push origin v1.2.3
```

### 4. Include Health Checks

Add health check endpoints to your services:
```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10
```

### 5. Monitor Deployments

Use GitHub Actions job summaries and notifications:
```yaml
- name: Notify on failure
  if: failure()
  run: |
    curl -X POST ${{ secrets.SLACK_WEBHOOK }} \
      -d '{"text":"Deployment failed!"}'
```

### 6. Scan Images for Vulnerabilities

Add security scanning before push:
```yaml
- name: Scan image
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: ${{ env.IMAGE_URL }}
    format: 'sarif'
    output: 'trivy-results.sarif'
```

### 7. Use Build Cache

Speed up builds with Docker layer caching:
```yaml
- name: Build with cache
  uses: docker/build-push-action@v5
  with:
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

## Advanced Configuration

### Multi-stage Deployments

Deploy to multiple environments sequentially:

```yaml
jobs:
  deploy-dev:
    runs-on: ubuntu-latest
    # Deploy to dev

  deploy-staging:
    needs: deploy-dev
    runs-on: ubuntu-latest
    # Deploy to staging

  deploy-prod:
    needs: deploy-staging
    environment: production
    runs-on: ubuntu-latest
    # Deploy to prod
```

### Canary Deployments

Deploy to a subset of pods first:

```yaml
- name: Canary deployment
  run: |
    # Deploy canary version (10% traffic)
    kubectl set image deployment/api-canary \
      api=${{ env.IMAGE_URL }}

    # Wait and monitor metrics
    sleep 300

    # If metrics good, deploy to main
    kubectl set image deployment/api \
      api=${{ env.IMAGE_URL }}
```

### Database Migrations

Run migrations before deployment:

```yaml
- name: Run migrations
  run: |
    kubectl run migration-${{ github.sha }} \
      --image=${{ env.IMAGE_URL }} \
      --restart=Never \
      --command -- npm run migrate

    kubectl wait --for=condition=complete job/migration-${{ github.sha }} \
      --timeout=300s
```

## Getting Help

### Resources
- [Workflow Examples](.github/workflows-examples/README.md)
- [Workload Identity Federation](.github/workflows-examples/WORKLOAD_IDENTITY_FEDERATION.md)
- [Deployment Workflow](DEPLOYMENT_WORKFLOW.md)

### Common Commands

```bash
# View service account
terraform output -raw ci_cd_sa_email

# View registry URLs
terraform output api_repository_url

# Test docker push
gcloud auth configure-docker us-west1-docker.pkg.dev
docker push us-west1-docker.pkg.dev/airtrafik-ops/airtrafik-api:test

# Test kubectl access
kubectl get deployments -n default
```

### Support

For issues with:
- **Terraform**: See main README.md
- **GCP Access**: Check service account IAM roles
- **GitHub Actions**: Check workflow logs in Actions tab
- **Kubernetes**: Check pod logs and events

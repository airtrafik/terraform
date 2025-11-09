# GitHub Actions Workflow Examples

This directory contains example GitHub Actions workflows for CI/CD with the AirTrafik infrastructure.

## Workflows Available

### 1. `build-and-push.yml` - Build and Push Docker Images
Builds Docker images and pushes them to the shared Artifact Registry.

**When to use:** Simple build pipeline, separate deployment workflow

**Features:**
- Multi-tagging strategy based on branch/tag
- Automatic tag generation from git SHA
- Support for service account key or Workload Identity authentication

### 2. `deploy-to-gke.yml` - Deploy to GKE
Deploys a pre-built image to GKE cluster.

**When to use:** Manual deployments, deployment after build

**Features:**
- Manual deployment with workflow_dispatch
- Auto-deployment after successful build
- Environment selection (dev/staging/prod)
- Rollout verification

### 3. `full-cicd.yml` - Complete CI/CD Pipeline
Complete pipeline with testing, building, and multi-environment deployment.

**When to use:** Production-ready CI/CD setup

**Features:**
- Run tests on PR and main branch
- Build and deploy to dev on main branch merge
- Build and deploy to staging on version tag
- Manual approval for production deployment
- Progressive rollout through environments

## Setup Instructions

### Step 1: Choose Authentication Method

#### Option A: Service Account Key (Simpler)

1. Get the service account email from Terraform outputs:
   ```bash
   cd environments/dev  # or staging/prod
   terraform output ci_cd_sa_email
   ```

2. Create and download a service account key:
   ```bash
   gcloud iam service-accounts keys create key.json \
     --iam-account=<sa-email-from-step-1>

   # Base64 encode it for GitHub
   base64 key.json > key.json.b64
   ```

3. Add to GitHub repository secrets:
   - Go to repository Settings → Secrets and variables → Actions
   - Create secret: `GCP_SA_KEY` with the base64-encoded content

4. **Delete the local key file** (security best practice):
   ```bash
   rm key.json key.json.b64
   ```

#### Option B: Workload Identity Federation (Recommended for production)

See `WORKLOAD_IDENTITY_FEDERATION.md` for setup instructions.

**Benefits:**
- No long-lived service account keys
- Automatic token rotation
- Better security posture
- Audit trail in GCP

### Step 2: Copy Workflow to Your Service Repository

1. Choose the workflow that fits your needs
2. Copy to your service repository at `.github/workflows/`
3. Update the `SERVICE_NAME` environment variable:
   ```yaml
   env:
     SERVICE_NAME: api  # Change to: frontend, worker, etc.
   ```

### Step 3: Configure GitHub Environments (Optional)

For production deployments with manual approval:

1. Go to repository Settings → Environments
2. Create environments: `dev`, `staging`, `production`
3. For `production` environment:
   - Add required reviewers
   - Add deployment branch rule (only `v*` tags)

### Step 4: Test the Workflow

1. Make a commit to a feature branch
2. Push to GitHub
3. Check Actions tab to see the workflow run

## Image Tagging Strategy

The workflows use the following tagging strategy:

### Branch-based Tags
- `main` branch → `dev-latest`, `{git-sha}`
- `develop` branch → `develop`, `{git-sha}`
- `feature/*` branch → `feature-{name}`, `{git-sha}`

### Version Tags
- `v*` tags → `{version}`, `staging-{version}`, `{git-sha}`
- Production deployment → Also tagged with `prod`

### Always Included
- `{git-sha}` - Short commit SHA (immutable reference)

## Shared Registry URLs

All services push to shared registries:
```
us-west1-docker.pkg.dev/airtrafik-ops/airtrafik-{service}
```

Where `{service}` is: `api`, `frontend`, `worker`, etc.

## Customization

### Update Service Name
Change the `SERVICE_NAME` environment variable at the top of the workflow:
```yaml
env:
  SERVICE_NAME: your-service-name
```

### Change Testing Commands
Update the test job steps based on your language/framework:
```yaml
- name: Run tests
  run: npm test  # or: pytest, go test, cargo test, etc.
```

### Modify Deployment Strategy
Adjust the deployment jobs to match your needs:
- Add smoke tests after deployment
- Add Slack/Discord notifications
- Add database migrations
- Add health checks

### Add Environment Variables
Use GitHub Secrets for environment-specific configuration:
```yaml
- name: Deploy
  env:
    DATABASE_URL: ${{ secrets.DATABASE_URL }}
    API_KEY: ${{ secrets.API_KEY }}
```

## Deployment Flow Examples

### Development Flow
```
1. Commit to main branch
2. Tests run
3. Docker image built and tagged: {sha}, dev-latest
4. Auto-deploy to dev environment
```

### Staging/Production Flow
```
1. Create version tag (e.g., v1.2.3)
2. Tests run
3. Docker image built and tagged: {sha}, v1.2.3
4. Auto-deploy to staging environment
5. Manual approval required
6. Deploy to production
7. Tag image with 'prod'
```

### Hotfix Flow
```
1. Create hotfix branch from prod tag
2. Commit fix
3. Create new version tag (e.g., v1.2.4)
4. Follow staging/production flow above
```

## Monitoring Deployments

### Check Deployment Status
```bash
kubectl get deployment <service-name> -n <namespace>
kubectl rollout status deployment/<service-name> -n <namespace>
```

### View Deployment History
```bash
kubectl rollout history deployment/<service-name> -n <namespace>
```

### Rollback if Needed
```bash
kubectl rollout undo deployment/<service-name> -n <namespace>
```

## Troubleshooting

### Authentication Errors
- Verify service account has `roles/artifactregistry.writer`
- Check that the secret is properly base64-encoded
- Ensure service account key hasn't expired

### Image Push Failures
- Verify registry project ID is correct (`airtrafik-ops`)
- Check service name matches registry name
- Ensure `gcloud auth configure-docker` was called

### Deployment Failures
- Check GKE cluster credentials are correct
- Verify deployment name matches service name
- Check namespace exists in cluster
- Review deployment logs: `kubectl logs deployment/<service-name>`

### Workflow Not Triggering
- Check branch protection rules
- Verify workflow file is in `.github/workflows/`
- Check workflow file YAML syntax
- Review GitHub Actions tab for errors

## Security Best Practices

1. **Use Workload Identity Federation** instead of service account keys
2. **Rotate service account keys** regularly (if using keys)
3. **Use GitHub Environments** for production deployments
4. **Require manual approval** for production
5. **Enable branch protection** on main branch
6. **Use signed commits** for production releases
7. **Scan images** for vulnerabilities before deploying
8. **Limit secret access** to necessary workflows only

## Next Steps

1. Set up Workload Identity Federation (see `WORKLOAD_IDENTITY_FEDERATION.md`)
2. Configure GitHub Environments with protection rules
3. Add vulnerability scanning to workflows
4. Set up notification integrations (Slack, Discord, etc.)
5. Implement automated rollback on failure
6. Add performance testing in staging environment

## Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Google Cloud Auth Action](https://github.com/google-github-actions/auth)
- [GKE Auth Plugin](https://cloud.google.com/blog/products/containers-kubernetes/kubectl-auth-changes-in-gke)
- [Artifact Registry Documentation](https://cloud.google.com/artifact-registry/docs)
- [Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation)

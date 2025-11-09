# AirTrafik Terraform Infrastructure

This repository contains Terraform configurations for deploying AirTrafik infrastructure on Google Cloud Platform (GCP).

## Architecture Overview

The infrastructure includes:
- **GKE** - Kubernetes cluster for running containerized applications
- **Cloud SQL** - Managed PostgreSQL database
- **Memorystore** - Managed Valkey (Redis-compatible) cache
- **Artifact Registry** - Docker container registry
- **Cloud Storage** - Object storage for uploads and backups
- **VPC** - Custom network with private subnets

## Repository Structure

```
terraform/
├── modules/           # Reusable Terraform modules
│   ├── vpc/          # Network configuration
│   ├── gke/          # Kubernetes cluster
│   ├── cloudsql/     # PostgreSQL database
│   ├── memorystore/  # Valkey cache
│   ├── artifact-registry/  # Container registry (shared across environments)
│   ├── gcs/          # Storage buckets
│   └── iam/          # Service accounts
├── environments/      # Environment-specific configurations
│   ├── shared/       # Shared resources (artifact registries)
│   ├── dev/          # Development environment
│   ├── staging/      # Staging environment
│   └── prod/         # Production environment
└── scripts/          # Helper scripts
```

## Artifact Registry Architecture

**Important**: Artifact registries are **shared across all environments** to follow the "build once, deploy many" best practice:

- ✅ One repository per service (api, frontend, worker)
- ✅ Same Docker image deployed to dev → staging → prod
- ✅ No environment-specific image rebuilds
- ✅ Easy to add new services

See [DEPLOYMENT_WORKFLOW.md](./DEPLOYMENT_WORKFLOW.md) for detailed deployment instructions.

## Prerequisites

1. **GCP Project Setup**
   - Create GCP projects:
     - `airtrafik-dev` - Development environment
     - `airtrafik-staging` - Staging environment
     - `airtrafik-prod` - Production environment
     - `airtrafik-ops` - Operational infrastructure (Terraform state, artifact registries, telemetry)
   - Enable required APIs in all projects:
     ```bash
     gcloud services enable compute.googleapis.com
     gcloud services enable container.googleapis.com
     gcloud services enable sqladmin.googleapis.com
     gcloud services enable redis.googleapis.com
     gcloud services enable artifactregistry.googleapis.com
     gcloud services enable secretmanager.googleapis.com
     gcloud services enable servicenetworking.googleapis.com
     ```

2. **Terraform Setup**
   - Install Terraform >= 1.5.0
   - Install gcloud CLI and authenticate:
     ```bash
     gcloud auth application-default login
     ```

3. **Create State Bucket** (first time only)

   The Terraform state bucket is hosted in the `airtrafik-ops` project for centralized state management:

   ```bash
   gsutil mb -p airtrafik-ops gs://airtrafik-terraform-state
   gsutil versioning set on gs://airtrafik-terraform-state
   ```

## Deployment Instructions

**⚠️ IMPORTANT**: Follow the deployment order in [DEPLOYMENT_WORKFLOW.md](./DEPLOYMENT_WORKFLOW.md)

### Quick Start

1. **Deploy all environments** (dev, staging, prod) to create service accounts
2. **Update shared configuration** with service account emails
3. **Deploy shared registries** with cross-project IAM
4. **Verify** registry access from all environments

### Detailed Steps

See [DEPLOYMENT_WORKFLOW.md](./DEPLOYMENT_WORKFLOW.md) for:
- Complete deployment order
- Service account configuration
- CI/CD image workflow
- Adding new services
- Troubleshooting

### First-Time Setup (State Bucket)

Create the Terraform state bucket first:

```bash
cd environments/dev
# Edit terraform.tfvars and set:
# create_state_bucket = true
# project_id = "your-actual-project-id"

terraform init
terraform plan
terraform apply
```

After the state bucket is created, set `create_state_bucket = false` in terraform.tfvars.

## Environment Configurations

### Development
- **Cost-optimized**: Uses preemptible nodes, minimal resources
- **GKE**: n2-standard-2 nodes (1-3 nodes)
- **Database**: db-f1-micro, no HA
- **Valkey**: 1GB Basic tier
- **Estimated cost**: ~$268/month

### Staging
- **Pre-production testing**: Better resources, similar to production
- **GKE**: n2-standard-4 nodes (2-4 nodes)
- **Database**: db-g1-small, no HA
- **Valkey**: 2GB Basic tier
- **Estimated cost**: ~$450/month

### Production
- **High availability**: Full HA, auto-scaling, backups
- **GKE**: n2-standard-4 nodes (3-10 nodes), auto-scaling enabled
- **Database**: db-n1-standard-2, HA enabled
- **Valkey**: 5GB Standard HA tier
- **Estimated cost**: ~$1200/month

## Connecting to GKE Cluster

After deployment, configure kubectl:

```bash
gcloud container clusters get-credentials airtrafik-gke-dev \
  --region us-west1 \
  --project airtrafik-dev
```

## Important Outputs

The Terraform configurations output values needed for Helm deployments:

- `gke_cluster_name` - Kubernetes cluster name
- `cloudsql_connection_name` - For Cloud SQL proxy
- `cloudsql_private_ip` - Database private IP
- `valkey_host` - Cache host address
- `artifact_registry_base_url` - Shared registry base URL
- `api_repository_url` - API service Docker repository
- `frontend_repository_url` - Frontend Docker repository
- `worker_repository_url` - Worker Docker repository
- `database_password_secret_id` - Secret Manager reference
- Service account emails for Workload Identity

### Shared Registry URLs

All environments use the same registries (hosted in ops project):
- API: `us-west1-docker.pkg.dev/airtrafik-ops/airtrafik-api`
- Frontend: `us-west1-docker.pkg.dev/airtrafik-ops/airtrafik-frontend`
- Worker: `us-west1-docker.pkg.dev/airtrafik-ops/airtrafik-worker`

## Security Considerations

1. **Private Infrastructure**
   - All resources use private IPs
   - GKE nodes are private
   - Cloud NAT for outbound traffic

2. **Secrets Management**
   - Database passwords in Secret Manager
   - Valkey auth strings in Secret Manager
   - Workload Identity for pod authentication

3. **Network Security**
   - Custom VPC with isolated subnets
   - Firewall rules restrict internal traffic
   - Private service connections for managed services

## Maintenance

### Updating Kubernetes Version

```bash
# Update kubernetes_version_prefix in terraform.tfvars
kubernetes_version_prefix = "1.30."

# Apply changes
terraform plan
terraform apply
```

### Scaling Resources

Edit the appropriate `terraform.tfvars` file:

```hcl
# Increase node count
gke_app_min_nodes = 5
gke_app_max_nodes = 15

# Upgrade database
db_tier = "db-n1-standard-4"
```

### Destroying Infrastructure

**WARNING**: This will delete all resources and data!

```bash
cd environments/dev
terraform destroy
```

## Troubleshooting

### State Lock Issues
```bash
terraform force-unlock <lock-id>
```

### API Not Enabled Errors
Enable the required API:
```bash
gcloud services enable <api-name>
```

### Network Quota Issues
Check and request quota increases:
```bash
gcloud compute project-info describe --project=<project-id>
```

## Cost Optimization

1. **Development**: Use preemptible nodes and minimal resources
2. **Off-hours scaling**: Implement GKE node pool schedules
3. **Untagged image cleanup**: Configured in Artifact Registry
4. **Lifecycle policies**: Automatic deletion of old backups/uploads

## CI/CD with GitHub Actions

This infrastructure is designed to work with **GitHub Actions** for building and deploying services.

### Quick Start
1. Copy workflow templates from `.github/workflows-examples/` to your service repository
2. Set up authentication (see [GITHUB_ACTIONS.md](./GITHUB_ACTIONS.md))
3. Update `SERVICE_NAME` in the workflow to match your service
4. Push to trigger the workflow

### Available Workflows
- **build-and-push.yml** - Build and push Docker images to shared registries
- **deploy-to-gke.yml** - Deploy to GKE environments
- **full-cicd.yml** - Complete CI/CD pipeline with testing and deployment

### Authentication Options
- **Service Account Key** - Simple setup, less secure (good for testing)
- **Workload Identity Federation** - Recommended for production (no long-lived keys)

See [GITHUB_ACTIONS.md](./GITHUB_ACTIONS.md) for complete setup instructions.

## Next Steps

After infrastructure is deployed:

1. **Set up CI/CD**: Configure GitHub Actions (see [GITHUB_ACTIONS.md](./GITHUB_ACTIONS.md))
2. **Deploy applications**: Install Helm charts or use kubectl
3. **Configure ingress**: Set up ingress controllers and load balancers
4. **Setup monitoring**: Install Prometheus/Grafana or use Cloud Monitoring
5. **Setup DNS and SSL**: Configure domains and certificates

## Support

For issues or questions, create an issue in the GitHub repository or contact the infrastructure team.
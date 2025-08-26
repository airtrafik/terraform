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
│   ├── artifact-registry/  # Container registry
│   ├── gcs/          # Storage buckets
│   └── iam/          # Service accounts
├── environments/      # Environment-specific configurations
│   ├── dev/          # Development environment
│   ├── staging/      # Staging environment
│   └── prod/         # Production environment
└── scripts/          # Helper scripts
```

## Prerequisites

1. **GCP Project Setup**
   - Create GCP projects: `airtrafik-dev`, `airtrafik-staging`, `airtrafik-prod`
   - Enable required APIs:
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
   ```bash
   gsutil mb -p airtrafik-dev gs://airtrafik-terraform-state
   gsutil versioning set on gs://airtrafik-terraform-state
   ```

## Deployment Instructions

### 1. First-Time Setup

For the initial deployment, you need to create the state bucket:

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

### 2. Deploy Development Environment

```bash
cd environments/dev

# Initialize Terraform
terraform init

# Review planned changes
terraform plan

# Apply infrastructure
terraform apply

# Get outputs for Helm configuration
terraform output -json > outputs.json
```

### 3. Deploy Staging Environment

```bash
cd environments/staging

# Update terraform.tfvars with your project ID
terraform init
terraform plan
terraform apply
```

### 4. Deploy Production Environment

```bash
cd environments/prod

# Update terraform.tfvars with your project ID
# Review all settings carefully
terraform init
terraform plan
terraform apply
```

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
- `artifact_registry_url` - Docker registry URL
- `database_password_secret_id` - Secret Manager reference
- Service account emails for Workload Identity

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

## Next Steps

After infrastructure is deployed:

1. Install Helm charts for applications
2. Configure ingress controllers
3. Setup monitoring (Prometheus/Grafana)
4. Configure CI/CD pipelines
5. Setup DNS and SSL certificates

## Support

For issues or questions, create an issue in the GitHub repository or contact the infrastructure team.
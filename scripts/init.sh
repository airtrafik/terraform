#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}AirTrafik Terraform Infrastructure Setup${NC}"
echo "=========================================="

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}Error: gcloud CLI is not installed${NC}"
    echo "Please install it from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Error: Terraform is not installed${NC}"
    echo "Please install it from: https://www.terraform.io/downloads"
    exit 1
fi

# Get environment
read -p "Enter environment (dev/staging/prod/shared/ops): " ENV
if [[ ! "$ENV" =~ ^(dev|staging|prod|shared|ops)$ ]]; then
    echo -e "${RED}Invalid environment. Must be dev, staging, prod, shared, or ops${NC}"
    exit 1
fi

# Get project ID
read -p "Enter GCP project ID for $ENV: " PROJECT_ID

echo -e "\n${YELLOW}Setting up project: $PROJECT_ID${NC}"

# Set the project
gcloud config set project $PROJECT_ID

# Enable required APIs
echo -e "\n${YELLOW}Enabling required APIs...${NC}"
gcloud services enable compute.googleapis.com \
    container.googleapis.com \
    sqladmin.googleapis.com \
    redis.googleapis.com \
    artifactregistry.googleapis.com \
    secretmanager.googleapis.com \
    servicenetworking.googleapis.com \
    cloudresourcemanager.googleapis.com \
    iam.googleapis.com

echo -e "${GREEN}APIs enabled successfully${NC}"

# Create terraform service account
SA_NAME="terraform-sa"
SA_EMAIL="$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com"

echo -e "\n${YELLOW}Creating Terraform service account...${NC}"
if gcloud iam service-accounts describe $SA_EMAIL &> /dev/null; then
    echo "Service account already exists"
else
    gcloud iam service-accounts create $SA_NAME \
        --display-name="Terraform Service Account"
fi

# Grant necessary roles to the service account
echo -e "\n${YELLOW}Granting IAM roles...${NC}"
ROLES=(
    "roles/compute.admin"
    "roles/container.admin"
    "roles/storage.admin"
    "roles/iam.serviceAccountAdmin"
    "roles/resourcemanager.projectIamAdmin"
    "roles/secretmanager.admin"
    "roles/servicenetworking.networksAdmin"
    "roles/cloudsql.admin"
    "roles/redis.admin"
    "roles/artifactregistry.admin"
)

for ROLE in "${ROLES[@]}"; do
    echo "Granting $ROLE..."
    gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:$SA_EMAIL" \
        --role="$ROLE" \
        --quiet
done

# Check state bucket (should be created in airtrafik-ops project)
BUCKET_NAME="airtrafik-terraform-state"
echo -e "\n${YELLOW}Checking state bucket...${NC}"
if gsutil ls -b gs://$BUCKET_NAME &> /dev/null; then
    echo -e "${GREEN}State bucket exists${NC}"
else
    echo -e "${YELLOW}WARNING: State bucket does not exist${NC}"
    echo "The state bucket should be created in the airtrafik-ops project:"
    echo "  gsutil mb -p airtrafik-ops gs://$BUCKET_NAME"
    echo "  gsutil versioning set on gs://$BUCKET_NAME"
    if [[ "$ENV" == "ops" ]]; then
        read -p "Create state bucket in this project? (y/n): " CREATE_BUCKET
        if [[ "$CREATE_BUCKET" == "y" ]]; then
            echo "Creating state bucket..."
            gsutil mb -p $PROJECT_ID gs://$BUCKET_NAME
            gsutil versioning set on gs://$BUCKET_NAME
            echo -e "${GREEN}State bucket created${NC}"
        fi
    fi
fi

# Update terraform.tfvars
TFVARS_FILE="../environments/$ENV/terraform.tfvars"
if [ -f "$TFVARS_FILE" ]; then
    echo -e "\n${YELLOW}Updating terraform.tfvars...${NC}"
    sed -i.bak "s/project_id   = \".*\"/project_id   = \"$PROJECT_ID\"/" $TFVARS_FILE
    echo -e "${GREEN}terraform.tfvars updated${NC}"
fi

echo -e "\n${GREEN}Setup complete!${NC}"
echo -e "\nNext steps:"
echo "1. cd ../environments/$ENV"
echo "2. terraform init"
echo "3. terraform plan"
echo "4. terraform apply"
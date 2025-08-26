#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
ENV=${1:-}
ACTION=${2:-plan}

if [[ -z "$ENV" ]] || [[ ! "$ENV" =~ ^(dev|staging|prod)$ ]]; then
    echo -e "${RED}Usage: $0 <environment> [action]${NC}"
    echo "  environment: dev, staging, or prod"
    echo "  action: plan (default), apply, destroy, output"
    exit 1
fi

if [[ ! "$ACTION" =~ ^(plan|apply|destroy|output)$ ]]; then
    echo -e "${RED}Invalid action. Must be plan, apply, destroy, or output${NC}"
    exit 1
fi

# Production safety check
if [[ "$ENV" == "prod" ]] && [[ "$ACTION" == "destroy" ]]; then
    echo -e "${RED}WARNING: You are about to destroy PRODUCTION infrastructure!${NC}"
    read -p "Type 'destroy production' to confirm: " CONFIRM
    if [[ "$CONFIRM" != "destroy production" ]]; then
        echo "Aborted"
        exit 1
    fi
fi

ENV_DIR="../environments/$ENV"

if [ ! -d "$ENV_DIR" ]; then
    echo -e "${RED}Environment directory not found: $ENV_DIR${NC}"
    exit 1
fi

cd "$ENV_DIR"

echo -e "${BLUE}==================================${NC}"
echo -e "${BLUE}Environment: $ENV${NC}"
echo -e "${BLUE}Action: $ACTION${NC}"
echo -e "${BLUE}==================================${NC}\n"

# Initialize if needed
if [ ! -d ".terraform" ]; then
    echo -e "${YELLOW}Initializing Terraform...${NC}"
    terraform init
fi

# Execute action
case $ACTION in
    plan)
        echo -e "${YELLOW}Running terraform plan...${NC}"
        terraform plan -out=tfplan
        echo -e "\n${GREEN}Plan saved to tfplan${NC}"
        echo -e "Run '$0 $ENV apply' to apply these changes"
        ;;
    apply)
        if [ -f "tfplan" ]; then
            echo -e "${YELLOW}Applying saved plan...${NC}"
            terraform apply tfplan
            rm -f tfplan
        else
            echo -e "${YELLOW}No saved plan found. Running plan first...${NC}"
            terraform plan -out=tfplan
            echo -e "\n${YELLOW}Review the plan above. Apply it?${NC}"
            read -p "Type 'yes' to continue: " CONFIRM
            if [[ "$CONFIRM" == "yes" ]]; then
                terraform apply tfplan
                rm -f tfplan
            else
                echo "Aborted"
                rm -f tfplan
                exit 1
            fi
        fi
        echo -e "\n${GREEN}Infrastructure deployed successfully!${NC}"
        
        # Show important outputs
        echo -e "\n${YELLOW}Key Outputs:${NC}"
        terraform output -json | jq -r 'to_entries[] | "\(.key): \(.value.value)"' 2>/dev/null || terraform output
        
        # Show connection instructions
        echo -e "\n${YELLOW}To connect to GKE cluster:${NC}"
        CLUSTER_NAME=$(terraform output -raw gke_cluster_name 2>/dev/null || echo "airtrafik-gke-$ENV")
        PROJECT_ID=$(terraform output -raw project_id 2>/dev/null || grep project_id terraform.tfvars | cut -d'"' -f2)
        echo "gcloud container clusters get-credentials $CLUSTER_NAME --region us-west1 --project $PROJECT_ID"
        ;;
    destroy)
        echo -e "${YELLOW}Planning destruction...${NC}"
        terraform plan -destroy -out=tfplan
        echo -e "\n${RED}Review the destruction plan above. Destroy?${NC}"
        read -p "Type 'yes' to continue: " CONFIRM
        if [[ "$CONFIRM" == "yes" ]]; then
            terraform destroy -auto-approve
            rm -f tfplan
            echo -e "\n${GREEN}Infrastructure destroyed${NC}"
        else
            echo "Aborted"
            rm -f tfplan
        fi
        ;;
    output)
        echo -e "${YELLOW}Terraform Outputs:${NC}\n"
        terraform output
        
        echo -e "\n${YELLOW}Saving outputs to outputs.json...${NC}"
        terraform output -json > outputs.json
        echo -e "${GREEN}Outputs saved to $ENV_DIR/outputs.json${NC}"
        ;;
esac
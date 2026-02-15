#!/bin/bash
# GCP Project Setup Script for VPN-Jenkins Infrastructure

set -e

echo "=== GCP Project Setup for learningmyway.space Jenkins Infrastructure ==="
echo ""

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "Error: gcloud CLI is not installed"
    echo "Install from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Prompt for inputs
read -p "Enter your GCP Organization ID: " ORG_ID
read -p "Enter your Billing Account ID: " BILLING_ACCOUNT
read -p "Enter Project 1 ID (default: test-project1-485105): " PROJECT1_ID
PROJECT1_ID=${PROJECT1_ID:-test-project1-485105}
read -p "Enter Project 2 ID (default: test-project2-485105): " PROJECT2_ID
PROJECT2_ID=${PROJECT2_ID:-test-project2-485105}

echo ""
echo "Configuration:"
echo "  Organization ID: $ORG_ID"
echo "  Billing Account: $BILLING_ACCOUNT"
echo "  Project 1: $PROJECT1_ID"
echo "  Project 2: $PROJECT2_ID"
echo ""
read -p "Continue? (y/n): " CONFIRM

if [ "$CONFIRM" != "y" ]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo "Step 1: Creating GCP Projects..."

# Create Project 1
echo "Creating $PROJECT1_ID..."
gcloud projects create $PROJECT1_ID \
  --organization=$ORG_ID \
  --name="Networking Global" || echo "Project may already exist"

# Create Project 2
echo "Creating $PROJECT2_ID..."
gcloud projects create $PROJECT2_ID \
  --organization=$ORG_ID \
  --name="Core IT Infrastructure" || echo "Project may already exist"

echo ""
echo "Step 2: Linking billing accounts..."

gcloud billing projects link $PROJECT1_ID \
  --billing-account=$BILLING_ACCOUNT

gcloud billing projects link $PROJECT2_ID \
  --billing-account=$BILLING_ACCOUNT

echo ""
echo "Step 3: Enabling required APIs..."

# Project 1 APIs
echo "Enabling APIs for $PROJECT1_ID..."
gcloud services enable compute.googleapis.com \
  --project=$PROJECT1_ID

# Project 2 APIs
echo "Enabling APIs for $PROJECT2_ID..."
gcloud services enable compute.googleapis.com \
  dns.googleapis.com \
  secretmanager.googleapis.com \
  --project=$PROJECT2_ID

echo ""
echo "Step 4: Creating Terraform state bucket..."

BUCKET_NAME="${PROJECT1_ID}-terraform-state"
gsutil mb -p $PROJECT1_ID \
  -l us-central1 \
  gs://$BUCKET_NAME || echo "Bucket may already exist"

gsutil versioning set on gs://$BUCKET_NAME

echo ""
echo "=== Setup Complete! ==="
echo ""
echo "Next steps:"
echo "1. Get Firezone token from https://firezone.dev"
echo "2. Configure terraform/terraform.tfvars"
echo "3. Run: cd terraform && terraform init"
echo "4. Run: terraform plan && terraform apply"
echo ""
echo "Projects created:"
echo "  - $PROJECT1_ID (Networking)"
echo "  - $PROJECT2_ID (Core IT)"
echo ""
echo "Terraform state bucket: gs://$BUCKET_NAME"

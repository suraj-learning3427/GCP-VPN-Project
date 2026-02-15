# Project IDs Reference - learningmyway.space

## Your GCP Projects

| Display Name | Project ID | Purpose | VPC CIDR |
|--------------|------------|---------|----------|
| project1-networkingglobal-prod | test-project1-485105 | VPN Gateway & Networking | 20.20.20.0/16 |
| project2-core-it-infra-prod | test-project2-485105 | Jenkins Infrastructure | 10.10.10.0/16 |

## Quick Reference

### Project 1: Networking (test-project1-485105)
- **Display Name**: project1-networkingglobal-prod
- **Project ID**: test-project1-485105
- **Purpose**: VPN Gateway
- **Resources**:
  - Firezone VPN Gateway VM
  - VPC: networkingglobal-vpc (20.20.20.0/16)
  - Subnet: vpn-subnet (20.20.20.0/24)

### Project 2: Core IT Infrastructure (test-project2-485105)
- **Display Name**: project2-core-it-infra-prod
- **Project ID**: test-project2-485105
- **Purpose**: Jenkins Application
- **Resources**:
  - Jenkins VM (10.10.10.10)
  - Internal Load Balancer (10.10.10.100)
  - VPC: core-it-vpc (10.10.10.0/16)
  - Subnet: jenkins-subnet (10.10.10.0/24)
  - Private DNS Zone: learningmyway.space

## All Commands Use Project IDs

**Important**: All gcloud commands use the Project ID (test-project1-485105, test-project2-485105), not the display names.

### Example Commands

```bash
# List resources in Project 1
gcloud compute instances list --project=test-project1-485105

# List resources in Project 2
gcloud compute instances list --project=test-project2-485105

# SSH to Jenkins VM
gcloud compute ssh jenkins-vm \
  --project=test-project2-485105 \
  --zone=us-central1-a \
  --tunnel-through-iap

# SSH to Firezone Gateway
gcloud compute ssh firezone-gateway \
  --project=test-project1-485105 \
  --zone=us-central1-a
```

## Terraform Configuration

Your `terraform/terraform.tfvars` is configured with:

```hcl
project_id_networking = "test-project1-485105"  # project1-networkingglobal-prod
project_id_coreit     = "test-project2-485105"  # project2-core-it-infra-prod
```

## Verification

Verify your projects exist:

```bash
# List all your projects
gcloud projects list

# Should show:
# PROJECT_ID              NAME                            PROJECT_NUMBER
# test-project1-485105    project1-networkingglobal-prod  ...
# test-project2-485105    project2-core-it-infra-prod     ...
```

## Documentation Status

✅ All documentation files updated with correct project IDs:
- terraform/main.tf
- terraform/variables.tf
- terraform/terraform.tfvars
- DEPLOYMENT.md
- QUICK-REFERENCE.md
- CHECKLIST.md
- START-HERE.md
- PROJECT-SUMMARY.md
- README.md
- YOUR-PROJECT-INFO.md
- scripts/verify-deployment.sh

---

**Last Updated**: February 12, 2026  
**Status**: All files synchronized with project IDs

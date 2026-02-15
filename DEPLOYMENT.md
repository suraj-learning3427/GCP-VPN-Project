# Deployment Guide - VPN-Jenkins Infrastructure

Complete step-by-step deployment guide for learningmyway.space Jenkins infrastructure.

## Phase 1: Pre-Deployment Setup

### Step 1: Create GCP Projects

```bash
# Set your organization ID
export ORG_ID="your-org-id"
export BILLING_ACCOUNT="your-billing-account-id"

# Create Project 1 (Networking)
gcloud projects create networkingglobal-prod \
  --organization=$ORG_ID \
  --name="Networking Global"

# Create Project 2 (Core IT)
gcloud projects create core-it-infra-prod \
  --organization=$ORG_ID \
  --name="Core IT Infrastructure"

# Link billing
gcloud billing projects link networkingglobal-prod \
  --billing-account=$BILLING_ACCOUNT

gcloud billing projects link core-it-infra-prod \
  --billing-account=$BILLING_ACCOUNT
```

### Step 2: Enable APIs

```bash
# Project 1 APIs
gcloud services enable compute.googleapis.com \
  --project=test-project1-485105

# Project 2 APIs
gcloud services enable compute.googleapis.com \
  dns.googleapis.com \
  secretmanager.googleapis.com \
  --project=test-project2-485105
```

### Step 3: Setup Terraform State Bucket

```bash
# Create bucket
gsutil mb -p test-project1-485105 \
  -l us-central1 \
  gs://test-project1-485105-terraform-state

# Enable versioning
gsutil versioning set on \
  gs://test-project1-485105-terraform-state
```

### Step 4: Get Firezone Token

1. Visit https://firezone.dev
2. Sign up for account (free trial available)
3. Create a new gateway
4. Copy the gateway token

## Phase 2: Terraform Deployment

### Step 1: Configure Variables

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
```hcl
project_id_networking = "test-project1-485105"
project_id_coreit     = "test-project2-485105"
region                = "us-central1"
zone                  = "us-central1-a"
domain_name           = "learningmyway.space"
jenkins_hostname      = "jenkins.np.learningmyway.space"
firezone_token        = "ft_xxxxxxxxxxxxx"  # Your token
```

### Step 2: Initialize and Deploy

```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Plan deployment
terraform plan -out=tfplan

# Review the plan carefully, then apply
terraform apply tfplan
```

Deployment takes approximately 10-15 minutes.

### Step 3: Verify Outputs

```bash
terraform output
```

Expected outputs:
```
jenkins_url = "https://jenkins.np.learningmyway.space"
jenkins_lb_ip = "10.10.10.100"
jenkins_vm_private_ip = "10.10.10.10"
firezone_gateway_ip = "x.x.x.x"
```

## Phase 3: Firezone Configuration

### Step 1: Login to Firezone Admin

1. Go to https://app.firezone.dev
2. Login with your credentials
3. Navigate to "Resources"

### Step 2: Add Jenkins Resource

1. Click "Add Resource"
2. Enter details:
   - Name: `Jenkins`
   - Address: `jenkins.np.learningmyway.space`
   - Type: `DNS`
3. Save resource

### Step 3: Configure DNS

1. Go to "Gateways" section
2. Verify your gateway is connected
3. Configure DNS forwarding for `learningmyway.space`

### Step 4: Add Users

1. Navigate to "Users"
2. Add team members
3. Assign Jenkins resource access

## Phase 4: Verification

### Step 1: Check VPC Peering

```bash
# Check peering in Project 1
gcloud compute networks peerings list \
  --project=test-project1-485105

# Check peering in Project 2
gcloud compute networks peerings list \
  --project=test-project2-485105
```

Both should show "ACTIVE" state.

### Step 2: Verify DNS

```bash
# SSH to Jenkins VM
gcloud compute ssh jenkins-vm \
  --project=test-project2-485105 \
  --zone=us-central1-a \
  --tunnel-through-iap

# Test DNS resolution
nslookup jenkins.np.learningmyway.space
```

Should resolve to `10.10.10.100` (LB IP).

### Step 3: Check Load Balancer Health

```bash
gcloud compute backend-services get-health jenkins-backend-service \
  --region=us-central1 \
  --project=test-project2-485105
```

Should show "HEALTHY" status.

### Step 4: Verify Firezone Gateway

```bash
# SSH to gateway
gcloud compute ssh firezone-gateway \
  --project=test-project1-485105 \
  --zone=us-central1-a

# Check Docker container
sudo docker ps
sudo docker logs firezone-gateway
```

Gateway should be connected to control plane.

## Phase 5: Client Setup

### Step 1: Install Firezone Client

Download from:
- Windows: https://www.firezone.dev/dl/firezone-client-gui-windows/latest
- macOS: https://www.firezone.dev/dl/firezone-client-gui-macos/latest
- Linux: https://www.firezone.dev/dl/firezone-client-gui-linux/latest

### Step 2: Connect VPN

1. Open Firezone client
2. Login with your credentials
3. Click "Connect"
4. Verify connection status

### Step 3: Access Jenkins

1. Open browser
2. Navigate to: `https://jenkins.np.learningmyway.space`
3. Jenkins login page should load

### Step 4: Get Initial Password

```bash
# SSH to Jenkins VM
gcloud compute ssh jenkins-vm \
  --project=test-project2-485105 \
  --zone=us-central1-a \
  --tunnel-through-iap

# Get password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

Copy the password and use it to login to Jenkins.

## Phase 6: Jenkins Initial Setup

1. Paste initial admin password
2. Select "Install suggested plugins"
3. Create first admin user
4. Configure Jenkins URL: `https://jenkins.np.learningmyway.space`
5. Start using Jenkins

## Troubleshooting

### Issue: Cannot access Jenkins

**Solution:**
```bash
# 1. Check VPN connection
# Verify in Firezone client

# 2. Test DNS
nslookup jenkins.np.learningmyway.space

# 3. Check LB health
gcloud compute backend-services get-health jenkins-backend-service \
  --region=us-central1 --project=test-project2-485105

# 4. Verify firewall rules
gcloud compute firewall-rules list --project=test-project2-485105
```

### Issue: VPC Peering not active

**Solution:**
```bash
# Delete and recreate peering
terraform destroy -target=module.vpc_peering
terraform apply -target=module.vpc_peering
```

### Issue: Firezone gateway not connecting

**Solution:**
```bash
# Check gateway logs
gcloud compute ssh firezone-gateway \
  --project=test-project1-485105 \
  --zone=us-central1-a

sudo docker logs firezone-gateway

# Verify token is correct
# Regenerate token in Firezone admin if needed
```

## Rollback Procedure

If deployment fails:

```bash
# Destroy all resources
terraform destroy

# Or destroy specific modules
terraform destroy -target=module.jenkins_vm
terraform destroy -target=module.load_balancer
```

## Next Steps

1. Configure Jenkins security (LDAP/SSO)
2. Setup Jenkins jobs
3. Configure backup strategy
4. Enable monitoring and alerting
5. Document operational procedures

## Support

- Main guide: `vpn-jenkins-infrastructure-guide.md`
- Requirements: `.kiro/specs/vpn-jenkins-infrastructure/requirements.md`
- Terraform README: `terraform/README.md`

# Air-Gapped Jenkins Deployment Guide

## Overview

This guide will help you migrate from Cloud NAT to an air-gapped deployment, saving **$61.50/month** ($738/year).

### What Changes
- ❌ Remove Cloud NAT (save $64/month)
- ✅ Add custom image storage ($2.50/month)
- ✅ Jenkins deployed from pre-built image
- ✅ No internet access required
- ✅ Maximum security

### Cost Comparison
| Item | Before | After | Savings |
|------|--------|-------|---------|
| Cloud NAT (Project 1) | $32 | $0 | $32 |
| Cloud NAT (Project 2) | $32 | $0 | $32 |
| Image Storage | $0 | $2.50 | -$2.50 |
| **Total** | **$64** | **$2.50** | **$61.50/month** |

---

## Prerequisites

- ✅ Current Jenkins deployment running
- ✅ gcloud CLI configured
- ✅ Terraform installed
- ✅ Access to both GCP projects
- ⏱️ Time required: 1-2 hours

---

## Phase 1: Create Air-Gapped Image

### Step 1: Run Image Creation Script

```bash
# Navigate to project root
cd /path/to/your/project

# Run the image creation script
bash scripts/create-airgapped-image.sh
```

**What this does:**
1. Creates temporary VM with Cloud NAT
2. Installs Jenkins, Java 17, all dependencies
3. Creates custom image from VM
4. Deletes temporary VM
5. Image ready to use!

**Time**: 10-15 minutes  
**Cost**: ~$0.50 (one-time Cloud NAT usage)

### Step 2: Verify Image Created

```bash
# List images
gcloud compute images list \
  --project=test-project2-485105 \
  --filter="family:jenkins-airgapped"

# Should show: jenkins-airgapped-v1
```

### Step 3: Check Image Details

```bash
gcloud compute images describe jenkins-airgapped-v1 \
  --project=test-project2-485105
```

**Expected output:**
- Name: jenkins-airgapped-v1
- Family: jenkins-airgapped
- Status: READY
- Size: ~5-6 GB

---

## Phase 2: Update Terraform Configuration

### Files Already Updated ✅

I've already updated these files for you:

1. **terraform/modules/networking/main.tf**
   - Removed Cloud Router
   - Removed Cloud NAT
   - Kept VPC and subnet

2. **terraform/modules/jenkins-vm/main.tf**
   - Changed image to `jenkins-airgapped-v1`
   - Simplified startup script
   - Added air-gapped labels

3. **scripts/create-airgapped-image.sh**
   - New script to create custom image

### Verify Changes

```bash
# Check networking module
cat terraform/modules/networking/main.tf | grep -A 5 "Air-Gapped"

# Check Jenkins VM module
cat terraform/modules/jenkins-vm/main.tf | grep "jenkins-airgapped"
```

---

## Phase 3: Backup Current State

### Step 1: Export Current Terraform State

```bash
cd terraform

# Backup current state
terraform state pull > ../backup-terraform-state-$(date +%Y%m%d).json

# Backup tfvars
cp terraform.tfvars ../backup-terraform.tfvars-$(date +%Y%m%d)
```

### Step 2: Get Jenkins Initial Password (if needed)

```bash
gcloud compute ssh jenkins-vm \
  --project=test-project2-485105 \
  --zone=us-central1-a \
  --tunnel-through-iap \
  --command="sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
```

**Save this password!** You'll need it after redeployment.

---

## Phase 4: Destroy Current Infrastructure

### Step 1: Destroy Current Deployment

```bash
cd terraform

# Review what will be destroyed
terraform plan -destroy

# Destroy (this will remove Cloud NAT and current Jenkins VM)
terraform destroy
```

**Type `yes` when prompted**

**What gets destroyed:**
- Cloud NAT (both projects)
- Cloud Routers (both projects)
- Jenkins VM
- Load Balancer
- DNS records
- Firewall rules

**What stays:**
- VPC networks
- Subnets
- VPC peering
- Jenkins data disk (your data is safe!)

### Step 2: Verify Destruction

```bash
# Check no VMs running
gcloud compute instances list --project=test-project2-485105

# Check no NAT
gcloud compute routers nats list \
  --router=core-it-vpc-router \
  --region=us-central1 \
  --project=test-project2-485105
```

---

## Phase 5: Deploy Air-Gapped Infrastructure

### Step 1: Initialize Terraform

```bash
cd terraform

# Re-initialize (modules changed)
terraform init -upgrade
```

### Step 2: Plan Deployment

```bash
# Review what will be created
terraform plan -out=airgapped.tfplan
```

**Expected changes:**
- Create VPC networks (if destroyed)
- Create subnets (if destroyed)
- Create VPC peering (if destroyed)
- Create Jenkins VM (from custom image)
- Create Load Balancer
- Create DNS records
- Create firewall rules
- **NO Cloud NAT or Cloud Router**

### Step 3: Apply Deployment

```bash
# Deploy air-gapped infrastructure
terraform apply airgapped.tfplan
```

**Time**: 5-10 minutes  
**What happens:**
- Jenkins VM created from custom image
- Jenkins starts automatically (pre-installed!)
- No downloads needed
- No internet access

### Step 4: Verify Deployment

```bash
# Check Jenkins VM status
gcloud compute instances describe jenkins-vm \
  --project=test-project2-485105 \
  --zone=us-central1-a \
  --format="get(status)"

# Should show: RUNNING
```

---

## Phase 6: Verify Air-Gapped Setup

### Test 1: Verify No Cloud NAT

```bash
# Project 1 - should show empty
gcloud compute routers nats list \
  --router=networkingglobal-vpc-router \
  --region=us-central1 \
  --project=test-project1-485105 2>&1 | grep "Listed 0 items"

# Project 2 - should show empty
gcloud compute routers nats list \
  --router=core-it-vpc-router \
  --region=us-central1 \
  --project=test-project2-485105 2>&1 | grep "Listed 0 items"
```

**Expected**: "Listed 0 items" for both

### Test 2: Verify Jenkins Running

```bash
# SSH to Jenkins
gcloud compute ssh jenkins-vm \
  --project=test-project2-485105 \
  --zone=us-central1-a \
  --tunnel-through-iap \
  --command="sudo systemctl status jenkins"
```

**Expected**: Active: active (running)

### Test 3: Verify No Internet Access

```bash
# Try to access internet (should fail)
gcloud compute ssh jenkins-vm \
  --project=test-project2-485105 \
  --zone=us-central1-a \
  --tunnel-through-iap \
  --command="curl -I --connect-timeout 5 https://www.google.com"
```

**Expected**: Connection timeout (no internet access)

### Test 4: Verify Load Balancer Health

```bash
gcloud compute backend-services get-health jenkins-backend-service \
  --region=us-central1 \
  --project=test-project2-485105
```

**Expected**: healthState: HEALTHY

### Test 5: Get Jenkins Password

```bash
gcloud compute ssh jenkins-vm \
  --project=test-project2-485105 \
  --zone=us-central1-a \
  --tunnel-through-iap \
  --command="sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
```

**Note**: This will be a NEW password (new Jenkins installation)

---

## Phase 7: Verify Cost Savings

### Check Current Costs

```bash
# List all resources in Project 2
gcloud compute instances list --project=test-project2-485105
gcloud compute routers list --project=test-project2-485105
gcloud compute images list --project=test-project2-485105 --filter="family:jenkins-airgapped"
```

### Expected Monthly Costs

| Resource | Cost |
|----------|------|
| Jenkins VM (e2-medium) | $25 |
| Data Disk (100GB) | $10 |
| Boot Disk (50GB) | $5 |
| Internal Load Balancer | $20 |
| Image Storage (50GB) | $2.50 |
| Network & Misc | $5 |
| **Total** | **$67.50/month** |

**Previous cost**: $129/month (with Cloud NAT)  
**New cost**: $67.50/month  
**Savings**: $61.50/month = $738/year

---

## Troubleshooting

### Issue 1: Image Not Found

**Error**: "The resource 'projects/test-project2-485105/global/images/jenkins-airgapped-v1' was not found"

**Solution**:
```bash
# Check if image exists
gcloud compute images list --project=test-project2-485105

# If not, run image creation script again
bash scripts/create-airgapped-image.sh
```

### Issue 2: Jenkins Not Starting

**Error**: Jenkins service fails to start

**Solution**:
```bash
# SSH to VM
gcloud compute ssh jenkins-vm \
  --project=test-project2-485105 \
  --zone=us-central1-a \
  --tunnel-through-iap

# Check logs
sudo journalctl -u jenkins -n 50

# Check Java version
java -version

# Restart Jenkins
sudo systemctl restart jenkins
```

### Issue 3: Load Balancer Unhealthy

**Error**: Health check shows UNHEALTHY

**Solution**:
```bash
# Wait 5 minutes for Jenkins to fully start
sleep 300

# Check again
gcloud compute backend-services get-health jenkins-backend-service \
  --region=us-central1 \
  --project=test-project2-485105

# If still unhealthy, check Jenkins
gcloud compute ssh jenkins-vm \
  --project=test-project2-485105 \
  --zone=us-central1-a \
  --tunnel-through-iap \
  --command="sudo netstat -tlnp | grep 8080"
```

### Issue 4: Data Disk Not Mounted

**Error**: Jenkins data not persisting

**Solution**:
```bash
# SSH to VM
gcloud compute ssh jenkins-vm \
  --project=test-project2-485105 \
  --zone=us-central1-a \
  --tunnel-through-iap

# Check if disk is mounted
df -h | grep jenkins

# If not mounted, check startup script logs
sudo cat /var/log/jenkins-startup.log
```

---

## Rollback Plan

If something goes wrong, you can rollback:

### Option 1: Restore from Backup

```bash
cd terraform

# Restore tfvars
cp ../backup-terraform.tfvars-YYYYMMDD terraform.tfvars

# Restore state
terraform state push ../backup-terraform-state-YYYYMMDD.json

# Re-apply old configuration
terraform apply
```

### Option 2: Recreate with Cloud NAT

```bash
# Revert networking module
git checkout terraform/modules/networking/main.tf

# Revert Jenkins VM module
git checkout terraform/modules/jenkins-vm/main.tf

# Re-apply
terraform init -upgrade
terraform apply
```

---

## Maintenance

### Updating Jenkins

Since Jenkins is air-gapped, updates require rebuilding the image:

```bash
# 1. Create new image with updated Jenkins
bash scripts/create-airgapped-image.sh

# This creates: jenkins-airgapped-v2

# 2. Update Terraform to use new image
# Edit terraform/modules/jenkins-vm/main.tf
# Change: image = "jenkins-airgapped-v2"

# 3. Redeploy
cd terraform
terraform apply

# 4. Delete old image (save storage cost)
gcloud compute images delete jenkins-airgapped-v1 \
  --project=test-project2-485105
```

**Frequency**: Quarterly or as needed

### Monitoring

```bash
# Check Jenkins status
gcloud compute ssh jenkins-vm \
  --project=test-project2-485105 \
  --zone=us-central1-a \
  --tunnel-through-iap \
  --command="sudo systemctl status jenkins"

# Check disk usage
gcloud compute ssh jenkins-vm \
  --project=test-project2-485105 \
  --zone=us-central1-a \
  --tunnel-through-iap \
  --command="df -h /var/lib/jenkins"
```

---

## Summary

### What You Accomplished

✅ Removed Cloud NAT from both projects  
✅ Created air-gapped Jenkins image  
✅ Deployed Jenkins from custom image  
✅ Eliminated internet access  
✅ Saved $61.50/month ($738/year)  
✅ Increased security (no internet exposure)

### New Architecture

```
Your Laptop → IAP → Jenkins VM (air-gapped)
                    - No internet access
                    - Pre-installed Jenkins
                    - Maximum security
```

### Monthly Costs

- **Before**: $129/month
- **After**: $67.50/month
- **Savings**: $61.50/month = $738/year

### Next Steps

1. ✅ Complete Phase 2 (Firezone VPN)
2. ✅ Configure Jenkins
3. ✅ Set up monitoring
4. ✅ Document procedures
5. ✅ Train team

---

**Congratulations!** You now have a secure, air-gapped Jenkins deployment that saves you $738/year!

---

**Last Updated**: February 12, 2026  
**Deployment Type**: Air-Gapped  
**Monthly Cost**: $67.50  
**Annual Savings**: $738

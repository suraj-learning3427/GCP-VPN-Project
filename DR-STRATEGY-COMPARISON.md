# 🔄 Disaster Recovery Strategy Comparison

## Complete DR Options Analysis for VPN-Based Jenkins Infrastructure

**Document Version:** 1.0  
**Date:** February 16, 2026  
**Project:** VPN-Based Air-Gapped Jenkins on GCP

---

## Executive Summary

This document compares all available DR strategies for the Jenkins infrastructure project, including custom scripts and GCP native services. The recommended approach is **Machine Images + GCS Backup** for optimal cost/benefit ratio.

---

## Table of Contents

1. [Custom DR Strategies](#custom-dr-strategies)
2. [GCP Native Services](#gcp-native-services)
3. [Detailed Comparison](#detailed-comparison)
4. [Cost Analysis by Usage Pattern](#cost-analysis-by-usage-pattern)
5. [Recommended Solution](#recommended-solution)
6. [Implementation Guide](#implementation-guide)

---

## Custom DR Strategies

### Option 1: Backup & Restore ✅ (Current Implementation)
**Method:** Scripts + Terraform + Manual restore

**How it works:**
- Daily backup script (`backup-jenkins.sh`)
- Compress Jenkins data to tar.gz
- Store locally or upload to GCS
- On disaster: Destroy → Redeploy → Restore

**Metrics:**
- RTO: 2-8 hours
- RPO: 6-24 hours
- Cost: $3-10/month
- Automation: Medium
- Complexity: Low

**Pros:**
- ✅ Simple to understand
- ✅ Full control over process
- ✅ Works with any cloud provider
- ✅ Low cost
- ✅ Already implemented

**Cons:**
- ❌ Slow recovery (2-8 hours)
- ❌ Manual steps required
- ❌ High RPO (data loss risk)
- ❌ Requires expertise to execute


---

### Option 2: Pilot Light
**Method:** Minimal infrastructure always running

**How it works:**
- Keep Jenkins VM created but stopped
- Keep VPN gateway active
- On disaster: Start VM, restore data
- Faster than full rebuild

**Metrics:**
- RTO: 1-2 hours
- RPO: 1-6 hours
- Cost: $20-30/month
- Automation: Medium
- Complexity: Low

**Pros:**
- ✅ Faster than backup/restore
- ✅ VM already exists (just start it)
- ✅ Moderate cost
- ✅ Simple architecture

**Cons:**
- ❌ Still costs money when "off"
- ❌ Stopped VM still charges for disk
- ❌ 1-2 hour recovery still slow
- ❌ Manual intervention needed

---

### Option 3: Warm Standby
**Method:** Secondary Jenkins with reduced capacity

**How it works:**
- Second Jenkins VM in different zone
- Continuous backup sync every 15 minutes
- Load balancer switches on failure
- Standby VM runs at lower capacity

**Metrics:**
- RTO: 15-30 minutes
- RPO: 5-15 minutes
- Cost: $50-80/month
- Automation: High
- Complexity: Medium

**Pros:**
- ✅ Fast recovery (15-30 min)
- ✅ Low data loss
- ✅ Automated failover
- ✅ Good for production

**Cons:**
- ❌ Higher cost (2x infrastructure)
- ❌ Complex setup
- ❌ Overkill for learning project
- ❌ Requires load balancer config


---

### Option 4: Hot Standby (Active-Passive)
**Method:** Full duplicate infrastructure, real-time replication

**How it works:**
- Two identical Jenkins VMs (active + passive)
- Shared storage (GCS FUSE or NFS)
- Load balancer health checks
- Automatic failover on failure
- Real-time data sync

**Metrics:**
- RTO: 1-5 minutes
- RPO: < 1 minute
- Cost: $150-200/month
- Automation: High
- Complexity: High

**Pros:**
- ✅ Near-zero downtime
- ✅ Minimal data loss
- ✅ Fully automated
- ✅ Production-grade

**Cons:**
- ❌ Expensive (2x full infrastructure)
- ❌ Complex shared storage setup
- ❌ Requires advanced networking
- ❌ Not cost-effective for learning

---

### Option 5: Active-Active (Multi-Master)
**Method:** Multiple Jenkins masters, distributed workload

**How it works:**
- 2+ Jenkins masters behind load balancer
- Shared storage for jobs/config
- CloudBees Jenkins HA or custom setup
- Traffic distributed across all nodes
- No single point of failure

**Metrics:**
- RTO: 0 seconds (no downtime)
- RPO: 0 seconds (no data loss)
- Cost: $300-400/month
- Automation: Very High
- Complexity: Very High

**Pros:**
- ✅ Zero downtime
- ✅ Zero data loss
- ✅ Load distribution
- ✅ Highest availability

**Cons:**
- ❌ Very expensive
- ❌ Complex setup (CloudBees or custom)
- ❌ Requires enterprise Jenkins
- ❌ Overkill for most use cases


---

### Option 6: Multi-Region DR
**Method:** Secondary infrastructure in different GCP region

**How it works:**
- Primary: us-central1 (current)
- Secondary: us-east1 (standby)
- Cross-region VPC peering
- DNS failover or Global Load Balancer
- Continuous backup replication
- Protects against regional outages

**Metrics:**
- RTO: 5-30 minutes
- RPO: 1-15 minutes
- Cost: $200-300/month
- Automation: High
- Complexity: High

**Pros:**
- ✅ Regional disaster protection
- ✅ Geographic redundancy
- ✅ Fast recovery
- ✅ Enterprise-grade

**Cons:**
- ❌ Very expensive (2x regions)
- ❌ Complex networking
- ❌ Cross-region data transfer costs
- ❌ Unnecessary for single-region failures

---

### Option 7: Chaos Engineering + Auto-Healing
**Method:** Automated failure detection and recovery

**How it works:**
- Managed Instance Groups (MIG)
- Health check monitoring
- Automatic VM recreation on failure
- Self-healing infrastructure
- Chaos Monkey testing
- No manual intervention

**Metrics:**
- RTO: 2-10 minutes
- RPO: 1-5 minutes
- Cost: $100-150/month
- Automation: Very High
- Complexity: Medium

**Pros:**
- ✅ Fully automated recovery
- ✅ Fast recovery
- ✅ No manual intervention
- ✅ Continuous testing

**Cons:**
- ❌ Requires MIG setup
- ❌ Complex health checks
- ❌ May recreate VM unnecessarily
- ❌ Requires robust backup strategy


---

## GCP Native Services

### Service 1: Backup and DR Service (Actifio)
**Type:** Enterprise-grade managed backup

**Features:**
- Automated VM backups
- Application-aware snapshots
- Continuous data protection (CDP)
- Point-in-time recovery
- Cross-region replication
- Supports Jenkins, databases, file systems

**Metrics:**
- RTO: 15-30 minutes
- RPO: 15 minutes to 24 hours
- Cost: $10-15/month (100GB)
- Automation: Very High
- Complexity: Medium

**Pricing:**
- $0.10/GB/month for backup storage
- $0.05/GB for data transfer

**Pros:**
- ✅ Enterprise-grade solution
- ✅ Application-aware backups
- ✅ Point-in-time recovery
- ✅ Automated scheduling
- ✅ GCP native integration

**Cons:**
- ❌ Costs money even when infra is down
- ❌ Complex setup
- ❌ Overkill for learning projects
- ❌ Requires API enablement

**Best for:** Enterprise production workloads

---

### Service 2: Persistent Disk Snapshots ⭐
**Type:** Incremental disk backup

**Features:**
- Incremental snapshots (only changed blocks)
- Automatic scheduling
- Cross-region snapshot copy
- Fast restore (create new disk from snapshot)
- Very cost-effective

**Metrics:**
- RTO: 30-60 minutes
- RPO: 1-24 hours
- Cost: $2-3/month (100GB)
- Automation: High
- Complexity: Low

**Pricing:**
- $0.026/GB/month (standard snapshots)
- $0.013/GB/month (archive snapshots)

**Pros:**
- ✅ Very cheap
- ✅ Simple to setup
- ✅ Automated scheduling
- ✅ Incremental (efficient)
- ✅ GCP native

**Cons:**
- ❌ Slower than machine images
- ❌ Requires disk creation + data restore
- ❌ 30-60 min recovery time
- ❌ Only backs up disk, not VM config

**Best for:** Cost-sensitive projects, disk-level backup


---

### Service 3: Compute Engine Machine Images 🏆
**Type:** Complete VM backup (disk + metadata + config)

**Features:**
- Captures entire VM state (all disks + metadata)
- Faster restore than snapshots
- Cross-region replication
- Can create VM directly from image
- Includes VM configuration

**Metrics:**
- RTO: 10-20 minutes
- RPO: 1-24 hours
- Cost: $5/month (100GB)
- Automation: High
- Complexity: Low

**Pricing:**
- $0.050/GB/month (standard)
- $0.010/GB/month (archive)

**Pros:**
- ✅ Fast recovery (10-20 min)
- ✅ Complete VM backup
- ✅ One-command restore
- ✅ Includes all VM config
- ✅ Simple to use

**Cons:**
- ❌ Slightly more expensive than snapshots
- ❌ Larger storage size
- ❌ Manual image creation (can automate)

**Best for:** Fast recovery, complete VM backup, learning projects

---

### Service 4: Cloud Storage (GCS) Backup
**Type:** Application-level backup

**Features:**
- Store backup files in GCS buckets
- Versioning and lifecycle policies
- Cross-region replication
- Cheapest option
- Flexible retention

**Metrics:**
- RTO: 1-2 hours
- RPO: 1-24 hours
- Cost: $2-5/month (100GB)
- Automation: Medium
- Complexity: Low

**Pricing:**
- $0.020/GB/month (Standard)
- $0.004/GB/month (Nearline - 30-day access)
- $0.0012/GB/month (Coldline - 90-day access)

**Pros:**
- ✅ Very cheap
- ✅ Flexible storage classes
- ✅ Versioning support
- ✅ Cross-region replication
- ✅ Works with existing scripts

**Cons:**
- ❌ Slower recovery (download + restore)
- ❌ Requires VM to exist first
- ❌ Manual restore process
- ❌ Application-level only

**Best for:** Application data backup, long-term retention


---

### Service 5: Regional Persistent Disk
**Type:** High availability disk with automatic replication

**Features:**
- Synchronous replication across 2 zones
- Automatic failover
- No data loss (RPO = 0)
- Transparent to application
- Zone-level disaster protection

**Metrics:**
- RTO: 5-10 minutes
- RPO: 0 seconds
- Cost: $34/month (100GB)
- Automation: Very High
- Complexity: Low

**Pricing:**
- $0.34/GB/month (2x cost of standard disk)

**Pros:**
- ✅ Zero data loss
- ✅ Automatic failover
- ✅ Fast recovery
- ✅ Transparent to app
- ✅ Zone disaster protection

**Cons:**
- ❌ Expensive (2x disk cost)
- ❌ Only protects against zone failure
- ❌ Doesn't protect against VM failure
- ❌ Costs money even when VM is stopped

**Best for:** Mission-critical data, zero RPO requirement

---

### Service 6: Managed Instance Groups (MIG) with Auto-Healing
**Type:** Automated VM recovery

**Features:**
- Health check monitoring
- Automatic VM recreation on failure
- Rolling updates
- Auto-scaling
- Self-healing

**Metrics:**
- RTO: 5-10 minutes
- RPO: Depends on backup strategy
- Cost: $0 extra (just VM cost)
- Automation: Very High
- Complexity: Medium

**Pricing:**
- No additional cost

**Pros:**
- ✅ Free (no extra cost)
- ✅ Automated recovery
- ✅ Fast recovery
- ✅ Self-healing
- ✅ Production-ready

**Cons:**
- ❌ Recreates VM (data loss without backup)
- ❌ Requires health check setup
- ❌ Complex configuration
- ❌ May recreate unnecessarily

**Best for:** Automated recovery, stateless applications


---

## Detailed Comparison

### All Options Summary Table

| Strategy | RTO | RPO | Monthly Cost | Automation | Complexity | Best For |
|----------|-----|-----|--------------|------------|------------|----------|
| **Custom Strategies** |
| 1. Backup & Restore ✅ | 2-8h | 6-24h | $3-10 | Medium | Low | Learning, Cost-sensitive |
| 2. Pilot Light | 1-2h | 1-6h | $20-30 | Medium | Low | Small production |
| 3. Warm Standby | 15-30m | 5-15m | $50-80 | High | Medium | Production |
| 4. Hot Standby | 1-5m | <1m | $150-200 | High | High | Mission-critical |
| 5. Active-Active | 0s | 0s | $300-400 | Very High | Very High | Enterprise |
| 6. Multi-Region | 5-30m | 1-15m | $200-300 | High | High | Regional DR |
| 7. Auto-Healing | 2-10m | 1-5m | $100-150 | Very High | Medium | Automated ops |
| **GCP Native Services** |
| Backup and DR Service | 15-30m | 15m-24h | $10-15 | Very High | Medium | Enterprise |
| Persistent Disk Snapshots ⭐ | 30-60m | 1-24h | $2-3 | High | Low | Cost-effective |
| Machine Images 🏆 | 10-20m | 1-24h | $5 | High | Low | Fast recovery |
| GCS Backup | 1-2h | 1-24h | $2-5 | Medium | Low | App-level backup |
| Regional Persistent Disk | 5-10m | 0s | $34 | Very High | Low | Zero data loss |
| MIG Auto-Healing | 5-10m | Varies | $0 | Very High | Medium | Self-healing |

---

### RTO Comparison (Recovery Speed)

```
Fastest ←─────────────────────────────────────────────→ Slowest

Active-Active (0s)
├─ Hot Standby (1-5m)
├─ Regional Disk (5-10m)
├─ MIG Auto-Healing (5-10m)
├─ Multi-Region (5-30m)
├─ Machine Images (10-20m) 🏆
├─ Warm Standby (15-30m)
├─ Backup and DR Service (15-30m)
├─ Snapshots (30-60m)
├─ Pilot Light (1-2h)
├─ GCS Backup (1-2h)
├─ Backup & Restore (2-8h) ✅ Current
```

---

### Cost Comparison (Monthly)

```
Cheapest ←────────────────────────────────────────────→ Most Expensive

$0 - MIG Auto-Healing
$2-3 - Persistent Disk Snapshots ⭐
$2-5 - GCS Backup
$3-10 - Backup & Restore ✅ Current
$5 - Machine Images 🏆
$10-15 - Backup and DR Service
$20-30 - Pilot Light
$34 - Regional Persistent Disk
$50-80 - Warm Standby
$100-150 - Auto-Healing (with infra)
$150-200 - Hot Standby
$200-300 - Multi-Region
$300-400 - Active-Active
```


---

## Cost Analysis by Usage Pattern

### Your Project: Learning/Portfolio (Infrastructure Destroyed Most of Time)

#### Pattern A: Infrastructure DOWN (90% of time)
**Current (Backup & Restore):**
- Cost: $2/month (GCS storage only)
- RTO: 2-8 hours
- Status: ✅ Works but slow

**Recommended (Machine Images + GCS):**
- Cost: $2/month (GCS storage, no images when destroyed)
- RTO: 15 minutes (when you redeploy)
- Status: 🏆 Best option

**Alternative (Snapshots + GCS):**
- Cost: $1-2/month
- RTO: 30-60 minutes
- Status: ⭐ Cheapest option

#### Pattern B: Infrastructure UP for Demo/Testing (1 week/month)
**Current (Backup & Restore):**
- Infrastructure: $91/month ÷ 4 = $23/week
- Backup: $0.50/week
- Total: $23.50/week

**Recommended (Machine Images + GCS):**
- Infrastructure: $23/week
- Machine Images (7 daily): $5/week
- GCS: $0.50/week
- Total: $28.50/week
- Extra cost: $5/week for 87% faster recovery

**Alternative (Snapshots + GCS):**
- Infrastructure: $23/week
- Snapshots (7 daily): $2/week
- GCS: $0.50/week
- Total: $25.50/week
- Extra cost: $2/week for 75% faster recovery

#### Pattern C: Infrastructure UP for Interview Prep (3 days)
**Current (Backup & Restore):**
- Infrastructure: $91/month ÷ 30 × 3 = $9
- Backup: $0.20
- Total: $9.20

**Recommended (Machine Images + GCS):**
- Infrastructure: $9
- Machine Images (3): $2
- GCS: $0.20
- Total: $11.20
- Extra cost: $2 for professional DR demo

---

### Production Use Case (Infrastructure Always Running)

#### Small Production (24/7 uptime)
**Current (Backup & Restore):**
- Infrastructure: $91/month
- Backup: $3/month
- Total: $94/month
- RTO: 2-8 hours ❌ Too slow

**Recommended (Machine Images + GCS):**
- Infrastructure: $91/month
- Machine Images: $5/month
- GCS: $2/month
- Total: $98/month
- RTO: 15 minutes ✅ Acceptable

**Alternative (Warm Standby):**
- Infrastructure: $182/month (2x)
- Backup: $5/month
- Total: $187/month
- RTO: 15-30 minutes ✅ Better


---

## Recommended Solution

### 🏆 Best for Your Project: Machine Images + GCS Backup

#### Why This is Perfect for You

**1. Cost Efficiency**
- When DOWN: $2/month (only GCS)
- When UP: $7/month extra (vs current)
- Best cost/benefit ratio

**2. Recovery Speed**
- RTO: 15 minutes (vs 2-8 hours current)
- 87% faster recovery
- One-command restore

**3. Learning Value**
- Demonstrates GCP native services
- Shows infrastructure-level backup
- Professional approach
- Great for resume/interviews

**4. Simplicity**
- Easy to implement (30 minutes)
- Automated with Terraform
- One command to restore
- No complex setup

**5. Flexibility**
- Create images only when needed
- Delete images to save cost
- Keep GCS backup for safety
- Works with existing scripts

#### Interview Story You Can Tell

> "I evaluated 7 DR strategies and multiple GCP services. I chose a hybrid approach combining Machine Images for fast infrastructure recovery (15-min RTO) and GCS for application-level backups. This reduced recovery time by 87% while keeping costs minimal ($2/month when infrastructure is down). The solution demonstrates understanding of both infrastructure-as-code and cloud-native backup services."

---

### Implementation Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  DR Strategy Layers                      │
├─────────────────────────────────────────────────────────┤
│  Layer 1: Machine Images (Infrastructure Level)         │
│  - Complete VM backup (disk + config + metadata)        │
│  - Created before terraform destroy                     │
│  - Fast restore: 15 minutes                             │
│  - Cost: $5/month when running, $0 when destroyed       │
├─────────────────────────────────────────────────────────┤
│  Layer 2: GCS Backup (Application Level)                │
│  - Jenkins jobs, config, users, plugins                 │
│  - Daily automated backups                              │
│  - Granular restore capability                          │
│  - Cost: $2/month always                                │
├─────────────────────────────────────────────────────────┤
│  Layer 3: Terraform State (Infrastructure as Code)      │
│  - Complete infrastructure definition                   │
│  - Version controlled in Git                            │
│  - Reproducible deployments                             │
│  - Cost: $0                                             │
└─────────────────────────────────────────────────────────┘

Recovery Process:
1. Create VM from Machine Image (5 min)
2. Verify VM is running (2 min)
3. Download GCS backup (3 min)
4. Restore Jenkins data (5 min)
Total: 15 minutes
```


---

## Implementation Guide

### Step 1: Add GCS Bucket (5 minutes)

Add to `terraform/main.tf`:

```hcl
# GCS bucket for Jenkins backups
resource "google_storage_bucket" "jenkins_backups" {
  name          = "${var.project_id_jenkins}-jenkins-backups"
  location      = var.region
  project       = var.project_id_jenkins
  force_destroy = true

  # Lifecycle policy - delete backups older than 7 days
  lifecycle_rule {
    condition {
      age = 7
    }
    action {
      type = "Delete"
    }
  }

  # Enable versioning for safety
  versioning {
    enabled = true
  }

  # Uniform bucket-level access
  uniform_bucket_level_access = true
}

# Output bucket name
output "backup_bucket_name" {
  value       = google_storage_bucket.jenkins_backups.name
  description = "GCS bucket for Jenkins backups"
}
```

### Step 2: Create Machine Image Script (10 minutes)

Create `scripts/create-machine-image.sh`:

```bash
#!/bin/bash
# Create machine image before destroying infrastructure

PROJECT_ID="test-project2-485105"
ZONE="us-central1-a"
INSTANCE_NAME="jenkins-vm"
IMAGE_NAME="jenkins-backup-$(date +%Y%m%d-%H%M%S)"
REGION="us-central1"

echo "Creating machine image: $IMAGE_NAME"

gcloud compute machine-images create "$IMAGE_NAME" \
  --source-instance="$INSTANCE_NAME" \
  --source-instance-zone="$ZONE" \
  --project="$PROJECT_ID" \
  --storage-location="$REGION"

echo "Machine image created successfully!"
echo "Image name: $IMAGE_NAME"
```

### Step 3: Update Backup Script (5 minutes)

Add to end of `scripts/backup-jenkins.sh`:

```bash
# Upload to GCS
echo -e "${YELLOW}Uploading to Google Cloud Storage...${NC}"
PROJECT_ID=$(gcloud config get-value project)
BUCKET_NAME="${PROJECT_ID}-jenkins-backups"

gsutil cp "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" \
  "gs://${BUCKET_NAME}/"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Uploaded to: gs://${BUCKET_NAME}/${BACKUP_NAME}.tar.gz${NC}"
else
    echo -e "${RED}Warning: Failed to upload to GCS${NC}"
fi
```

### Step 4: Create Restore from Image Script (10 minutes)

Create `scripts/restore-from-image.sh`:

```bash
#!/bin/bash
# Restore Jenkins VM from machine image

PROJECT_ID="test-project2-485105"
ZONE="us-central1-a"
INSTANCE_NAME="jenkins-vm"

# List available images
echo "Available machine images:"
gcloud compute machine-images list \
  --project="$PROJECT_ID" \
  --filter="name~jenkins-backup" \
  --format="table(name,creationTimestamp)"

# Prompt for image name
read -p "Enter image name to restore from: " IMAGE_NAME

# Create VM from image
echo "Creating VM from image: $IMAGE_NAME"
gcloud compute instances create "$INSTANCE_NAME" \
  --source-machine-image="$IMAGE_NAME" \
  --zone="$ZONE" \
  --project="$PROJECT_ID"

echo "VM restored successfully!"
echo "Waiting for VM to be ready..."
sleep 30

# Verify VM is running
gcloud compute instances describe "$INSTANCE_NAME" \
  --zone="$ZONE" \
  --project="$PROJECT_ID" \
  --format="get(status)"
```


---

### Step 5: Update Deployment Workflow

#### Before Destroying Infrastructure:

```bash
# 1. Create final backup
gcloud compute ssh jenkins-vm \
  --project=test-project2-485105 \
  --zone=us-central1-a \
  --tunnel-through-iap \
  --command="sudo bash /tmp/backup-jenkins.sh"

# 2. Create machine image
bash scripts/create-machine-image.sh

# 3. Destroy infrastructure
cd terraform
terraform destroy -auto-approve

# Cost now: $2/month (GCS only)
```

#### When Redeploying:

**Option A: Fast Recovery (from Machine Image)**
```bash
# 1. Restore VM from image (15 minutes)
bash scripts/restore-from-image.sh

# 2. Verify Jenkins is running
gcloud compute ssh jenkins-vm \
  --project=test-project2-485105 \
  --zone=us-central1-a \
  --tunnel-through-iap \
  --command="sudo systemctl status jenkins"

# Done! Jenkins is back online
```

**Option B: Full Rebuild (from Terraform)**
```bash
# 1. Deploy infrastructure (20 minutes)
cd terraform
terraform apply -auto-approve

# 2. Restore from GCS backup (30 minutes)
# Download latest backup
gsutil ls gs://test-project2-485105-jenkins-backups/

# Upload to VM and restore
gcloud compute scp gs://test-project2-485105-jenkins-backups/jenkins-backup-*.tar.gz \
  jenkins-vm:/tmp/ \
  --project=test-project2-485105 \
  --zone=us-central1-a \
  --tunnel-through-iap

# Restore
gcloud compute ssh jenkins-vm \
  --project=test-project2-485105 \
  --zone=us-central1-a \
  --tunnel-through-iap \
  --command="sudo bash /tmp/restore-jenkins.sh /tmp/jenkins-backup-*.tar.gz"
```

---

### Step 6: Automated Workflow (Optional)

Create `scripts/dr-workflow.sh`:

```bash
#!/bin/bash
# Complete DR workflow automation

ACTION=$1

case $ACTION in
  backup)
    echo "Creating backup and machine image..."
    bash scripts/create-machine-image.sh
    ;;
  
  destroy)
    echo "Destroying infrastructure..."
    cd terraform && terraform destroy -auto-approve
    ;;
  
  restore-fast)
    echo "Fast restore from machine image..."
    bash scripts/restore-from-image.sh
    ;;
  
  restore-full)
    echo "Full restore from Terraform + GCS..."
    cd terraform && terraform apply -auto-approve
    # Then restore from GCS
    ;;
  
  *)
    echo "Usage: $0 {backup|destroy|restore-fast|restore-full}"
    exit 1
    ;;
esac
```

Usage:
```bash
# Before destroying
bash scripts/dr-workflow.sh backup
bash scripts/dr-workflow.sh destroy

# When restoring
bash scripts/dr-workflow.sh restore-fast  # 15 minutes
# OR
bash scripts/dr-workflow.sh restore-full  # 50 minutes
```


---

## Alternative Options Analysis

### If You Want Even Lower Cost: Snapshots Only

**Cost:** $1-2/month  
**RTO:** 30-60 minutes  
**Implementation:**

```bash
# Create snapshot schedule
gcloud compute resource-policies create snapshot-schedule jenkins-daily \
  --region=us-central1 \
  --max-retention-days=7 \
  --on-source-disk-delete=keep-auto-snapshots \
  --daily-schedule \
  --start-time=02:00

# Attach to Jenkins disk
gcloud compute disks add-resource-policies jenkins-vm-disk \
  --resource-policies=jenkins-daily \
  --zone=us-central1-a
```

**Pros:** Cheapest option  
**Cons:** Slower recovery, more manual steps

---

### If You Need Faster Recovery: Regional Disk + MIG

**Cost:** $34/month (disk) + $0 (MIG)  
**RTO:** 5-10 minutes  
**Implementation:**

```hcl
# Regional disk with auto-replication
resource "google_compute_disk" "jenkins_disk" {
  name = "jenkins-disk"
  type = "pd-balanced"
  size = 100
  
  replica_zones = [
    "us-central1-a",
    "us-central1-b"
  ]
}

# Managed Instance Group with auto-healing
resource "google_compute_instance_group_manager" "jenkins_mig" {
  name               = "jenkins-mig"
  base_instance_name = "jenkins"
  zone               = "us-central1-a"
  target_size        = 1

  auto_healing_policies {
    health_check      = google_compute_health_check.jenkins.id
    initial_delay_sec = 300
  }
}
```

**Pros:** Fastest recovery, zero data loss  
**Cons:** Higher cost, complex setup

---

### If You Need Production-Grade: Warm Standby

**Cost:** $50-80/month  
**RTO:** 15-30 minutes  
**Implementation:**

- Deploy second Jenkins VM in different zone
- Setup continuous backup sync (every 15 min)
- Configure load balancer with health checks
- Automatic failover on primary failure

**Pros:** Production-ready, fast failover  
**Cons:** 2x infrastructure cost


---

## Decision Matrix

### Choose Based on Your Needs

| Your Priority | Recommended Solution | Cost | RTO |
|---------------|---------------------|------|-----|
| **Lowest Cost** | Snapshots + GCS | $1-2/mo | 30-60m |
| **Best Balance** 🏆 | Machine Images + GCS | $2-7/mo | 15m |
| **Fastest Recovery** | Regional Disk + MIG | $34/mo | 5-10m |
| **Production Ready** | Warm Standby | $50-80/mo | 15-30m |
| **Zero Downtime** | Active-Active | $300+/mo | 0s |
| **Learning/Portfolio** 🎓 | Machine Images + GCS | $2-7/mo | 15m |
| **Interview Demo** 💼 | Machine Images + GCS | $2-7/mo | 15m |

---

## Summary

### Current Implementation ✅
- Strategy: Backup & Restore (scripts)
- RTO: 2-8 hours
- RPO: 6-24 hours
- Cost: $3-10/month
- Status: Works but slow

### Recommended Upgrade 🏆
- Strategy: Machine Images + GCS Backup
- RTO: 15 minutes (87% faster)
- RPO: 1-24 hours
- Cost: $2/month (down), $7/month extra (up)
- Benefits:
  - ✅ 87% faster recovery
  - ✅ GCP native services
  - ✅ Professional approach
  - ✅ Great for resume/interviews
  - ✅ Minimal cost increase
  - ✅ Easy to implement (30 min)

### Implementation Effort
- Time: 30 minutes
- Complexity: Low
- Changes: Add GCS bucket, create scripts, update workflow
- Risk: Low (keeps existing backup as fallback)

---

## Next Steps

1. **Review this document** - Understand all options
2. **Decide on strategy** - Machine Images + GCS recommended
3. **Implement changes** - Follow implementation guide
4. **Test recovery** - Verify 15-minute RTO
5. **Update documentation** - Add to runbook
6. **Demo for interviews** - Show professional DR approach

---

## Appendix: Quick Reference

### Recovery Time Comparison
- Current: 2-8 hours
- Snapshots: 30-60 minutes
- Machine Images: 15 minutes 🏆
- Regional Disk: 5-10 minutes
- Active-Active: 0 seconds

### Cost Comparison (Infrastructure Down)
- Current: $2/month
- Snapshots: $1-2/month
- Machine Images: $2/month 🏆
- Regional Disk: $34/month
- Warm Standby: $50-80/month

### Cost Comparison (Infrastructure Up)
- Current: $94/month
- Snapshots: $93/month
- Machine Images: $98/month 🏆
- Regional Disk: $125/month
- Warm Standby: $187/month

---

**Document Version:** 1.0  
**Last Updated:** February 16, 2026  
**Next Review:** March 16, 2026

**END OF DOCUMENT**

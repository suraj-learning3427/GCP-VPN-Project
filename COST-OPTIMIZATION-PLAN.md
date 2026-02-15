# Cost Optimization Plan - Minimum Cost Jenkins

## Current Cost Breakdown

| Item | Current | Cost/Month |
|------|---------|------------|
| Jenkins VM (e2-medium) | 2 vCPU, 4GB RAM | $25 |
| Data Disk (100GB) | pd-standard | $10 |
| Boot Disk (50GB) | pd-standard | $5 |
| Internal Load Balancer | Regional | $20 |
| Network & Misc | - | $5 |
| **Total** | - | **$65/month** |

---

## 💰 Cost Reduction Options

### Option 1: Smaller VM (Save $10/month)

**Change**: e2-medium → e2-small

| Item | Before | After | Savings |
|------|--------|-------|---------|
| VM Type | e2-medium (2 vCPU, 4GB) | e2-small (2 vCPU, 2GB) | $10/month |
| **New Total** | $65 | **$55** | **$10/month** |

**Pros:**
- ✅ Save $10/month = $120/year
- ✅ Same CPU (2 vCPU)
- ✅ Jenkins still works fine

**Cons:**
- ⚠️ Less RAM (2GB vs 4GB)
- ⚠️ May be slower with many concurrent builds

**Recommendation:** ✅ **DO THIS** - Jenkins works fine with 2GB RAM for small teams

---

### Option 2: Smaller Data Disk (Save $5/month)

**Change**: 100GB → 50GB data disk

| Item | Before | After | Savings |
|------|--------|-------|---------|
| Data Disk | 100GB | 50GB | $5/month |
| **New Total** | $55 | **$50** | **$5/month** |

**Pros:**
- ✅ Save $5/month = $60/year
- ✅ 50GB is enough for most Jenkins setups

**Cons:**
- ⚠️ Less space for build artifacts
- ⚠️ Need to clean up old builds more often

**Recommendation:** ✅ **DO THIS** - 50GB is usually enough

---

### Option 3: Remove Load Balancer (Save $20/month)

**Change**: Remove internal load balancer, access Jenkins directly

| Item | Before | After | Savings |
|------|--------|-------|---------|
| Load Balancer | $20 | $0 | $20/month |
| **New Total** | $50 | **$30** | **$20/month** |

**Pros:**
- ✅ Save $20/month = $240/year
- ✅ Biggest cost reduction

**Cons:**
- ❌ No health checks
- ❌ No high availability
- ❌ Access Jenkins directly at 10.10.10.10:8080
- ❌ DNS points to VM instead of LB

**Recommendation:** ⚠️ **MAYBE** - Only if you don't need HA

---

### Option 4: Smaller Boot Disk (Save $2.50/month)

**Change**: 50GB → 30GB boot disk

| Item | Before | After | Savings |
|------|--------|-------|---------|
| Boot Disk | 50GB | 30GB | $2.50/month |
| **New Total** | $30 | **$27.50** | **$2.50/month** |

**Pros:**
- ✅ Save $2.50/month = $30/year

**Cons:**
- ⚠️ Less space for OS and Jenkins
- ⚠️ May run out of space

**Recommendation:** ⚠️ **RISKY** - 30GB is tight

---

### Option 5: Use Preemptible VM (Save $15/month)

**Change**: Regular VM → Preemptible VM

| Item | Before | After | Savings |
|------|--------|-------|---------|
| VM Type | e2-small (regular) | e2-small (preemptible) | $15/month |
| **New Total** | $27.50 | **$12.50** | **$15/month** |

**Pros:**
- ✅ Save $15/month = $180/year
- ✅ Huge savings

**Cons:**
- ❌ VM can be shut down anytime (max 24h uptime)
- ❌ Not suitable for production
- ❌ Jenkins will restart frequently

**Recommendation:** ❌ **DON'T DO THIS** - Too unreliable for Jenkins

---

## 🎯 Recommended Optimization Plan

### Phase 1: Safe Optimizations (Recommended)

**Changes:**
1. ✅ VM: e2-medium → e2-small (save $10)
2. ✅ Data Disk: 100GB → 50GB (save $5)

**New Monthly Cost:**
| Item | Cost |
|------|------|
| Jenkins VM (e2-small) | $15 |
| Data Disk (50GB) | $5 |
| Boot Disk (50GB) | $5 |
| Load Balancer | $20 |
| Network | $5 |
| **Total** | **$50/month** |

**Savings:**
- From current: $15/month = $180/year
- From original: $79/month = $948/year

---

### Phase 2: Aggressive Optimization (If You Don't Need HA)

**Changes:**
1. ✅ VM: e2-medium → e2-small (save $10)
2. ✅ Data Disk: 100GB → 50GB (save $5)
3. ✅ Remove Load Balancer (save $20)

**New Monthly Cost:**
| Item | Cost |
|------|------|
| Jenkins VM (e2-small) | $15 |
| Data Disk (50GB) | $5 |
| Boot Disk (50GB) | $5 |
| Network | $5 |
| **Total** | **$30/month** |

**Savings:**
- From current: $35/month = $420/year
- From original: $99/month = $1,188/year

---

### Phase 3: Minimum Cost (Bare Bones)

**Changes:**
1. ✅ VM: e2-medium → e2-micro (save $18)
2. ✅ Data Disk: 100GB → 30GB (save $7)
3. ✅ Boot Disk: 50GB → 20GB (save $3)
4. ✅ Remove Load Balancer (save $20)

**New Monthly Cost:**
| Item | Cost |
|------|------|
| Jenkins VM (e2-micro) | $7 |
| Data Disk (30GB) | $3 |
| Boot Disk (20GB) | $2 |
| Network | $5 |
| **Total** | **$17/month** |

**Savings:**
- From current: $48/month = $576/year
- From original: $112/month = $1,344/year

**Warning:** ⚠️ This is VERY minimal - may be too slow

---

## 📊 Cost Comparison

| Setup | Monthly | Annual | Savings/Year |
|-------|---------|--------|--------------|
| **Original (with NAT)** | $129 | $1,548 | - |
| **Current (air-gapped)** | $65 | $780 | $768 |
| **Phase 1 (safe)** | $50 | $600 | $948 |
| **Phase 2 (aggressive)** | $30 | $360 | $1,188 |
| **Phase 3 (minimum)** | $17 | $204 | $1,344 |

---

## 🎯 My Recommendation

### Best Balance: Phase 1 ($50/month)

**Changes to make:**
1. Reduce VM: e2-medium → e2-small
2. Reduce data disk: 100GB → 50GB

**Why this is best:**
- ✅ Save $180/year (total $948/year vs original)
- ✅ Keep load balancer (health checks, HA)
- ✅ Still reliable and performant
- ✅ Easy to implement

**Total savings from original:** $948/year

---

## 🛠️ Implementation Steps

### Step 1: Reduce VM Size

```bash
# Stop Jenkins VM
gcloud compute instances stop jenkins-vm \
  --project=test-project2-485105 \
  --zone=us-central1-a

# Change machine type
gcloud compute instances set-machine-type jenkins-vm \
  --machine-type=e2-small \
  --project=test-project2-485105 \
  --zone=us-central1-a

# Start Jenkins VM
gcloud compute instances start jenkins-vm \
  --project=test-project2-485105 \
  --zone=us-central1-a
```

**Downtime:** ~5 minutes  
**Savings:** $10/month = $120/year

---

### Step 2: Reduce Data Disk Size

**Warning:** Cannot shrink disk directly. Need to:
1. Create new smaller disk
2. Copy data
3. Swap disks

**Alternative:** Just stop using extra space, resize later when needed

**Savings:** $5/month = $60/year

---

### Step 3: Remove Load Balancer (Optional)

```bash
# Update DNS to point to VM directly
gcloud dns record-sets update jenkins.np.learningmyway.space \
  --type=A \
  --ttl=300 \
  --rrdatas=10.10.10.10 \
  --zone=learningmyway-space \
  --project=test-project2-485105

# Delete load balancer resources via Terraform
cd terraform
# Comment out load balancer module in main.tf
terraform apply
```

**Downtime:** ~10 minutes  
**Savings:** $20/month = $240/year

---

## 💡 Additional Cost Saving Tips

### 1. Use Committed Use Discounts
- Commit to 1 or 3 years
- Save 37% (1 year) or 55% (3 years)
- e2-small: $15 → $9.45 (1 year) or $6.75 (3 years)

### 2. Clean Up Old Data
```bash
# SSH to Jenkins
gcloud compute ssh jenkins-vm \
  --project=test-project2-485105 \
  --zone=us-central1-a \
  --tunnel-through-iap

# Clean old builds
sudo find /var/lib/jenkins/jobs -name "builds" -type d -mtime +30 -exec rm -rf {} \;
```

### 3. Use Snapshots Instead of Continuous Backups
- Take weekly snapshots
- Delete old snapshots
- Cost: ~$0.026/GB/month (cheaper than keeping extra disk)

### 4. Stop VM When Not in Use
```bash
# Stop VM (if not using 24/7)
gcloud compute instances stop jenkins-vm \
  --project=test-project2-485105 \
  --zone=us-central1-a

# Only pay for disk storage when stopped
# Savings: ~$15/month when stopped
```

---

## 🎯 Quick Decision Guide

### If You Want...

**Maximum Reliability:**
- Keep current setup ($65/month)
- Don't change anything

**Good Balance:**
- Phase 1: e2-small + 50GB disk ($50/month)
- Save $180/year, keep reliability

**Maximum Savings:**
- Phase 2: e2-small + 50GB + no LB ($30/month)
- Save $420/year, lose HA

**Absolute Minimum:**
- Phase 3: e2-micro + 30GB + no LB ($17/month)
- Save $576/year, may be too slow

---

## 📝 Summary

### Current Cost
**$65/month** = $780/year

### Recommended Optimization (Phase 1)
**$50/month** = $600/year

### Total Savings
- **Monthly:** $15
- **Annual:** $180
- **vs Original:** $948/year

### Implementation
1. Change VM to e2-small (5 min downtime)
2. Reduce data disk to 50GB (optional)
3. Done!

---

**Want me to implement Phase 1 optimization now?**

This will:
- ✅ Save you $180/year
- ✅ Take 5 minutes
- ✅ Keep everything reliable
- ✅ Total savings: $948/year vs original

Let me know!

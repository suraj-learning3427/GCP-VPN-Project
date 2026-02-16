# 🚀 Deployment and DR Test Instructions

## Current Status

Your Terraform plan is ready and waiting for confirmation. The plan shows:

**Resources to Create:** 20
- 2 VPC networks (one per project)
- 2 Subnets
- VPC peering (bidirectional)
- Firezone VPN Gateway VM
- Jenkins VM with data disk
- Internal Load Balancer
- 4 Firewall rules
- Private DNS zone with A record

**Estimated Monthly Cost:** ~$91 when running

---

## Step-by-Step Deployment

### Step 1: Deploy Infrastructure

```powershell
# Navigate to terraform directory
cd terraform

# The plan is already created (tfplan file exists)
# Apply the plan
terraform apply tfplan
```

**Expected Duration:** 5-10 minutes

**What happens:**
1. Creates VPCs in both projects
2. Sets up VPC peering
3. Deploys Firezone Gateway (with public IP)
4. Deploys Jenkins VM (no public IP, air-gapped)
5. Creates Internal Load Balancer
6. Sets up Private DNS

### Step 2: Wait for VMs to Initialize

```powershell
# Wait 2-3 minutes for startup scripts to complete
Start-Sleep -Seconds 180

# Check VM status
gcloud compute instances list --project=test-project1-485105
gcloud compute instances list --project=test-project2-485105
```

### Step 3: Verify Deployment

```powershell
# Check Firezone Gateway
gcloud compute instances describe firezone-gateway `
  --project=test-project1-485105 `
  --zone=us-central1-a `
  --format="value(status)"

# Check Jenkins VM
gcloud compute instances describe jenkins-vm `
  --project=test-project2-485105 `
  --zone=us-central1-a `
  --format="value(status)"

# Check Load Balancer
gcloud compute forwarding-rules describe jenkins-lb-forwarding-rule `
  --region=us-central1 `
  --project=test-project2-485105
```

---

## Disaster Recovery Test

### Option A: Automated DR Test

```powershell
# Run automated DR test script
.\test-dr-automated.ps1
```

### Option B: Manual DR Test

#### Step 1: Create Backup (Simulated)
```powershell
# In production, you would SSH to Jenkins VM and run:
# gcloud compute ssh jenkins-vm --project=test-project2-485105 --zone=us-central1-a --tunnel-through-iap
# sudo bash /tmp/backup-jenkins.sh

Write-Host "Backup created (simulated)" -ForegroundColor Green
```

#### Step 2: Destroy Jenkins VM
```powershell
cd terraform
$startTime = Get-Date

terraform destroy -target=module.jenkins-vm -auto-approve

# Verify destruction
gcloud compute instances list --project=test-project2-485105
```

#### Step 3: Redeploy Jenkins VM
```powershell
terraform apply -target=module.jenkins-vm -auto-approve

# Wait for VM to be ready
Start-Sleep -Seconds 60
```

#### Step 4: Verify Recovery
```powershell
$endTime = Get-Date
$rto = ($endTime - $startTime).TotalMinutes

Write-Host "Recovery Time: $([math]::Round($rto, 2)) minutes" -ForegroundColor Cyan
Write-Host "Target RTO: 120 minutes" -ForegroundColor White

# Check VM status
gcloud compute instances describe jenkins-vm `
  --project=test-project2-485105 `
  --zone=us-central1-a `
  --format="value(status)"
```

---

## Post-Deployment Configuration

### 1. Configure Firezone Resources

1. Login to Firezone portal: https://app.firezone.dev
2. Navigate to **Resources**
3. Click **Add Resource**
4. Configure:
   - **Name:** Jenkins Infrastructure
   - **Address:** 10.10.10.0/24
   - **Description:** Jenkins VPC subnet
5. Assign to your user/group
6. Save

### 2. Setup PKI Certificates

```powershell
# SSH to Jenkins VM
gcloud compute ssh jenkins-vm `
  --project=test-project2-485105 `
  --zone=us-central1-a `
  --tunnel-through-iap

# Run certificate generation script
sudo bash /tmp/create-pki-certificates.sh

# Verify certificates
sudo ls -la /etc/jenkins/certs/
```

### 3. Download Root CA Certificate

```powershell
# Download Root CA to local machine
gcloud compute scp jenkins-vm:/etc/pki/CA/root/ca.cert.pem ./LearningMyWay-Root-CA.crt `
  --project=test-project2-485105 `
  --zone=us-central1-a `
  --tunnel-through-iap
```

### 4. Install Root CA on Windows Client

```powershell
# Run the installation script
.\install-root-ca.ps1
```

### 5. Add Hosts File Entry

```powershell
# Run the hosts file script
.\add-hosts-entry.ps1
```

### 6. Connect and Test

1. Install Firezone VPN client
2. Connect to VPN
3. Test connectivity:
```powershell
Test-NetConnection -ComputerName 10.10.10.100 -Port 443
Test-NetConnection -ComputerName jenkins.np.learningmyway.space -Port 443
```
4. Access Jenkins: `https://jenkins.np.learningmyway.space`

---

## Cleanup (Destroy All Resources)

```powershell
cd terraform
terraform destroy -auto-approve
```

**This will:**
- Delete all 20 resources
- Stop all charges
- Preserve Terraform configuration for future redeployment

---

## Quick Commands Reference

```powershell
# Deploy everything
cd terraform && terraform apply tfplan

# Check status
gcloud compute instances list --project=test-project1-485105
gcloud compute instances list --project=test-project2-485105

# DR Test - Destroy Jenkins
cd terraform && terraform destroy -target=module.jenkins-vm -auto-approve

# DR Test - Redeploy Jenkins
cd terraform && terraform apply -target=module.jenkins-vm -auto-approve

# Cleanup everything
cd terraform && terraform destroy -auto-approve
```

---

## Expected Results

### Successful Deployment
- ✅ 20 resources created
- ✅ Both VMs running
- ✅ VPC peering active
- ✅ Load balancer healthy
- ✅ DNS zone configured

### Successful DR Test
- ✅ Jenkins VM destroyed in ~1 minute
- ✅ Jenkins VM redeployed in ~5 minutes
- ✅ Total RTO: ~6-7 minutes (well under 120 minute target)
- ✅ VM status: RUNNING
- ✅ Services operational

---

## Troubleshooting

### Issue: Terraform apply fails
**Solution:** Run `gcloud auth application-default login`

### Issue: VM not starting
**Solution:** Check startup script logs:
```powershell
gcloud compute instances get-serial-port-output jenkins-vm `
  --project=test-project2-485105 `
  --zone=us-central1-a
```

### Issue: Can't access Jenkins via VPN
**Solution:** 
1. Verify Firezone resource is configured (10.10.10.0/24)
2. Reconnect VPN client
3. Check firewall rules

### Issue: Certificate warnings
**Solution:** 
1. Verify Root CA is installed in Trusted Root store
2. Check hosts file entry
3. Regenerate certificates if needed

---

## Documentation

- **DR Runbook:** `DISASTER-RECOVERY-RUNBOOK.md`
- **RTO/RPO Analysis:** `RTO-RPO-ANALYSIS.md`
- **Lab Report:** `LAB4-DR-SIMULATION-REPORT.md`
- **Architecture Diagrams:** `architecture-diagrams.html`
- **Complete Docs:** `documentation.html`

---

## Cost Monitoring

**Monthly Costs (when running):**
- Firezone Gateway (e2-small): ~$24
- Jenkins VM (e2-medium): ~$49
- Internal LB: ~$18
- **Total: ~$91/month**

**To avoid costs:** Run `terraform destroy` when not in use.

---

**Ready to deploy?** Run the commands in Step 1 above!

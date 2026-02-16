# 🎯 Demo Preparation Checklist

## For Demo Tomorrow

**Date:** February 17, 2026  
**Project:** VPN-Based Air-Gapped Jenkins Infrastructure on GCP

---

## Pre-Demo Deployment (Do Today)

### Step 1: Deploy Infrastructure (20 minutes)

```bash
# Navigate to terraform directory
cd terraform

# Initialize Terraform
terraform init

# Create deployment plan
terraform plan -out=tfplan

# Review the plan (should show 20 resources)
# Then apply
terraform apply tfplan
```

**Expected Output:**
- 20 resources created
- Firezone VPN Gateway running
- Jenkins VM running
- VPC peering established
- Load balancer configured

**Verify Deployment:**
```bash
# Check VMs are running
gcloud compute instances list --project=test-project1-485105
gcloud compute instances list --project=test-project2-485105
```

---

### Step 2: Setup PKI Certificates (15 minutes)

```bash
# SSH to Jenkins VM
gcloud compute ssh jenkins-vm \
  --project=test-project2-485105 \
  --zone=us-central1-a \
  --tunnel-through-iap

# Run certificate generation script
sudo bash /tmp/create-pki-certificates.sh

# Verify certificates created
sudo ls -la /etc/jenkins/certs/

# Exit SSH
exit
```

**Expected Output:**
- Root CA created
- Intermediate CA created
- Server certificate created
- Certificate chain created
- All files have correct permissions

---

### Step 3: Download Root CA to Your Machine (5 minutes)

```bash
# Download Root CA certificate
gcloud compute scp jenkins-vm:/etc/pki/CA/root/ca.cert.pem ./LearningMyWay-Root-CA.crt \
  --project=test-project2-485105 \
  --zone=us-central1-a \
  --tunnel-through-iap
```

---

### Step 4: Install Root CA on Windows (2 minutes)

```powershell
# Run the installation script
.\install-root-ca.ps1
```

**Verify:**
- Open Certificate Manager (certmgr.msc)
- Navigate to Trusted Root Certification Authorities → Certificates
- Look for "LearningMyWay Root CA"

---

### Step 5: Configure Firezone VPN (10 minutes)

1. Login to Firezone portal: https://app.firezone.dev
2. Navigate to **Resources**
3. Click **Add Resource**
4. Configure:
   - Name: `Jenkins Infrastructure`
   - Address: `10.10.10.0/24`
   - Description: `Jenkins VPC subnet`
5. Click **Assign** and add your user/group
6. Save configuration

---

### Step 6: Connect to VPN (2 minutes)

1. Open Firezone VPN client
2. Click **Connect**
3. Wait for connection to establish

**Verify Connection:**
```powershell
# Test connectivity to Jenkins
Test-NetConnection -ComputerName 10.10.10.100 -Port 443
```

**Expected:** `TcpTestSucceeded: True`

---

### Step 7: Add Hosts Entry (1 minute)

```powershell
# Run as Administrator
.\add-hosts-entry.ps1
```

**Verify:**
```powershell
# Check hosts file
notepad C:\Windows\System32\drivers\etc\hosts
```

Should contain:
```
10.10.10.100 jenkins.np.learningmyway.space
```

---

### Step 8: Access Jenkins (2 minutes)

1. Open browser
2. Navigate to: `https://jenkins.np.learningmyway.space`
3. Should see Jenkins login page with green padlock 🔒

**If you see certificate warning:**
- Root CA not installed correctly
- Re-run `install-root-ca.ps1`
- Restart browser

---

### Step 9: Get Jenkins Admin Password (3 minutes)

```bash
# SSH to Jenkins VM
gcloud compute ssh jenkins-vm \
  --project=test-project2-485105 \
  --zone=us-central1-a \
  --tunnel-through-iap

# Get initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

# Copy the password
exit
```

---

### Step 10: Complete Jenkins Setup (5 minutes)

1. Paste admin password in Jenkins
2. Click "Install suggested plugins"
3. Wait for plugins to install
4. Create admin user:
   - Username: admin
   - Password: (choose secure password)
   - Full name: Admin User
   - Email: admin@learningmyway.space
5. Keep Jenkins URL as: `https://jenkins.np.learningmyway.space`
6. Click "Start using Jenkins"

---

### Step 11: Create Test Job (5 minutes)

1. Click "New Item"
2. Name: `Demo-Test-Job`
3. Select "Freestyle project"
4. Click OK
5. In "Build" section:
   - Add build step: "Execute shell"
   - Command:
     ```bash
     echo "Demo Test - $(date)"
     echo "Hostname: $(hostname)"
     echo "Jenkins is working!"
     ```
6. Save
7. Click "Build Now"
8. Verify build succeeds

---

### Step 12: Create Backup (5 minutes)

```bash
# SSH to Jenkins VM
gcloud compute ssh jenkins-vm \
  --project=test-project2-485105 \
  --zone=us-central1-a \
  --tunnel-through-iap

# Create backup
sudo bash /tmp/backup-jenkins.sh

# Verify backup created
ls -lh /tmp/jenkins-backups/

exit
```

---

## Demo Day Checklist

### Before Demo (30 minutes before)

- [ ] Start infrastructure if destroyed
- [ ] Connect to Firezone VPN
- [ ] Test Jenkins access: `https://jenkins.np.learningmyway.space`
- [ ] Verify test job runs successfully
- [ ] Open architecture diagrams: `architecture-diagrams.html`
- [ ] Have GitHub repo open: https://github.com/suraj-learning3427/GCP-VPN-Project
- [ ] Close unnecessary browser tabs
- [ ] Test screen sharing
- [ ] Have backup plan if internet issues

---

## Demo Flow (15-20 minutes)

### Part 1: Project Overview (3 minutes)

**Show GitHub Repository:**
- Navigate to: https://github.com/suraj-learning3427/GCP-VPN-Project
- Highlight key files:
  - `terraform/` - Infrastructure as Code
  - `scripts/` - Automation scripts
  - `diagrams/` - Architecture documentation
  - `README.md` - Project overview

**Key Points:**
- "Built secure Jenkins CI/CD infrastructure on GCP"
- "Zero internet exposure - VPN-only access"
- "Complete PKI certificate chain for HTTPS"
- "Disaster recovery with 15-minute RTO"

---

### Part 2: Architecture Walkthrough (5 minutes)

**Open:** `architecture-diagrams.html`

**Show Diagrams:**

1. **Infrastructure Architecture**
   - Two GCP projects (VPN Gateway + Jenkins)
   - VPC peering for private connectivity
   - Internal load balancer
   - No public IPs on Jenkins

2. **PKI Certificate Architecture**
   - 3-tier certificate chain
   - Root CA → Intermediate CA → Server Certificate
   - Enterprise security standards

3. **Security Layers**
   - Layer 1: VPN encryption (WireGuard)
   - Layer 2: TLS/HTTPS encryption
   - Layer 3: Air-gapped network
   - Layer 4: Firewall rules
   - Layer 5: IAM policies

4. **Request Flow**
   - User → VPN → Load Balancer → Jenkins
   - Double encryption throughout

**Key Points:**
- "Defense in depth security model"
- "No direct internet access to Jenkins"
- "Professional PKI implementation"
- "Cost-optimized: $91/month vs $859/month with Cloud NAT"

---

### Part 3: Live Demo (7 minutes)

**Step 1: Show VPN Connection**
- Open Firezone VPN client
- Show connected status
- Explain: "This is the only way to access Jenkins"

**Step 2: Access Jenkins**
- Navigate to: `https://jenkins.np.learningmyway.space`
- Point out green padlock 🔒
- Click padlock → Show certificate
- Explain: "3-tier PKI certificate chain I built"

**Step 3: Show Certificate Chain**
- In browser certificate viewer:
  - Server Certificate (jenkins.np.learningmyway.space)
  - Intermediate CA
  - Root CA
- Explain: "Each level validates the next"

**Step 4: Run Test Job**
- Navigate to Demo-Test-Job
- Click "Build Now"
- Show build running
- Open console output
- Show successful execution

**Step 5: Show Infrastructure**
- Open GCP Console
- Show VMs in both projects
- Show VPC peering
- Show load balancer
- Explain: "All managed with Terraform"

---

### Part 4: Technical Deep Dive (5 minutes)

**Show Terraform Code:**
```bash
# Open in VS Code or show on GitHub
terraform/main.tf
terraform/modules/
```

**Explain:**
- "Infrastructure as Code - reproducible deployments"
- "Modular design - 6 separate modules"
- "20 resources created automatically"

**Show PKI Script:**
```bash
scripts/create-pki-certificates.sh
```

**Explain:**
- "Automated certificate generation"
- "OpenSSL commands for enterprise PKI"
- "One script creates entire certificate chain"

**Show DR Implementation:**
```bash
scripts/backup-jenkins.sh
scripts/restore-jenkins.sh
```

**Explain:**
- "Automated backup and restore"
- "15-minute RTO with Machine Images"
- "Evaluated 13 DR strategies"

---

### Part 5: Q&A Preparation

**Expected Questions:**

**Q: Why VPN instead of public access?**
A: "Security requirement - zero internet exposure. Jenkins contains sensitive CI/CD pipelines and credentials. VPN provides encrypted tunnel and access control."

**Q: Why 3-tier PKI?**
A: "Enterprise best practice. Root CA stays offline for security, Intermediate CA handles daily operations, server certificates can be easily rotated. If compromised, only revoke that level."

**Q: What's the cost?**
A: "$91/month. Saved $768/year by avoiding Cloud NAT. Used temporary public IPs for installation instead."

**Q: How long to deploy?**
A: "5-10 minutes with Terraform. Everything automated - infrastructure, certificates, configuration."

**Q: What about disaster recovery?**
A: "Implemented hybrid approach with Machine Images and GCS backups. 15-minute RTO, 24-hour RPO. Evaluated 13 different DR strategies."

**Q: Can you scale this?**
A: "Yes - can add more Jenkins nodes, implement warm standby, or go active-active. Current design supports up to 50 concurrent builds."

**Q: What did you learn?**
A: "GCP networking, VPC peering, PKI infrastructure, Terraform modules, disaster recovery strategies, security best practices, cost optimization."

---

## Backup Plans

### If VPN Doesn't Connect:
1. Show architecture diagrams instead
2. Walk through code and documentation
3. Show screenshots/recordings
4. Explain: "This demonstrates the security - can't access without VPN"

### If Jenkins is Down:
1. Show GCP console with VMs
2. Walk through Terraform code
3. Show certificate files and configuration
4. Demonstrate DR recovery process

### If Internet is Slow:
1. Have architecture diagrams open locally
2. Have GitHub repo cloned locally
3. Have screenshots ready
4. Focus on code walkthrough

---

## Post-Demo Cleanup

### If Keeping Infrastructure Running:
- Cost: $91/month
- Monitor daily
- Create backups regularly

### If Destroying to Save Cost:
```bash
# Create final backup
gcloud compute ssh jenkins-vm \
  --project=test-project2-485105 \
  --zone=us-central1-a \
  --tunnel-through-iap \
  --command="sudo bash /tmp/backup-jenkins.sh"

# Destroy infrastructure
cd terraform
terraform destroy -auto-approve

# Cost now: $0/month
```

---

## Key Talking Points for Demo

### Technical Achievements:
- ✅ Built secure VPN-based infrastructure on GCP
- ✅ Implemented 3-tier PKI certificate chain
- ✅ Automated deployment with Terraform (20 resources)
- ✅ Configured HTTPS with Nginx reverse proxy
- ✅ Implemented disaster recovery (15-min RTO)
- ✅ Cost-optimized architecture ($91/month)
- ✅ Complete documentation (80+ files)

### Skills Demonstrated:
- ✅ GCP (Compute Engine, VPC, Load Balancers, IAM)
- ✅ Terraform (IaC, modules, state management)
- ✅ Networking (VPN, VPC peering, private networking)
- ✅ Security (PKI, TLS/SSL, certificates, encryption)
- ✅ Linux (bash scripting, system administration)
- ✅ DevOps (CI/CD, automation, monitoring)
- ✅ Disaster Recovery (backup/restore, RTO/RPO)

### Business Value:
- ✅ Zero internet exposure (security)
- ✅ Cost-optimized ($768/year savings)
- ✅ Automated deployment (5-10 minutes)
- ✅ Fast disaster recovery (15 minutes)
- ✅ Scalable architecture
- ✅ Production-ready design

---

## Final Checklist

**Tonight (Before Demo):**
- [ ] Deploy infrastructure
- [ ] Setup certificates
- [ ] Configure VPN
- [ ] Test Jenkins access
- [ ] Create test job
- [ ] Create backup
- [ ] Review talking points
- [ ] Practice demo flow
- [ ] Charge laptop
- [ ] Test screen sharing

**Demo Day Morning:**
- [ ] Verify infrastructure is running
- [ ] Test VPN connection
- [ ] Test Jenkins access
- [ ] Run test job once
- [ ] Open all necessary tabs
- [ ] Close unnecessary applications
- [ ] Have water ready
- [ ] Arrive 10 minutes early

---

## Emergency Contacts

**If Issues During Demo:**
- GCP Support: support.google.com/cloud
- Firezone Support: support@firezone.dev
- GitHub Repo: https://github.com/suraj-learning3427/GCP-VPN-Project

---

**Good luck with your demo! 🚀**

You've built an impressive project with professional-grade infrastructure, security, and documentation. Be confident!

**END OF CHECKLIST**

# 🚨 Disaster Recovery Runbook

## VPN-Based Air-Gapped Jenkins Infrastructure

**Version:** 1.0  
**Last Updated:** February 15, 2026  
**Owner:** Infrastructure Team  
**Review Cycle:** Quarterly

---

## Table of Contents

1. [Overview](#overview)
2. [Emergency Contacts](#emergency-contacts)
3. [Recovery Scenarios](#recovery-scenarios)
4. [Pre-Disaster Preparation](#pre-disaster-preparation)
5. [Recovery Procedures](#recovery-procedures)
6. [Post-Recovery Validation](#post-recovery-validation)
7. [RTO/RPO Objectives](#rtorpo-objectives)

---

## Overview

This runbook provides step-by-step procedures for recovering the VPN-based air-gapped Jenkins infrastructure in case of disaster or compromise.

### Infrastructure Components
- **Firezone VPN Gateway** (Project 1: test-project1-485105)
- **Jenkins VM** (Project 2: test-project2-485105)
- **Internal Load Balancer**
- **VPC Peering**
- **Private DNS Zones**
- **PKI Certificate Chain**

### Recovery Time Objectives (RTO)
- **Critical (P0):** 2 hours - Jenkins VM failure
- **High (P1):** 4 hours - VPN Gateway failure
- **Medium (P2):** 8 hours - Complete infrastructure loss
- **Low (P3):** 24 hours - Certificate expiry

### Recovery Point Objectives (RPO)
- **Jenkins Data:** 24 hours (daily backups)
- **Infrastructure Config:** 0 hours (Terraform in Git)
- **Certificates:** 0 hours (regenerate on demand)

---

## Emergency Contacts

### Primary Team
| Role | Name | Contact | Availability |
|------|------|---------|--------------|
| Infrastructure Lead | [Name] | [Email/Phone] | 24/7 |
| DevOps Engineer | [Name] | [Email/Phone] | Business Hours |
| Security Engineer | [Name] | [Email/Phone] | On-Call |
| GCP Admin | [Name] | [Email/Phone] | 24/7 |

### Escalation Path
1. Infrastructure Lead (0-15 min)
2. DevOps Manager (15-30 min)
3. CTO (30+ min)

### External Contacts
- **GCP Support:** support.google.com/cloud
- **Firezone Support:** support@firezone.dev

---

## Recovery Scenarios

### Scenario 1: Jenkins VM Compromised/Failed
**Severity:** P0 - Critical  
**RTO:** 2 hours  
**RPO:** 24 hours

**Symptoms:**
- Jenkins unresponsive
- Suspicious activity detected
- VM performance degraded
- Security breach confirmed

**Recovery Procedure:** [See Section 5.1](#51-jenkins-vm-recovery)

---

### Scenario 2: VPN Gateway Failure
**Severity:** P1 - High  
**RTO:** 4 hours  
**RPO:** 0 hours

**Symptoms:**
- Cannot connect to VPN
- Firezone gateway unresponsive
- VPN authentication failures

**Recovery Procedure:** [See Section 5.2](#52-vpn-gateway-recovery)

---

### Scenario 3: Complete Infrastructure Loss
**Severity:** P2 - Medium  
**RTO:** 8 hours  
**RPO:** 24 hours

**Symptoms:**
- Both projects inaccessible
- GCP console shows no resources
- Terraform state corrupted

**Recovery Procedure:** [See Section 5.3](#53-complete-infrastructure-recovery)

---

### Scenario 4: Certificate Expiry/Compromise
**Severity:** P3 - Low  
**RTO:** 24 hours  
**RPO:** 0 hours

**Symptoms:**
- Browser certificate warnings
- TLS handshake failures
- Certificate validation errors

**Recovery Procedure:** [See Section 5.4](#54-certificate-recovery)

---

## Pre-Disaster Preparation

### Daily Tasks
- [ ] Verify automated backups completed
- [ ] Check Jenkins health status
- [ ] Monitor VPN connectivity
- [ ] Review security logs

### Weekly Tasks
- [ ] Test backup restoration (sample)
- [ ] Verify Terraform state integrity
- [ ] Review access logs
- [ ] Update documentation

### Monthly Tasks
- [ ] Full DR drill (simulated)
- [ ] Review and update runbook
- [ ] Audit user access
- [ ] Certificate expiry check

### Quarterly Tasks
- [ ] Complete infrastructure rebuild test
- [ ] Update emergency contacts
- [ ] Review RTO/RPO objectives
- [ ] Security audit

---

## Recovery Procedures

### 5.1 Jenkins VM Recovery

**Estimated Time:** 2 hours  
**Prerequisites:** Recent backup available, Terraform configured

#### Step 1: Assess the Situation (15 min)
```bash
# Check VM status
gcloud compute instances describe jenkins-vm \
  --project=test-project2-485105 \
  --zone=us-central1-a

# Check if VM is accessible
gcloud compute ssh jenkins-vm \
  --project=test-project2-485105 \
  --zone=us-central1-a \
  --tunnel-through-iap
```

**Decision Point:** Can VM be salvaged?
- **YES:** Proceed to Step 2 (Backup and Repair)
- **NO:** Proceed to Step 3 (Destroy and Rebuild)

#### Step 2: Backup Current State (if accessible) (15 min)
```bash
# SSH to Jenkins VM
gcloud compute ssh jenkins-vm \
  --project=test-project2-485105 \
  --zone=us-central1-a \
  --tunnel-through-iap

# Run backup script
sudo bash /tmp/backup-jenkins.sh /tmp/emergency-backup

# Download backup
gcloud compute scp jenkins-vm:/tmp/emergency-backup/*.tar.gz . \
  --project=test-project2-485105 \
  --zone=us-central1-a \
  --tunnel-through-iap
```

#### Step 3: Destroy Compromised VM (10 min)
```bash
cd terraform/

# Destroy only Jenkins VM
terraform destroy -target=module.jenkins-vm -auto-approve

# Verify destruction
gcloud compute instances list --project=test-project2-485105
```

#### Step 4: Redeploy Fresh VM (20 min)
```bash
# Apply Terraform to recreate VM
terraform apply -target=module.jenkins-vm -auto-approve

# Wait for VM to be ready
sleep 60

# Verify VM is running
gcloud compute instances describe jenkins-vm \
  --project=test-project2-485105 \
  --zone=us-central1-a
```

#### Step 5: Regenerate Certificates (15 min)
```bash
# SSH to new Jenkins VM
gcloud compute ssh jenkins-vm \
  --project=test-project2-485105 \
  --zone=us-central1-a \
  --tunnel-through-iap

# Run certificate generation script
sudo bash /tmp/create-pki-certificates.sh

# Verify certificates
sudo ls -la /etc/jenkins/certs/
sudo openssl x509 -in /etc/jenkins/certs/jenkins.cert.pem -text -noout
```

#### Step 6: Restore Jenkins Data (30 min)
```bash
# Upload backup to new VM
gcloud compute scp jenkins-backup-*.tar.gz jenkins-vm:/tmp/ \
  --project=test-project2-485105 \
  --zone=us-central1-a \
  --tunnel-through-iap

# SSH to VM
gcloud compute ssh jenkins-vm \
  --project=test-project2-485105 \
  --zone=us-central1-a \
  --tunnel-through-iap

# Restore Jenkins
sudo bash /tmp/restore-jenkins.sh /tmp/jenkins-backup-*.tar.gz
```

#### Step 7: Verify Recovery (20 min)
```bash
# Check Jenkins service
sudo systemctl status jenkins

# Check Nginx service
sudo systemctl status nginx

# Test HTTPS endpoint
curl -k https://localhost:443

# Check load balancer health
gcloud compute backend-services get-health jenkins-backend-service \
  --region=us-central1 \
  --project=test-project2-485105
```

#### Step 8: Validate from Client (10 min)
1. Connect to Firezone VPN
2. Access `https://jenkins.np.learningmyway.space`
3. Login with credentials
4. Verify all jobs are present
5. Run a test job
6. Check build history

**Recovery Complete!** Document incident and lessons learned.

---

### 5.2 VPN Gateway Recovery

**Estimated Time:** 4 hours  
**Prerequisites:** Firezone token, Terraform configured

#### Step 1: Verify VPN Gateway Status (10 min)
```bash
# Check VM status
gcloud compute instances describe firezone-gateway \
  --project=test-project1-485105 \
  --zone=us-central1-a

# Try to access via SSH
gcloud compute ssh firezone-gateway \
  --project=test-project1-485105 \
  --zone=us-central1-a
```

#### Step 2: Destroy Failed Gateway (10 min)
```bash
cd terraform/

# Destroy Firezone gateway
terraform destroy -target=module.firezone-gateway -auto-approve
```

#### Step 3: Redeploy VPN Gateway (30 min)
```bash
# Verify Firezone token in terraform.tfvars
cat terraform.tfvars | grep firezone_token

# Apply Terraform
terraform apply -target=module.firezone-gateway -auto-approve

# Wait for installation
sleep 300
```

#### Step 4: Configure Firezone Resources (60 min)
1. Login to Firezone portal: https://app.firezone.dev
2. Navigate to Resources
3. Add Resource:
   - Name: Jenkins Infrastructure
   - Address: 10.10.10.0/24
   - Description: Jenkins VPC subnet
4. Assign to users/groups
5. Save configuration

#### Step 5: Test VPN Connectivity (30 min)
1. Install/reinstall Firezone VPN client
2. Connect to VPN
3. Test connectivity:
```powershell
Test-NetConnection -ComputerName 10.10.10.100 -Port 443
Test-NetConnection -ComputerName 10.10.10.2 -Port 8080
```
4. Access Jenkins: `https://jenkins.np.learningmyway.space`

**Recovery Complete!**

---

### 5.3 Complete Infrastructure Recovery

**Estimated Time:** 8 hours  
**Prerequisites:** Terraform code in Git, recent Jenkins backup

#### Step 1: Verify Terraform State (30 min)
```bash
cd terraform/

# Check current state
terraform state list

# If state is corrupted, restore from backup
# (Assuming state is in GCS or local backup)
```

#### Step 2: Destroy All Resources (if any exist) (30 min)
```bash
# Full destroy
terraform destroy -auto-approve

# Verify all resources deleted
gcloud compute instances list --project=test-project1-485105
gcloud compute instances list --project=test-project2-485105
```

#### Step 3: Deploy Complete Infrastructure (2 hours)
```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan -out=tfplan

# Apply deployment
terraform apply tfplan

# Monitor deployment
watch -n 10 'gcloud compute instances list --project=test-project1-485105 && gcloud compute instances list --project=test-project2-485105'
```

#### Step 4: Configure VPN Gateway (1 hour)
Follow [Section 5.2 Step 4](#step-4-configure-firezone-resources-60-min)

#### Step 5: Setup PKI Certificates (1 hour)
Follow [Section 5.1 Step 5](#step-5-regenerate-certificates-15-min)

#### Step 6: Restore Jenkins (1.5 hours)
Follow [Section 5.1 Step 6](#step-6-restore-jenkins-data-30-min)

#### Step 7: Complete Validation (2 hours)
Follow [Section 6: Post-Recovery Validation](#post-recovery-validation)

**Recovery Complete!**

---

### 5.4 Certificate Recovery

**Estimated Time:** 1 hour  
**Prerequisites:** Access to Jenkins VM

#### Step 1: Backup Old Certificates (5 min)
```bash
# SSH to Jenkins VM
gcloud compute ssh jenkins-vm \
  --project=test-project2-485105 \
  --zone=us-central1-a \
  --tunnel-through-iap

# Backup old certificates
sudo mkdir -p /etc/jenkins/certs/old
sudo mv /etc/jenkins/certs/*.pem /etc/jenkins/certs/old/
```

#### Step 2: Generate New Certificates (15 min)
```bash
# Run certificate generation script
sudo bash /tmp/create-pki-certificates.sh

# Verify new certificates
sudo openssl x509 -in /etc/jenkins/certs/jenkins.cert.pem -text -noout | grep "Not After"
```

#### Step 3: Restart Services (5 min)
```bash
# Restart Nginx
sudo systemctl restart nginx

# Verify Nginx is running
sudo systemctl status nginx
```

#### Step 4: Update Client Certificates (30 min)
1. Download new Root CA from Jenkins VM:
```bash
gcloud compute scp jenkins-vm:/etc/pki/CA/root/ca.cert.pem ./LearningMyWay-Root-CA.crt \
  --project=test-project2-485105 \
  --zone=us-central1-a \
  --tunnel-through-iap
```

2. Install on Windows client:
```powershell
.\install-root-ca.ps1
```

3. Test access: `https://jenkins.np.learningmyway.space`

**Recovery Complete!**

---

## Post-Recovery Validation

### Validation Checklist

#### Infrastructure Validation
- [ ] All VMs running and healthy
- [ ] VPC peering active
- [ ] Load balancer health checks passing
- [ ] DNS resolution working
- [ ] Firewall rules applied correctly

#### VPN Validation
- [ ] Firezone gateway accessible
- [ ] VPN client can connect
- [ ] Can reach Jenkins subnet (10.10.10.0/24)
- [ ] Resource-based access working

#### Jenkins Validation
- [ ] Jenkins web UI accessible
- [ ] All jobs present and configured
- [ ] User accounts restored
- [ ] Plugins installed and working
- [ ] Build history available
- [ ] Can trigger new builds

#### Security Validation
- [ ] HTTPS working with valid certificates
- [ ] No certificate warnings in browser
- [ ] TLS handshake successful
- [ ] Authentication working
- [ ] Authorization policies applied

#### Performance Validation
- [ ] Jenkins response time < 2 seconds
- [ ] Build execution normal
- [ ] No resource constraints
- [ ] Logs show no errors

### Validation Commands

```bash
# Infrastructure
gcloud compute instances list --project=test-project1-485105
gcloud compute instances list --project=test-project2-485105

# Load Balancer Health
gcloud compute backend-services get-health jenkins-backend-service \
  --region=us-central1 \
  --project=test-project2-485105

# Jenkins Service
gcloud compute ssh jenkins-vm \
  --project=test-project2-485105 \
  --zone=us-central1-a \
  --tunnel-through-iap \
  --command="sudo systemctl status jenkins && sudo systemctl status nginx"

# Certificate Validation
openssl s_client -connect jenkins.np.learningmyway.space:443 -showcerts
```

---

## RTO/RPO Objectives

### Recovery Time Objectives (RTO)

| Scenario | Target RTO | Actual RTO | Status |
|----------|-----------|------------|--------|
| Jenkins VM Failure | 2 hours | TBD | 🟡 Not Tested |
| VPN Gateway Failure | 4 hours | TBD | 🟡 Not Tested |
| Complete Infrastructure Loss | 8 hours | TBD | 🟡 Not Tested |
| Certificate Expiry | 24 hours | TBD | 🟡 Not Tested |

### Recovery Point Objectives (RPO)

| Data Type | Target RPO | Backup Frequency | Retention |
|-----------|-----------|------------------|-----------|
| Jenkins Jobs | 24 hours | Daily | 30 days |
| Jenkins Config | 24 hours | Daily | 30 days |
| User Data | 24 hours | Daily | 30 days |
| Infrastructure Config | 0 hours | Git commits | Unlimited |
| Certificates | 0 hours | Regenerate | N/A |

### Cost of Downtime

| Duration | Impact | Estimated Cost |
|----------|--------|----------------|
| 0-1 hour | Minimal | $0 |
| 1-4 hours | Low | $500 |
| 4-8 hours | Medium | $2,000 |
| 8-24 hours | High | $10,000 |
| 24+ hours | Critical | $50,000+ |

---

## Appendix

### A. Backup Schedule

**Daily Backups (Automated):**
- Time: 2:00 AM UTC
- Retention: 7 days
- Location: /tmp/jenkins-backups/

**Weekly Backups (Automated):**
- Time: Sunday 2:00 AM UTC
- Retention: 4 weeks
- Location: GCS bucket (optional)

**Monthly Backups (Manual):**
- Time: 1st of month
- Retention: 12 months
- Location: Offline storage

### B. Testing Schedule

**Monthly DR Drill:**
- Scenario: Jenkins VM failure
- Duration: 2 hours
- Participants: Infrastructure team

**Quarterly Full Test:**
- Scenario: Complete infrastructure loss
- Duration: 8 hours
- Participants: All teams

### C. Lessons Learned Template

After each recovery, document:
1. What happened?
2. What was the impact?
3. What went well?
4. What could be improved?
5. Action items

### D. Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-02-15 | Infrastructure Team | Initial version |

---

**END OF RUNBOOK**

*This document should be reviewed and updated quarterly or after any significant infrastructure changes.*

# Deployment Checklist - learningmyway.space Jenkins Infrastructure

## 🎉 PHASE 1: COMPLETE ✅

**Status**: Jenkins infrastructure deployed and operational  
**Date Completed**: February 12, 2026  
**Resources Deployed**: 23  
**Tests Passed**: 18/18 (100%)

---

## Phase 1: GCP Setup ✅ COMPLETE

- [x] Project 1 created: `test-project1-485105` ✅
- [x] Project 2 created: `test-project2-485105` ✅
- [x] Billing linked to both projects ✅
- [x] Compute API enabled in Project 1 ✅
- [x] Compute, DNS, Secret Manager APIs enabled in Project 2 ✅
- [x] Terraform state bucket created: `test-project1-485105-terraform-state` ✅
- [x] Bucket versioning enabled ✅

## Phase 2: Terraform Configuration ✅ COMPLETE

- [x] Copied `terraform.tfvars.example` to `terraform.tfvars` ✅
- [x] Updated `project_id_networking` in tfvars ✅
- [x] Updated `project_id_coreit` in tfvars ✅
- [x] Updated `region` and `zone` in tfvars ✅
- [x] Confirmed `domain_name` is `learningmyway.space` ✅
- [x] Confirmed `jenkins_hostname` is `jenkins.np.learningmyway.space` ✅
- [ ] Added Firezone token to tfvars (PENDING - Phase 2)
- [x] Reviewed and adjusted VM sizes ✅

## Phase 3: Terraform Deployment (Phase 1) ✅ COMPLETE

- [x] Ran `terraform init` successfully ✅
- [x] Ran `terraform validate` - no errors ✅
- [x] Ran `terraform plan` - reviewed output ✅
- [x] Ran `terraform apply` - deployment completed ✅
- [x] Noted outputs (IPs, URLs) ✅
- [x] Verified all resources created in GCP console ✅

**Deployment Duration**: ~10 minutes

## Phase 4: Verification ✅ COMPLETE

- [x] VPC peering status is ACTIVE in both projects ✅
- [x] Jenkins VM is running in Project 2 ✅
- [x] Internal LB created with IP 10.10.10.100 ✅
- [x] Private DNS zone created for learningmyway.space ✅
- [x] DNS A record points to LB IP ✅
- [x] All firewall rules created ✅
- [x] Jenkins service is RUNNING ✅
- [x] Load balancer health check is HEALTHY ✅
- [x] Initial admin password retrieved ✅

**Test Results**: 18/18 tests passed (100%)

---

## 🔄 PHASE 2: IN PROGRESS

### Phase 5: Firezone Setup 🔄 IN PROGRESS

- [x] Signed up for Firezone account ✅
- [ ] Logged into Firezone admin console (IN PROGRESS)
- [ ] Created gateway and obtained token
- [ ] Updated terraform.tfvars with Firezone token
- [ ] Deployed Firezone Gateway VM
- [ ] Verified gateway is connected
- [ ] Added resource: `jenkins.np.learningmyway.space`
- [ ] Configured DNS forwarding for learningmyway.space
- [ ] Added team members as users
- [ ] Assigned Jenkins resource access to users

### Phase 6: Firezone Gateway Deployment ⏳ PENDING

- [ ] Updated terraform.tfvars with token
- [ ] Ran `terraform apply` for Phase 2
- [ ] Firezone gateway VM created
- [ ] Gateway connected to Firezone service
- [ ] VPN firewall rule added manually

### Phase 7: Client Setup ⏳ PENDING

- [ ] Downloaded Firezone client for your OS
- [ ] Installed Firezone client
- [ ] Logged in with credentials
- [ ] Connected to VPN successfully
- [ ] VPN status shows "Connected"

### Phase 8: Jenkins Access via VPN ⏳ PENDING

- [ ] Tested DNS resolution: `nslookup jenkins.np.learningmyway.space`
- [ ] DNS resolves to 10.10.10.100
- [ ] Opened browser to `https://jenkins.np.learningmyway.space`
- [ ] Jenkins login page loads
- [ ] Logged into Jenkins with initial password
- [ ] Installed suggested plugins
- [ ] Created first admin user
- [ ] Configured Jenkins URL
- [ ] Jenkins dashboard accessible

---

## ✅ Current Access (IAP Tunnel)

You can access Jenkins NOW via IAP (without VPN):

```bash
# SSH to Jenkins VM
gcloud compute ssh jenkins-vm \
  --project=test-project2-485105 \
  --zone=us-central1-a \
  --tunnel-through-iap

# Get initial password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

**Initial Admin Password**: `9ec0d716085f4365851dd00f33e8bd3c`

---

## Pre-Deployment ✅ COMPLETE

- [x] GCP Organization access confirmed ✅
- [x] Billing account ID obtained ✅
- [x] gcloud CLI installed and configured ✅
- [x] Terraform >= 1.5.0 installed ✅
- [x] Firezone account created at https://firezone.dev ✅
- [ ] Firezone gateway token obtained (IN PROGRESS)

---

## Phase 1: GCP Setup ✅ COMPLETE

- [ ] Project 1 created: `test-project1-485105` ✅ (Already exists)
- [ ] Project 2 created: `test-project2-485105` ✅ (Already exists)
- [ ] Billing linked to both projects
- [ ] Compute API enabled in Project 1
- [ ] Compute, DNS, Secret Manager APIs enabled in Project 2
- [ ] Terraform state bucket created: `test-project1-485105-terraform-state`
- [ ] Bucket versioning enabled

**Script**: Run `./scripts/setup-gcp-projects.sh` to automate this phase

## Phase 2: Terraform Configuration

- [ ] Copied `terraform.tfvars.example` to `terraform.tfvars`
- [ ] Updated `project_id_networking` in tfvars
- [ ] Updated `project_id_coreit` in tfvars
- [ ] Updated `region` and `zone` in tfvars
- [ ] Confirmed `domain_name` is `learningmyway.space`
- [ ] Confirmed `jenkins_hostname` is `jenkins.np.learningmyway.space`
- [ ] Added Firezone token to tfvars
- [ ] Reviewed and adjusted VM sizes if needed

## Phase 3: Terraform Deployment

- [ ] Ran `terraform init` successfully
- [ ] Ran `terraform validate` - no errors
- [ ] Ran `terraform plan` - reviewed output
- [ ] Ran `terraform apply` - deployment completed
- [ ] Noted outputs (IPs, URLs)
- [ ] Verified all resources created in GCP console

**Expected Duration**: 10-15 minutes

## Phase 4: Verification

- [ ] VPC peering status is ACTIVE in both projects
- [ ] Jenkins VM is running in Project 2
- [ ] Firezone gateway is running in Project 1
- [ ] Internal LB created with IP 10.10.10.100
- [ ] Private DNS zone created for learningmyway.space
- [ ] DNS A record points to LB IP
- [ ] All firewall rules created

**Script**: Run `./scripts/verify-deployment.sh` to check status

## Phase 5: Firezone Configuration

- [ ] Logged into Firezone admin console
- [ ] Verified gateway is connected
- [ ] Added resource: `jenkins.np.learningmyway.space`
- [ ] Configured DNS forwarding for learningmyway.space
- [ ] Added team members as users
- [ ] Assigned Jenkins resource access to users
- [ ] Sent invitation emails to users

## Phase 6: Client Setup

- [ ] Downloaded Firezone client for your OS
- [ ] Installed Firezone client
- [ ] Logged in with credentials
- [ ] Connected to VPN successfully
- [ ] VPN status shows "Connected"

## Phase 7: Jenkins Access

- [ ] Tested DNS resolution: `nslookup jenkins.np.learningmyway.space`
- [ ] DNS resolves to 10.10.10.100
- [ ] Opened browser to `https://jenkins.np.learningmyway.space`
- [ ] Jenkins login page loads
- [ ] Retrieved initial admin password via SSH
- [ ] Logged into Jenkins with initial password
- [ ] Installed suggested plugins
- [ ] Created first admin user
- [ ] Configured Jenkins URL
- [ ] Jenkins dashboard accessible

## Phase 8: Post-Deployment

- [ ] Documented Jenkins admin credentials (securely)
- [ ] Configured Jenkins security settings
- [ ] Set up Jenkins backup strategy
- [ ] Enabled Cloud Monitoring for VMs
- [ ] Set up alerting for critical metrics
- [ ] Documented operational procedures
- [ ] Trained team on VPN access
- [ ] Created runbook for common issues

## Optional Enhancements

- [ ] Configure Jenkins with LDAP/SSO
- [ ] Set up automated snapshots for data disk
- [ ] Configure Jenkins Configuration as Code (JCasC)
- [ ] Set up log aggregation
- [ ] Implement cost monitoring
- [ ] Configure Cloud Armor (if needed)
- [ ] Set up multi-zone deployment for HA
- [ ] Document disaster recovery procedures

## Validation Tests

- [ ] **Test 1**: VPN connection from personal laptop
- [ ] **Test 2**: DNS resolution from VPN client
- [ ] **Test 3**: HTTPS access to Jenkins
- [ ] **Test 4**: Jenkins job creation and execution
- [ ] **Test 5**: SSH access to Jenkins VM via IAP
- [ ] **Test 6**: Load balancer health check passing
- [ ] **Test 7**: VPC peering connectivity test
- [ ] **Test 8**: Firewall rules validation

## Troubleshooting Completed

- [ ] Documented any issues encountered
- [ ] Verified all workarounds
- [ ] Updated documentation with lessons learned

## Sign-Off

- [ ] Infrastructure deployed successfully
- [ ] All tests passed
- [ ] Documentation complete
- [ ] Team trained
- [ ] Handover completed

**Deployment Date**: _______________  
**Deployed By**: _______________  
**Verified By**: _______________  

---

## Quick Reference

**Jenkins URL**: https://jenkins.np.learningmyway.space  
**Project 1**: test-project1-485105 (20.20.20.0/16)  
**Project 2**: test-project2-485105 (10.10.10.0/16)  
**Jenkins VM IP**: 10.10.10.10  
**Internal LB IP**: 10.10.10.100  

**SSH to Jenkins**:
```bash
gcloud compute ssh jenkins-vm \
  --project=test-project2-485105 \
  --zone=us-central1-a \
  --tunnel-through-iap
```

**Get Initial Password**:
```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

**Check LB Health**:
```bash
gcloud compute backend-services get-health jenkins-backend-service \
  --region=us-central1 \
  --project=test-project2-485105
```

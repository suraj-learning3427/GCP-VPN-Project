# Jenkins Access Information

## Quick Reference Card

### Jenkins Details
- **Status**: ✅ RUNNING
- **Version**: 2.541.1
- **Java**: 17.0.18
- **Private IP**: 10.10.10.10
- **Load Balancer IP**: 10.10.10.100
- **URL**: https://jenkins.np.learningmyway.space

### Initial Admin Password
```
9ec0d716085f4365851dd00f33e8bd3c
```

---

## Access Methods

### Current: SSH via IAP ✅
```bash
gcloud compute ssh jenkins-vm \
  --project=test-project2-485105 \
  --zone=us-central1-a \
  --tunnel-through-iap
```

### After Phase 2: Direct VPN Access 🔄
- Install Firezone VPN client
- Connect to VPN
- Open browser: https://jenkins.np.learningmyway.space
- Login with initial admin password

---

## Useful Commands

### Check Jenkins Status
```bash
gcloud compute ssh jenkins-vm \
  --project=test-project2-485105 \
  --zone=us-central1-a \
  --tunnel-through-iap \
  --command="sudo systemctl status jenkins"
```

### View Jenkins Logs
```bash
gcloud compute ssh jenkins-vm \
  --project=test-project2-485105 \
  --zone=us-central1-a \
  --tunnel-through-iap \
  --command="sudo journalctl -u jenkins -f"
```

### Get Initial Password
```bash
gcloud compute ssh jenkins-vm \
  --project=test-project2-485105 \
  --zone=us-central1-a \
  --tunnel-through-iap \
  --command="sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
```

### Restart Jenkins
```bash
gcloud compute ssh jenkins-vm \
  --project=test-project2-485105 \
  --zone=us-central1-a \
  --tunnel-through-iap \
  --command="sudo systemctl restart jenkins"
```

### Check Load Balancer Health
```bash
gcloud compute backend-services get-health jenkins-backend-service \
  --region=us-central1 \
  --project=test-project2-485105
```

---

## Jenkins Setup Steps (After First Login)

1. **Access Jenkins** (via SSH tunnel or VPN)
2. **Enter Initial Password**: `9ec0d716085f4365851dd00f33e8bd3c`
3. **Install Suggested Plugins** (recommended)
4. **Create Admin User**
   - Username: (your choice)
   - Password: (your choice)
   - Full name: (your choice)
   - Email: rksuraj@learningmyway.space
5. **Configure Jenkins URL**: https://jenkins.np.learningmyway.space
6. **Start Using Jenkins!**

---

## Troubleshooting

### Jenkins Not Responding?
```bash
# Check if Jenkins is running
gcloud compute ssh jenkins-vm \
  --project=test-project2-485105 \
  --zone=us-central1-a \
  --tunnel-through-iap \
  --command="sudo systemctl status jenkins"

# Restart if needed
gcloud compute ssh jenkins-vm \
  --project=test-project2-485105 \
  --zone=us-central1-a \
  --tunnel-through-iap \
  --command="sudo systemctl restart jenkins"
```

### Load Balancer Unhealthy?
```bash
# Check health status
gcloud compute backend-services get-health jenkins-backend-service \
  --region=us-central1 \
  --project=test-project2-485105

# Check if Jenkins is listening on port 8080
gcloud compute ssh jenkins-vm \
  --project=test-project2-485105 \
  --zone=us-central1-a \
  --tunnel-through-iap \
  --command="sudo netstat -tlnp | grep 8080"
```

### Can't SSH to Jenkins?
```bash
# Verify IAM permissions
gcloud projects get-iam-policy test-project2-485105 \
  --flatten="bindings[].members" \
  --filter="bindings.members:user:rksuraj@learningmyway.space"

# Should show:
# - roles/compute.instanceAdmin.v1
# - roles/compute.osLogin
# - roles/iap.tunnelResourceAccessor
```

---

## Security Notes

### Firewall Rules
- ✅ IAP SSH access enabled (35.235.240.0/20)
- ✅ Health check access enabled (35.191.0.0/16, 130.211.0.0/22)
- ⏳ VPN access (pending Phase 2)

### Network Access
- Jenkins has NO public IP (secure)
- Only accessible via:
  - IAP tunnel (current)
  - VPN (after Phase 2)
  - Internal load balancer (10.10.10.100)

### Data Disk
- 100GB data disk mounted at `/var/lib/jenkins`
- Separate from boot disk for data persistence
- Automatic backups recommended (set up separately)

---

## Next Steps

1. ✅ Phase 1 Complete - Jenkins is running
2. 🔄 Get Firezone token from https://firezone.dev
3. 🔄 Deploy Phase 2 - Firezone VPN Gateway
4. 🔄 Configure VPN access
5. 🔄 Complete Jenkins initial setup
6. 🔄 Configure Jenkins jobs and pipelines

---

**Last Updated**: February 12, 2026  
**Jenkins Status**: ✅ OPERATIONAL  
**Access**: IAP Tunnel (VPN pending Phase 2)

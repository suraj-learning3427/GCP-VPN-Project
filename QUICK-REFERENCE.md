# Quick Reference - learningmyway.space Jenkins Infrastructure

## 🎉 Phase 1: COMPLETE ✅

**Current Status**:
- Jenkins: RUNNING (version 2.541.1)
- Load Balancer: HEALTHY
- VPC Peering: ACTIVE
- Tests: 18/18 PASSED
- Initial Password: `9ec0d716085f4365851dd00f33e8bd3c`

**Next**: Get Firezone token for Phase 2

---

## Access Information

| Item | Value |
|------|-------|
| **Phase 1 Status** | ✅ COMPLETE |
| **Phase 2 Status** | 🔄 IN PROGRESS |
| Jenkins URL | https://jenkins.np.learningmyway.space (via VPN after Phase 2) |
| Jenkins Status | ✅ RUNNING |
| Jenkins Version | 2.541.1 |
| Java Version | 17.0.18 |
| Initial Password | `9ec0d716085f4365851dd00f33e8bd3c` |
| Domain | learningmyway.space |
| Project 1 | test-project1-485105 |
| Project 2 | test-project2-485105 |
| Region | us-central1 |
| Zone | us-central1-a |

## Network Configuration

| Component | IP/CIDR | Location | Status |
|-----------|---------|----------|--------|
| Project 1 VPC | 20.20.20.0/16 | test-project1-485105 | ✅ ACTIVE |
| Project 2 VPC | 10.10.10.0/16 | test-project2-485105 | ✅ ACTIVE |
| VPC Peering | - | Both projects | ✅ ACTIVE |
| Jenkins VM | 10.10.10.10 | Project 2 | ✅ RUNNING |
| Internal LB | 10.10.10.100 | Project 2 | ✅ HEALTHY |
| Firezone Gateway | 20.20.20.10 | Project 1 | ⏳ Phase 2 |

## Common Commands

### Quick Health Check (Phase 1)

```bash
# Check everything at once
echo "=== Phase 1 Status ===" && \
echo "Jenkins VM:" && gcloud compute instances describe jenkins-vm --project=test-project2-485105 --zone=us-central1-a --format="get(status)" && \
echo "Load Balancer:" && gcloud compute backend-services get-health jenkins-backend-service --region=us-central1 --project=test-project2-485105 --format="get(status.healthStatus[0].healthState)" && \
echo "VPC Peering:" && gcloud compute networks peerings list --project=test-project1-485105 --format="get(state)"
```

### Access Jenkins Now (via IAP)

```bash
# SSH to Jenkins VM
gcloud compute ssh jenkins-vm \
  --project=test-project2-485105 \
  --zone=us-central1-a \
  --tunnel-through-iap

# Get initial password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

**Initial Password**: `9ec0d716085f4365851dd00f33e8bd3c`

---

### Terraform Operations

```bash
# Initialize
cd terraform && terraform init

# Plan changes
terraform plan

# Apply changes
terraform apply

# Show current state
terraform show

# View outputs
terraform output

# Destroy infrastructure
terraform destroy
```

### GCP Operations

```bash
# SSH to Jenkins VM
gcloud compute ssh jenkins-vm \
  --project=test-project2-485105 \
  --zone=us-central1-a \
  --tunnel-through-iap

# SSH to Firezone Gateway
gcloud compute ssh firezone-gateway \
  --project=test-project1-485105 \
  --zone=us-central1-a

# List VMs in Project 2
gcloud compute instances list --project=test-project2-485105

# Check VPC peering status
gcloud compute networks peerings list --project=test-project1-485105
gcloud compute networks peerings list --project=test-project2-485105

# Check LB health
gcloud compute backend-services get-health jenkins-backend-service \
  --region=us-central1 \
  --project=test-project2-485105

# List firewall rules
gcloud compute firewall-rules list --project=test-project2-485105

# View DNS zones
gcloud dns managed-zones list --project=test-project2-485105

# View DNS records
gcloud dns record-sets list \
  --zone=learningmyway-space \
  --project=test-project2-485105
```

### Jenkins Operations

```bash
# Get initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

# Restart Jenkins
sudo systemctl restart jenkins

# Check Jenkins status
sudo systemctl status jenkins

# View Jenkins logs
sudo journalctl -u jenkins -f

# Check disk usage
df -h /var/lib/jenkins
```

### Firezone Operations

```bash
# Check gateway container
sudo docker ps

# View gateway logs
sudo docker logs firezone-gateway

# Restart gateway
sudo docker restart firezone-gateway

# Check gateway health
curl http://localhost:8080/healthz
```

## Troubleshooting

### Cannot Access Jenkins

1. **Check VPN connection**
   - Open Firezone client
   - Verify "Connected" status

2. **Test DNS resolution**
   ```bash
   nslookup jenkins.np.learningmyway.space
   # Should return: 10.10.10.100
   ```

3. **Check LB health**
   ```bash
   gcloud compute backend-services get-health jenkins-backend-service \
     --region=us-central1 --project=test-project2-485105
   ```

4. **Verify Jenkins is running**
   ```bash
   gcloud compute ssh jenkins-vm \
     --project=test-project2-485105 \
     --zone=us-central1-a \
     --tunnel-through-iap
   
   sudo systemctl status jenkins
   ```

### VPC Peering Not Active

```bash
# Check peering status
gcloud compute networks peerings list --project=test-project1-485105

# If not ACTIVE, recreate peering
cd terraform
terraform destroy -target=module.vpc_peering
terraform apply -target=module.vpc_peering
```

### Firezone Gateway Issues

```bash
# SSH to gateway
gcloud compute ssh firezone-gateway \
  --project=test-project1-485105 \
  --zone=us-central1-a

# Check container status
sudo docker ps -a

# View logs
sudo docker logs firezone-gateway --tail 100

# Restart if needed
sudo docker restart firezone-gateway
```

### DNS Not Resolving

1. **Verify DNS zone exists**
   ```bash
   gcloud dns managed-zones list --project=test-project2-485105
   ```

2. **Check A record**
   ```bash
   gcloud dns record-sets list \
     --zone=learningmyway-space \
     --project=test-project2-485105
   ```

3. **Verify VPC association**
   - DNS zone should be associated with both VPCs

## Firewall Rules

| Rule Name | Direction | Source | Destination | Ports | Purpose |
|-----------|-----------|--------|-------------|-------|---------|
| jenkins-iap-ssh | Ingress | 35.235.240.0/20 | jenkins-vm | 22 | SSH via IAP |
| jenkins-vpn-access | Ingress | 20.20.20.0/16 | jenkins-vm | 8080, 443 | VPN access |
| jenkins-health-check | Ingress | 35.191.0.0/16, 130.211.0.0/22 | jenkins-vm | 8080 | LB health checks |
| firezone-vpn-traffic | Ingress | 0.0.0.0/0 | firezone-gateway | 51820, 443 | VPN traffic |
| firezone-to-jenkins-egress | Egress | firezone-gateway | 10.10.10.0/16 | all | Gateway to Jenkins |

## Monitoring

### Key Metrics to Watch

- **Jenkins VM**: CPU, Memory, Disk usage
- **Load Balancer**: Request count, latency, error rate
- **Firezone Gateway**: Connection count, bandwidth
- **VPC Peering**: Bytes sent/received

### Set Up Alerts

```bash
# Create alert for Jenkins VM high CPU
gcloud alpha monitoring policies create \
  --notification-channels=CHANNEL_ID \
  --display-name="Jenkins High CPU" \
  --condition-display-name="CPU > 80%" \
  --condition-threshold-value=0.8 \
  --condition-threshold-duration=300s
```

## Backup & Recovery

### Jenkins Data Backup

```bash
# Create snapshot of data disk
gcloud compute disks snapshot jenkins-data-disk \
  --project=test-project2-485105 \
  --zone=us-central1-a \
  --snapshot-names=jenkins-backup-$(date +%Y%m%d)

# List snapshots
gcloud compute snapshots list --project=test-project2-485105
```

### Restore from Snapshot

```bash
# Create new disk from snapshot
gcloud compute disks create jenkins-data-restored \
  --source-snapshot=jenkins-backup-YYYYMMDD \
  --zone=us-central1-a \
  --project=test-project2-485105

# Attach to VM (requires VM stop)
gcloud compute instances attach-disk jenkins-vm \
  --disk=jenkins-data-restored \
  --zone=us-central1-a \
  --project=test-project2-485105
```

## Cost Management

### View Current Costs

```bash
# Project 1 costs
gcloud billing projects describe test-project1-485105

# Project 2 costs
gcloud billing projects describe test-project2-485105
```

### Set Budget Alerts

1. Go to GCP Console → Billing → Budgets & alerts
2. Create budget for each project
3. Set threshold alerts at 50%, 80%, 100%

## Security Best Practices

- ✅ Rotate Firezone tokens every 90 days
- ✅ Review firewall rules monthly
- ✅ Update Jenkins plugins regularly
- ✅ Monitor access logs
- ✅ Backup Jenkins data weekly
- ✅ Review user access quarterly
- ✅ Keep OS and packages updated

## Support Contacts

| Issue Type | Resource |
|------------|----------|
| Firezone | https://www.firezone.dev/support |
| GCP Support | https://cloud.google.com/support |
| Jenkins | https://www.jenkins.io/doc/ |
| Terraform | https://www.terraform.io/docs |

## Documentation Links

- [Main README](README.md)
- [Deployment Guide](DEPLOYMENT.md)
- [Infrastructure Guide](vpn-jenkins-infrastructure-guide.md)
- [Terraform README](terraform/README.md)
- [Requirements](.kiro/specs/vpn-jenkins-infrastructure/requirements.md)
- [Checklist](CHECKLIST.md)

---

**Last Updated**: February 2026  
**Version**: 1.0

# VPN-Jenkins Infrastructure - Terraform

This Terraform configuration deploys a secure, private Jenkins infrastructure accessible via Firezone VPN across two GCP projects.

## Architecture

- **Project 1 (test-project1-485105)**: VPN gateway (20.20.20.0/16)
- **Project 2 (test-project2-485105)**: Jenkins VM + Internal LB (10.10.10.0/16)
- **Domain**: learningmyway.space
- **Jenkins URL**: https://jenkins.np.learningmyway.space

## Prerequisites

1. **GCP Setup**
   - Two GCP projects created
   - Billing enabled on both projects
   - Required APIs enabled (Compute, DNS, Secret Manager)
   - Appropriate IAM permissions

2. **Tools**
   - Terraform >= 1.5.0
   - gcloud CLI >= 450.0.0
   - Firezone account with gateway token

3. **Firezone**
   - Sign up at https://firezone.dev
   - Create a gateway and obtain the token

## Quick Start

### 1. Clone and Configure

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:
```hcl
project_id_networking = "your-networking-project-id"
project_id_coreit     = "your-coreit-project-id"
region                = "us-central1"
zone                  = "us-central1-a"
domain_name           = "learningmyway.space"
jenkins_hostname      = "jenkins.np.learningmyway.space"
firezone_token        = "your-firezone-token"
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Plan Deployment

```bash
terraform plan -out=tfplan
```

### 4. Apply Configuration

```bash
terraform apply tfplan
```

This will create:
- VPC networks in both projects
- VPC peering between projects
- Private DNS zone
- Jenkins VM with data disk
- Internal Load Balancer
- Firezone VPN gateway
- All necessary firewall rules

### 5. Get Outputs

```bash
terraform output
```

Key outputs:
- `jenkins_url`: Access URL for Jenkins
- `jenkins_lb_ip`: Internal LB IP address
- `firezone_gateway_ip`: Public IP of VPN gateway

## Module Structure

```
terraform/
├── main.tf                      # Root configuration
├── variables.tf                 # Global variables
├── outputs.tf                   # Global outputs
├── terraform.tfvars.example     # Example variables
└── modules/
    ├── networking/              # VPC and subnets
    ├── vpc-peering/             # VPC peering setup
    ├── dns/                     # Private DNS zone
    ├── jenkins-vm/              # Jenkins VM and firewall
    ├── load-balancer/           # Internal HTTPS LB
    └── firezone-gateway/        # Firezone VPN gateway
```

## Post-Deployment Steps

### 1. Configure Firezone Resources

Login to Firezone admin console and:
- Add resource: `jenkins.np.learningmyway.space`
- Configure DNS forwarding
- Assign user access

### 2. Access Jenkins

```bash
# Connect Firezone VPN client
# Then access Jenkins
https://jenkins.np.learningmyway.space
```

### 3. Get Jenkins Initial Password

```bash
gcloud compute ssh jenkins-vm \
  --project=core-it-infra-prod \
  --zone=us-central1-a \
  --tunnel-through-iap

sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

## Maintenance

### Update Infrastructure

```bash
# Make changes to .tf files
terraform plan
terraform apply
```

### Destroy Infrastructure

```bash
terraform destroy
```

### SSH to Jenkins VM

```bash
gcloud compute ssh jenkins-vm \
  --project=core-it-infra-prod \
  --zone=us-central1-a \
  --tunnel-through-iap
```

## Troubleshooting

### VPC Peering Not Active

```bash
gcloud compute networks peerings list \
  --project=test-project1-485105
```

### Jenkins Not Accessible

1. Check VPN connection
2. Verify DNS resolution: `nslookup jenkins.np.learningmyway.space`
3. Check LB health: `gcloud compute backend-services get-health jenkins-backend-service --region=us-central1`
4. Verify firewall rules

### Firezone Gateway Issues

```bash
# SSH to gateway
gcloud compute ssh firezone-gateway \
  --project=test-project1-485105 \
  --zone=us-central1-a

# Check Docker container
sudo docker ps
sudo docker logs firezone-gateway
```

## Security Notes

- Jenkins has no public IP
- Access only via VPN
- SSH via IAP tunneling only
- All traffic encrypted end-to-end
- Firewall rules follow least privilege

## Cost Estimation

Monthly costs (approximate):
- Jenkins VM (e2-medium): ~$25
- Firezone Gateway (e2-small): ~$15
- Load Balancer: ~$20
- Storage (150GB): ~$15
- **Total**: ~$75/month

## Support

For issues or questions:
- Check the main guide: `vpn-jenkins-infrastructure-guide.md`
- Review requirements: `.kiro/specs/vpn-jenkins-infrastructure/requirements.md`
- Implementation plan: `.kiro/specs/vpn-jenkins-infrastructure/implementation-plan.md`

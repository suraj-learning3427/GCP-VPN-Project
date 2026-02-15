# 🔐 VPN-Based Air-Gapped Jenkins Infrastructure on GCP

A production-ready, secure CI/CD infrastructure with zero internet exposure, VPN-only access, and complete PKI certificate chain implementation.

## 🌟 Project Overview

This project implements a highly secure Jenkins CI/CD environment on Google Cloud Platform (GCP) with:
- **Zero Internet Exposure**: No public IPs, no Cloud NAT, completely air-gapped
- **VPN-Only Access**: Firezone VPN with WireGuard protocol
- **Complete PKI Infrastructure**: 3-tier certificate chain (Root → Intermediate → Server)
- **HTTPS/TLS Encryption**: Nginx reverse proxy with SSL termination
- **Defense in Depth**: 5-layer security architecture

## 🏗️ Architecture

### Infrastructure Components
- **GCP Project 1**: Firezone VPN Gateway (10.0.0.0/16)
- **GCP Project 2**: Jenkins VM with Internal Load Balancer (10.10.0.0/16)
- **VPC Peering**: Private connectivity between projects
- **Private DNS**: Internal DNS zones for name resolution

### Security Layers
1. **Network Isolation**: No public IPs, no Cloud NAT
2. **VPN Authentication**: WireGuard protocol with user authentication
3. **Firewall Rules**: GCP firewall with deny-all default
4. **TLS Encryption**: HTTPS with PKI certificate chain
5. **Application Security**: Jenkins authentication and RBAC

## 📊 Interactive Architecture Diagrams

Open `architecture-diagrams.html` in your browser to view:
- Infrastructure Architecture
- PKI Certificate Chain
- TLS/SSL Handshake Flow
- Complete Request Flow
- Security Layers
- Network Topology

## 🚀 Quick Start

### Prerequisites
- GCP account with two projects
- Terraform installed
- Firezone account (free tier available)
- gcloud CLI configured

### Deployment Steps

1. **Configure Terraform Variables**
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

2. **Initialize and Deploy**
```bash
terraform init
terraform plan
terraform apply
```

3. **Configure PKI Certificates**
```bash
# SSH to Jenkins VM
gcloud compute ssh jenkins-vm --zone=us-central1-a --project=YOUR_PROJECT_ID

# Run certificate generation script
sudo bash /tmp/create-pki-certificates.sh
```

4. **Setup Client Access**
```powershell
# On Windows client
# Install Root CA certificate
.\install-root-ca.ps1

# Add hosts file entry
.\add-hosts-entry.ps1
```

5. **Connect via VPN**
- Install Firezone VPN client
- Configure resource access in Firezone portal
- Connect to VPN
- Access Jenkins: `https://jenkins.np.learningmyway.space`

## 📁 Project Structure

```
├── terraform/                  # Infrastructure as Code
│   ├── main.tf                # Main Terraform configuration
│   ├── variables.tf           # Variable definitions
│   ├── terraform.tfvars       # Your configuration values
│   └── modules/               # Terraform modules
│       ├── firezone-gateway/  # VPN gateway module
│       ├── jenkins-vm/        # Jenkins VM module
│       ├── load-balancer/     # Internal LB module
│       └── vpc-peering/       # VPC peering module
├── scripts/                   # Automation scripts
│   ├── create-pki-certificates.sh
│   └── complete-https-setup.sh
├── diagrams/                  # Architecture diagrams (ASCII)
├── diagram-generator/         # Diagram generators
│   ├── python/               # Python + Graphviz
│   ├── typescript/           # TypeScript + Mermaid
│   └── java/                 # Java + PlantUML
├── architecture-diagrams.html # Interactive diagrams
├── documentation.html         # Complete documentation
└── README.md                 # This file
```

## 💰 Cost Analysis

### Monthly Costs (when running)
- Firezone Gateway (e2-medium): ~$24/month
- Jenkins VM (n1-standard-2): ~$49/month
- Internal Load Balancer: ~$18/month
- VPC Peering: Free
- **Total: ~$91/month**

### Cost Savings
- No Cloud NAT: Saves $45/month
- No public IPs: Saves additional costs
- **Annual Savings: ~$540 vs Cloud NAT approach**

### Current Status
Infrastructure is **destroyed** to avoid costs. Redeploy anytime with `terraform apply`.

## 🔒 Security Features

### PKI Certificate Chain
- **Root CA**: 4096-bit RSA, 10-year validity
- **Intermediate CA**: 4096-bit RSA, 5-year validity
- **Server Certificate**: 2048-bit RSA, 1-year validity
- **SAN Support**: DNS name and IP address

### Encryption
- **VPN Layer**: WireGuard with modern cryptography
- **TLS Layer**: HTTPS with AES-256-GCM cipher
- **Double Encryption**: Maximum security for data in transit

### Network Security
- Zero internet exposure
- No public IPs on Jenkins VM
- VPC peering for private connectivity
- GCP firewall with strict rules
- Resource-based VPN access control

## 📚 Documentation

### Quick Access
- **Architecture Diagrams**: Open `architecture-diagrams.html`
- **Complete Documentation**: Open `documentation.html`
- **Quick Reference**: See `QUICK-REFERENCE-CARD.md`
- **Current Status**: See `CURRENT-STATUS.md`

### Detailed Guides
- `PKI-CERTIFICATE-CHAIN-GUIDE.md` - Complete PKI setup
- `HTTPS-SETUP-GUIDE.md` - HTTPS configuration
- `FIREZONE-RESOURCE-SETUP.md` - VPN access setup
- `ACCESS-JENKINS-HTTPS.md` - Client access instructions

## 🛠️ Technologies Used

- **Infrastructure**: Terraform, GCP
- **VPN**: Firezone (WireGuard)
- **CI/CD**: Jenkins
- **Web Server**: Nginx
- **OS**: Rocky Linux 8
- **Certificates**: OpenSSL
- **Diagrams**: Mermaid.js, Graphviz, PlantUML

## 🎯 Use Cases

- Secure CI/CD pipelines for sensitive projects
- Compliance-required air-gapped environments
- Internal development infrastructure
- Zero-trust network architecture
- Private cloud deployments

## 📈 Diagram Generators

Generate professional architecture diagrams in multiple formats:

### Python (Graphviz)
```bash
cd diagram-generator/python
pip install -r requirements.txt
python generate_diagrams.py
```

### TypeScript (Mermaid)
```bash
cd diagram-generator/typescript
npm install
npm start
```

### Java (PlantUML)
```bash
cd diagram-generator/java
javac DiagramGenerator.java
java DiagramGenerator
```

## 🔧 Maintenance

### Redeploy Infrastructure
```bash
cd terraform
terraform apply
```

### Destroy Infrastructure
```bash
cd terraform
terraform destroy
```

### Update Certificates
```bash
# SSH to Jenkins VM
sudo bash /tmp/create-pki-certificates.sh
sudo systemctl restart nginx
```

## 🤝 Contributing

This is a personal learning project. Feel free to fork and adapt for your needs.

## 📝 License

MIT License - See LICENSE file for details

## 👤 Author

**Suraj**
- GitHub: [@suraj-learning3427](https://github.com/suraj-learning3427)
- Project: [GCP-VPN-Project](https://github.com/suraj-learning3427/GCP-VPN-Project)

## 🙏 Acknowledgments

- Firezone for excellent VPN solution
- GCP for reliable cloud infrastructure
- Terraform for infrastructure as code
- Jenkins for CI/CD capabilities

## 📞 Support

For issues or questions:
1. Check documentation in `documentation.html`
2. Review troubleshooting guides
3. Open an issue on GitHub

---

**⚠️ Security Note**: This infrastructure is designed for maximum security. Always follow security best practices and keep all components updated.

**💡 Tip**: Start with `architecture-diagrams.html` to understand the complete architecture visually!

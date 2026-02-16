# 📊 Terraform Visual Guide

## VPN-Based Air-Gapped Jenkins Infrastructure

**Companion to:** TERRAFORM-COMPLETE-AUDIT.md

---

## Module Connection Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         main.tf                                  │
│                    (Root Orchestrator)                           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ├─────────────────────────────────┐
                              │                                 │
                              ▼                                 ▼
┌──────────────────────────────────────┐  ┌──────────────────────────────────────┐
│  Module: networking_project1         │  │  Module: networking_project2         │
│  ├─ VPC: networkingglobal-vpc        │  │  ├─ VPC: core-it-vpc                 │
│  ├─ CIDR: 20.20.20.0/16              │  │  ├─ CIDR: 10.10.10.0/16              │
│  └─ Subnet: vpn-subnet (20.20.20/24) │  │  └─ Subnet: jenkins-subnet (10.10/24)│
└──────────────────────────────────────┘  └──────────────────────────────────────┘
                    │                                     │
                    └──────────────┬──────────────────────┘
                                   ▼
                    ┌──────────────────────────────┐
                    │  Module: vpc_peering         │
                    │  ├─ Peering 1→2              │
                    │  └─ Peering 2→1              │
                    └──────────────────────────────┘
                                   │
                ┌──────────────────┴──────────────────┐
                ▼                                     ▼
┌──────────────────────────────┐    ┌──────────────────────────────┐
│  Module: firezone_gateway    │    │  Module: jenkins_vm          │
│  ├─ VM: firezone-gateway     │    │  ├─ Data Disk: 100GB         │
│  ├─ Public IP: Yes           │    │  ├─ VM: jenkins-vm           │
│  ├─ VPN: WireGuard           │    │  ├─ Public IP: No            │
│  └─ Firewall: VPN traffic    │    │  └─ Firewall: VPN + IAP      │
└──────────────────────────────┘    └──────────────────────────────┘
                                                    │
                                                    ▼
                                    ┌──────────────────────────────┐
                                    │  Module: load_balancer       │
                                    │  ├─ Health Check             │
                                    │  ├─ Instance Group           │
                                    │  ├─ Backend Service          │
                                    │  └─ Forwarding Rule (10.10.10.100)│
                                    └──────────────────────────────┘
                                                    │
                                                    ▼
                                    ┌──────────────────────────────┐
                                    │  Module: dns                 │
                                    │  ├─ Private Zone             │
                                    │  └─ A Record: jenkins.np →   │
                                    │     10.10.10.100             │
                                    └──────────────────────────────┘
```

---

## Resource Creation Timeline

```
Time →

T0: terraform init
    └─> Download providers
    └─> Initialize modules

T1: terraform plan
    └─> Calculate changes

T2: terraform apply
    │
    ├─> [0-30s] Create VPCs
    │   ├─ networkingglobal-vpc (Project 1)
    │   └─ core-it-vpc (Project 2)
    │
    ├─> [30-45s] Create Subnets
    │   ├─ vpn-subnet
    │   └─ jenkins-subnet
    │
    ├─> [45-60s] Create VPC Peering
    │   ├─ networking-to-coreit
    │   └─ coreit-to-networking
    │
    ├─> [60-90s] Create Disks & VMs
    │   ├─ jenkins-data-disk
    │   ├─ jenkins-vm
    │   └─ firezone-gateway
    │
    ├─> [90-120s] Create Firewall Rules
    │   ├─ jenkins-iap-ssh
    │   ├─ jenkins-vpn-access
    │   ├─ jenkins-health-check
    │   ├─ firezone-vpn-traffic
    │   └─ firezone-to-jenkins-egress
    │
    ├─> [120-150s] Create Load Balancer
    │   ├─ jenkins-health-check
    │   ├─ jenkins-instance-group
    │   ├─ jenkins-backend-service
    │   └─ jenkins-lb-forwarding-rule
    │
    └─> [150-180s] Create DNS
        ├─ learningmyway-space zone
        └─ jenkins.np A record

T3: Resources Ready (3-5 minutes total)
```

---

## Data Flow Diagrams

### 1. User Access Flow

```
┌─────────────┐
│   User      │
│  (Laptop)   │
└──────┬──────┘
       │ 1. Connect VPN
       ▼
┌─────────────────────┐
│ Firezone VPN Client │
│   (WireGuard)       │
└──────┬──────────────┘
       │ 2. Encrypted Tunnel
       ▼
┌──────────────────────────────────┐
│ Firezone Gateway VM              │
│ IP: 20.20.20.x (Project 1)       │
│ Public IP: xxx.xxx.xxx.xxx       │
└──────┬───────────────────────────┘
       │ 3. VPC Peering
       ▼
┌──────────────────────────────────┐
│ Internal Load Balancer           │
│ IP: 10.10.10.100 (Project 2)     │
└──────┬───────────────────────────┘
       │ 4. Forward Traffic
       ▼
┌──────────────────────────────────┐
│ Jenkins VM                       │
│ IP: 10.10.10.10 (Project 2)      │
│ No Public IP (Air-Gapped)        │
└──────────────────────────────────┘
```

### 2. DNS Resolution Flow

```
User types: https://jenkins.np.learningmyway.space
       │
       ▼
┌──────────────────────┐
│ DNS Query            │
│ "What is jenkins.np  │
│  .learningmyway      │
│  .space?"            │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────────────────┐
│ Private DNS Zone                 │
│ (learningmyway.space)            │
│ Visible to both VPCs             │
└──────┬───────────────────────────┘
       │
       ▼
┌──────────────────────────────────┐
│ A Record                         │
│ jenkins.np.learningmyway.space   │
│ → 10.10.10.100                   │
└──────┬───────────────────────────┘
       │
       ▼
Browser connects to 10.10.10.100:443
```

### 3. Health Check Flow

```
Every 10 seconds:

┌──────────────────────────────────┐
│ Health Check Service             │
│ (GCP Infrastructure)             │
└──────┬───────────────────────────┘
       │ HTTP GET /login
       ▼
┌──────────────────────────────────┐
│ Jenkins VM:8080                  │
│ Response: 200 OK                 │
└──────┬───────────────────────────┘
       │
       ▼
┌──────────────────────────────────┐
│ Backend Service                  │
│ Status: HEALTHY ✓                │
│ Action: Send traffic             │
└──────────────────────────────────┘

If 3 failures:
┌──────────────────────────────────┐
│ Backend Service                  │
│ Status: UNHEALTHY ✗              │
│ Action: Stop traffic             │
└──────────────────────────────────┘
```

---

## Firewall Rules Matrix

```
┌─────────────────────────────────────────────────────────────────┐
│                    Firewall Rules Overview                       │
└─────────────────────────────────────────────────────────────────┘

Rule: jenkins-iap-ssh
├─ Direction: INGRESS
├─ Source: 35.235.240.0/20 (Google IAP)
├─ Target: jenkins-server tag
├─ Protocol: TCP
├─ Port: 22
└─ Purpose: SSH access via IAP

Rule: jenkins-vpn-access
├─ Direction: INGRESS
├─ Source: 20.20.20.0/24 (VPN subnet)
├─ Target: jenkins-server tag
├─ Protocol: TCP
├─ Ports: 8080, 443
└─ Purpose: Jenkins access from VPN

Rule: jenkins-health-check
├─ Direction: INGRESS
├─ Source: 35.191.0.0/16, 130.211.0.0/22 (GCP LB)
├─ Target: jenkins-server tag
├─ Protocol: TCP
├─ Port: 8080
└─ Purpose: Load balancer health checks

Rule: firezone-vpn-traffic
├─ Direction: INGRESS
├─ Source: 0.0.0.0/0 (Internet)
├─ Target: firezone-gateway tag
├─ Protocol: UDP/TCP
├─ Ports: 51820 (UDP), 443 (TCP)
└─ Purpose: VPN client connections

Rule: firezone-to-jenkins-egress
├─ Direction: EGRESS
├─ Destination: 10.10.10.0/24 (Jenkins subnet)
├─ Target: firezone-gateway tag
├─ Protocol: TCP, UDP
├─ Ports: All
└─ Purpose: Forward VPN traffic to Jenkins
```

---

## Variable Flow

```
terraform.tfvars
├─ project_id_networking = "test-project1-485105"
├─ project_id_coreit = "test-project2-485105"
├─ region = "us-central1"
├─ zone = "us-central1-a"
├─ domain_name = "learningmyway.space"
├─ jenkins_hostname = "jenkins.np.learningmyway.space"
└─ firezone_token = "..."
       │
       ▼
variables.tf (validates types)
       │
       ▼
main.tf (uses variables)
       │
       ├──> module "networking_project1"
       │    ├─ project_id = var.project_id_networking
       │    ├─ region = var.region
       │    └─ vpc_name = "networkingglobal-vpc"
       │
       ├──> module "networking_project2"
       │    ├─ project_id = var.project_id_coreit
       │    ├─ region = var.region
       │    └─ vpc_name = "core-it-vpc"
       │
       └──> module "firezone_gateway"
            └─ firezone_token = var.firezone_token
```

---

## State File Structure

```
terraform.tfstate
├─ version: 4
├─ terraform_version: "1.7.5"
├─ serial: 1
└─ resources: [
    ├─ module.networking_project1.google_compute_network.vpc
    │  ├─ type: "google_compute_network"
    │  ├─ name: "networkingglobal-vpc"
    │  ├─ id: "projects/test-project1-485105/global/networks/networkingglobal-vpc"
    │  └─ attributes: { ... }
    │
    ├─ module.networking_project1.google_compute_subnetwork.subnet
    │  ├─ type: "google_compute_subnetwork"
    │  ├─ name: "vpn-subnet"
    │  └─ dependencies: ["module.networking_project1.google_compute_network.vpc"]
    │
    ├─ module.jenkins_vm.google_compute_disk.jenkins_data
    │  ├─ type: "google_compute_disk"
    │  ├─ name: "jenkins-data-disk"
    │  └─ size: 100
    │
    ├─ module.jenkins_vm.google_compute_instance.jenkins
    │  ├─ type: "google_compute_instance"
    │  ├─ name: "jenkins-vm"
    │  └─ dependencies: ["module.jenkins_vm.google_compute_disk.jenkins_data"]
    │
    └─ ... (16 more resources)
]
```

---

## Cost Breakdown

```
Monthly Cost Estimate:

Project 1 (Networking)
├─ Firezone Gateway (e2-small)
│  ├─ Compute: $24.27/month
│  ├─ Disk (20GB): $0.80/month
│  └─ Public IP: $3.00/month
├─ VPC: Free
├─ Subnet: Free
└─ Subtotal: $28.07/month

Project 2 (Core IT)
├─ Jenkins VM (e2-medium)
│  ├─ Compute: $48.54/month
│  ├─ Boot Disk (50GB): $2.00/month
│  └─ Data Disk (100GB): $4.00/month
├─ Internal Load Balancer: $18.00/month
├─ VPC: Free
├─ Subnet: Free
├─ DNS Zone: $0.20/month
└─ Subtotal: $72.74/month

VPC Peering: Free
Firewall Rules: Free

Total: $100.81/month

Cost Savings:
├─ No Cloud NAT: -$32/month per project = -$64/month
└─ Actual Total: ~$91/month
```

---

## Security Layers Visualization

```
┌─────────────────────────────────────────────────────────────────┐
│ Layer 5: Application Security                                   │
│ ├─ Jenkins Authentication                                       │
│ ├─ Role-Based Access Control                                    │
│ └─ Audit Logging                                                │
└─────────────────────────────────────────────────────────────────┘
                              ▲
┌─────────────────────────────────────────────────────────────────┐
│ Layer 4: TLS Encryption                                         │
│ ├─ HTTPS/TLS 1.2+                                               │
│ ├─ PKI Certificate Chain                                        │
│ └─ Strong Cipher Suites                                         │
└─────────────────────────────────────────────────────────────────┘
                              ▲
┌─────────────────────────────────────────────────────────────────┐
│ Layer 3: Firewall Rules                                         │
│ ├─ GCP Firewall                                                 │
│ ├─ Allow: VPN → Jenkins                                         │
│ └─ Deny: All Others                                             │
└─────────────────────────────────────────────────────────────────┘
                              ▲
┌─────────────────────────────────────────────────────────────────┐
│ Layer 2: VPN Authentication                                     │
│ ├─ Firezone VPN                                                 │
│ ├─ WireGuard Protocol                                           │
│ └─ User Authentication                                          │
└─────────────────────────────────────────────────────────────────┘
                              ▲
┌─────────────────────────────────────────────────────────────────┐
│ Layer 1: Network Isolation                                      │
│ ├─ No Public IPs on Jenkins                                    │
│ ├─ No Cloud NAT                                                 │
│ └─ Air-Gapped VM                                                │
└─────────────────────────────────────────────────────────────────┘
```

---

**END OF VISUAL GUIDE**

*Use this alongside TERRAFORM-COMPLETE-AUDIT.md for complete understanding*

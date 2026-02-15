# Infrastructure Architecture Diagram

## End-to-End Infrastructure Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              INTERNET / PUBLIC NETWORK                              │
│                                                                                     │
│                                    ┌──────────┐                                     │
│                                    │  User's  │                                     │
│                                    │ Windows  │                                     │
│                                    │  Client  │                                     │
│                                    └─────┬────┘                                     │
│                                          │                                          │
│                                          │ HTTPS Request                            │
│                                          │ (Encrypted)                              │
└──────────────────────────────────────────┼──────────────────────────────────────────┘
                                           │
                                           │ Port 51820 (WireGuard)
                                           │ Port 443 (Firezone Admin)
                                           ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                         GCP PROJECT 1: test-project1-485105                         │
│                              NETWORKING / VPN GATEWAY                               │
│                                                                                     │
│  ┌────────────────────────────────────────────────────────────────────────────┐   │
│  │                    VPC: networkingglobal-vpc                                │   │
│  │                    CIDR: 20.20.20.0/16                                      │   │
│  │                                                                             │   │
│  │  ┌──────────────────────────────────────────────────────────────────────┐ │   │
│  │  │              Subnet: vpn-subnet (20.20.20.0/24)                      │ │   │
│  │  │                                                                       │ │   │
│  │  │  ┌─────────────────────────────────────────────────────────────┐    │ │   │
│  │  │  │         Firezone VPN Gateway VM                             │    │ │   │
│  │  │  │  ┌──────────────────────────────────────────────────────┐  │    │ │   │
│  │  │  │  │  VM: firezone-gateway                                │  │    │ │   │
│  │  │  │  │  Type: e2-small (2 vCPU, 2GB RAM)                    │  │    │ │   │
│  │  │  │  │  OS: Ubuntu 22.04 LTS                                │  │    │ │   │
│  │  │  │  │  Private IP: 20.20.20.x (dynamic)                    │  │    │ │   │
│  │  │  │  │  Public IP: 34.132.108.194 (dynamic)                 │  │    │ │   │
│  │  │  │  │                                                       │  │    │ │   │
│  │  │  │  │  Services:                                           │  │    │ │   │
│  │  │  │  │  • Firezone Gateway (Docker)                         │  │    │ │   │
│  │  │  │  │  • WireGuard VPN Server                              │  │    │ │   │
│  │  │  │  │  • VPN Tunnel Management                             │  │    │ │   │
│  │  │  │  │                                                       │  │    │ │   │
│  │  │  │  │  Ports:                                              │  │    │ │   │
│  │  │  │  │  • 51820/UDP - WireGuard VPN                         │  │    │ │   │
│  │  │  │  │  • 443/TCP - Firezone Admin                          │  │    │ │   │
│  │  │  │  └──────────────────────────────────────────────────────┘  │    │ │   │
│  │  │  └─────────────────────────────────────────────────────────────┘    │ │   │
│  │  │                                                                       │ │   │
│  │  │  Firewall Rules:                                                     │ │   │
│  │  │  • allow-firezone-vpn: 0.0.0.0/0 → 51820/UDP, 443/TCP               │ │   │
│  │  │  • firezone-to-jenkins-egress: Allow egress to 10.10.10.0/24        │ │   │
│  │  └───────────────────────────────────────────────────────────────────────┘ │   │
│  └────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                     │
└─────────────────────────────────────┬───────────────────────────────────────────────┘
                                      │
                                      │ VPC Peering
                                      │ (Bidirectional)
                                      │ Routes: 20.20.20.0/24 ↔ 10.10.10.0/24
                                      │
┌─────────────────────────────────────┴───────────────────────────────────────────────┐
│                         GCP PROJECT 2: test-project2-485105                         │
│                              CORE IT / JENKINS INFRASTRUCTURE                       │
│                                                                                     │
│  ┌────────────────────────────────────────────────────────────────────────────┐   │
│  │                    VPC: core-it-vpc                                         │   │
│  │                    CIDR: 10.10.10.0/16                                      │   │
│  │                                                                             │   │
│  │  ┌──────────────────────────────────────────────────────────────────────┐ │   │
│  │  │              Subnet: jenkins-subnet (10.10.10.0/24)                  │ │   │
│  │  │                                                                       │ │   │
│  │  │  ┌────────────────────────────────────────────────────────────┐     │ │   │
│  │  │  │      Internal Load Balancer                                │     │ │   │
│  │  │  │  ┌──────────────────────────────────────────────────────┐ │     │ │   │
│  │  │  │  │  IP: 10.10.10.100 (static, private)                  │ │     │ │   │
│  │  │  │  │  Type: Internal TCP Load Balancer                    │ │     │ │   │
│  │  │  │  │  Scheme: INTERNAL                                    │ │     │ │   │
│  │  │  │  │                                                       │ │     │ │   │
│  │  │  │  │  Forwarding Rules:                                   │ │     │ │   │
│  │  │  │  │  • Port 8080 → Backend (Jenkins HTTP)                │ │     │ │   │
│  │  │  │  │  • Port 443 → Backend (Jenkins HTTPS)                │ │     │ │   │
│  │  │  │  │                                                       │ │     │ │   │
│  │  │  │  │  Health Check:                                       │ │     │ │   │
│  │  │  │  │  • Protocol: HTTP                                    │ │     │ │   │
│  │  │  │  │  • Port: 8080                                        │ │     │ │   │
│  │  │  │  │  • Path: /login                                      │ │     │ │   │
│  │  │  │  │  • Interval: 10s                                     │ │     │ │   │
│  │  │  │  │  • Status: ✅ Healthy                                 │ │     │ │   │
│  │  │  │  └──────────────────────────────────────────────────────┘ │     │ │   │
│  │  │  └────────────────────────┬───────────────────────────────────┘     │ │   │
│  │  │                           │                                          │ │   │
│  │  │                           │ Forwards to                              │ │   │
│  │  │                           ▼                                          │ │   │
│  │  │  ┌─────────────────────────────────────────────────────────────┐   │ │   │
│  │  │  │         Jenkins VM (Air-Gapped)                             │   │ │   │
│  │  │  │  ┌──────────────────────────────────────────────────────┐  │   │ │   │
│  │  │  │  │  VM: jenkins-vm                                      │  │   │ │   │
│  │  │  │  │  Type: e2-medium (2 vCPU, 4GB RAM)                   │  │   │ │   │
│  │  │  │  │  OS: Rocky Linux 8                                   │  │   │ │   │
│  │  │  │  │  Private IP: 10.10.10.10 (static)                    │  │   │ │   │
│  │  │  │  │  Public IP: None (Air-gapped)                        │  │   │ │   │
│  │  │  │  │                                                       │  │   │ │   │
│  │  │  │  │  Disks:                                              │  │   │ │   │
│  │  │  │  │  • Boot: 50GB SSD                                    │  │   │ │   │
│  │  │  │  │  • Data: 100GB SSD (/var/lib/jenkins)                │  │   │ │   │
│  │  │  │  │                                                       │  │   │ │   │
│  │  │  │  │  Services:                                           │  │   │ │   │
│  │  │  │  │  ┌────────────────────────────────────────────────┐ │  │   │ │   │
│  │  │  │  │  │  Nginx (Reverse Proxy)                         │ │  │   │ │   │
│  │  │  │  │  │  • Port 443 (HTTPS) - SSL Termination          │ │  │   │ │   │
│  │  │  │  │  │  • Port 80 (HTTP) - Redirect to HTTPS          │ │  │   │ │   │
│  │  │  │  │  │  • Proxy to: localhost:8080                    │ │  │   │ │   │
│  │  │  │  │  │  • SSL Cert: /etc/jenkins/certs/               │ │  │   │ │   │
│  │  │  │  │  └────────────────────────────────────────────────┘ │  │   │ │   │
│  │  │  │  │           │                                          │  │   │ │   │
│  │  │  │  │           │ Proxy Pass                               │  │   │ │   │
│  │  │  │  │           ▼                                          │  │   │ │   │
│  │  │  │  │  ┌────────────────────────────────────────────────┐ │  │   │ │   │
│  │  │  │  │  │  Jenkins CI/CD Server                          │ │  │   │ │   │
│  │  │  │  │  │  • Port 8080 (HTTP) - Internal only            │ │  │   │ │   │
│  │  │  │  │  │  • Version: 2.541.1 LTS                        │ │  │   │ │   │
│  │  │  │  │  │  • Java: OpenJDK 17                            │ │  │   │ │   │
│  │  │  │  │  │  • Status: ✅ Running                           │ │  │   │ │   │
│  │  │  │  │  └────────────────────────────────────────────────┘ │  │   │ │   │
│  │  │  │  └──────────────────────────────────────────────────────┘  │   │ │   │
│  │  │  └─────────────────────────────────────────────────────────────┘   │ │   │
│  │  │                                                                       │ │   │
│  │  │  Firewall Rules:                                                     │ │   │
│  │  │  • jenkins-iap-ssh: 35.235.240.0/20 → 22/TCP (IAP access)           │ │   │
│  │  │  • allow-vpn-to-jenkins: 20.20.20.0/24 → 8080,443/TCP               │ │   │
│  │  │  • jenkins-health-check: GCP ranges → 8080/TCP                       │ │   │
│  │  └───────────────────────────────────────────────────────────────────────┘ │   │
│  │                                                                             │   │
│  │  ┌──────────────────────────────────────────────────────────────────────┐ │   │
│  │  │              Private DNS Zone                                         │ │   │
│  │  │  ┌────────────────────────────────────────────────────────────────┐  │ │   │
│  │  │  │  Zone: learningmyway.space (Private)                           │  │ │   │
│  │  │  │  Visibility: Both VPCs                                          │  │ │   │
│  │  │  │                                                                 │  │ │   │
│  │  │  │  DNS Records:                                                  │  │ │   │
│  │  │  │  • jenkins.np.learningmyway.space → 10.10.10.100 (A record)   │  │ │   │
│  │  │  │  • TTL: 300 seconds                                            │  │ │   │
│  │  │  └────────────────────────────────────────────────────────────────┘  │ │   │
│  │  └──────────────────────────────────────────────────────────────────────┘ │   │
│  └────────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

## Component Details

### Network Flow
1. User connects to Firezone VPN (WireGuard on port 51820)
2. VPN establishes encrypted tunnel
3. User traffic routes through VPN gateway (20.20.20.x)
4. VPC peering forwards traffic to Jenkins VPC (10.10.10.0/24)
5. Load balancer receives request on 10.10.10.100:443
6. Load balancer forwards to Jenkins VM (10.10.10.10:443)
7. Nginx terminates SSL and proxies to Jenkins (localhost:8080)
8. Jenkins processes request and responds
9. Response flows back through same path (encrypted)

### Security Boundaries
- **Internet → VPN Gateway:** Public internet, VPN authentication required
- **VPN Gateway → Jenkins VPC:** VPC peering, encrypted tunnel
- **Load Balancer → Jenkins VM:** Internal network, TLS encryption
- **Nginx → Jenkins:** Localhost, HTTP (internal only)

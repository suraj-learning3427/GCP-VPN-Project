# Architecture Diagram - learningmyway.space Jenkins Infrastructure

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Internet                                     │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             │ HTTPS/WireGuard
                             │
┌────────────────────────────▼────────────────────────────────────────┐
│                   Firezone Control Plane (SaaS)                      │
│                   - User Authentication                              │
│                   - Resource Management                              │
│                   - Policy Enforcement                               │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             │ Encrypted Tunnel
                             │
┌────────────────────────────▼────────────────────────────────────────┐
│  PROJECT 1: test-project1-485105 (20.20.20.0/16)                    │
│  Display Name: project1-networkingglobal-prod                       │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │  VPC: networkingglobal-vpc                                  │    │
│  │  ┌──────────────────────────────────────────────────────┐  │    │
│  │  │  Subnet: vpn-subnet (20.20.20.0/24)                  │  │    │
│  │  │  ┌────────────────────────────────────────────────┐  │  │    │
│  │  │  │  Firezone Gateway VM                           │  │  │    │
│  │  │  │  - Public IP: x.x.x.x                          │  │  │    │
│  │  │  │  - Private IP: 20.20.20.x                      │  │  │    │
│  │  │  │  - Docker: Firezone Gateway                    │  │  │    │
│  │  │  │  - Ports: 51820 (UDP), 443 (TCP)              │  │  │    │
│  │  │  └────────────────────────────────────────────────┘  │  │    │
│  │  └──────────────────────────────────────────────────────┘  │    │
│  │                                                              │    │
│  │  Firewall Rules:                                            │    │
│  │  - Allow VPN traffic from Internet                         │    │
│  │  - Allow egress to 10.10.10.0/16                           │    │
│  └────────────────────────────────────────────────────────────┘    │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             │ VPC Peering (Bidirectional)
                             │ - Export/Import Custom Routes
                             │ - Private Connectivity
                             │
┌────────────────────────────▼────────────────────────────────────────┐
│  PROJECT 2: test-project2-485105 (10.10.10.0/16)                    │
│  Display Name: project2-core-it-infra-prod                          │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │  VPC: core-it-vpc                                           │    │
│  │  ┌──────────────────────────────────────────────────────┐  │    │
│  │  │  Subnet: jenkins-subnet (10.10.10.0/24)             │  │    │
│  │  │                                                       │  │    │
│  │  │  ┌────────────────────────────────────────────────┐ │  │    │
│  │  │  │  Private DNS Zone                              │ │  │    │
│  │  │  │  - Domain: learningmyway.space                 │ │  │    │
│  │  │  │  - A Record: jenkins.np → 10.10.10.100        │ │  │    │
│  │  │  │  - Visibility: Private (both VPCs)            │ │  │    │
│  │  │  └────────────────────────────────────────────────┘ │  │    │
│  │  │                                                       │  │    │
│  │  │  ┌────────────────────────────────────────────────┐ │  │    │
│  │  │  │  Internal Load Balancer                        │ │  │    │
│  │  │  │  - IP: 10.10.10.100 (static)                  │ │  │    │
│  │  │  │  - Protocol: HTTP (port 80)                   │ │  │    │
│  │  │  │  - Health Check: HTTP /login                  │ │  │    │
│  │  │  │  - Backend: Jenkins Instance Group            │ │  │    │
│  │  │  └────────────┬───────────────────────────────────┘ │  │    │
│  │  │               │                                      │  │    │
│  │  │               │ HTTP :8080                           │  │    │
│  │  │               │                                      │  │    │
│  │  │  ┌────────────▼───────────────────────────────────┐ │  │    │
│  │  │  │  Jenkins VM                                    │ │  │    │
│  │  │  │  - IP: 10.10.10.10 (static)                   │ │  │    │
│  │  │  │  - OS: Rocky Linux 8                          │ │  │    │
│  │  │  │  - Machine: e2-medium (2 vCPU, 4GB RAM)       │ │  │    │
│  │  │  │  ┌──────────────────────────────────────────┐ │ │  │    │
│  │  │  │  │  Boot Disk (50GB)                        │ │ │  │    │
│  │  │  │  │  - OS and system files                   │ │ │  │    │
│  │  │  │  └──────────────────────────────────────────┘ │ │  │    │
│  │  │  │  ┌──────────────────────────────────────────┐ │ │  │    │
│  │  │  │  │  Data Disk (100GB)                       │ │ │  │    │
│  │  │  │  │  - /var/lib/jenkins                      │ │ │  │    │
│  │  │  │  │  - Jenkins home, jobs, artifacts         │ │ │  │    │
│  │  │  │  └──────────────────────────────────────────┘ │ │  │    │
│  │  │  └────────────────────────────────────────────────┘ │  │    │
│  │  └──────────────────────────────────────────────────────┘  │    │
│  │                                                              │    │
│  │  Firewall Rules:                                            │    │
│  │  - Allow SSH from IAP (35.235.240.0/20)                    │    │
│  │  - Allow 8080,443 from VPN subnet (20.20.20.0/16)          │    │
│  │  - Allow 8080 from LB health checks                        │    │
│  └────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────┘
```

## Traffic Flow Diagram

```
┌──────────────┐
│ User Laptop  │
│ (VPN Client) │
└──────┬───────┘
       │
       │ 1. Connect to Firezone
       │    (HTTPS/WireGuard)
       │
       ▼
┌──────────────────┐
│ Firezone Control │
│     Plane        │
└──────┬───────────┘
       │
       │ 2. Establish tunnel
       │    to gateway
       │
       ▼
┌──────────────────┐
│ Firezone Gateway │
│  (Project 1)     │
│  20.20.20.x      │
└──────┬───────────┘
       │
       │ 3. VPC Peering
       │    (Private network)
       │
       ▼
┌──────────────────┐
│  Private DNS     │
│  Resolution      │
│  jenkins.np →    │
│  10.10.10.100    │
└──────┬───────────┘
       │
       │ 4. HTTP request
       │    to LB IP
       │
       ▼
┌──────────────────┐
│ Internal Load    │
│   Balancer       │
│  10.10.10.100    │
└──────┬───────────┘
       │
       │ 5. Forward to
       │    Jenkins VM
       │    (port 8080)
       │
       ▼
┌──────────────────┐
│   Jenkins VM     │
│  10.10.10.10     │
│  Port 8080       │
└──────────────────┘
```

## Network Topology

```
                    Internet
                       │
                       │
        ┌──────────────┴──────────────┐
        │                             │
        │                             │
   VPN Traffic                   SSH via IAP
   (51820, 443)                 (35.235.240.0/20)
        │                             │
        │                             │
        ▼                             │
┌───────────────┐                     │
│   Project 1   │                     │
│  20.20.20.0/16│                     │
│               │                     │
│  Firezone GW  │                     │
└───────┬───────┘                     │
        │                             │
        │ VPC Peering                 │
        │ (Private)                   │
        │                             │
        ▼                             ▼
┌───────────────────────────────────────┐
│           Project 2                   │
│         10.10.10.0/16                 │
│                                       │
│  ┌─────────────┐    ┌─────────────┐  │
│  │ Internal LB │───▶│ Jenkins VM  │  │
│  │ 10.10.10.100│    │ 10.10.10.10 │  │
│  └─────────────┘    └─────────────┘  │
│                                       │
│  ┌─────────────────────────────────┐ │
│  │      Private DNS Zone           │ │
│  │   learningmyway.space           │ │
│  └─────────────────────────────────┘ │
└───────────────────────────────────────┘
```

## Security Layers

```
┌─────────────────────────────────────────────────────────┐
│ Layer 1: VPN Authentication                             │
│ - User credentials required                             │
│ - Firezone policy enforcement                           │
│ - WireGuard encryption                                  │
└─────────────────────────────────────────────────────────┘
                        ▼
┌─────────────────────────────────────────────────────────┐
│ Layer 2: Network Isolation                              │
│ - Private VPC networks                                  │
│ - No public IPs on Jenkins                              │
│ - VPC peering for controlled access                     │
└─────────────────────────────────────────────────────────┘
                        ▼
┌─────────────────────────────────────────────────────────┐
│ Layer 3: Firewall Rules                                 │
│ - Source IP restrictions                                │
│ - Port-level controls                                   │
│ - Least privilege access                                │
└─────────────────────────────────────────────────────────┘
                        ▼
┌─────────────────────────────────────────────────────────┐
│ Layer 4: Load Balancer                                  │
│ - Health checks                                         │
│ - Traffic distribution                                  │
│ - Internal only (no public access)                      │
└─────────────────────────────────────────────────────────┘
                        ▼
┌─────────────────────────────────────────────────────────┐
│ Layer 5: Application Security                           │
│ - Jenkins authentication                                │
│ - Role-based access control                             │
│ - Audit logging                                         │
└─────────────────────────────────────────────────────────┘
```

## Data Flow

```
┌─────────────────────────────────────────────────────────┐
│                    User Request                          │
│  https://jenkins.np.learningmyway.space                 │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│              DNS Resolution (Private)                    │
│  jenkins.np.learningmyway.space → 10.10.10.100         │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│           Route through VPN Tunnel                       │
│  Encrypted traffic via Firezone Gateway                 │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│            Cross VPC via Peering                         │
│  Project 1 (20.20.20.0/16) → Project 2 (10.10.10.0/16) │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│         Internal Load Balancer Processing                │
│  - Health check validation                               │
│  - Forward to healthy backend                            │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│              Jenkins VM Processing                       │
│  - Receive request on port 8080                         │
│  - Process Jenkins request                              │
│  - Return response                                      │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│              Response to User                            │
│  Same path in reverse, encrypted end-to-end             │
└─────────────────────────────────────────────────────────┘
```

## Component Relationships

```
┌─────────────────────────────────────────────────────────┐
│                  Terraform Root                          │
│                    (main.tf)                             │
└───┬─────────┬─────────┬─────────┬─────────┬────────────┘
    │         │         │         │         │
    ▼         ▼         ▼         ▼         ▼
┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────────┐
│Network │ │Network │ │  VPC   │ │  DNS   │ │  Firezone  │
│Module  │ │Module  │ │Peering │ │ Module │ │   Gateway  │
│(Proj 1)│ │(Proj 2)│ │ Module │ │        │ │   Module   │
└───┬────┘ └───┬────┘ └───┬────┘ └───┬────┘ └─────┬──────┘
    │          │          │          │            │
    │          │          │          │            │
    │          └──────────┴──────────┘            │
    │                     │                       │
    │                     ▼                       │
    │          ┌──────────────────────┐           │
    │          │    Jenkins VM        │           │
    │          │      Module          │           │
    │          └──────────┬───────────┘           │
    │                     │                       │
    │                     ▼                       │
    │          ┌──────────────────────┐           │
    │          │   Load Balancer      │           │
    │          │      Module          │           │
    │          └──────────────────────┘           │
    │                                             │
    └─────────────────────────────────────────────┘
```

## Deployment Sequence

```
Step 1: Project Setup
├── Create GCP Projects
├── Enable APIs
└── Setup Terraform State Bucket

Step 2: Network Foundation
├── Deploy Project 1 VPC (20.20.20.0/16)
├── Deploy Project 2 VPC (10.10.10.0/16)
└── Establish VPC Peering

Step 3: DNS Configuration
├── Create Private DNS Zone
└── Add A Record for Jenkins

Step 4: Compute Resources
├── Deploy Jenkins VM
│   ├── Boot Disk (50GB)
│   └── Data Disk (100GB)
└── Deploy Firezone Gateway

Step 5: Load Balancer
├── Create Instance Group
├── Configure Health Checks
├── Setup Backend Service
└── Create Forwarding Rule

Step 6: Firewall Rules
├── IAP SSH Access
├── VPN to Jenkins Access
├── Health Check Access
└── VPN Gateway Rules

Step 7: Verification
├── Check VPC Peering Status
├── Verify DNS Resolution
├── Test Load Balancer Health
└── Validate End-to-End Access
```

---

**Legend:**
- `─` : Connection/Flow
- `│` : Vertical connection
- `┌┐└┘` : Borders
- `▼` : Direction of flow
- `→` : Mapping/Resolution

**Color Coding (if viewing in color-capable viewer):**
- Blue: Network components
- Green: Compute resources
- Yellow: Security components
- Red: External access points

---

**Document Version**: 1.0  
**Last Updated**: February 2026

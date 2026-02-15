# Air-Gapped Jenkins Infrastructure - Design Document

**Project:** VPN-Based Air-Gapped Jenkins CI/CD Infrastructure  
**Status:** ✅ Production Ready  
**Last Updated:** February 13, 2026  
**Version:** 2.0

---

## 1. Architecture Overview

### 1.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         INTERNET                                 │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ VPN Connection (WireGuard UDP/51820)
                         │
┌────────────────────────▼────────────────────────────────────────┐
│                    PROJECT 1: VPN Gateway                        │
│                  (test-project1-485105)                          │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Firezone Gateway VM                                      │  │
│  │  - Public IP: 136.114.231.135                            │  │
│  │  - Private IP: 20.20.20.x                                │  │
│  │  - Machine: e2-small (2vCPU, 2GB)                        │  │
│  │  - OS: Ubuntu 22.04 LTS                                  │  │
│  │  - VPN Server (WireGuard)                                │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  VPC: networkingglobal-vpc (20.20.20.0/16)                     │
│  Subnet: vpn-subnet (20.20.20.0/24)                            │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ VPC Peering (Bidirectional)
                         │ Export/Import Subnet Routes
                         │
┌────────────────────────▼────────────────────────────────────────┐
│                  PROJECT 2: Jenkins Infrastructure               │
│                    (test-project2-485105)                        │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Internal Load Balancer                                   │  │
│  │  - IP: 10.10.10.100 (static, private)                    │  │
│  │  - Port: 8080                                             │  │
│  │  - Health Checks: /login (10s interval)                  │  │
│  └────────────────────┬─────────────────────────────────────┘  │
│                       │                                          │
│                       │ Routes to                                │
│                       │                                          │
│  ┌────────────────────▼─────────────────────────────────────┐  │
│  │  Jenkins VM (Air-Gapped)                                  │  │
│  │  - Private IP: 10.10.10.10                               │  │
│  │  - Machine: e2-medium (2vCPU, 4GB)                       │  │
│  │  - OS: Rocky Linux 8                                      │  │
│  │  - Jenkins: 2.541.1 (Pre-installed)                      │  │
│  │  - Java: 17                                               │  │
│  │  - Boot Disk: 50GB                                        │  │
│  │  - Data Disk: 100GB (/var/lib/jenkins)                   │  │
│  │  - NO INTERNET ACCESS ❌                                  │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  VPC: core-it-vpc (10.10.10.0/16)                              │
│  Subnet: jenkins-subnet (10.10.10.0/24)                        │
│                                                                  │
│  Private DNS Zone: learningmyway.space                          │
│  - jenkins.np.learningmyway.space → 10.10.10.100              │
└──────────────────────────────────────────────────────────────────┘
```

### 1.2 Traffic Flow Diagram

```
User Device
    │
    │ (1) VPN Connection (WireGuard)
    ▼
Firezone Gateway (136.114.231.135)
    │
    │ (2) VPC Peering
    ▼
Private DNS Resolution
jenkins.np.learningmyway.space → 10.10.10.100
    │
    │ (3) HTTP Request
    ▼
Internal Load Balancer (10.10.10.100:8080)
    │
    │ (4) Health Check & Route
    ▼
Jenkins VM (10.10.10.10:8080)
    │
    │ (5) Response flows back
    └──────────────────────►
```

### 1.3 Network Topology

```
Internet
    │
    ▼
[Firezone Gateway] ◄──────────────┐
    │                              │
    │ Project 1                    │ VPC Peering
    │ 20.20.20.0/16                │ (Bidirectional)
    │                              │
    └──────────────────────────────┤
                                   │
                                   ▼
                        [Private DNS Zone]
                                   │
                                   │ Project 2
                                   │ 10.10.10.0/16
                                   │
                        [Internal Load Balancer]
                                   │
                                   ▼
                            [Jenkins VM]
                            (Air-Gapped)
                                   │
                            [Data Disk 100GB]
```

---

## 2. Component Design

### 2.1 Project 1: VPN Gateway (test-project1-485105)

**Purpose:** VPN gateway and network bridge

**VPC Network:**
- Name: `networkingglobal-vpc`
- CIDR: `20.20.20.0/16`
- Subnet: `vpn-subnet` (20.20.20.0/24)
- Region: us-central1

**Firezone Gateway VM:**
- Name: `firezone-gateway`
- Machine Type: e2-small (2 vCPU, 2GB RAM)
- OS: Ubuntu 22.04 LTS
- Boot Disk: 20GB SSD
- Public IP: 136.114.231.135 (static)
- Private IP: 20.20.20.x (dynamic)
- Tags: `firezone-gateway`

**Firezone Configuration:**
- VPN Protocol: WireGuard
- Port: UDP/51820
- Management: TCP/443
- Container: Docker-based Firezone gateway
- Token: Configured in terraform.tfvars

**Firewall Rules:**
1. `allow-firezone-vpn`
   - Source: 0.0.0.0/0
   - Ports: UDP/51820, TCP/443
   - Purpose: VPN connections

2. `allow-firezone-iap-ssh`
   - Source: 35.235.240.0/20 (IAP)
   - Ports: TCP/22
   - Purpose: SSH management

3. `allow-egress-to-jenkins`
   - Destination: 10.10.10.0/24
   - Ports: All
   - Purpose: VPN traffic to Jenkins

### 2.2 Project 2: Jenkins Infrastructure (test-project2-485105)

**Purpose:** Jenkins hosting with air-gapped deployment

#### 2.2.1 VPC Network
- Name: `core-it-vpc`
- CIDR: `10.10.10.0/16`
- Subnet: `jenkins-subnet` (10.10.10.0/24)
- Region: us-central1
- Private Google Access: Disabled (air-gapped)

#### 2.2.2 Private DNS Zone
- Zone Name: `learningmyway-space`
- DNS Name: `learningmyway.space.`
- Type: Private
- Visibility: Both VPCs (networkingglobal-vpc, core-it-vpc)
- Record: `jenkins.np.learningmyway.space` → `10.10.10.100`
- TTL: 300 seconds

#### 2.2.3 Custom Air-Gapped Image
- Name: `jenkins-airgapped-v1`
- Family: `jenkins-airgapped`
- Base: Rocky Linux 8
- Size: ~6GB
- Pre-installed Software:
  - Jenkins 2.541.1
  - Java 17
  - System dependencies
  - Firewall configuration

**Image Creation Process:**
1. Create temporary builder VM with internet access
2. Install Jenkins, Java, and dependencies
3. Configure system
4. Create image from stopped VM
5. Delete builder VM
6. Deploy Jenkins from custom image (no internet needed)

#### 2.2.4 Jenkins VM
- Name: `jenkins-vm`
- Machine Type: e2-medium (2 vCPU, 4GB RAM)
- OS: Rocky Linux 8 (from custom image)
- Boot Disk: 50GB SSD
- Data Disk: 100GB SSD (persistent)
- Private IP: 10.10.10.10 (static)
- Public IP: None (air-gapped)
- Tags: `jenkins-server`

**Disk Configuration:**
- `/dev/sda`: Boot disk (OS and Jenkins binaries)
- `/dev/sdb`: Data disk (mounted at /var/lib/jenkins)
- Jenkins Home: /var/lib/jenkins
- Data Persistence: Survives VM recreation

**Network Configuration:**
- No internet gateway
- No Cloud NAT
- No public IP
- VPN-only access

#### 2.2.5 Internal Load Balancer
- Type: Internal TCP Load Balancer
- Name: `jenkins-lb`
- IP: 10.10.10.100 (static, reserved)
- Port: 8080
- Protocol: TCP
- Scheme: INTERNAL (private only)

**Backend Service:**
- Name: `jenkins-backend-service`
- Protocol: TCP
- Port: 8080
- Timeout: 30 seconds
- Session Affinity: None

**Health Check:**
- Name: `jenkins-health-check`
- Protocol: HTTP
- Port: 8080
- Path: `/login`
- Check Interval: 10 seconds
- Timeout: 5 seconds
- Healthy Threshold: 2 consecutive successes
- Unhealthy Threshold: 3 consecutive failures

**Forwarding Rule:**
- Name: `jenkins-forwarding-rule`
- IP: 10.10.10.100
- Port: 8080
- Load Balancing Scheme: INTERNAL
- Backend Service: jenkins-backend-service

#### 2.2.6 Firewall Rules

**allow-iap-ssh:**
- Source: 35.235.240.0/20 (IAP range)
- Target: jenkins-server tag
- Ports: TCP/22
- Purpose: SSH access via IAP tunneling

**allow-vpn-to-jenkins:**
- Source: 20.20.20.0/24 (VPN subnet)
- Target: jenkins-server tag
- Ports: TCP/8080
- Purpose: Jenkins access from VPN

**allow-health-checks:**
- Source: 130.211.0.0/22, 35.191.0.0/16 (GCP health check ranges)
- Target: jenkins-server tag
- Ports: TCP/8080
- Purpose: Load balancer health checks

### 2.3 VPC Peering

**Peering 1: Project 1 → Project 2**
- Name: `networking-to-coreit`
- Local Network: networkingglobal-vpc (Project 1)
- Peer Network: core-it-vpc (Project 2)
- Import Custom Routes: Yes
- Export Custom Routes: Yes
- Import Subnet Routes with Public IP: Yes
- Export Subnet Routes with Public IP: Yes

**Peering 2: Project 2 → Project 1**
- Name: `coreit-to-networking`
- Local Network: core-it-vpc (Project 2)
- Peer Network: networkingglobal-vpc (Project 1)
- Import Custom Routes: Yes
- Export Custom Routes: Yes
- Import Subnet Routes with Public IP: Yes
- Export Subnet Routes with Public IP: Yes

**Status:** ACTIVE (bidirectional)

---

## 3. Security Design

### 3.1 Defense-in-Depth Architecture (5 Layers)

**Layer 1: Network Isolation**
- No public IPs on Jenkins VM
- Private subnets only
- VPC peering (no internet gateway)
- Separate projects for isolation

**Layer 2: VPN Access Control**
- Firezone authentication required
- Resource-based access policies
- User/group access control
- WireGuard encryption

**Layer 3: Firewall Rules**
- Strict ingress rules (least privilege)
- Source IP restrictions
- Service-specific ports only
- Default deny all

**Layer 4: IAP for SSH**
- Google Identity-Aware Proxy
- No direct SSH access
- Audit logging
- MFA support

**Layer 5: Air-Gapped Deployment**
- No internet access from Jenkins
- Pre-installed software (custom image)
- No outbound connections
- Zero attack surface

### 3.2 Access Control Matrix

| Source | Destination | Protocol | Port | Purpose | Status |
|--------|-------------|----------|------|---------|--------|
| Internet | Firezone Gateway | UDP | 51820 | VPN tunnel | ✅ |
| Internet | Firezone Gateway | TCP | 443 | VPN management | ✅ |
| VPN Clients (20.20.20.0/24) | Jenkins LB | TCP | 8080 | Jenkins access | ✅ |
| IAP Range (35.235.240.0/20) | Jenkins VM | TCP | 22 | SSH management | ✅ |
| LB Health Check | Jenkins VM | TCP | 8080 | Health monitoring | ✅ |
| Jenkins VM | Internet | Any | Any | Outbound | ❌ Blocked |

### 3.3 Network Security

**Ingress Controls:**
- Only required ports open
- Source IP whitelisting
- Service-specific rules
- Default deny

**Egress Controls:**
- No egress rules for Jenkins (air-gapped)
- Firezone can egress to Jenkins subnet only
- No internet access from Jenkins

**VPC Security:**
- Private IP ranges only
- No internet gateway in Project 2
- No Cloud NAT
- VPC peering for controlled connectivity

---

## 4. Data Flow

### 4.1 User Access Flow

```
1. User opens Firezone VPN client on laptop
2. Client authenticates with Firezone control plane
3. VPN tunnel established to Firezone Gateway (136.114.231.135)
4. User requests http://10.10.10.100:8080 or jenkins.np.learningmyway.space
5. DNS query sent through VPN tunnel
6. Firezone Gateway forwards DNS query to Project 2
7. Private DNS resolves to 10.10.10.100 (LB IP)
8. HTTP request routed via VPC peering to Project 2
9. Internal LB receives request on port 8080
10. LB performs health check validation
11. LB forwards HTTP request to Jenkins VM on port 8080
12. Jenkins processes request, returns response
13. Response flows back through LB → VPC peering → VPN → Client
```

### 4.2 Health Check Flow

```
1. LB sends HTTP GET to Jenkins VM:8080/login every 10 seconds
2. Jenkins responds with HTTP 200 (login page)
3. LB marks backend as healthy
4. If 3 consecutive failures → LB marks backend as unhealthy
5. If 2 consecutive successes → LB marks backend as healthy again
6. Unhealthy backends removed from rotation
```

### 4.3 Deployment Flow

```
1. Create custom air-gapped image (one-time, 10-15 min)
   - Temporary builder VM with internet
   - Install Jenkins, Java, dependencies
   - Create image, delete builder VM

2. Deploy network infrastructure (2 min)
   - Create VPCs in both projects
   - Create subnets
   - Establish VPC peering

3. Deploy application layer (3 min)
   - Deploy Jenkins VM from custom image
   - Configure load balancer
   - Set up private DNS

4. Deploy VPN access (3 min)
   - Deploy Firezone gateway
   - Configure Firezone resources
   - Create access policies

Total: ~20 minutes
```

---

## 5. Deployment Architecture

### 5.1 Infrastructure as Code

**Tool:** Terraform v1.5+  
**State Storage:** GCS bucket (test-project1-485105-terraform-state)  
**State Locking:** Enabled

**Terraform Modules:**
1. `networking` - VPC and subnet creation
2. `vpc-peering` - Cross-project connectivity
3. `firezone-gateway` - VPN server deployment
4. `jenkins-vm` - Application server
5. `load-balancer` - Internal TCP LB
6. `dns` - Private DNS zone

**Module Dependencies:**
```
networking_project1 ──┐
                      ├──> vpc_peering ──> firezone_gateway
networking_project2 ──┤                 └──> dns
                      └──> jenkins_vm ──> load_balancer ──┘
```

### 5.2 Deployment Phases

**Phase 1: Image Creation (10-15 min, one-time)**
- Create temporary builder VM with internet
- Install Jenkins 2.541.1 and Java 17
- Configure system
- Create custom image
- Delete builder VM

**Phase 2: Network Foundation (2 min)**
- Create VPCs in both projects
- Create subnets
- Establish VPC peering
- Verify connectivity

**Phase 3: Application Layer (3 min)**
- Deploy Jenkins VM from custom image
- Configure load balancer
- Set up private DNS
- Configure firewall rules

**Phase 4: VPN Access (3 min)**
- Deploy Firezone gateway
- Configure Firezone resources
- Create access policies
- Test VPN connectivity

**Total Deployment Time:** ~20 minutes (excluding image creation)

---

## 6. Monitoring and Observability

### 6.1 Metrics to Monitor

**Infrastructure Metrics:**
- Firezone Gateway: CPU, Memory, Network
- Jenkins VM: CPU, Memory, Disk I/O, Disk Usage
- Load Balancer: Request rate, Latency, Error rate
- VPC Peering: Traffic volume

**Application Metrics:**
- Jenkins: Job success/failure rate
- Jenkins: Response time
- Jenkins: Active users
- Jenkins: Queue length

**Network Metrics:**
- VPN: Active connections
- VPN: Throughput
- DNS: Query rate
- Firewall: Rule hit count

### 6.2 Health Checks

**Load Balancer Health Check:**
- Endpoint: http://10.10.10.10:8080/login
- Interval: 10 seconds
- Timeout: 5 seconds
- Healthy: 2 consecutive successes
- Unhealthy: 3 consecutive failures

**Manual Health Checks:**
```bash
# Check Jenkins status
gcloud compute ssh jenkins-vm \
  --project=test-project2-485105 \
  --zone=us-central1-a \
  --tunnel-through-iap \
  --command="sudo systemctl status jenkins"

# Check LB health
gcloud compute backend-services get-health jenkins-backend-service \
  --region=us-central1 \
  --project=test-project2-485105
```

### 6.3 Alerting (Recommended)

**Critical Alerts:**
- Jenkins VM down
- Load balancer unhealthy
- VPN gateway unreachable
- Disk usage > 85%
- Memory usage > 90%

**Warning Alerts:**
- High CPU utilization (> 80%)
- High memory usage (> 85%)
- Slow response time (> 5s)
- Disk usage > 75%

---

## 7. Disaster Recovery

### 7.1 Backup Strategy

**Jenkins Data:**
- Data disk is persistent (survives VM deletion)
- Manual snapshots recommended
- Retention: 30 days
- Automated via Cloud Scheduler (optional)

**Configuration:**
- Terraform state in GCS with versioning
- Custom image stored in GCP
- DNS zone configuration in Terraform

### 7.2 Recovery Procedures

**Scenario 1: Jenkins VM Failure**
1. Terraform will recreate VM from custom image
2. Data disk persists (not deleted)
3. Jenkins data intact
4. Downtime: ~5 minutes

**Scenario 2: Data Disk Corruption**
1. Restore from snapshot
2. Attach to new VM
3. Restart Jenkins
4. Downtime: ~15 minutes

**Scenario 3: Complete Project Loss**
1. Restore Terraform state from GCS
2. Run `terraform apply`
3. Restore Jenkins data from backup
4. Downtime: ~30 minutes

**Scenario 4: VPN Gateway Failure**
1. Terraform recreates Firezone VM
2. Firezone auto-connects to control plane
3. Users reconnect VPN clients
4. Downtime: ~5 minutes

---

## 8. Cost Analysis

### 8.1 Monthly Cost Breakdown

| Component | Specification | Monthly Cost |
|-----------|---------------|--------------|
| **Compute** | | |
| Firezone VM | e2-small (730 hrs) | $15.00 |
| Jenkins VM | e2-medium (730 hrs) | $25.00 |
| **Storage** | | |
| Boot Disks | 70GB SSD | $7.00 |
| Data Disk | 100GB SSD | $10.00 |
| Custom Image | 6GB | $0.30 |
| **Networking** | | |
| Internal LB | 1 forwarding rule | $20.00 |
| VPC Peering | Data transfer | $2.00 |
| Public IP | 1 static | $3.00 |
| Egress | Minimal | $2.00 |
| **Total** | | **$84.30/month** |

### 8.2 Cost Comparison

| Scenario | Monthly Cost | Annual Cost | Savings |
|----------|--------------|-------------|---------|
| Air-Gapped (current) | $84.30 | $1,011.60 | Baseline |
| With Cloud NAT | $148.30 | $1,779.60 | -$768/year |
| **Difference** | **-$64.00** | **-$768.00** | **43%** |

### 8.3 Cost Optimization Options

**Option 1: Reduce VM Size**
- Jenkins: e2-medium → e2-small
- Savings: $10/month
- Trade-off: Slower builds

**Option 2: Reduce Disk Size**
- Data disk: 100GB → 50GB
- Savings: $5/month
- Trade-off: Less storage

**Option 3: Remove Load Balancer**
- Direct access to Jenkins VM
- Savings: $20/month
- Trade-off: No health checks, no failover

---

## 9. Deployment Options Comparison

### Option 1: Air-Gapped (IMPLEMENTED)
**Cost:** $84.30/month  
**Security:** Maximum (zero internet)  
**Maintenance:** Manual updates  
**Use Case:** Regulated industries, high security

### Option 2: Cloud NAT
**Cost:** $148.30/month  
**Security:** Medium (outbound internet)  
**Maintenance:** Automatic updates  
**Use Case:** Development, less strict security

### Option 3: Temporary Public IP
**Cost:** $84.30/month (after removal)  
**Security:** High (after IP removal)  
**Maintenance:** Manual (during setup)  
**Use Case:** One-time setup, testing

### Option 4: Bastion Proxy
**Cost:** $109.30/month  
**Security:** High (controlled access)  
**Maintenance:** Semi-automated  
**Use Case:** Occasional updates, audit trail

---

## 10. Testing Strategy

### 10.1 Network Tests
- VPC peering connectivity
- DNS resolution
- Firewall rule validation
- No internet access verification

### 10.2 Application Tests
- Jenkins accessibility via VPN
- Load balancer health checks
- Failover simulation
- Performance testing

### 10.3 Security Tests
- Port scanning (verify only required ports)
- VPN authentication
- IAP SSH access
- Air-gap verification (no outbound)

---

**Document Version:** 2.0  
**Status:** Production Ready  
**Next Review:** March 13, 2026

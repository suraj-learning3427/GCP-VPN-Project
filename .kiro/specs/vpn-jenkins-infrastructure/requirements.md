# Air-Gapped Jenkins Infrastructure - Requirements Document

**Project:** VPN-Based Air-Gapped Jenkins CI/CD Infrastructure  
**Status:** ✅ Production Ready  
**Last Updated:** February 13, 2026  
**Owner:** rksuraj@learningmyway.space

---

## 1. Executive Summary

Deploy a secure, air-gapped Jenkins CI/CD infrastructure accessible only via VPN, with zero internet exposure, meeting compliance requirements while optimizing costs by eliminating Cloud NAT.

### Key Objectives
- Zero internet exposure for Jenkins server
- VPN-only authenticated access
- Cost reduction of 43% vs traditional Cloud NAT approach
- 100% automated deployment via Infrastructure as Code
- Production-ready with comprehensive documentation

---

## 2. Business Requirements

### BR-1: Cost Optimization
**Requirement:** Reduce infrastructure costs while maintaining security  
**Target:** Save minimum $60/month compared to Cloud NAT approach  
**Achieved:** $64/month savings ($768 annually) - 43% cost reduction

### BR-2: Security Compliance
**Requirement:** Meet air-gapped deployment standards for regulated industries  
**Standards:** Zero internet connectivity, VPN-only access, defense-in-depth  
**Achieved:** 5-layer security architecture with complete network isolation

### BR-3: Operational Efficiency
**Requirement:** Automated deployment and minimal maintenance overhead  
**Target:** Deploy complete infrastructure in under 30 minutes  
**Achieved:** 20-minute deployment with 100% automation via Terraform

### BR-4: Scalability
**Requirement:** Architecture must support future growth  
**Capability:** Load balancer enables horizontal scaling, multi-region capable

---

## 3. Functional Requirements

### FR-1: Network Infrastructure
**Requirement:** Two isolated GCP projects with VPC peering

**Specifications:**
- Project 1 (test-project1-485105): VPN Gateway
  - VPC CIDR: 20.20.20.0/16
  - Subnet: 20.20.20.0/24
  - Purpose: VPN termination and routing
  
- Project 2 (test-project2-485105): Jenkins Infrastructure
  - VPC CIDR: 10.10.10.0/16
  - Subnet: 10.10.10.0/24
  - Purpose: Application hosting

- VPC Peering: Bidirectional with subnet route export/import

**Acceptance Criteria:**
✅ Both VPCs created and configured  
✅ VPC peering active and bidirectional  
✅ Network connectivity verified between projects  
✅ No internet gateway in Project 2 (air-gapped)

### FR-2: VPN Gateway (Firezone)
**Requirement:** Secure VPN access point for remote users

**Specifications:**
- VM Type: e2-small (2 vCPU, 2GB RAM)
- OS: Ubuntu 22.04 LTS
- Public IP: Dynamic (assigned at deployment)
- Private IP: 20.20.20.x (dynamic)
- VPN Protocol: WireGuard
- Container: Docker-based Firezone gateway

**Acceptance Criteria:**
✅ Firezone gateway deployed and online  
✅ VPN authentication configured  
✅ Resource-based access control enabled  
✅ VPN clients can connect successfully

### FR-3: Jenkins Deployment with Automated Installation
**Requirement:** Jenkins server with minimal internet access during setup

**Specifications:**
- VM Type: e2-medium (2 vCPU, 4GB RAM)
- OS: Rocky Linux 8
- Boot Disk: 50GB SSD
- Data Disk: 100GB SSD (persistent)
- Private IP: 10.10.10.10 (static)
- Public IP: None (air-gapped after installation)
- Jenkins Version: Latest LTS (installed during first boot)
- Java Version: 17

**Deployment Approach:**
- Base Image: Rocky Linux 8 (standard)
- Installation: Automated via startup script
- Internet Access: Required during initial setup only
- Post-Install: No internet access (air-gapped)

**Acceptance Criteria:**
✅ Jenkins VM deployed from standard Rocky Linux image  
✅ No public IP assigned (private only)  
✅ Data disk mounted at /var/lib/jenkins  
✅ Jenkins accessible via VPN only after installation  
✅ IAP SSH access configured  
✅ Internet access only during initial setup

### FR-4: Internal Load Balancer
**Requirement:** Stable endpoint with health monitoring

**Specifications:**
- Type: Internal TCP Load Balancer
- IP: 10.10.10.100 (static, private)
- Ports: 8080 (HTTP), 443 (HTTPS)
- Protocol: TCP
- Scheme: INTERNAL

**Health Check:**
- Path: /login
- Port: 8080
- Interval: 10 seconds
- Timeout: 5 seconds
- Healthy threshold: 2
- Unhealthy threshold: 3

**Acceptance Criteria:**
✅ Load balancer created with static IP  
✅ Health checks passing  
✅ Backend service configured  
✅ Only accessible from internal networks  
⏳ Port 443 forwarding configured for HTTPS

### FR-5: Private DNS
**Requirement:** Internal name resolution for services

**Specifications:**
- Zone: learningmyway.space
- Type: Private
- Visibility: Both VPCs (Project 1 & 2)
- Record: jenkins.np.learningmyway.space → 10.10.10.100
- TTL: 300 seconds

**DNS Resolution:**
- GCP Private DNS zones only work for VMs inside GCP VPCs
- External VPN clients cannot query GCP private DNS zones
- Workaround: Add to Windows hosts file: `10.10.10.100 jenkins.np.learningmyway.space`

**Acceptance Criteria:**
✅ Private DNS zone created  
✅ A record configured  
✅ DNS resolution works from VPN clients (via hosts file)  
✅ Zone visible to both VPCs

### FR-5.1: SSL/TLS Configuration with Certificate Chain
**Requirement:** Secure HTTPS access to Jenkins with proper certificate chain

**Specifications:**
- Protocol: HTTPS (TLS 1.2+)
- Port: 443
- Certificate Type: Internal PKI with full certificate chain
- Certificate Chain: Root CA → Intermediate CA → Server Certificate
- Certificate Subject: jenkins.np.learningmyway.space
- Validity: Root CA (10 years), Intermediate CA (5 years), Server (1 year)
- Key Size: 4096-bit RSA (Root/Intermediate), 2048-bit RSA (Server)
- Signature Algorithm: SHA-256

**Certificate Chain Structure:**
1. **Root CA Certificate**
   - Common Name: LearningMyWay Root CA
   - Purpose: Trust anchor for the organization
   - Self-signed
   - Validity: 10 years (3650 days)
   - Key Usage: Certificate Sign, CRL Sign
   - Basic Constraints: CA:TRUE

2. **Intermediate CA Certificate**
   - Common Name: LearningMyWay Intermediate CA
   - Purpose: Issue server certificates
   - Signed by Root CA
   - Validity: 5 years (1825 days)
   - Key Usage: Certificate Sign, CRL Sign
   - Basic Constraints: CA:TRUE, pathlen:0

3. **Server Certificate**
   - Common Name: jenkins.np.learningmyway.space
   - Subject Alternative Names: jenkins.np.learningmyway.space, 10.10.10.100
   - Purpose: Jenkins HTTPS endpoint
   - Signed by Intermediate CA
   - Validity: 1 year (365 days)
   - Key Usage: Digital Signature, Key Encipherment
   - Extended Key Usage: Server Authentication
   - Basic Constraints: CA:FALSE

**Implementation:**
- Create internal PKI infrastructure
- Generate Root CA certificate and private key
- Generate Intermediate CA certificate signed by Root CA
- Generate server certificate signed by Intermediate CA
- Build certificate chain file (server → intermediate → root)
- Configure Jenkins to use certificate chain
- Distribute Root CA certificate to all client machines
- Update load balancer to forward port 443

**Security Benefits:**
- No browser warnings after Root CA installation
- Proper certificate validation chain
- Ability to issue multiple certificates from same CA
- Certificate revocation capability
- Industry-standard PKI architecture

**Client Configuration:**
- Install Root CA certificate on Windows: Import to "Trusted Root Certification Authorities"
- Install Root CA certificate on macOS: Add to Keychain and trust
- Install Root CA certificate on Linux: Copy to /usr/local/share/ca-certificates/

**Acceptance Criteria:**
⏳ Root CA certificate and key generated  
⏳ Intermediate CA certificate and key generated  
⏳ Server certificate signed by Intermediate CA  
⏳ Certificate chain file created  
⏳ Jenkins configured for HTTPS on port 443  
⏳ Load balancer forwards port 443  
⏳ Firewall allows port 443  
⏳ Certificate chain validates correctly  
⏳ Jenkins accessible via https://jenkins.np.learningmyway.space  
⏳ No browser warnings after Root CA installation

### FR-6: Firewall Rules
**Requirement:** Strict access control with least privilege

**Rules:**
1. **allow-iap-ssh**
   - Source: 35.235.240.0/20 (IAP range)
   - Target: jenkins-server tag
   - Ports: TCP 22
   - Purpose: SSH access via IAP

2. **allow-vpn-to-jenkins**
   - Source: 20.20.20.0/24 (VPN subnet)
   - Target: jenkins-server tag
   - Ports: TCP 8080, 443
   - Purpose: Jenkins access from VPN (HTTP and HTTPS)

3. **allow-health-checks**
   - Source: 130.211.0.0/22, 35.191.0.0/16
   - Target: jenkins-server tag
   - Ports: TCP 8080
   - Purpose: Load balancer health checks

4. **allow-firezone-vpn**
   - Source: 0.0.0.0/0
   - Target: firezone-gateway tag
   - Ports: UDP 51820, TCP 443
   - Purpose: VPN connections

**Acceptance Criteria:**
✅ All firewall rules created  
✅ Only required ports open  
✅ Default deny for all other traffic  
✅ No egress rules for Jenkins (air-gapped)  
⏳ Port 443 allowed for HTTPS access

---

## 4. Non-Functional Requirements

### NFR-1: Security
**Requirements:**
- Zero internet exposure for Jenkins
- VPN authentication required for all access
- Defense-in-depth architecture (5 layers)
- Air-gapped deployment (no outbound connections)
- IAP-only SSH access
- HTTPS encryption for web access

**Acceptance Criteria:**
✅ Jenkins has no public IP  
✅ No internet gateway in Jenkins VPC  
✅ VPN authentication enforced  
✅ 5 security layers implemented  
✅ Firewall rules follow least privilege  
⏳ HTTPS enabled with SSL/TLS certificate

### NFR-2: Performance
**Requirements:**
- Jenkins response time < 5 seconds
- Load balancer latency < 100ms
- DNS resolution < 1 second
- VPN connection time < 10 seconds

**Acceptance Criteria:**
✅ Response times within targets  
✅ Health checks passing consistently  
✅ No performance degradation under normal load

### NFR-3: Reliability
**Requirements:**
- Jenkins uptime target: 99%
- Automated health monitoring
- Data persistence independent of VM
- Disaster recovery capability

**Acceptance Criteria:**
✅ Health checks configured and passing  
✅ Data disk separate from boot disk  
✅ Terraform enables quick recovery  
✅ Backup strategy documented

### NFR-4: Maintainability
**Requirements:**
- Infrastructure as Code (Terraform)
- Modular architecture
- Comprehensive documentation
- Version-controlled configuration

**Acceptance Criteria:**
✅ All infrastructure in Terraform  
✅ 6 modular Terraform modules  
✅ Complete documentation provided  
✅ Git repository with version control

### NFR-5: Cost Efficiency
**Requirements:**
- Monthly cost < $100
- No unnecessary components
- Right-sized VMs
- Cost tracking and optimization

**Acceptance Criteria:**
✅ Monthly cost: $84.30  
✅ 43% cheaper than Cloud NAT approach  
✅ No Cloud NAT charges  
✅ Cost breakdown documented

---

## 5. Technical Constraints

### Platform Constraints
- Cloud Provider: Google Cloud Platform (GCP)
- Projects: 2 separate GCP projects
- Region: us-central1
- Zone: us-central1-a

### Software Constraints
- OS: Rocky Linux 8 (Jenkins VM)
- OS: Ubuntu 22.04 LTS (Firezone Gateway)
- Jenkins: 2.541.1 (standalone, not containerized)
- Java: Version 17
- VPN: Firezone (WireGuard-based)
- IaC: Terraform >= 1.5.0

### Network Constraints
- No internet access for Jenkins VM
- VPN-only access (no direct public access)
- Private DNS only (no public DNS)
- Internal load balancer only

### Deployment Constraints
- Must use custom air-gapped image
- No Cloud NAT allowed
- No public IPs on Jenkins
- All resources via Terraform

---

## 6. Deployment Options

### Option 1: Simplified Air-Gapped Deployment (IMPLEMENTED)
**Description:** Jenkins with internet access during initial setup, then air-gapped

**Pros:**
- Simplified deployment (no custom image needed)
- Automated installation via Terraform
- Cost savings ($64/month vs Cloud NAT)
- Air-gapped after initial setup
- Easy to maintain and update

**Cons:**
- Brief internet access during first boot (~5-10 minutes)
- Not suitable for strictest compliance requirements
- Manual plugin updates required after deployment

**Use Cases:**
- Most production environments
- Cost-sensitive deployments
- Rapid deployment needs
- Standard security requirements

**Cost:** $58.87/month

### Option 2: True Air-Gapped Deployment (OPTIONAL)
**Description:** Jenkins with zero internet access using pre-built custom image

**Pros:**
- Maximum security (zero internet access ever)
- Compliance-ready for strictest regulations
- Faster deployment (no installation time)
- Completely offline

**Cons:**
- Requires custom image creation (10-15 min setup)
- More complex maintenance
- Image updates needed for Jenkins updates
- Additional storage for custom image

**Use Cases:**
- Highly regulated industries (finance, healthcare, government)
- Maximum security requirements
- Compliance mandates for zero internet
- Air-gapped networks

**Cost:** $58.87/month + custom image storage (~$0.50/month)

### Option 2: Cloud NAT with Internet Access
**Description:** Jenkins with outbound internet via Cloud NAT

**Pros:**
- Automatic plugin updates
- Automatic security patches
- Easier maintenance
- Standard deployment

**Cons:**
- Higher cost ($148.30/month)
- Internet exposure (outbound)
- Additional attack surface
- Cloud NAT charges ($64/month)

**Use Cases:**
- Development environments
- Less strict security requirements
- Need for automatic updates

**Cost:** $148.30/month

### Option 3: Temporary Public IP
**Description:** Assign public IP temporarily for setup, then remove

**Pros:**
- Easy initial setup
- Can install plugins during setup
- Remove IP after configuration
- Lower ongoing cost

**Cons:**
- Manual process to add/remove IP
- Temporary internet exposure
- Requires VM restart
- Not fully automated

**Use Cases:**
- One-time setup scenarios
- Hybrid approach
- Testing environments

**Cost:** $84.30/month (after IP removal)

### Option 4: Bastion Host with Proxy
**Description:** Use bastion host as proxy for Jenkins updates

**Pros:**
- Controlled internet access
- Audit trail for connections
- Can be automated
- Maintains air-gap most of time

**Cons:**
- Additional bastion host cost ($25/month)
- More complex architecture
- Requires proxy configuration
- Additional maintenance

**Use Cases:**
- Need occasional updates
- Want audit trail
- Hybrid security model

**Cost:** $109.30/month

---

## 7. Dependencies

### External Dependencies
- GCP Organization with billing enabled
- Firezone account (trial or paid)
- Domain: learningmyway.space
- Firezone token for gateway deployment

### Tool Dependencies
- Terraform >= 1.5.0
- gcloud CLI >= 450.0.0
- Git for version control
- Bash shell for scripts

### Access Requirements
- GCP Project Owner role (both projects)
- Billing account access
- Firezone admin access
- SSH key for VM access

---

## 8. Success Criteria

### Deployment Success
✅ Complete infrastructure deployed in < 30 minutes  
✅ All Terraform modules apply successfully  
✅ No manual configuration required  
✅ All resources created as specified

### Functional Success
✅ Jenkins accessible via http://10.10.10.100:8080  
⏳ Jenkins accessible via https://jenkins.np.learningmyway.space  
✅ VPN connection successful  
✅ DNS resolution working (via hosts file)  
✅ Health checks passing  
✅ No internet connectivity from Jenkins

### Security Success
✅ Zero internet exposure verified  
✅ VPN authentication required  
✅ Firewall rules enforced  
✅ IAP SSH access working  
✅ 5 security layers validated  
⏳ HTTPS encryption enabled

### Business Success
✅ Monthly cost: $84.30 (within budget)  
✅ 43% cost reduction achieved  
✅ Compliance requirements met  
✅ Documentation complete

---

## 9. Out of Scope

The following are explicitly out of scope for this project:

❌ Jenkins plugin installation (air-gapped)  
❌ Jenkins job configuration  
❌ User management in Jenkins  
❌ Integration with external systems  
❌ Multi-region deployment  
❌ High availability (multiple Jenkins nodes)  
❌ Automated backup solution  
❌ Monitoring dashboard setup

---

## 10. Future Enhancements

### Short-term (1-3 months)
- Automated backup solution for Jenkins data
- Monitoring dashboard with alerts
- User access management documentation
- Jenkins job templates

### Medium-term (3-6 months)
- High availability with multiple Jenkins nodes
- Automated disaster recovery testing
- Security audit and penetration testing
- Performance optimization

### Long-term (6-12 months)
- Multi-region deployment
- Kubernetes migration path
- Advanced monitoring and observability
- CI/CD pipeline for infrastructure updates

---

## 11. Acceptance Testing

### Test Cases

**TC-1: Network Connectivity**
- Verify VPC peering is active
- Verify no internet access from Jenkins
- Verify VPN can reach Jenkins subnet

**TC-2: VPN Access**
- Connect Firezone VPN client
- Verify VPN tunnel established
- Verify can ping Jenkins LB IP

**TC-3: Jenkins Access**
- Access http://10.10.10.100:8080
- Verify Jenkins login page loads
- Verify can login with admin credentials
- Access https://jenkins.np.learningmyway.space
- Accept self-signed certificate warning
- Verify HTTPS connection established
- Verify can login via HTTPS

**TC-4: Security Validation**
- Verify Jenkins has no public IP
- Verify cannot curl external sites from Jenkins
- Verify firewall rules block unauthorized access

**TC-5: Health Checks**
- Verify LB health check passing
- Stop Jenkins service
- Verify LB marks backend unhealthy
- Start Jenkins service
- Verify LB marks backend healthy

---

## 12. Sign-off

### Stakeholder Approval

| Role | Name | Signature | Date |
|------|------|-----------|------|
| Project Owner | rksuraj@learningmyway.space | ✅ | Feb 13, 2026 |
| Security Lead | - | Pending | - |
| DevOps Lead | - | Pending | - |
| Finance Approval | - | Pending | - |

---

**Document Version:** 2.0  
**Status:** Production Ready  
**Next Review:** March 13, 2026

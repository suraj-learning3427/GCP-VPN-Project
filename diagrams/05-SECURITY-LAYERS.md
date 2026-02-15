# Security Architecture - Defense in Depth

## 5-Layer Security Model

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         LAYER 1: NETWORK ISOLATION                          │
│                                                                             │
│  ┌───────────────────────────────────────────────────────────────────────┐ │
│  │  • No Public IP on Jenkins VM                                         │ │
│  │  • Air-Gapped Environment                                             │ │
│  │  • Private Subnets Only                                               │ │
│  │  • No Internet Gateway in Jenkins VPC                                 │ │
│  │  • VPC Peering Only (no VPN gateway in Jenkins VPC)                   │ │
│  │                                                                        │ │
│  │  Protection Against:                                                  │ │
│  │  ✓ Direct internet attacks                                            │ │
│  │  ✓ Port scanning from internet                                        │ │
│  │  ✓ DDoS attacks                                                       │ │
│  │  ✓ Unauthorized access attempts                                       │ │
│  └───────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                      LAYER 2: VPN AUTHENTICATION                            │
│                                                                             │
│  ┌───────────────────────────────────────────────────────────────────────┐ │
│  │  Firezone VPN Gateway (WireGuard)                                     │ │
│  │  • User Authentication Required                                       │ │
│  │  • Resource-Based Access Control                                      │ │
│  │  • Per-User VPN Tunnels                                               │ │
│  │  • Modern Cryptography (Curve25519, ChaCha20-Poly1305)               │ │
│  │                                                                        │ │
│  │  Authentication Methods:                                              │ │
│  │  • Email/Password                                                     │ │
│  │  • SSO Integration (Optional)                                         │ │
│  │  • MFA Support (Optional)                                             │ │
│  │                                                                        │ │
│  │  Access Control:                                                      │ │
│  │  • Resource: 10.10.10.0/24 (Jenkins subnet)                          │ │
│  │  • Policy: User must be authenticated                                 │ │
│  │  • Audit: All connections logged                                      │ │
│  │                                                                        │ │
│  │  Protection Against:                                                  │ │
│  │  ✓ Unauthorized network access                                        │ │
│  │  ✓ Brute force attacks                                                │ │
│  │  ✓ Credential theft (with MFA)                                        │ │
│  └───────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                      LAYER 3: FIREWALL PROTECTION                           │
│                                                                             │
│  ┌───────────────────────────────────────────────────────────────────────┐ │
│  │  GCP Firewall Rules (Stateful)                                        │ │
│  │                                                                        │ │
│  │  Rule 1: jenkins-iap-ssh                                              │ │
│  │  ├─ Source: 35.235.240.0/20 (Google IAP)                              │ │
│  │  ├─ Target: jenkins-server tag                                        │ │
│  │  ├─ Allow: TCP/22 (SSH)                                               │ │
│  │  └─ Purpose: Emergency SSH access via IAP                             │ │
│  │                                                                        │ │
│  │  Rule 2: allow-vpn-to-jenkins                                         │ │
│  │  ├─ Source: 20.20.20.0/24 (VPN subnet)                                │ │
│  │  ├─ Target: jenkins-server tag                                        │ │
│  │  ├─ Allow: TCP/8080, TCP/443                                          │ │
│  │  └─ Purpose: Jenkins access from VPN only                             │ │
│  │                                                                        │ │
│  │  Rule 3: jenkins-health-check                                         │ │
│  │  ├─ Source: 35.191.0.0/16, 130.211.0.0/22 (GCP LB)                   │ │
│  │  ├─ Target: jenkins-server tag                                        │ │
│  │  ├─ Allow: TCP/8080                                                   │ │
│  │  └─ Purpose: Load balancer health checks                              │ │
│  │                                                                        │ │
│  │  Rule 4: allow-firezone-vpn                                           │ │
│  │  ├─ Source: 0.0.0.0/0 (Internet)                                      │ │
│  │  ├─ Target: firezone-gateway tag                                      │ │
│  │  ├─ Allow: UDP/51820, TCP/443                                         │ │
│  │  └─ Purpose: VPN connections                                          │ │
│  │                                                                        │ │
│  │  Default: DENY ALL (implicit)                                         │ │
│  │                                                                        │ │
│  │  Protection Against:                                                  │ │
│  │  ✓ Unauthorized port access                                           │ │
│  │  ✓ Lateral movement                                                   │ │
│  │  ✓ Service enumeration                                                │ │
│  └───────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                      LAYER 4: VPN ENCRYPTION                                │
│                                                                             │
│  ┌───────────────────────────────────────────────────────────────────────┐ │
│  │  WireGuard VPN Tunnel                                                 │ │
│  │                                                                        │ │
│  │  Encryption:                                                          │ │
│  │  • Algorithm: ChaCha20-Poly1305                                       │ │
│  │  • Key Exchange: Curve25519 (ECDH)                                    │ │
│  │  • Authentication: Poly1305 MAC                                       │ │
│  │  • Key Size: 256-bit                                                  │ │
│  │                                                                        │ │
│  │  Features:                                                            │ │
│  │  • Perfect Forward Secrecy                                            │ │
│  │  • Replay Protection                                                  │ │
│  │  • Identity Hiding                                                    │ │
│  │  • DoS Mitigation                                                     │ │
│  │                                                                        │ │
│  │  Tunnel:                                                              │ │
│  │  Client (100.64.0.1) ←→ Gateway (20.20.20.x)                         │ │
│  │  All traffic encrypted end-to-end                                     │ │
│  │                                                                        │ │
│  │  Protection Against:                                                  │ │
│  │  ✓ Packet sniffing                                                    │ │
│  │  ✓ Man-in-the-middle attacks                                          │ │
│  │  ✓ Traffic analysis                                                   │ │
│  │  ✓ Replay attacks                                                     │ │
│  └───────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                      LAYER 5: TLS ENCRYPTION                                │
│                                                                             │
│  ┌───────────────────────────────────────────────────────────────────────┐ │
│  │  HTTPS/TLS 1.2 & 1.3                                                  │ │
│  │                                                                        │ │
│  │  Certificate Chain:                                                   │ │
│  │  • Root CA: LearningMyWay Root CA (4096-bit RSA)                      │ │
│  │  • Intermediate CA: LearningMyWay Intermediate CA (4096-bit RSA)      │ │
│  │  • Server: jenkins.np.learningmyway.space (2048-bit RSA)              │ │
│  │                                                                        │ │
│  │  Cipher Suite: TLS_AES_256_GCM_SHA384                                 │ │
│  │  • Key Exchange: ECDHE (Perfect Forward Secrecy)                      │ │
│  │  • Encryption: AES-256-GCM                                            │ │
│  │  • Authentication: RSA (from certificate)                             │ │
│  │  • MAC: Integrated in GCM (AEAD)                                      │ │
│  │                                                                        │ │
│  │  Security Headers:                                                    │ │
│  │  • Strict-Transport-Security: max-age=31536000                        │ │
│  │  • X-Frame-Options: SAMEORIGIN                                        │ │
│  │  • X-Content-Type-Options: nosniff                                    │ │
│  │  • X-XSS-Protection: 1; mode=block                                    │ │
│  │                                                                        │ │
│  │  Protection Against:                                                  │ │
│  │  ✓ Eavesdropping                                                      │ │
│  │  ✓ Tampering                                                          │ │
│  │  ✓ Certificate spoofing                                               │ │
│  │  ✓ Protocol downgrade attacks                                         │ │
│  │  ✓ Clickjacking                                                       │ │
│  │  ✓ XSS attacks                                                        │ │
│  └───────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
                            ┌──────────────────┐
                            │  Jenkins Server  │
                            │  (Application)   │
                            └──────────────────┘
```

## Attack Surface Analysis

```
Attack Vector                    Mitigation
─────────────────────────────────────────────────────────────────
Direct Internet Access           ✅ No public IP
Port Scanning                    ✅ Firewall blocks all except VPN
Brute Force Login                ✅ VPN authentication required first
Man-in-the-Middle                ✅ VPN + TLS double encryption
Certificate Spoofing             ✅ Full PKI chain validation
DDoS Attack                      ✅ No public endpoint
SQL Injection                    ✅ Application-level (Jenkins)
XSS Attack                       ✅ Security headers + Jenkins
Lateral Movement                 ✅ Firewall rules + network isolation
Data Exfiltration                ✅ No outbound internet access
```

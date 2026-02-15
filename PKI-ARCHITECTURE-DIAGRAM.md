# PKI Certificate Chain Architecture

**Last Updated:** February 13, 2026

---

## Certificate Chain Hierarchy

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│                    LEARNINGMYWAY ROOT CA                        │
│                                                                 │
│  Common Name: LearningMyWay Root CA                            │
│  Type: Self-Signed Root Certificate                            │
│  Key Size: 4096-bit RSA                                        │
│  Validity: 10 years (3650 days)                                │
│  Signature: SHA-256                                             │
│  Purpose: Trust Anchor for Organization                        │
│                                                                 │
│  Key Usage:                                                     │
│    ✓ Certificate Sign                                          │
│    ✓ CRL Sign                                                  │
│                                                                 │
│  Basic Constraints: CA:TRUE                                     │
│                                                                 │
│  Location: /etc/pki/CA/certs/ca.cert.pem                       │
│  Private Key: /etc/pki/CA/private/ca.key.pem (ENCRYPTED)       │
│                                                                 │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ Signs with Root CA Private Key
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│                LEARNINGMYWAY INTERMEDIATE CA                    │
│                                                                 │
│  Common Name: LearningMyWay Intermediate CA                    │
│  Type: Intermediate Certificate                                │
│  Key Size: 4096-bit RSA                                        │
│  Validity: 5 years (1825 days)                                 │
│  Signature: SHA-256                                             │
│  Signed By: LearningMyWay Root CA                              │
│  Purpose: Issue Server Certificates                            │
│                                                                 │
│  Key Usage:                                                     │
│    ✓ Certificate Sign                                          │
│    ✓ CRL Sign                                                  │
│                                                                 │
│  Basic Constraints: CA:TRUE, pathlen:0                          │
│                                                                 │
│  Location: /etc/pki/CA/intermediate/certs/intermediate.cert.pem│
│  Private Key: /etc/pki/CA/intermediate/private/intermediate... │
│               (ENCRYPTED)                                       │
│                                                                 │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ Signs with Intermediate CA Private Key
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│                    SERVER CERTIFICATE                           │
│                                                                 │
│  Common Name: jenkins.np.learningmyway.space                   │
│  Type: End-Entity Server Certificate                           │
│  Key Size: 2048-bit RSA                                        │
│  Validity: 1 year (365 days)                                   │
│  Signature: SHA-256                                             │
│  Signed By: LearningMyWay Intermediate CA                      │
│  Purpose: Jenkins HTTPS Endpoint                               │
│                                                                 │
│  Subject Alternative Names:                                     │
│    ✓ DNS: jenkins.np.learningmyway.space                       │
│    ✓ IP: 10.10.10.100                                          │
│                                                                 │
│  Key Usage:                                                     │
│    ✓ Digital Signature                                         │
│    ✓ Key Encipherment                                          │
│                                                                 │
│  Extended Key Usage:                                            │
│    ✓ Server Authentication (TLS Web Server)                    │
│                                                                 │
│  Basic Constraints: CA:FALSE                                    │
│                                                                 │
│  Location: /etc/jenkins/certs/jenkins.cert.pem                 │
│  Private Key: /etc/jenkins/certs/jenkins.key.pem (UNENCRYPTED) │
│  Chain File: /etc/jenkins/certs/jenkins-chain.cert.pem         │
│  PKCS12: /etc/jenkins/certs/jenkins.p12                        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Certificate Validation Flow

```
┌──────────────┐
│   Browser    │
│   (Client)   │
└──────┬───────┘
       │
       │ 1. Connects to https://jenkins.np.learningmyway.space
       │
       ▼
┌──────────────────────────────────────────────────────────────┐
│                     Jenkins Server                           │
│                                                              │
│  Presents Certificate Chain:                                │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ 1. Server Certificate (jenkins.np.learningmyway.space) │ │
│  │ 2. Intermediate CA Certificate                         │ │
│  │ 3. Root CA Certificate                                  │ │
│  └────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────┘
       │
       │ 2. Browser receives certificate chain
       │
       ▼
┌──────────────────────────────────────────────────────────────┐
│              Browser Certificate Validation                  │
│                                                              │
│  Step 1: Verify Server Certificate                          │
│    ✓ Check signature using Intermediate CA public key       │
│    ✓ Verify domain name matches (jenkins.np.learningmyway..│
│    ✓ Check validity dates (not expired)                     │
│    ✓ Verify key usage (Server Authentication)               │
│                                                              │
│  Step 2: Verify Intermediate CA Certificate                 │
│    ✓ Check signature using Root CA public key               │
│    ✓ Verify CA constraints (CA:TRUE, pathlen:0)             │
│    ✓ Check validity dates (not expired)                     │
│    ✓ Verify key usage (Certificate Sign)                    │
│                                                              │
│  Step 3: Verify Root CA Certificate                         │
│    ✓ Check if Root CA is in Trusted Root Store              │
│    ✓ Verify self-signature                                  │
│    ✓ Check validity dates (not expired)                     │
│                                                              │
└──────────────────────────────────────────────────────────────┘
       │
       │ 3. Validation Result
       │
       ▼
┌──────────────────────────────────────────────────────────────┐
│                                                              │
│  ✅ TRUSTED - Root CA found in Trusted Root Store           │
│                                                              │
│  Browser shows: 🔒 Secure                                    │
│  Connection: Encrypted with TLS 1.2+                        │
│  No warnings displayed                                       │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

---

## Trust Chain Establishment

```
┌─────────────────────────────────────────────────────────────────┐
│                    CLIENT MACHINE                               │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │         Trusted Root Certification Authorities            │ │
│  │                                                           │ │
│  │  • Microsoft Root Certificate Authority                  │ │
│  │  • DigiCert Global Root CA                               │ │
│  │  • Let's Encrypt Root CA                                 │ │
│  │  • ... (hundreds of public CAs)                          │ │
│  │                                                           │ │
│  │  ✅ LearningMyWay Root CA  ← MANUALLY INSTALLED          │ │
│  │                                                           │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
│  Once Root CA is installed here, all certificates signed by    │
│  this CA (or its Intermediate CAs) are automatically trusted.  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## File Structure and Relationships

```
/etc/pki/CA/
│
├── certs/
│   └── ca.cert.pem ──────────────────┐
│       (Root CA Certificate)         │
│       • Public certificate          │
│       • Distribute to clients       │
│       • 10-year validity            │
│                                     │
├── private/                          │
│   └── ca.key.pem                    │
│       (Root CA Private Key)         │
│       • HIGHLY SENSITIVE            │
│       • Encrypted with passphrase   │
│       • Store offline/secure        │
│       • Used to sign Intermediate   │
│                                     │
└── intermediate/                     │
    │                                 │
    ├── certs/                        │
    │   └── intermediate.cert.pem ────┼───────────┐
    │       (Intermediate CA Cert)    │           │
    │       • Signed by Root CA ──────┘           │
    │       • 5-year validity                     │
    │                                             │
    ├── private/                                  │
    │   └── intermediate.key.pem                  │
    │       (Intermediate CA Private Key)         │
    │       • Encrypted with passphrase           │
    │       • Used to sign server certs           │
    │                                             │
    └── csr/                                      │
        └── intermediate.csr.pem                  │
            (Certificate Signing Request)         │
                                                  │
                                                  │
/etc/jenkins/certs/                               │
│                                                 │
├── jenkins.key.pem                               │
│   (Server Private Key)                          │
│   • NOT encrypted (for auto-start)              │
│   • 2048-bit RSA                                │
│   • Used for TLS handshake                      │
│                                                 │
├── jenkins.cert.pem ────────────────────────────┘
│   (Server Certificate)
│   • Signed by Intermediate CA
│   • 1-year validity
│   • Contains: CN=jenkins.np.learningmyway.space
│   • SAN: DNS + IP address
│
├── jenkins-chain.cert.pem
│   (Full Certificate Chain)
│   • jenkins.cert.pem
│   • + intermediate.cert.pem
│   • + ca.cert.pem
│   • Presented to clients during TLS handshake
│
└── jenkins.p12
    (PKCS12 Keystore)
    • Contains: private key + certificate chain
    • Format required by Jenkins
    • Password protected
```

---

## TLS Handshake with Certificate Chain

```
┌──────────────┐                                    ┌──────────────┐
│   Browser    │                                    │   Jenkins    │
│   (Client)   │                                    │   (Server)   │
└──────┬───────┘                                    └──────┬───────┘
       │                                                   │
       │ 1. ClientHello (TLS 1.2, cipher suites)          │
       │──────────────────────────────────────────────────>│
       │                                                   │
       │                2. ServerHello (TLS 1.2, cipher)  │
       │<──────────────────────────────────────────────────│
       │                                                   │
       │                3. Certificate Chain:              │
       │                   - Server Cert                   │
       │                   - Intermediate CA Cert          │
       │                   - Root CA Cert                  │
       │<──────────────────────────────────────────────────│
       │                                                   │
       │ 4. Verify Certificate Chain                       │
       │    ✓ Server cert signed by Intermediate CA        │
       │    ✓ Intermediate CA signed by Root CA            │
       │    ✓ Root CA in Trusted Root Store                │
       │                                                   │
       │ 5. ClientKeyExchange (encrypted with server key)  │
       │──────────────────────────────────────────────────>│
       │                                                   │
       │                6. ChangeCipherSpec                │
       │<─────────────────────────────────────────────────>│
       │                                                   │
       │ 7. Encrypted Application Data (HTTPS)            │
       │<═════════════════════════════════════════════════>│
       │                                                   │
```

---

## Certificate Lifecycle

```
┌─────────────────────────────────────────────────────────────────┐
│                     ROOT CA LIFECYCLE                           │
│                                                                 │
│  Creation (Feb 2026)                                            │
│      │                                                          │
│      ├─ Generate 4096-bit RSA key pair                          │
│      ├─ Create self-signed certificate                          │
│      ├─ Validity: 10 years (expires Feb 2036)                   │
│      └─ Distribute to all client machines                       │
│                                                                 │
│  Usage (2026-2036)                                              │
│      │                                                          │
│      ├─ Sign Intermediate CA certificates                       │
│      ├─ Revoke compromised Intermediate CAs                     │
│      └─ Store private key offline (rarely used)                 │
│                                                                 │
│  Renewal (2035)                                                 │
│      │                                                          │
│      ├─ Generate new Root CA (overlap period)                   │
│      ├─ Distribute new Root CA to clients                       │
│      ├─ Migrate Intermediate CAs to new Root                    │
│      └─ Retire old Root CA after migration                      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                 INTERMEDIATE CA LIFECYCLE                       │
│                                                                 │
│  Creation (Feb 2026)                                            │
│      │                                                          │
│      ├─ Generate 4096-bit RSA key pair                          │
│      ├─ Create CSR                                              │
│      ├─ Sign with Root CA                                       │
│      └─ Validity: 5 years (expires Feb 2031)                    │
│                                                                 │
│  Usage (2026-2031)                                              │
│      │                                                          │
│      ├─ Sign server certificates                                │
│      ├─ Revoke compromised server certificates                  │
│      └─ Maintain CRL (Certificate Revocation List)              │
│                                                                 │
│  Renewal (2030)                                                 │
│      │                                                          │
│      ├─ Generate new Intermediate CA                            │
│      ├─ Sign with Root CA                                       │
│      ├─ Issue new server certificates                           │
│      └─ Retire old Intermediate CA                              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                   SERVER CERTIFICATE LIFECYCLE                  │
│                                                                 │
│  Creation (Feb 2026)                                            │
│      │                                                          │
│      ├─ Generate 2048-bit RSA key pair                          │
│      ├─ Create CSR with SAN                                     │
│      ├─ Sign with Intermediate CA                               │
│      └─ Validity: 1 year (expires Feb 2027)                     │
│                                                                 │
│  Deployment (Feb 2026)                                          │
│      │                                                          │
│      ├─ Convert to PKCS12 format                                │
│      ├─ Configure Jenkins                                       │
│      └─ Test HTTPS access                                       │
│                                                                 │
│  Monitoring (2026-2027)                                         │
│      │                                                          │
│      ├─ Monitor expiration date                                 │
│      ├─ Set renewal reminder (30 days before)                   │
│      └─ Check for security vulnerabilities                      │
│                                                                 │
│  Renewal (Jan 2027)                                             │
│      │                                                          │
│      ├─ Generate new CSR (reuse private key OR new key)         │
│      ├─ Sign with Intermediate CA                               │
│      ├─ Deploy new certificate                                  │
│      └─ Restart Jenkins (zero downtime possible)                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Security Layers

```
┌─────────────────────────────────────────────────────────────────┐
│                      SECURITY ARCHITECTURE                      │
│                                                                 │
│  Layer 1: Network Isolation                                     │
│    ✓ No public IP on Jenkins VM                                │
│    ✓ VPN-only access (Firezone)                                │
│    ✓ VPC peering between projects                              │
│                                                                 │
│  Layer 2: Firewall Rules                                        │
│    ✓ Allow VPN subnet → Jenkins (ports 8080, 443)              │
│    ✓ Allow IAP → Jenkins (port 22)                             │
│    ✓ Allow health checks → Jenkins (port 8080)                 │
│    ✓ Deny all other traffic                                    │
│                                                                 │
│  Layer 3: VPN Authentication                                    │
│    ✓ Firezone WireGuard VPN                                    │
│    ✓ User authentication required                              │
│    ✓ Resource-based access control                             │
│                                                                 │
│  Layer 4: TLS Encryption (NEW!)                                │
│    ✓ HTTPS with proper certificate chain                       │
│    ✓ TLS 1.2+ encryption                                       │
│    ✓ Certificate validation                                    │
│    ✓ Man-in-the-middle protection                              │
│                                                                 │
│  Layer 5: Application Security                                 │
│    ✓ Jenkins authentication                                    │
│    ✓ Role-based access control                                 │
│    ✓ Audit logging                                             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Benefits of Certificate Chain

| Aspect | Self-Signed Certificate | Certificate Chain (PKI) |
|--------|------------------------|-------------------------|
| Browser Warning | ❌ Always shows warning | ✅ No warning after Root CA install |
| Trust Model | ❌ Trust each certificate | ✅ Trust Root CA once |
| Multiple Servers | ❌ Install each cert | ✅ Issue from same CA |
| Certificate Management | ❌ Manual per server | ✅ Centralized CA |
| Revocation | ❌ No revocation | ✅ CRL/OCSP support |
| Professional | ❌ Not production-ready | ✅ Industry standard |
| Compliance | ❌ May not meet requirements | ✅ Meets PKI standards |
| User Experience | ❌ Confusing warnings | ✅ Seamless access |

---

## Summary

This PKI architecture provides:

✅ **Professional certificate validation** - Industry-standard 3-tier PKI  
✅ **No browser warnings** - After one-time Root CA installation  
✅ **Scalable** - Issue multiple certificates from same CA  
✅ **Secure** - Proper certificate chain validation  
✅ **Manageable** - Centralized certificate authority  
✅ **Compliant** - Meets enterprise PKI standards  
✅ **Cost-effective** - No additional infrastructure cost

**Result:** Enterprise-grade HTTPS security for your air-gapped Jenkins infrastructure!

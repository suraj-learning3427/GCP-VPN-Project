# 🔐 Certificate Installation - Complete Summary

## High-Level Overview

We implemented a complete 3-tier PKI (Public Key Infrastructure) certificate chain for HTTPS on Jenkins, following enterprise security standards.

---

## What We Built

### Certificate Hierarchy (3 Levels)

```
Root CA (Self-Signed)
    ↓ signs
Intermediate CA
    ↓ signs
Server Certificate (Jenkins)
```

**Why 3 tiers?**
- Root CA stays offline (most secure)
- Intermediate CA does daily signing work
- Server cert is what Jenkins uses for HTTPS
- Industry standard for enterprise PKI

---

## Step-by-Step Process

### Step 1: Create Root CA (Certificate Authority)
**What:** Created the top-level trusted authority  
**Where:** Jenkins VM at `/etc/pki/CA/root/`  
**Details:**
- Generated 4096-bit RSA private key
- Created self-signed certificate valid for 10 years
- This is the "trust anchor" - everything chains back to this

**Key Files:**
- `ca.key.pem` - Root CA private key (most sensitive)
- `ca.cert.pem` - Root CA certificate (public)

---

### Step 2: Create Intermediate CA
**What:** Created middle-level CA for daily operations  
**Where:** Jenkins VM at `/etc/pki/CA/intermediate/`  
**Details:**
- Generated 4096-bit RSA private key
- Created certificate signing request (CSR)
- Root CA signed the intermediate certificate
- Valid for 5 years

**Key Files:**
- `intermediate.key.pem` - Intermediate CA private key
- `intermediate.cert.pem` - Intermediate CA certificate
- `intermediate.csr.pem` - Certificate signing request

**Why intermediate?**
- Protects root CA (can revoke intermediate if compromised)
- Root CA can stay offline
- Industry best practice

---

### Step 3: Create Server Certificate (Jenkins)
**What:** Created the actual certificate Jenkins uses  
**Where:** Jenkins VM at `/etc/jenkins/certs/`  
**Details:**
- Generated 2048-bit RSA private key
- Created CSR with Subject Alternative Names (SAN)
- Intermediate CA signed the server certificate
- Valid for 1 year

**Subject Alternative Names (SAN):**
- DNS: jenkins.np.learningmyway.space
- IP: 10.10.10.100

**Key Files:**
- `jenkins.key.pem` - Server private key
- `jenkins.cert.pem` - Server certificate
- `jenkins.csr.pem` - Certificate signing request

---

### Step 4: Create Certificate Chain
**What:** Combined certificates for browser validation  
**Where:** `/etc/jenkins/certs/jenkins-chain.cert.pem`  
**Details:**
- Combined server cert + intermediate cert + root cert
- Browser validates entire chain
- Proves certificate authenticity

**Chain order:**
```
Server Certificate
↓
Intermediate Certificate
↓
Root Certificate
```

---

### Step 5: Create PKCS12 Keystore (Optional)
**What:** Java-compatible certificate format  
**Where:** `/etc/jenkins/certs/jenkins.p12`  
**Details:**
- Combined private key + certificate chain
- Password protected (changeit)
- Used if Jenkins needs Java keystore

---

### Step 6: Configure Nginx for HTTPS
**What:** Setup SSL termination with Nginx  
**Where:** `/etc/nginx/conf.d/jenkins.conf`  
**Details:**
- Nginx listens on port 443 (HTTPS)
- Uses server certificate and private key
- Proxies decrypted traffic to Jenkins on port 8080
- Redirects HTTP (80) to HTTPS (443)

**Configuration:**
```nginx
ssl_certificate /etc/jenkins/certs/jenkins-chain.cert.pem;
ssl_certificate_key /etc/jenkins/certs/jenkins.key.pem;
```

---

### Step 7: Install Root CA on Client (Windows)
**What:** Make Windows trust our certificates  
**Where:** Windows Certificate Store  
**Details:**
- Downloaded Root CA from Jenkins VM
- Installed in "Trusted Root Certification Authorities"
- Now Windows trusts all certificates signed by our CA

**Installation:**
```powershell
.\install-root-ca.ps1
```

**What it does:**
- Imports Root CA certificate
- Adds to Trusted Root store
- Browser now shows green padlock

---

### Step 8: Configure DNS Resolution
**What:** Map domain name to Jenkins IP  
**Where:** Windows hosts file  
**Details:**
- Added entry: `10.10.10.100 jenkins.np.learningmyway.space`
- Allows accessing Jenkins by domain name
- Required for certificate validation (SAN match)

**File:** `C:\Windows\System32\drivers\etc\hosts`

---

## How It All Works Together

### When You Access Jenkins:

1. **Browser connects** to `https://jenkins.np.learningmyway.space:443`
2. **DNS resolves** to 10.10.10.100 (via hosts file)
3. **VPN routes** traffic through Firezone to Jenkins VPC
4. **Nginx receives** HTTPS request on port 443
5. **TLS handshake** begins:
   - Nginx sends certificate chain
   - Browser validates: Server → Intermediate → Root CA
   - Browser checks Root CA is in Trusted Root store ✓
   - Browser verifies domain matches SAN ✓
6. **Encryption established** using negotiated cipher
7. **Nginx decrypts** HTTPS traffic
8. **Nginx proxies** plain HTTP to Jenkins on localhost:8080
9. **Jenkins responds** back through Nginx
10. **Nginx encrypts** response and sends to browser

---

## Security Layers

### Layer 1: VPN Encryption
- WireGuard protocol
- Traffic encrypted from client to VPN gateway

### Layer 2: TLS/HTTPS Encryption
- TLS 1.2/1.3
- Traffic encrypted from VPN gateway to Jenkins
- Certificate-based authentication

### Result: Double Encryption
- Data encrypted twice during transit
- Even if VPN is compromised, HTTPS protects data
- Defense in depth security model

---

## Key Concepts Explained

### What is a Certificate?
A digital document that proves identity, like a passport for websites.

### What is a Certificate Authority (CA)?
A trusted entity that signs certificates, like a government issuing passports.

### What is a Certificate Chain?
A series of certificates where each one vouches for the next:
- Root CA says "I trust Intermediate CA"
- Intermediate CA says "I trust Jenkins Server"
- Browser says "I trust Root CA, so I trust Jenkins"

### What is Self-Signed?
Root CA signs its own certificate (no higher authority). We manually trust it by installing in Windows.

### What is Subject Alternative Name (SAN)?
List of domains/IPs the certificate is valid for:
- jenkins.np.learningmyway.space ✓
- 10.10.10.100 ✓

### What is SSL Termination?
Nginx handles HTTPS encryption/decryption, Jenkins only sees plain HTTP. Simplifies Jenkins configuration.

---

## Files Created

### On Jenkins VM:
```
/etc/pki/CA/
├── root/
│   ├── ca.key.pem (Root CA private key)
│   └── ca.cert.pem (Root CA certificate)
├── intermediate/
│   ├── intermediate.key.pem (Intermediate private key)
│   ├── intermediate.cert.pem (Intermediate certificate)
│   └── intermediate.csr.pem (Certificate request)
└── /etc/jenkins/certs/
    ├── jenkins.key.pem (Server private key)
    ├── jenkins.cert.pem (Server certificate)
    ├── jenkins.csr.pem (Certificate request)
    ├── jenkins-chain.cert.pem (Full chain)
    └── jenkins.p12 (PKCS12 keystore)
```

### On Windows Client:
```
C:\Windows\System32\drivers\etc\hosts
    10.10.10.100 jenkins.np.learningmyway.space

Certificate Store:
    Trusted Root Certification Authorities
        └── LearningMyWay Root CA
```

---

## Automation Script

We created `scripts/create-pki-certificates.sh` that automates everything:
- Creates all directories
- Generates all keys
- Creates all certificates
- Sets up certificate chain
- Configures proper permissions
- One command does it all

**Usage:**
```bash
sudo bash /tmp/create-pki-certificates.sh
```

---

## Certificate Validity Periods

| Certificate | Validity | Expires |
|-------------|----------|---------|
| Root CA | 10 years | Feb 13, 2036 |
| Intermediate CA | 5 years | Feb 12, 2031 |
| Server Certificate | 1 year | Feb 13, 2027 |

**Why different periods?**
- Root CA: Long-lived (rarely changes)
- Intermediate: Medium-lived (balance security/convenience)
- Server: Short-lived (best practice, easy to rotate)

---

## Verification Commands

### Check Certificate Details:
```bash
openssl x509 -in /etc/jenkins/certs/jenkins.cert.pem -text -noout
```

### Verify Certificate Chain:
```bash
openssl verify -CAfile /etc/pki/CA/root/ca.cert.pem \
  -untrusted /etc/pki/CA/intermediate/intermediate.cert.pem \
  /etc/jenkins/certs/jenkins.cert.pem
```

### Test HTTPS Connection:
```bash
openssl s_client -connect jenkins.np.learningmyway.space:443 -showcerts
```

### Check from Browser:
1. Visit `https://jenkins.np.learningmyway.space`
2. Click padlock icon
3. View certificate details
4. Verify chain: Server → Intermediate → Root

---

## Common Issues & Solutions

### Issue 1: Browser Shows "Not Secure"
**Cause:** Root CA not installed on client  
**Solution:** Run `install-root-ca.ps1` on Windows

### Issue 2: Certificate Name Mismatch
**Cause:** Accessing by IP instead of domain  
**Solution:** Use `https://jenkins.np.learningmyway.space` (not IP)

### Issue 3: Connection Refused
**Cause:** Nginx not running or firewall blocking  
**Solution:** Check `systemctl status nginx` and firewall rules

### Issue 4: Certificate Expired
**Cause:** Server cert valid for 1 year  
**Solution:** Regenerate certificates with script

---

## Why This Approach?

### Professional Standards:
- ✅ 3-tier PKI (enterprise standard)
- ✅ Proper certificate chain
- ✅ Strong encryption (RSA 4096/2048)
- ✅ Subject Alternative Names
- ✅ SSL termination at reverse proxy
- ✅ Automated certificate generation

### Security Benefits:
- ✅ End-to-end encryption
- ✅ Certificate-based authentication
- ✅ Protection against man-in-the-middle attacks
- ✅ Browser validation of certificate chain
- ✅ Defense in depth (VPN + TLS)

### Learning Value:
- ✅ Understand PKI concepts
- ✅ Certificate chain validation
- ✅ OpenSSL commands
- ✅ Nginx SSL configuration
- ✅ Windows certificate management
- ✅ Enterprise security practices

---

## Interview Talking Points

**"How did you implement HTTPS?"**
> "I built a complete 3-tier PKI infrastructure with Root CA, Intermediate CA, and server certificates. Used OpenSSL to generate 4096-bit RSA keys, created certificate chains, and configured Nginx for SSL termination. Implemented proper SAN entries for domain and IP validation, and automated the entire process with a bash script."

**"Why 3-tier PKI?"**
> "It's enterprise best practice. The Root CA stays offline for security, the Intermediate CA handles daily operations, and server certificates can be easily rotated. If the server cert is compromised, we only revoke that one certificate, not the entire CA."

**"How does certificate validation work?"**
> "The browser receives the certificate chain and validates each level. It checks the server certificate was signed by the Intermediate CA, the Intermediate was signed by the Root CA, and the Root CA is in the trusted store. It also verifies the domain matches the SAN and the certificate hasn't expired."

---

**Document Version:** 1.0  
**Date:** February 16, 2026  
**Related Files:**
- `PKI-CERTIFICATE-CHAIN-GUIDE.md` - Detailed technical guide
- `scripts/create-pki-certificates.sh` - Automation script
- `install-root-ca.ps1` - Windows installation script
- `PKI-ARCHITECTURE-DIAGRAM.md` - Visual diagrams

**END OF SUMMARY**

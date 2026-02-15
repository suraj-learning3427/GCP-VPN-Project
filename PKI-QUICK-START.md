# PKI Certificate Chain - Quick Start Guide

**Status:** Ready to implement  
**Time Required:** 30 minutes  
**Last Updated:** February 13, 2026

---

## What You're Building

A complete internal PKI (Public Key Infrastructure) with proper certificate chain:

```
┌─────────────────────────────────────┐
│   LearningMyWay Root CA             │
│   (10-year validity)                │
│   Trust Anchor                      │
└──────────────┬──────────────────────┘
               │
               │ Signs
               ▼
┌─────────────────────────────────────┐
│   LearningMyWay Intermediate CA     │
│   (5-year validity)                 │
│   Issues Server Certificates        │
└──────────────┬──────────────────────┘
               │
               │ Signs
               ▼
┌─────────────────────────────────────┐
│   jenkins.np.learningmyway.space    │
│   (1-year validity)                 │
│   Server Certificate                │
└─────────────────────────────────────┘
```

**Result:** No browser warnings after Root CA installation!

---

## Two Options

### Option 1: Automated Script (Recommended)

**Fastest way** - One command creates everything:

```bash
# SSH into Jenkins VM
gcloud compute ssh jenkins-vm --project=test-project2-485105 --zone=us-central1-a --tunnel-through-iap

# Upload and run the script
sudo bash /path/to/create-pki-certificates.sh
```

The script automatically:
- Creates all directory structures
- Generates Root CA (4096-bit, 10-year validity)
- Generates Intermediate CA (4096-bit, 5-year validity)
- Generates Server Certificate (2048-bit, 1-year validity)
- Builds certificate chain
- Converts to PKCS12 for Jenkins
- Sets all permissions correctly

**Time:** 5 minutes

### Option 2: Manual Step-by-Step

Follow the detailed guide in `PKI-CERTIFICATE-CHAIN-GUIDE.md` for complete control and understanding of each step.

**Time:** 30 minutes

---

## After Certificate Creation

### 1. Configure Jenkins for HTTPS

Edit Jenkins service file:
```bash
sudo vi /usr/lib/systemd/system/jenkins.service
```

Add after `Environment="JENKINS_PORT=8080"`:
```
Environment="JENKINS_HTTPS_PORT=443"
Environment="JENKINS_HTTPS_KEYSTORE=/etc/jenkins/certs/jenkins.p12"
Environment="JENKINS_HTTPS_KEYSTORE_PASSWORD=changeit"
```

Restart Jenkins:
```bash
sudo systemctl daemon-reload
sudo systemctl restart jenkins
sudo systemctl status jenkins
```

### 2. Download Root CA Certificate

From your local machine:
```bash
gcloud compute scp jenkins-vm:/tmp/LearningMyWay-Root-CA.crt . \
  --project=test-project2-485105 \
  --zone=us-central1-a \
  --tunnel-through-iap
```

### 3. Install Root CA on Your Computer

**Windows:**
```powershell
# Run as Administrator
Import-Certificate -FilePath "LearningMyWay-Root-CA.crt" -CertStoreLocation Cert:\LocalMachine\Root
```

**macOS:**
```bash
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain LearningMyWay-Root-CA.crt
```

**Linux:**
```bash
sudo cp LearningMyWay-Root-CA.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates
```

### 4. Update Terraform Load Balancer

Edit `terraform/modules/load-balancer/main.tf`:

```terraform
resource "google_compute_forwarding_rule" "jenkins_lb" {
  name                  = "jenkins-lb-forwarding-rule"
  region                = var.region
  project               = var.project_id
  load_balancing_scheme = "INTERNAL"
  backend_service       = google_compute_region_backend_service.jenkins_backend.id
  ip_protocol           = "TCP"
  ports                 = ["8080", "443"]  # Add 443
  network               = var.vpc_name
  subnetwork            = var.subnet_name
  ip_address            = "10.10.10.100"
}
```

Apply:
```bash
cd terraform
terraform plan
terraform apply
```

### 5. Test HTTPS Access

1. Connect to Firezone VPN
2. Open browser
3. Go to: `https://jenkins.np.learningmyway.space`
4. **No warning!** Browser shows "Secure" 🔒

---

## Certificate Files Location

After creation, you'll have:

```
/etc/pki/CA/
├── certs/
│   └── ca.cert.pem                    # Root CA certificate
├── private/
│   └── ca.key.pem                     # Root CA private key (PROTECT!)
└── intermediate/
    ├── certs/
    │   └── intermediate.cert.pem      # Intermediate CA certificate
    └── private/
        └── intermediate.key.pem       # Intermediate CA private key (PROTECT!)

/etc/jenkins/certs/
├── jenkins.key.pem                    # Server private key
├── jenkins.cert.pem                   # Server certificate
├── jenkins-chain.cert.pem             # Full certificate chain
└── jenkins.p12                        # PKCS12 keystore for Jenkins

/tmp/
└── LearningMyWay-Root-CA.crt          # Root CA for client distribution
```

---

## Important Passphrases

**Save these securely!**

- Root CA Passphrase: `RootCA@LearningMyWay2026!`
- Intermediate CA Passphrase: `IntermediateCA@LearningMyWay2026!`
- PKCS12 Password: `changeit`

**Security Note:** Change these in the script before running in production!

---

## Certificate Renewal Schedule

| Certificate | Expires | Renewal Action |
|-------------|---------|----------------|
| Root CA | Feb 2036 (10 years) | Rarely needed, major event |
| Intermediate CA | Feb 2031 (5 years) | Regenerate and re-sign server certs |
| Server Certificate | Feb 2027 (1 year) | Annual renewal (automated script available) |

**Set calendar reminder:** January 2027 to renew server certificate

---

## Verification Commands

```bash
# Verify Root CA
openssl x509 -noout -text -in /etc/pki/CA/certs/ca.cert.pem

# Verify Intermediate CA
openssl x509 -noout -text -in /etc/pki/CA/intermediate/certs/intermediate.cert.pem

# Verify Server Certificate
openssl x509 -noout -text -in /etc/jenkins/certs/jenkins.cert.pem

# Verify Certificate Chain
openssl verify -CAfile /etc/pki/CA/certs/ca.cert.pem \
  -untrusted /etc/pki/CA/intermediate/certs/intermediate.cert.pem \
  /etc/jenkins/certs/jenkins.cert.pem

# Test HTTPS Connection
curl -v https://localhost:443

# Check Certificate Chain from Browser
openssl s_client -connect localhost:443 -showcerts
```

---

## Troubleshooting

### Jenkins Won't Start

```bash
# Check logs
sudo journalctl -u jenkins -n 50

# Common issues:
# - Wrong PKCS12 password in jenkins.service
# - Incorrect file permissions
# - Certificate files missing
```

### Browser Still Shows Warning

```bash
# Verify Root CA is installed
# Windows: Win+R → certmgr.msc → Trusted Root Certification Authorities
# macOS: Keychain Access → System → Certificates
# Linux: ls /usr/local/share/ca-certificates/
```

### Certificate Chain Invalid

```bash
# Verify chain
openssl verify -CAfile /etc/pki/CA/certs/ca.cert.pem \
  -untrusted /etc/pki/CA/intermediate/certs/intermediate.cert.pem \
  /etc/jenkins/certs/jenkins.cert.pem

# Should output: OK
```

---

## Security Best Practices

1. **Backup Everything**
   ```bash
   # Backup entire PKI
   sudo tar -czf pki-backup-$(date +%Y%m%d).tar.gz /etc/pki/CA
   
   # Store encrypted backup offline
   ```

2. **Protect Private Keys**
   - Root CA key: Store offline, encrypted
   - Intermediate CA key: Keep on secure server
   - Server key: File permissions 400

3. **Monitor Expiration**
   - Set calendar reminders
   - Automate expiration checks
   - Renew 30 days before expiry

4. **Change Default Passphrases**
   - Edit script before running
   - Use strong, unique passphrases
   - Store in password manager

---

## Cost Impact

**$0** - No additional infrastructure cost, just proper certificates!

---

## Summary

After completing this guide:

✅ Complete internal PKI infrastructure  
✅ Root CA certificate (10-year validity)  
✅ Intermediate CA certificate (5-year validity)  
✅ Server certificate with full chain (1-year validity)  
✅ Jenkins configured for HTTPS  
✅ No browser warnings (after Root CA installation)  
✅ Professional certificate validation  
✅ Industry-standard PKI architecture

**Access Jenkins:** `https://jenkins.np.learningmyway.space` 🔒

---

## Need Help?

- Detailed guide: `PKI-CERTIFICATE-CHAIN-GUIDE.md`
- Automated script: `scripts/create-pki-certificates.sh`
- Requirements: `.kiro/specs/vpn-jenkins-infrastructure/requirements.md`

**Ready to start?** Run the automated script or follow the detailed guide!

# PKI Certificate Chain Implementation Guide

**Status:** Ready to implement  
**Estimated Time:** 30 minutes  
**Last Updated:** February 13, 2026

---

## Overview

This guide creates a complete internal PKI (Public Key Infrastructure) with a proper certificate chain for Jenkins HTTPS access.

**Certificate Chain:**
```
Root CA (LearningMyWay Root CA)
    └── Intermediate CA (LearningMyWay Intermediate CA)
            └── Server Certificate (jenkins.np.learningmyway.space)
```

**Benefits:**
- No browser warnings after Root CA installation
- Professional certificate validation
- Can issue multiple certificates from same CA
- Industry-standard PKI architecture

---

## Part 1: Create Root CA

### Step 1: SSH into Jenkins VM

```bash
gcloud compute ssh jenkins-vm --project=test-project2-485105 --zone=us-central1-a --tunnel-through-iap
```

### Step 2: Create PKI Directory Structure

```bash
# Create directory structure
sudo mkdir -p /etc/pki/CA/{certs,crl,newcerts,private,intermediate}
sudo mkdir -p /etc/pki/CA/intermediate/{certs,crl,csr,newcerts,private}

# Set permissions
sudo chmod 700 /etc/pki/CA/private
sudo chmod 700 /etc/pki/CA/intermediate/private

# Create index and serial files
sudo touch /etc/pki/CA/index.txt
sudo touch /etc/pki/CA/intermediate/index.txt
echo 1000 | sudo tee /etc/pki/CA/serial
echo 1000 | sudo tee /etc/pki/CA/intermediate/serial
echo 1000 | sudo tee /etc/pki/CA/intermediate/crlnumber
```

### Step 3: Create Root CA Configuration

```bash
sudo tee /etc/pki/CA/openssl-root.cnf > /dev/null << 'EOF'
[ ca ]
default_ca = CA_default

[ CA_default ]
dir               = /etc/pki/CA
certs             = $dir/certs
crl_dir           = $dir/crl
new_certs_dir     = $dir/newcerts
database          = $dir/index.txt
serial            = $dir/serial
RANDFILE          = $dir/private/.rand
private_key       = $dir/private/ca.key.pem
certificate       = $dir/certs/ca.cert.pem
crlnumber         = $dir/crlnumber
crl               = $dir/crl/ca.crl.pem
crl_extensions    = crl_ext
default_crl_days  = 30
default_md        = sha256
name_opt          = ca_default
cert_opt          = ca_default
default_days      = 375
preserve          = no
policy            = policy_strict

[ policy_strict ]
countryName             = match
stateOrProvinceName     = match
organizationName        = match
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ policy_loose ]
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ req ]
default_bits        = 4096
distinguished_name  = req_distinguished_name
string_mask         = utf8only
default_md          = sha256
x509_extensions     = v3_ca

[ req_distinguished_name ]
countryName                     = Country Name (2 letter code)
stateOrProvinceName             = State or Province Name
localityName                    = Locality Name
0.organizationName              = Organization Name
organizationalUnitName          = Organizational Unit Name
commonName                      = Common Name
emailAddress                    = Email Address

countryName_default             = US
stateOrProvinceName_default     = California
localityName_default            = San Francisco
0.organizationName_default      = LearningMyWay
organizationalUnitName_default  = IT Security
emailAddress_default            = rksuraj@learningmyway.space

[ v3_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ v3_intermediate_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true, pathlen:0
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ server_cert ]
basicConstraints = CA:FALSE
nsCertType = server
nsComment = "OpenSSL Generated Server Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer:always
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = jenkins.np.learningmyway.space
IP.1 = 10.10.10.100

[ crl_ext ]
authorityKeyIdentifier=keyid:always

[ ocsp ]
basicConstraints = CA:FALSE
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, digitalSignature
extendedKeyUsage = critical, OCSPSigning
EOF
```

### Step 4: Generate Root CA Private Key

```bash
# Generate 4096-bit RSA key for Root CA
sudo openssl genrsa -aes256 -out /etc/pki/CA/private/ca.key.pem 4096

# You'll be prompted for a passphrase - use a strong one and save it securely
# Example: RootCA@LearningMyWay2026!

# Set permissions
sudo chmod 400 /etc/pki/CA/private/ca.key.pem
```

### Step 5: Generate Root CA Certificate

```bash
# Create Root CA certificate (valid for 10 years)
sudo openssl req -config /etc/pki/CA/openssl-root.cnf \
  -key /etc/pki/CA/private/ca.key.pem \
  -new -x509 -days 3650 -sha256 -extensions v3_ca \
  -out /etc/pki/CA/certs/ca.cert.pem \
  -subj "/C=US/ST=California/L=San Francisco/O=LearningMyWay/OU=IT Security/CN=LearningMyWay Root CA/emailAddress=rksuraj@learningmyway.space"

# Set permissions
sudo chmod 444 /etc/pki/CA/certs/ca.cert.pem

# Verify Root CA certificate
sudo openssl x509 -noout -text -in /etc/pki/CA/certs/ca.cert.pem
```

---

## Part 2: Create Intermediate CA

### Step 6: Create Intermediate CA Configuration

```bash
sudo tee /etc/pki/CA/intermediate/openssl-intermediate.cnf > /dev/null << 'EOF'
[ ca ]
default_ca = CA_default

[ CA_default ]
dir               = /etc/pki/CA/intermediate
certs             = $dir/certs
crl_dir           = $dir/crl
new_certs_dir     = $dir/newcerts
database          = $dir/index.txt
serial            = $dir/serial
RANDFILE          = $dir/private/.rand
private_key       = $dir/private/intermediate.key.pem
certificate       = $dir/certs/intermediate.cert.pem
crlnumber         = $dir/crlnumber
crl               = $dir/crl/intermediate.crl.pem
crl_extensions    = crl_ext
default_crl_days  = 30
default_md        = sha256
name_opt          = ca_default
cert_opt          = ca_default
default_days      = 375
preserve          = no
policy            = policy_loose

[ policy_strict ]
countryName             = match
stateOrProvinceName     = match
organizationName        = match
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ policy_loose ]
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ req ]
default_bits        = 4096
distinguished_name  = req_distinguished_name
string_mask         = utf8only
default_md          = sha256
x509_extensions     = v3_intermediate_ca

[ req_distinguished_name ]
countryName                     = Country Name (2 letter code)
stateOrProvinceName             = State or Province Name
localityName                    = Locality Name
0.organizationName              = Organization Name
organizationalUnitName          = Organizational Unit Name
commonName                      = Common Name
emailAddress                    = Email Address

countryName_default             = US
stateOrProvinceName_default     = California
localityName_default            = San Francisco
0.organizationName_default      = LearningMyWay
organizationalUnitName_default  = IT Security
emailAddress_default            = rksuraj@learningmyway.space

[ v3_intermediate_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true, pathlen:0
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ server_cert ]
basicConstraints = CA:FALSE
nsCertType = server
nsComment = "OpenSSL Generated Server Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer:always
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = jenkins.np.learningmyway.space
IP.1 = 10.10.10.100

[ crl_ext ]
authorityKeyIdentifier=keyid:always

[ ocsp ]
basicConstraints = CA:FALSE
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, digitalSignature
extendedKeyUsage = critical, OCSPSigning
EOF
```

### Step 7: Generate Intermediate CA Private Key

```bash
# Generate 4096-bit RSA key for Intermediate CA
sudo openssl genrsa -aes256 -out /etc/pki/CA/intermediate/private/intermediate.key.pem 4096

# You'll be prompted for a passphrase - use a strong one and save it securely
# Example: IntermediateCA@LearningMyWay2026!

# Set permissions
sudo chmod 400 /etc/pki/CA/intermediate/private/intermediate.key.pem
```

### Step 8: Generate Intermediate CA Certificate Signing Request (CSR)

```bash
# Create CSR for Intermediate CA
sudo openssl req -config /etc/pki/CA/intermediate/openssl-intermediate.cnf \
  -new -sha256 \
  -key /etc/pki/CA/intermediate/private/intermediate.key.pem \
  -out /etc/pki/CA/intermediate/csr/intermediate.csr.pem \
  -subj "/C=US/ST=California/L=San Francisco/O=LearningMyWay/OU=IT Security/CN=LearningMyWay Intermediate CA/emailAddress=rksuraj@learningmyway.space"
```

### Step 9: Sign Intermediate CA Certificate with Root CA

```bash
# Sign Intermediate CA certificate with Root CA (valid for 5 years)
sudo openssl ca -config /etc/pki/CA/openssl-root.cnf \
  -extensions v3_intermediate_ca \
  -days 1825 -notext -md sha256 \
  -in /etc/pki/CA/intermediate/csr/intermediate.csr.pem \
  -out /etc/pki/CA/intermediate/certs/intermediate.cert.pem

# Set permissions
sudo chmod 444 /etc/pki/CA/intermediate/certs/intermediate.cert.pem

# Verify Intermediate CA certificate
sudo openssl x509 -noout -text -in /etc/pki/CA/intermediate/certs/intermediate.cert.pem

# Verify certificate chain
sudo openssl verify -CAfile /etc/pki/CA/certs/ca.cert.pem \
  /etc/pki/CA/intermediate/certs/intermediate.cert.pem
```

---

## Part 3: Create Server Certificate

### Step 10: Generate Server Private Key

```bash
# Create directory for Jenkins certificates
sudo mkdir -p /etc/jenkins/certs

# Generate 2048-bit RSA key for server (no passphrase for automated startup)
sudo openssl genrsa -out /etc/jenkins/certs/jenkins.key.pem 2048

# Set permissions
sudo chmod 400 /etc/jenkins/certs/jenkins.key.pem
```

### Step 11: Generate Server Certificate Signing Request (CSR)

```bash
# Create CSR for Jenkins server
sudo openssl req -config /etc/pki/CA/intermediate/openssl-intermediate.cnf \
  -key /etc/jenkins/certs/jenkins.key.pem \
  -new -sha256 -out /etc/jenkins/certs/jenkins.csr.pem \
  -subj "/C=US/ST=California/L=San Francisco/O=LearningMyWay/OU=IT Operations/CN=jenkins.np.learningmyway.space/emailAddress=rksuraj@learningmyway.space"
```

### Step 12: Sign Server Certificate with Intermediate CA

```bash
# Sign server certificate with Intermediate CA (valid for 1 year)
sudo openssl ca -config /etc/pki/CA/intermediate/openssl-intermediate.cnf \
  -extensions server_cert \
  -days 365 -notext -md sha256 \
  -in /etc/jenkins/certs/jenkins.csr.pem \
  -out /etc/jenkins/certs/jenkins.cert.pem

# Set permissions
sudo chmod 444 /etc/jenkins/certs/jenkins.cert.pem

# Verify server certificate
sudo openssl x509 -noout -text -in /etc/jenkins/certs/jenkins.cert.pem

# Verify certificate chain
sudo openssl verify -CAfile /etc/pki/CA/certs/ca.cert.pem \
  -untrusted /etc/pki/CA/intermediate/certs/intermediate.cert.pem \
  /etc/jenkins/certs/jenkins.cert.pem
```

---

## Part 4: Build Certificate Chain

### Step 13: Create Certificate Chain File

```bash
# Create certificate chain file (server → intermediate → root)
sudo cat /etc/jenkins/certs/jenkins.cert.pem \
  /etc/pki/CA/intermediate/certs/intermediate.cert.pem \
  /etc/pki/CA/certs/ca.cert.pem | \
  sudo tee /etc/jenkins/certs/jenkins-chain.cert.pem

# Set permissions
sudo chmod 444 /etc/jenkins/certs/jenkins-chain.cert.pem

# Verify chain
sudo openssl verify -CAfile /etc/pki/CA/certs/ca.cert.pem \
  -untrusted /etc/pki/CA/intermediate/certs/intermediate.cert.pem \
  /etc/jenkins/certs/jenkins-chain.cert.pem
```

### Step 14: Convert to PKCS12 Format for Jenkins

```bash
# Convert to PKCS12 format (Jenkins requirement)
sudo openssl pkcs12 -export \
  -out /etc/jenkins/certs/jenkins.p12 \
  -inkey /etc/jenkins/certs/jenkins.key.pem \
  -in /etc/jenkins/certs/jenkins-chain.cert.pem \
  -password pass:changeit

# Set ownership and permissions
sudo chown jenkins:jenkins /etc/jenkins/certs/*
sudo chmod 600 /etc/jenkins/certs/jenkins.key.pem
sudo chmod 600 /etc/jenkins/certs/jenkins.p12
```

---

## Part 5: Configure Jenkins for HTTPS

### Step 15: Update Jenkins Configuration

```bash
# Edit Jenkins service file
sudo vi /usr/lib/systemd/system/jenkins.service
```

Find the line with `Environment="JENKINS_PORT=8080"` and add these lines after it:

```
Environment="JENKINS_HTTPS_PORT=443"
Environment="JENKINS_HTTPS_KEYSTORE=/etc/jenkins/certs/jenkins.p12"
Environment="JENKINS_HTTPS_KEYSTORE_PASSWORD=changeit"
```

### Step 16: Restart Jenkins

```bash
# Reload systemd and restart Jenkins
sudo systemctl daemon-reload
sudo systemctl restart jenkins

# Check Jenkins status
sudo systemctl status jenkins

# Verify Jenkins is listening on port 443
sudo ss -tlnp | grep 443

# Check Jenkins logs
sudo journalctl -u jenkins -n 50
```

---

## Part 6: Export Root CA for Client Installation

### Step 17: Download Root CA Certificate

```bash
# Copy Root CA certificate to a location accessible via SCP
sudo cp /etc/pki/CA/certs/ca.cert.pem /tmp/LearningMyWay-Root-CA.crt
sudo chmod 644 /tmp/LearningMyWay-Root-CA.crt
```

From your local machine:

```bash
# Download Root CA certificate
gcloud compute scp jenkins-vm:/tmp/LearningMyWay-Root-CA.crt . \
  --project=test-project2-485105 \
  --zone=us-central1-a \
  --tunnel-through-iap
```

---

## Part 7: Install Root CA on Client Machines

### Windows Installation

1. Double-click `LearningMyWay-Root-CA.crt`
2. Click "Install Certificate"
3. Select "Local Machine"
4. Choose "Place all certificates in the following store"
5. Click "Browse" → Select "Trusted Root Certification Authorities"
6. Click "Next" → "Finish"
7. Accept security warning

Or via PowerShell (as Administrator):

```powershell
Import-Certificate -FilePath "LearningMyWay-Root-CA.crt" -CertStoreLocation Cert:\LocalMachine\Root
```

### macOS Installation

```bash
# Add to system keychain
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain LearningMyWay-Root-CA.crt
```

### Linux Installation

```bash
# Copy to CA certificates directory
sudo cp LearningMyWay-Root-CA.crt /usr/local/share/ca-certificates/

# Update CA certificates
sudo update-ca-certificates
```

---

## Part 8: Update Terraform Configuration

The firewall rules already allow port 443. You just need to update the load balancer.

Edit `terraform/modules/load-balancer/main.tf` and modify the forwarding rule:

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

Apply changes:

```bash
cd terraform
terraform plan
terraform apply
```

---

## Part 9: Test HTTPS Access

### Step 18: Test Certificate Chain

```bash
# Test from Jenkins VM
curl -v https://localhost:443

# Test certificate chain
openssl s_client -connect localhost:443 -showcerts
```

### Step 19: Access from Browser

1. Connect to Firezone VPN
2. Open browser
3. Go to: `https://jenkins.np.learningmyway.space`
4. **No browser warning!** (after Root CA installation)
5. Click the padlock icon → Certificate should show full chain

---

## Certificate Information Summary

| Certificate | Common Name | Validity | Key Size | Purpose |
|-------------|-------------|----------|----------|---------|
| Root CA | LearningMyWay Root CA | 10 years | 4096-bit | Trust anchor |
| Intermediate CA | LearningMyWay Intermediate CA | 5 years | 4096-bit | Issue server certs |
| Server | jenkins.np.learningmyway.space | 1 year | 2048-bit | Jenkins HTTPS |

---

## Certificate Renewal Process

### Renew Server Certificate (Annually)

```bash
# Generate new CSR
sudo openssl req -config /etc/pki/CA/intermediate/openssl-intermediate.cnf \
  -key /etc/jenkins/certs/jenkins.key.pem \
  -new -sha256 -out /etc/jenkins/certs/jenkins.csr.pem \
  -subj "/C=US/ST=California/L=San Francisco/O=LearningMyWay/OU=IT Operations/CN=jenkins.np.learningmyway.space/emailAddress=rksuraj@learningmyway.space"

# Sign with Intermediate CA
sudo openssl ca -config /etc/pki/CA/intermediate/openssl-intermediate.cnf \
  -extensions server_cert \
  -days 365 -notext -md sha256 \
  -in /etc/jenkins/certs/jenkins.csr.pem \
  -out /etc/jenkins/certs/jenkins.cert.pem

# Rebuild chain
sudo cat /etc/jenkins/certs/jenkins.cert.pem \
  /etc/pki/CA/intermediate/certs/intermediate.cert.pem \
  /etc/pki/CA/certs/ca.cert.pem | \
  sudo tee /etc/jenkins/certs/jenkins-chain.cert.pem

# Recreate PKCS12
sudo openssl pkcs12 -export \
  -out /etc/jenkins/certs/jenkins.p12 \
  -inkey /etc/jenkins/certs/jenkins.key.pem \
  -in /etc/jenkins/certs/jenkins-chain.cert.pem \
  -password pass:changeit

# Restart Jenkins
sudo systemctl restart jenkins
```

---

## Troubleshooting

### Certificate Chain Validation Failed

```bash
# Check certificate chain
openssl verify -CAfile /etc/pki/CA/certs/ca.cert.pem \
  -untrusted /etc/pki/CA/intermediate/certs/intermediate.cert.pem \
  /etc/jenkins/certs/jenkins.cert.pem

# Should output: /etc/jenkins/certs/jenkins.cert.pem: OK
```

### Jenkins Not Starting

```bash
# Check Jenkins logs
sudo journalctl -u jenkins -n 100

# Common issues:
# - Wrong PKCS12 password
# - Incorrect file permissions
# - Missing certificate files
```

### Browser Still Shows Warning

```bash
# Verify Root CA is installed on client machine
# Windows: certmgr.msc → Trusted Root Certification Authorities
# macOS: Keychain Access → System → Certificates
# Linux: ls /usr/local/share/ca-certificates/
```

---

## Security Best Practices

1. **Protect Private Keys**
   - Root CA key: Store offline, encrypted, in secure location
   - Intermediate CA key: Keep on secure server with strong passphrase
   - Server key: Protect with file permissions (400)

2. **Passphrase Management**
   - Use strong passphrases (20+ characters)
   - Store securely (password manager, vault)
   - Never commit to version control

3. **Certificate Lifecycle**
   - Set calendar reminders for renewal (30 days before expiry)
   - Monitor certificate expiration
   - Keep certificate inventory

4. **Backup**
   - Backup entire `/etc/pki/CA` directory
   - Store encrypted backup offline
   - Test restore procedure

---

## Cost Impact

**No additional cost** - Uses same infrastructure, just proper certificates.

---

## Summary

You now have a complete internal PKI with:
- ✅ Root CA certificate (10-year validity)
- ✅ Intermediate CA certificate (5-year validity)
- ✅ Server certificate with full chain (1-year validity)
- ✅ Jenkins configured for HTTPS
- ✅ No browser warnings after Root CA installation
- ✅ Professional certificate validation

**Next:** Install Root CA on all client machines and access Jenkins via HTTPS!

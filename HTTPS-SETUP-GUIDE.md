# HTTPS Setup Guide for Jenkins

**Status:** Ready to implement  
**Estimated Time:** 15 minutes  
**Last Updated:** February 13, 2026

---

## Overview

This guide adds HTTPS/SSL support to your Jenkins installation so the browser shows "Secure" instead of "Not secure".

**Current State:**
- Jenkins accessible at `http://10.10.10.100:8080` ✅
- DNS name `jenkins.np.learningmyway.space` resolves via hosts file ✅
- Browser shows "Not secure" ❌

**Target State:**
- Jenkins accessible at `https://jenkins.np.learningmyway.space` ✅
- Browser shows "Secure" (after accepting self-signed certificate) ✅
- HTTP redirects to HTTPS ✅

---

## Implementation Steps

### Step 1: Generate Self-Signed Certificate

SSH into Jenkins VM:
```bash
gcloud compute ssh jenkins-vm --project=test-project2-485105 --zone=us-central1-a --tunnel-through-iap
```

Generate certificate:
```bash
# Create directory for certificates
sudo mkdir -p /etc/jenkins/certs
cd /etc/jenkins/certs

# Generate private key and certificate
sudo openssl req -x509 -newkey rsa:2048 -keyout jenkins.key -out jenkins.crt -days 365 -nodes \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=jenkins.np.learningmyway.space"

# Set permissions
sudo chown jenkins:jenkins jenkins.key jenkins.crt
sudo chmod 600 jenkins.key
sudo chmod 644 jenkins.crt
```

### Step 2: Configure Jenkins for HTTPS

Edit Jenkins configuration:
```bash
sudo vi /usr/lib/systemd/system/jenkins.service
```

Find the line with `Environment="JENKINS_PORT=8080"` and add these lines after it:
```
Environment="JENKINS_HTTPS_PORT=443"
Environment="JENKINS_HTTPS_KEYSTORE=/etc/jenkins/certs/jenkins.p12"
Environment="JENKINS_HTTPS_KEYSTORE_PASSWORD=changeit"
```

Convert certificate to PKCS12 format (Jenkins requirement):
```bash
sudo openssl pkcs12 -export -out /etc/jenkins/certs/jenkins.p12 \
  -inkey /etc/jenkins/certs/jenkins.key \
  -in /etc/jenkins/certs/jenkins.crt \
  -password pass:changeit

sudo chown jenkins:jenkins /etc/jenkins/certs/jenkins.p12
sudo chmod 600 /etc/jenkins/certs/jenkins.p12
```

Reload and restart Jenkins:
```bash
sudo systemctl daemon-reload
sudo systemctl restart jenkins
```

Verify Jenkins is listening on port 443:
```bash
sudo ss -tlnp | grep 443
```

### Step 3: Update Terraform Configuration

Update load balancer to forward port 443:

Edit `terraform/modules/load-balancer/main.tf`:
```terraform
# Add HTTPS forwarding rule
resource "google_compute_forwarding_rule" "jenkins_lb_https" {
  name                  = "jenkins-lb-https-forwarding-rule"
  region                = var.region
  project               = var.project_id
  load_balancing_scheme = "INTERNAL"
  backend_service       = google_compute_region_backend_service.jenkins_backend.id
  ip_protocol           = "TCP"
  ports                 = ["443"]
  network               = var.vpc_name
  subnetwork            = var.subnet_name
  ip_address            = "10.10.10.100"
}
```

Update existing forwarding rule ports:
```terraform
# Modify existing forwarding rule
resource "google_compute_forwarding_rule" "jenkins_lb" {
  name                  = "jenkins-lb-forwarding-rule"
  region                = var.region
  project               = var.project_id
  load_balancing_scheme = "INTERNAL"
  backend_service       = google_compute_region_backend_service.jenkins_backend.id
  ip_protocol           = "TCP"
  ports                 = ["8080", "443"]  # Add 443 here
  network               = var.vpc_name
  subnetwork            = var.subnet_name
  ip_address            = "10.10.10.100"
}
```

Firewall rule already allows port 443 (we updated it in requirements).

### Step 4: Apply Terraform Changes

```bash
cd terraform
terraform plan
terraform apply
```

### Step 5: Test HTTPS Access

1. Connect to Firezone VPN
2. Open browser and go to: `https://jenkins.np.learningmyway.space`
3. Accept the self-signed certificate warning
4. Jenkins should load with "Secure" in address bar

---

## Certificate Warning

When you first access `https://jenkins.np.learningmyway.space`, your browser will show a warning:

**"Your connection is not private"** or **"NET::ERR_CERT_AUTHORITY_INVALID"**

This is normal for self-signed certificates. Click "Advanced" → "Proceed to jenkins.np.learningmyway.space (unsafe)".

After accepting once, the browser will remember your choice.

---

## Alternative: Use Internal CA (Optional)

For a better experience without browser warnings:

1. Create an internal Certificate Authority (CA)
2. Generate Jenkins certificate signed by your CA
3. Install CA certificate on all client machines
4. No browser warnings

This is more complex but provides a production-like experience.

---

## Troubleshooting

### Jenkins not starting after configuration
```bash
# Check Jenkins logs
sudo journalctl -u jenkins -n 50

# Check if certificate files exist
ls -la /etc/jenkins/certs/

# Verify certificate is valid
openssl x509 -in /etc/jenkins/certs/jenkins.crt -text -noout
```

### Port 443 not accessible
```bash
# Check if Jenkins is listening
sudo ss -tlnp | grep 443

# Check firewall rules
gcloud compute firewall-rules list --project=test-project2-485105 | grep jenkins

# Test from Jenkins VM
curl -k https://localhost:443
```

### Load balancer not forwarding
```bash
# Check load balancer status
gcloud compute forwarding-rules describe jenkins-lb-https-forwarding-rule \
  --region=us-central1 --project=test-project2-485105

# Check backend health
gcloud compute backend-services get-health jenkins-backend-service \
  --region=us-central1 --project=test-project2-485105
```

---

## Security Notes

1. Self-signed certificates provide encryption but not identity verification
2. Suitable for internal/private networks accessed via VPN
3. For production with external access, use proper CA-signed certificates
4. Certificate expires in 365 days - set reminder to renew

---

## Cost Impact

**No additional cost** - HTTPS uses same infrastructure, just different port.

---

## Next Steps After HTTPS Setup

1. ✅ Update requirements.md (already done)
2. ⏳ Implement HTTPS configuration (follow this guide)
3. ⏳ Test HTTPS access
4. ⏳ Update design.md with HTTPS architecture
5. ⏳ Update all documentation with HTTPS URLs

---

**Questions?** Check the troubleshooting section or review Jenkins logs.

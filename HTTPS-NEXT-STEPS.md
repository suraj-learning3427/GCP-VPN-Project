# HTTPS Implementation - Next Steps

**Status:** PKI Complete ✅ | HTTPS Pending ⏳  
**Date:** February 13, 2026

---

## What's Done

✅ Complete PKI certificate chain created  
✅ Root CA certificate downloaded to your machine  
✅ All certificates verified and working  
✅ Jenkins running on HTTP port 8080  
✅ VPN access working  
✅ DNS resolution configured

---

## What's Next - Choose Your Path

### Path A: Quick Win - Use HTTP with VPN (5 minutes)

**Best for:** Testing, development, getting started quickly

**Steps:**
1. Install Root CA on Windows (for future HTTPS)
2. Add hosts file entry
3. Access Jenkins via HTTP

**Security:** Traffic encrypted by VPN, no public exposure

**Commands:**
```powershell
# 1. Install Root CA (Run PowerShell as Administrator)
Import-Certificate -FilePath "LearningMyWay-Root-CA.crt" -CertStoreLocation Cert:\LocalMachine\Root

# 2. Add to hosts file
Add-Content C:\Windows\System32\drivers\etc\hosts "10.10.10.100 jenkins.np.learningmyway.space"

# 3. Connect to VPN and access
# http://jenkins.np.learningmyway.space:8080
```

---

### Path B: Full HTTPS with Nginx (30 minutes)

**Best for:** Production use, compliance, professional setup

**Challenge:** Jenkins VM is air-gapped, needs temporary internet for nginx installation

**Solution:** Temporarily add public IP, install nginx, remove public IP

**Steps:**

#### Step 1: Add Temporary Public IP (5 min)

```bash
# Add public IP to Jenkins VM
gcloud compute instances add-access-config jenkins-vm \
  --project=test-project2-485105 \
  --zone=us-central1-a

# Add temporary egress firewall rule
gcloud compute firewall-rules create temp-jenkins-egress \
  --project=test-project2-485105 \
  --network=core-it-vpc \
  --action=ALLOW \
  --rules=all \
  --direction=EGRESS \
  --target-tags=jenkins-server \
  --priority=1000
```

#### Step 2: Install and Configure Nginx (10 min)

```bash
# SSH into Jenkins VM
gcloud compute ssh jenkins-vm \
  --project=test-project2-485105 \
  --zone=us-central1-a \
  --tunnel-through-iap

# Install nginx
sudo dnf install -y nginx

# Create nginx configuration
sudo tee /etc/nginx/conf.d/jenkins.conf > /dev/null << 'EOF'
upstream jenkins {
    server 127.0.0.1:8080 fail_timeout=0;
}

server {
    listen 443 ssl http2;
    server_name jenkins.np.learningmyway.space;

    ssl_certificate /etc/jenkins/certs/jenkins-chain.cert.pem;
    ssl_certificate_key /etc/jenkins/certs/jenkins.key.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    location / {
        proxy_pass http://jenkins;
        proxy_redirect http:// https://;
        proxy_set_header Host $host:$server_port;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-Port 443;
    }
}
EOF

# Enable SELinux permission
sudo setsebool -P httpd_can_network_connect 1

# Start nginx
sudo systemctl enable nginx
sudo systemctl start nginx

# Verify
sudo systemctl status nginx
sudo ss -tlnp | grep 443
```

#### Step 3: Remove Public IP (5 min)

```bash
# Exit SSH session
exit

# Remove public IP
gcloud compute instances delete-access-config jenkins-vm \
  --project=test-project2-485105 \
  --zone=us-central1-a

# Remove egress firewall rule
gcloud compute firewall-rules delete temp-jenkins-egress \
  --project=test-project2-485105 \
  --quiet
```

#### Step 4: Update Terraform (5 min)

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

#### Step 5: Test HTTPS (5 min)

```bash
# Connect to VPN
# Open browser: https://jenkins.np.learningmyway.space
# Should show "Secure" with no warnings!
```

---

### Path C: Internal HTTPS Load Balancer (60 minutes)

**Best for:** Enterprise setup, GCP-managed SSL, high availability

**Cost:** +$18/month for HTTPS load balancer

**Complexity:** High - requires significant Terraform changes

**Not recommended** unless you need GCP-managed SSL termination

---

## Recommended Approach

### For Testing/Development
→ **Path A** (HTTP with VPN)
- Quickest to get started
- VPN provides encryption
- Can add HTTPS later

### For Production
→ **Path B** (Nginx HTTPS)
- Professional setup
- No additional cost
- Industry standard
- Takes 30 minutes

---

## Installation Guide: Root CA on Windows

**Why install Root CA?**
- Eliminates browser warnings
- Enables certificate validation
- Required for HTTPS to show "Secure"

**Steps:**

### Method 1: PowerShell (Recommended)

```powershell
# Run PowerShell as Administrator
Import-Certificate -FilePath "LearningMyWay-Root-CA.crt" -CertStoreLocation Cert:\LocalMachine\Root
```

### Method 2: GUI

1. Double-click `LearningMyWay-Root-CA.crt`
2. Click "Install Certificate"
3. Select "Local Machine"
4. Choose "Place all certificates in the following store"
5. Click "Browse" → Select "Trusted Root Certification Authorities"
6. Click "Next" → "Finish"
7. Accept security warning

### Verify Installation

```powershell
# Check if installed
Get-ChildItem -Path Cert:\LocalMachine\Root | Where-Object {$_.Subject -like "*LearningMyWay*"}
```

---

## Hosts File Configuration

**Location:** `C:\Windows\System32\drivers\etc\hosts`

**Add this line:**
```
10.10.10.100 jenkins.np.learningmyway.space
```

**PowerShell command:**
```powershell
# Run as Administrator
Add-Content C:\Windows\System32\drivers\etc\hosts "`n10.10.10.100 jenkins.np.learningmyway.space"
```

---

## Testing Checklist

### HTTP Access (Current)

- [ ] Connect to Firezone VPN
- [ ] Open browser
- [ ] Go to: `http://10.10.10.100:8080`
- [ ] Jenkins login page loads
- [ ] Can login with admin credentials

### HTTPS Access (After nginx setup)

- [ ] Root CA installed on Windows
- [ ] Hosts file configured
- [ ] Connect to Firezone VPN
- [ ] Open browser
- [ ] Go to: `https://jenkins.np.learningmyway.space`
- [ ] No certificate warnings
- [ ] Browser shows "Secure" 🔒
- [ ] Jenkins login page loads
- [ ] Can login with admin credentials

---

## Troubleshooting

### "Site can't be reached"
- Check VPN connection
- Verify hosts file entry
- Ping 10.10.10.100

### "Certificate error" (with HTTPS)
- Verify Root CA is installed
- Check certificate store
- Restart browser

### "Not secure" warning
- Root CA not installed correctly
- Install in "Trusted Root Certification Authorities"
- Not "Personal" or other stores

---

## Security Notes

### Current Setup (HTTP + VPN)
- Traffic encrypted by WireGuard VPN
- No public internet exposure
- Acceptable for internal use
- Browser shows "Not secure" (cosmetic only)

### With HTTPS (HTTP + VPN + TLS)
- Double encryption (VPN + TLS)
- Certificate validation
- Browser shows "Secure"
- Defense in depth

### Risk Assessment
- **Without HTTPS:** LOW risk (VPN encryption)
- **With HTTPS:** VERY LOW risk (VPN + TLS)

---

## Cost Summary

| Configuration | Monthly Cost | Change |
|---------------|--------------|--------|
| Current (HTTP) | $58.87 | Baseline |
| + Nginx HTTPS | $58.87 | $0 |
| + Internal HTTPS LB | $76.87 | +$18 |

**Recommendation:** Use Nginx (Path B) - no additional cost!

---

## Timeline

### Today (5 minutes)
1. Install Root CA on Windows
2. Add hosts file entry
3. Test HTTP access

### This Week (30 minutes)
4. Implement nginx HTTPS (Path B)
5. Test HTTPS access
6. Update documentation

### Next Month
7. Set calendar reminder for certificate renewal (Jan 2027)
8. Document any issues or improvements

---

## Files Reference

- **Root CA:** `./LearningMyWay-Root-CA.crt`
- **PKI Guide:** `PKI-CERTIFICATE-CHAIN-GUIDE.md`
- **Quick Start:** `PKI-QUICK-START.md`
- **Architecture:** `PKI-ARCHITECTURE-DIAGRAM.md`
- **Status:** `PKI-IMPLEMENTATION-STATUS.md`
- **Requirements:** `.kiro/specs/vpn-jenkins-infrastructure/requirements.md`

---

## Decision Time

**Which path do you want to take?**

1. **Path A** - Quick HTTP access (5 min) → Start testing now
2. **Path B** - Full HTTPS with nginx (30 min) → Production-ready
3. **Path C** - Internal HTTPS LB (60 min) → Enterprise setup

**My recommendation:** Start with Path A today, implement Path B this week.

---

## Ready to Proceed?

Let me know which path you choose, and I'll guide you through it step by step!

**Current status:**
- ✅ PKI infrastructure complete
- ✅ Certificates created and verified
- ✅ Root CA downloaded
- ⏳ Waiting for your decision on HTTPS implementation

**Next command:** Install Root CA on Windows (see above)

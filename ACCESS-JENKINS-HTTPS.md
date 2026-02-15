# Access Jenkins with HTTPS - Final Steps

**Status:** ✅ HTTPS Configured and Ready!  
**Date:** February 13, 2026

---

## ✅ What's Done

1. ✅ Complete PKI certificate chain created
2. ✅ Nginx installed and configured for HTTPS
3. ✅ Nginx listening on port 443
4. ✅ Jenkins VM air-gapped again (public IP removed)
5. ✅ Load balancer forwarding ports 8080 and 443
6. ✅ All firewall rules configured
7. ✅ Root CA certificate downloaded

---

## 🚀 Access Jenkins with HTTPS (3 Steps)

### Step 1: Install Root CA on Windows (2 minutes)

**Open PowerShell as Administrator** and run:

```powershell
# Install Root CA certificate
Import-Certificate -FilePath "LearningMyWay-Root-CA.crt" -CertStoreLocation Cert:\LocalMachine\Root
```

**Expected output:**
```
   PSParentPath: Microsoft.PowerShell.Security\Certificate::LocalMachine\Root

Thumbprint                                Subject
----------                                -------
...                                       CN=LearningMyWay Root CA, ...
```

---

### Step 2: Add Hosts File Entry (1 minute)

**In the same PowerShell (as Administrator):**

```powershell
# Add DNS entry to hosts file
Add-Content C:\Windows\System32\drivers\etc\hosts "`n10.10.10.100 jenkins.np.learningmyway.space"
```

**Verify it was added:**

```powershell
Get-Content C:\Windows\System32\drivers\etc\hosts | Select-String "jenkins"
```

---

### Step 3: Access Jenkins via HTTPS (30 seconds)

1. **Connect to Firezone VPN** (if not already connected)

2. **Open your browser** (Chrome, Edge, Firefox)

3. **Go to:** `https://jenkins.np.learningmyway.space`

4. **You should see:**
   - ✅ Browser shows "Secure" 🔒
   - ✅ No certificate warnings
   - ✅ Jenkins login page loads

5. **Login with your admin credentials**

---

## 🎉 Success Indicators

When everything is working correctly, you'll see:

### In Browser Address Bar:
```
🔒 Secure | https://jenkins.np.learningmyway.space
```

### Certificate Details (Click the padlock):
```
Certificate (Valid)
Issued to: jenkins.np.learningmyway.space
Issued by: LearningMyWay Intermediate CA
Valid from: Feb 13, 2026
Valid until: Feb 13, 2027
```

### Certificate Chain:
```
jenkins.np.learningmyway.space
  └── LearningMyWay Intermediate CA
        └── LearningMyWay Root CA (Trusted)
```

---

## 🔍 Troubleshooting

### Issue: "Site can't be reached"

**Check VPN:**
```powershell
# Test connectivity
ping 10.10.10.100
```

**Expected:** Replies from 10.10.10.100

**If fails:** Reconnect to Firezone VPN

---

### Issue: Certificate warning "Not secure"

**Cause:** Root CA not installed correctly

**Fix:**
1. Open `certmgr.msc` (Windows Certificate Manager)
2. Go to: Trusted Root Certification Authorities → Certificates
3. Look for "LearningMyWay Root CA"
4. If not there, reinstall using Step 1

---

### Issue: "DNS_PROBE_FINISHED_NXDOMAIN"

**Cause:** Hosts file entry missing

**Fix:**
```powershell
# Check hosts file
Get-Content C:\Windows\System32\drivers\etc\hosts

# Should contain:
# 10.10.10.100 jenkins.np.learningmyway.space

# If missing, add it:
Add-Content C:\Windows\System32\drivers\etc\hosts "`n10.10.10.100 jenkins.np.learningmyway.space"
```

---

### Issue: Certificate shows "Issued by: Unknown"

**Cause:** Certificate chain not complete

**This shouldn't happen** - nginx is configured with full chain

**Verify on Jenkins VM:**
```bash
gcloud compute ssh jenkins-vm --project=test-project2-485105 --zone=us-central1-a --tunnel-through-iap

# Check certificate chain
sudo openssl s_client -connect localhost:443 -showcerts
```

---

## 📊 What You Have Now

### Security Layers (5 Total)

1. **Network Isolation** ✅
   - No public IP on Jenkins
   - Air-gapped environment

2. **VPN Authentication** ✅
   - Firezone WireGuard VPN
   - User authentication required

3. **Firewall Protection** ✅
   - Strict access control
   - Only VPN subnet allowed

4. **VPN Encryption** ✅
   - WireGuard protocol
   - All traffic encrypted

5. **TLS Encryption** ✅ NEW!
   - HTTPS with certificate validation
   - Full PKI certificate chain
   - Browser shows "Secure"

---

## 🎯 Access Methods

### HTTPS (Recommended) - Port 443
```
https://jenkins.np.learningmyway.space
```
- ✅ Secure connection
- ✅ Certificate validated
- ✅ Browser shows padlock
- ✅ Professional setup

### HTTP (Still works) - Port 8080
```
http://10.10.10.100:8080
http://jenkins.np.learningmyway.space:8080
```
- ✅ Works but shows "Not secure"
- ⚠️ Use HTTPS instead

---

## 💰 Cost Impact

**No change!** Still $58.87/month

HTTPS via nginx adds zero additional cost.

---

## 📅 Certificate Renewal

### Important Dates

| Certificate | Expires | Action Required |
|-------------|---------|-----------------|
| Server | Feb 13, 2027 | Renew in Jan 2027 |
| Intermediate CA | Feb 12, 2031 | Renew in Jan 2031 |
| Root CA | Feb 13, 2036 | Renew in Jan 2036 |

**Set calendar reminders now!**

---

## 🔐 Security Status

**Before HTTPS:**
- Risk Level: LOW (VPN encryption)
- Browser: "Not secure"
- Encryption: VPN only

**After HTTPS:**
- Risk Level: VERY LOW (VPN + TLS)
- Browser: "Secure" 🔒
- Encryption: VPN + TLS (double encryption)

---

## ✅ Final Checklist

- [ ] Root CA installed on Windows
- [ ] Hosts file entry added
- [ ] Connected to Firezone VPN
- [ ] Accessed https://jenkins.np.learningmyway.space
- [ ] Browser shows "Secure" 🔒
- [ ] No certificate warnings
- [ ] Jenkins login page loads
- [ ] Successfully logged in

---

## 🎊 Congratulations!

You now have a **production-ready, enterprise-grade, secure Jenkins infrastructure** with:

✅ Complete PKI certificate chain  
✅ HTTPS with certificate validation  
✅ Air-gapped environment  
✅ VPN-only access  
✅ 5-layer security architecture  
✅ Zero internet exposure  
✅ Professional certificate management  
✅ Cost-optimized ($58.87/month)

**Your Jenkins is now accessible at:**
```
https://jenkins.np.learningmyway.space 🔒
```

---

## 📚 Documentation Reference

- **PKI Guide:** `PKI-CERTIFICATE-CHAIN-GUIDE.md`
- **Quick Start:** `PKI-QUICK-START.md`
- **Architecture:** `PKI-ARCHITECTURE-DIAGRAM.md`
- **Status:** `CURRENT-STATUS.md`
- **Summary:** `SESSION-SUMMARY.md`

---

**Need help?** All documentation is in your project folder!

**Enjoy your secure Jenkins! 🚀**

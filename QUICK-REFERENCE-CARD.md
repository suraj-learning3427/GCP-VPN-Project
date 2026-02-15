# Quick Reference Card - PKI & HTTPS

**Date:** February 13, 2026  
**Status:** PKI Complete ✅ | HTTPS Pending ⏳

---

## 🎯 What's Done

✅ Complete PKI certificate chain (Root → Intermediate → Server)  
✅ All certificates verified and working  
✅ Root CA downloaded: `LearningMyWay-Root-CA.crt`  
✅ Jenkins running on HTTP port 8080  
✅ Comprehensive documentation created

---

## 🚀 Quick Start (5 Minutes)

### 1. Install Root CA on Windows

```powershell
# Run PowerShell as Administrator
Import-Certificate -FilePath "LearningMyWay-Root-CA.crt" -CertStoreLocation Cert:\LocalMachine\Root
```

### 2. Add Hosts File Entry

```powershell
# Run PowerShell as Administrator
Add-Content C:\Windows\System32\drivers\etc\hosts "`n10.10.10.100 jenkins.np.learningmyway.space"
```

### 3. Access Jenkins

1. Connect to Firezone VPN
2. Open browser
3. Go to: `http://jenkins.np.learningmyway.space:8080`
4. Login with admin credentials

---

## 📋 Certificate Information

| Certificate | Validity | Expires | Location |
|-------------|----------|---------|----------|
| Root CA | 10 years | Feb 13, 2036 | `/etc/pki/CA/certs/ca.cert.pem` |
| Intermediate CA | 5 years | Feb 12, 2031 | `/etc/pki/CA/intermediate/certs/intermediate.cert.pem` |
| Server | 1 year | Feb 13, 2027 | `/etc/jenkins/certs/jenkins.cert.pem` |

---

## 🔐 Passphrases (SAVE SECURELY!)

```
Root CA: RootCA@LearningMyWay2026!
Intermediate CA: IntermediateCA@LearningMyWay2026!
PKCS12: changeit
```

---

## 📅 Renewal Reminders

- **Jan 2027** - Renew server certificate
- **Jan 2031** - Renew intermediate CA
- **Jan 2036** - Renew root CA

---

## 🛠️ HTTPS Implementation Options

### Option 1: HTTP with VPN (Current) ⚡
- **Time:** 5 minutes
- **Cost:** $0
- **Security:** VPN encryption
- **Status:** Working now

### Option 2: Nginx HTTPS (Recommended) 🎯
- **Time:** 30 minutes
- **Cost:** $0
- **Security:** VPN + TLS
- **Guide:** `HTTPS-NEXT-STEPS.md` → Path B

### Option 3: Internal HTTPS LB 💰
- **Time:** 60 minutes
- **Cost:** +$18/month
- **Security:** VPN + TLS
- **Recommendation:** Not recommended

---

## 📚 Documentation Files

| File | Purpose |
|------|---------|
| `PKI-CERTIFICATE-CHAIN-GUIDE.md` | Detailed implementation guide |
| `PKI-QUICK-START.md` | Quick reference |
| `PKI-ARCHITECTURE-DIAGRAM.md` | Visual diagrams |
| `HTTPS-NEXT-STEPS.md` | Action plan |
| `PKI-IMPLEMENTATION-STATUS.md` | Current status |
| `SESSION-SUMMARY.md` | Complete session overview |

---

## 🔍 Verification Commands

### Check Certificates

```bash
# SSH into Jenkins VM
gcloud compute ssh jenkins-vm --project=test-project2-485105 --zone=us-central1-a --tunnel-through-iap

# Verify Root CA
sudo openssl x509 -noout -text -in /etc/pki/CA/certs/ca.cert.pem

# Verify certificate chain
sudo openssl verify -CAfile /etc/pki/CA/certs/ca.cert.pem \
  -untrusted /etc/pki/CA/intermediate/certs/intermediate.cert.pem \
  /etc/jenkins/certs/jenkins.cert.pem
```

### Check Jenkins Status

```bash
# Check if Jenkins is running
sudo systemctl status jenkins

# Check ports
sudo ss -tlnp | grep -E '(8080|443)'
```

---

## 🐛 Troubleshooting

### Can't Access Jenkins
- ✓ Check VPN connection
- ✓ Verify hosts file entry
- ✓ Ping 10.10.10.100

### Certificate Warnings (HTTPS)
- ✓ Install Root CA in "Trusted Root Certification Authorities"
- ✓ Restart browser
- ✓ Clear browser cache

### Jenkins Not Starting
- ✓ Check logs: `sudo journalctl -u jenkins -n 50`
- ✓ Verify disk space: `df -h`
- ✓ Check permissions: `ls -la /etc/jenkins/certs/`

---

## 💰 Cost Summary

| Item | Monthly Cost |
|------|--------------|
| Current Infrastructure | $58.87 |
| + Nginx HTTPS | $0 |
| + Internal HTTPS LB | +$18 |

**Total with Nginx:** $58.87/month (no change)

---

## 🎯 Recommended Next Steps

1. **Today (5 min):** Install Root CA, test HTTP access
2. **This Week (30 min):** Implement nginx HTTPS
3. **Next Month:** Set renewal reminders

---

## 📞 Quick Commands

### Access Jenkins VM

```bash
gcloud compute ssh jenkins-vm \
  --project=test-project2-485105 \
  --zone=us-central1-a \
  --tunnel-through-iap
```

### Download Root CA

```bash
gcloud compute scp jenkins-vm:/tmp/LearningMyWay-Root-CA.crt . \
  --project=test-project2-485105 \
  --zone=us-central1-a \
  --tunnel-through-iap
```

### Check Certificate Expiry

```bash
# On Jenkins VM
sudo openssl x509 -noout -dates -in /etc/jenkins/certs/jenkins.cert.pem
```

---

## ✅ Success Checklist

### Completed
- [x] PKI infrastructure created
- [x] All certificates verified
- [x] Root CA downloaded
- [x] Documentation complete

### Pending
- [ ] Root CA installed on Windows
- [ ] Hosts file configured
- [ ] HTTP access tested
- [ ] HTTPS implementation chosen
- [ ] HTTPS configured and tested
- [ ] Renewal reminders set

---

## 🔗 Access URLs

**Current (HTTP):**
- `http://10.10.10.100:8080`
- `http://jenkins.np.learningmyway.space:8080`

**Future (HTTPS):**
- `https://jenkins.np.learningmyway.space`

---

## 📊 Security Status

**Current:** LOW risk (VPN encryption)  
**With HTTPS:** VERY LOW risk (VPN + TLS)

**Layers:**
1. Network isolation (no public IP)
2. VPN authentication (Firezone)
3. Firewall rules (strict access control)
4. VPN encryption (WireGuard)
5. TLS encryption (after HTTPS setup)

---

**Need Help?** See `HTTPS-NEXT-STEPS.md` for detailed instructions!

# Install Root CA and Access Jenkins - Simple Instructions

**Follow these steps exactly:**

---

## Step 1: Open PowerShell as Administrator

1. Press `Windows Key`
2. Type: `PowerShell`
3. **Right-click** on "Windows PowerShell"
4. Click **"Run as administrator"**
5. Click **"Yes"** when prompted

---

## Step 2: Install Root CA Certificate

In the Administrator PowerShell window, run:

```powershell
cd C:\Testing
.\install-root-ca.ps1
```

**Expected output:**
```
SUCCESS! Root CA certificate installed.

Certificate Details:
  Subject: CN=LearningMyWay Root CA, ...
  Thumbprint: ...
  Valid Until: ...
```

---

## Step 3: Add Hosts File Entry

In the same PowerShell window, run:

```powershell
.\add-hosts-entry.ps1
```

**Expected output:**
```
SUCCESS! Hosts file entry added.

Entry added:
  10.10.10.100 jenkins.np.learningmyway.space
```

---

## Step 4: Access Jenkins

1. **Connect to Firezone VPN** (if not already connected)

2. **Open your browser** (Chrome, Edge, or Firefox)

3. **Go to:** `https://jenkins.np.learningmyway.space`

4. **You should see:**
   - ✅ Browser shows **"Secure"** 🔒
   - ✅ **No certificate warnings**
   - ✅ Jenkins login page loads

---

## Troubleshooting

### If you see "Access is denied"
- You didn't run PowerShell as Administrator
- Close PowerShell and start over from Step 1

### If you see "Certificate file not found"
- Make sure you're in `C:\Testing` directory
- Run: `cd C:\Testing`
- Check file exists: `dir LearningMyWay-Root-CA.crt`

### If you see "Site can't be reached"
- Check VPN connection
- Make sure you're connected to Firezone VPN
- Try: `ping 10.10.10.100`

### If you still see certificate warning
- Root CA not installed correctly
- Run `certmgr.msc` and check "Trusted Root Certification Authorities"
- Look for "LearningMyWay Root CA"

---

## Quick Commands (Copy-Paste)

**All in one (run as Administrator):**

```powershell
cd C:\Testing
.\install-root-ca.ps1
.\add-hosts-entry.ps1
```

Then open browser: `https://jenkins.np.learningmyway.space`

---

## Verification

**Check if Root CA is installed:**
```powershell
Get-ChildItem -Path Cert:\LocalMachine\Root | Where-Object {$_.Subject -like "*LearningMyWay*"}
```

**Check if hosts entry exists:**
```powershell
Get-Content C:\Windows\System32\drivers\etc\hosts | Select-String "jenkins"
```

**Test connectivity:**
```powershell
ping 10.10.10.100
```

---

**Need help?** See `ACCESS-JENKINS-HTTPS.md` for detailed troubleshooting.

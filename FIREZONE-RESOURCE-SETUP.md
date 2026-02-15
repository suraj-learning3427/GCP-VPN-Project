# Firezone Resource Configuration - Allow Access to Jenkins

**Issue:** VPN is connected but cannot reach Jenkins (10.10.10.100)  
**Cause:** Firezone Resource not configured for Jenkins subnet  
**Solution:** Add Jenkins as a Resource in Firezone

---

## Step 1: Login to Firezone Admin Portal

1. Open browser
2. Go to: `https://app.firezone.dev` (or your Firezone URL)
3. Login with your Firezone admin credentials

---

## Step 2: Navigate to Resources

1. Click on **"Resources"** in the left sidebar
2. Click **"Add Resource"** button

---

## Step 3: Create Jenkins Resource

Fill in the following details:

**Resource Name:**
```
Jenkins Infrastructure
```

**Description:**
```
Jenkins CI/CD server and load balancer
```

**Address:**
```
10.10.10.0/24
```

**Or if you want to be more specific:**
```
10.10.10.100/32
```

**Gateway:** Select your gateway (should be the one you deployed)

---

## Step 4: Assign Resource to Users/Groups

1. After creating the resource, click on it
2. Go to **"Access"** or **"Policies"** tab
3. Add your user or group
4. Click **"Save"**

---

## Step 5: Reconnect VPN

1. **Disconnect** from Firezone VPN
2. **Reconnect** to Firezone VPN
3. Wait 10 seconds for routes to update

---

## Step 6: Test Connectivity

Open PowerShell and test:

```powershell
# Test ping
ping 10.10.10.100

# Test HTTPS port
Test-NetConnection -ComputerName 10.10.10.100 -Port 443
```

**Expected output:**
```
TcpTestSucceeded : True
```

---

## Step 7: Access Jenkins

Once connectivity works, open browser:

**Option 1 - Domain name:**
```
https://jenkins.np.learningmyway.space
```

**Option 2 - IP address:**
```
https://10.10.10.100
```

Both should work now!

---

## Troubleshooting

### Still can't connect after adding resource?

1. **Check Gateway Status**
   - In Firezone portal, check if gateway is "Online"
   - Gateway should show as "Connected"

2. **Check Resource Assignment**
   - Make sure resource is assigned to your user
   - Check if there are any policy restrictions

3. **Reconnect VPN**
   - Disconnect and reconnect VPN
   - Sometimes routes don't update immediately

4. **Check VPN Routes**
   ```powershell
   Get-NetRoute | Where-Object {$_.DestinationPrefix -like "10.10.10.*"}
   ```
   Should show route via Firezone interface

5. **Check Firewall**
   - Make sure Windows Firewall isn't blocking
   - Check if antivirus is interfering

---

## Alternative: Add Route Manually (Temporary)

If Firezone resource doesn't work immediately, you can add route manually:

```powershell
# Run as Administrator
route add 10.10.10.0 mask 255.255.255.0 100.96.0.1 metric 1
```

**Note:** Replace `100.96.0.1` with your Firezone gateway IP (check with `ipconfig`)

---

## Why This Is Needed?

Firezone uses **resource-based access control**. This means:

1. VPN connection alone doesn't give access to everything
2. You must explicitly define which resources (IP ranges) users can access
3. This provides better security and access control
4. Each resource can have different access policies

---

## Current Status

- ✅ VPN connected
- ✅ Nginx configured for HTTPS
- ✅ Load balancer configured
- ✅ Certificates installed
- ❌ Firezone resource not configured (THIS IS THE ISSUE)

Once you add the Firezone resource, everything will work!

---

**Next:** Configure the resource in Firezone portal, then test access.

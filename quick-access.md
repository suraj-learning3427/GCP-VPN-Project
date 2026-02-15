# Quick Access Guide

!!! tip "Setup Time: 5 Minutes"
    Follow these steps to access your Jenkins infrastructure via HTTPS.

## Prerequisites

- [x] Infrastructure deployed
- [x] VPN client installed
- [x] Root CA certificate downloaded

## Step 1: Install Root CA Certificate

=== "Windows"

    Open PowerShell as Administrator:

    ```powershell
    # Install Root CA certificate
    Import-Certificate -FilePath "LearningMyWay-Root-CA.crt" `
        -CertStoreLocation Cert:\LocalMachine\Root
    ```

    **Expected output:**
    ```
    PSParentPath: Microsoft.PowerShell.Security\Certificate::LocalMachine\Root
    
    Thumbprint                                Subject
    ----------                                -------
    ...                                       CN=LearningMyWay Root CA, ...
    ```

=== "macOS"

    ```bash
    # Add to system keychain
    sudo security add-trusted-cert -d -r trustRoot \
        -k /Library/Keychains/System.keychain \
        LearningMyWay-Root-CA.crt
    ```

=== "Linux"

    ```bash
    # Copy to CA certificates directory
    sudo cp LearningMyWay-Root-CA.crt /usr/local/share/ca-certificates/
    
    # Update CA certificates
    sudo update-ca-certificates
    ```

## Step 2: Add Hosts File Entry

=== "Windows"

    Open PowerShell as Administrator:

    ```powershell
    # Add DNS entry to hosts file
    Add-Content C:\Windows\System32\drivers\etc\hosts `
        "`n10.10.10.100 jenkins.np.learningmyway.space"
    
    # Verify entry
    Get-Content C:\Windows\System32\drivers\etc\hosts | Select-String "jenkins"
    ```

=== "macOS/Linux"

    ```bash
    # Edit hosts file
    sudo nano /etc/hosts
    
    # Add this line:
    10.10.10.100 jenkins.np.learningmyway.space
    
    # Save and exit (Ctrl+X, Y, Enter)
    ```

## Step 3: Configure Firezone Resource

!!! warning "Critical Step"
    Firezone uses resource-based access control. You must configure access to the Jenkins subnet.

1. Login to [Firezone Portal](https://app.firezone.dev)
2. Navigate to **Resources** → **Add Resource**
3. Fill in details:
    - **Name:** Jenkins Infrastructure
    - **Address:** `10.10.10.0/24` or `10.10.10.100/32`
    - **Gateway:** Select your deployed gateway
4. Assign to your user/group
5. **Reconnect VPN** (important!)

## Step 4: Test Connectivity

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

## Step 5: Access Jenkins

1. **Connect to Firezone VPN**
2. **Open browser**
3. **Navigate to:** `https://jenkins.np.learningmyway.space`
4. **Verify:** Browser shows "Secure" 🔒 with no warnings

!!! success "Success!"
    You should now see the Jenkins login page with a secure connection.

## Troubleshooting

### Can't reach Jenkins

??? question "VPN not connected?"
    - Check Firezone client is connected
    - Verify VPN status indicator is green
    - Try disconnecting and reconnecting

??? question "Firezone resource not configured?"
    - Login to Firezone portal
    - Check Resources section
    - Verify Jenkins subnet is added
    - Confirm resource is assigned to your user

### Certificate warnings

??? question "Browser shows 'Not secure'?"
    - Verify Root CA is installed in **Trusted Root Certification Authorities**
    - Check certificate store: `certmgr.msc` (Windows)
    - Restart browser after installing certificate
    - Clear browser cache

### DNS not resolving

??? question "Can't resolve jenkins.np.learningmyway.space?"
    - Verify hosts file entry exists
    - Check for typos in hosts file
    - Flush DNS cache: `ipconfig /flushdns` (Windows)
    - Try using IP directly: `https://10.10.10.100`

## Next Steps

- [Configure Jenkins](https://www.jenkins.io/doc/book/installing/)
- [Set up Jenkins users](https://www.jenkins.io/doc/book/security/)
- [Install Jenkins plugins](https://www.jenkins.io/doc/book/managing/plugins/)
- [Review security settings](diagrams/05-SECURITY-LAYERS.md)

## Quick Commands Reference

```powershell
# Check VPN connection
Get-NetAdapter | Where-Object {$_.InterfaceDescription -like "*Firezone*"}

# Test connectivity
Test-NetConnection -ComputerName 10.10.10.100 -Port 443

# View certificate
certutil -store Root "LearningMyWay Root CA"

# Check hosts file
Get-Content C:\Windows\System32\drivers\etc\hosts | Select-String "jenkins"
```

---

!!! info "Need More Help?"
    - [Detailed HTTPS Setup](ACCESS-JENKINS-HTTPS.md)
    - [Firezone Configuration](FIREZONE-RESOURCE-SETUP.md)
    - [Troubleshooting Guide](troubleshooting.md)

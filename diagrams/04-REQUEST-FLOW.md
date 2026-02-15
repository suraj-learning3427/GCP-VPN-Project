# Complete Request Flow - End to End

## User Request to Jenkins Response

```
[1] User's Browser
    │ User types: https://jenkins.np.learningmyway.space
    │ Browser checks: Hosts file
    │ Resolves to: 10.10.10.100
    ▼

[2] VPN Tunnel (WireGuard)
    │ Source: 100.64.0.1 (VPN client IP)
    │ Destination: 10.10.10.100:443
    │ Encryption: WireGuard (ChaCha20-Poly1305)
    │ Route: Via Firezone gateway (20.20.20.x)
    ▼

[3] Firezone VPN Gateway (Project 1)
    │ VM: firezone-gateway
    │ Receives: Encrypted VPN packet
    │ Decrypts: WireGuard tunnel
    │ Checks: Firezone resource policy
    │ Allows: 10.10.10.0/24 access
    │ Forwards: To 10.10.10.100 via VPC peering
    ▼

[4] VPC Peering
    │ From: networkingglobal-vpc (20.20.20.0/16)
    │ To: core-it-vpc (10.10.10.0/16)
    │ Route: Bidirectional peering
    │ Firewall: allow-vpn-to-jenkins (20.20.20.0/24 → 10.10.10.0/24)
    ▼

[5] Internal Load Balancer
    │ IP: 10.10.10.100
    │ Port: 443
    │ Type: Internal TCP LB
    │ Health Check: ✅ Backend healthy
    │ Forwards to: jenkins-vm (10.10.10.10:443)
    ▼

[6] Jenkins VM - Nginx (SSL Termination)
    │ VM: jenkins-vm (10.10.10.10)
    │ Service: Nginx
    │ Port: 443 (HTTPS)
    │
    │ [6a] TLS Handshake
    │      ├─ Presents certificate chain
    │      ├─ Client validates certificates
    │      ├─ Establishes session keys
    │      └─ ✅ Secure connection established
    │
    │ [6b] Decrypt HTTPS Request
    │      ├─ Uses: /etc/jenkins/certs/jenkins.key.pem
    │      ├─ Decrypts: TLS encrypted data
    │      └─ Extracts: HTTP request
    │
    │ [6c] Proxy to Jenkins
    │      ├─ Proxy Pass: http://127.0.0.1:8080
    │      ├─ Add Headers: X-Forwarded-For, X-Forwarded-Proto
    │      └─ Forward: HTTP request to Jenkins
    ▼

[7] Jenkins Application
    │ Service: Jenkins
    │ Port: 8080 (HTTP, localhost only)
    │ Receives: HTTP request from Nginx
    │
    │ [7a] Process Request
    │      ├─ Parse: HTTP headers
    │      ├─ Authenticate: User session
    │      ├─ Authorize: User permissions
    │      └─ Execute: Application logic
    │
    │ [7b] Generate Response
    │      ├─ Render: HTML page
    │      ├─ Add: HTTP headers
    │      └─ Return: HTTP response
    ▼

[8] Response Path (Reverse)
    │
    │ [8a] Jenkins → Nginx
    │      └─ HTTP response on localhost:8080
    │
    │ [8b] Nginx → Client
    │      ├─ Encrypt: Response with TLS
    │      ├─ Add: Security headers (HSTS, etc.)
    │      └─ Send: HTTPS response
    │
    │ [8c] Load Balancer → VPN Gateway
    │      └─ Forward: Encrypted response
    │
    │ [8d] VPN Gateway → Client
    │      ├─ Encrypt: With WireGuard
    │      └─ Send: Through VPN tunnel
    │
    │ [8e] Client Browser
    │      ├─ Decrypt: WireGuard tunnel
    │      ├─ Decrypt: TLS layer
    │      ├─ Render: HTML page
    │      └─ Display: 🔒 Secure
    ▼

[9] User sees Jenkins Dashboard
    ✅ Secure connection
    ✅ Certificate validated
    ✅ Double encryption (VPN + TLS)
```

## Packet Flow with Encryption Layers

```
┌─────────────────────────────────────────────────────────────┐
│                    User's Browser                           │
│  Application Data: GET /user/admin/account/ HTTP/1.1        │
└──────────────────────┬──────────────────────────────────────┘
                       │ Encrypt with TLS
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              TLS Encrypted Packet                           │
│  [TLS Header][Encrypted: HTTP Request][MAC]                 │
└──────────────────────┬──────────────────────────────────────┘
                       │ Encrypt with WireGuard
                       ▼
┌─────────────────────────────────────────────────────────────┐
│           WireGuard Encrypted Packet                        │
│  [WG Header][Encrypted: TLS Packet][Auth Tag]               │
└──────────────────────┬──────────────────────────────────────┘
                       │ Send over network
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              Firezone VPN Gateway                           │
│  Decrypt WireGuard → [TLS Encrypted Packet]                 │
└──────────────────────┬──────────────────────────────────────┘
                       │ Forward via VPC peering
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              Internal Load Balancer                         │
│  Forward: [TLS Encrypted Packet]                            │
└──────────────────────┬──────────────────────────────────────┘
                       │ Forward to Jenkins VM
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              Nginx (Jenkins VM)                             │
│  Decrypt TLS → [HTTP Request]                               │
└──────────────────────┬──────────────────────────────────────┘
                       │ Proxy to localhost
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              Jenkins Application                            │
│  Process: GET /user/admin/account/ HTTP/1.1                 │
│  Generate: HTTP Response                                    │
└─────────────────────────────────────────────────────────────┘
```

## Timing Breakdown

```
Total Request Time: ~500ms

├─ DNS Resolution: 0ms (hosts file)
├─ VPN Routing: 10ms
├─ VPC Peering: 5ms
├─ Load Balancer: 5ms
├─ TLS Handshake: 50ms (first request only)
├─ Nginx Processing: 5ms
├─ Jenkins Processing: 400ms
└─ Response Return: 25ms
```

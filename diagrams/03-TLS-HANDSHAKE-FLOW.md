# TLS/SSL Handshake Flow Diagram

## Complete TLS 1.2/1.3 Handshake Process

```
┌──────────────────┐                                              ┌──────────────────┐
│                  │                                              │                  │
│  User's Browser  │                                              │  Nginx Server    │
│  (TLS Client)    │                                              │  (TLS Server)    │
│                  │                                              │  10.10.10.10:443 │
│  Windows Client  │                                              │  Jenkins VM      │
│  via VPN         │                                              │                  │
└────────┬─────────┘                                              └────────┬─────────┘
         │                                                                 │
         │                                                                 │
         │ Step 1: TCP Connection                                         │
         │ ─────────────────────────────────────────────────────────────> │
         │ SYN                                                             │
         │                                                                 │
         │ <───────────────────────────────────────────────────────────── │
         │ SYN-ACK                                                         │
         │                                                                 │
         │ ─────────────────────────────────────────────────────────────> │
         │ ACK                                                             │
         │                                                                 │
         │ ✅ TCP Connection Established                                   │
         │                                                                 │
         │                                                                 │
         │ Step 2: ClientHello                                            │
         │ ─────────────────────────────────────────────────────────────> │
         │ • TLS Version: 1.2, 1.3                                        │
         │ • Cipher Suites: TLS_AES_256_GCM_SHA384, etc.                  │
         │ • Random: 32 bytes (client random)                             │
         │ • Session ID: (if resuming)                                    │
         │ • Extensions:                                                  │
         │   - server_name: jenkins.np.learningmyway.space (SNI)          │
         │   - supported_versions: TLS 1.2, 1.3                           │
         │   - supported_groups: x25519, secp256r1                        │
         │   - signature_algorithms: rsa_pss_rsae_sha256                  │
         │                                                                 │
         │                                                                 │
         │ Step 3: ServerHello                                            │
         │ <───────────────────────────────────────────────────────────── │
         │ • TLS Version: 1.2 or 1.3 (selected)                           │
         │ • Cipher Suite: TLS_AES_256_GCM_SHA384 (selected)              │
         │ • Random: 32 bytes (server random)                             │
         │ • Session ID: (for session resumption)                         │
         │ • Extensions: selected parameters                              │
         │                                                                 │
         │                                                                 │
         │ Step 4: Server Certificate Chain                               │
         │ <───────────────────────────────────────────────────────────── │
         │ ┌────────────────────────────────────────────────────────────┐ │
         │ │ Certificate 1: jenkins.np.learningmyway.space              │ │
         │ │ ├─ Subject: CN=jenkins.np.learningmyway.space              │ │
         │ │ ├─ Issuer: CN=LearningMyWay Intermediate CA                │ │
         │ │ ├─ Public Key: RSA 2048-bit                                │ │
         │ │ ├─ Signature: SHA-256 with RSA                             │ │
         │ │ ├─ Valid: Feb 13, 2026 → Feb 13, 2027                      │ │
         │ │ ├─ SAN: DNS:jenkins.np.learningmyway.space, IP:10.10.10.100│ │
         │ │ └─ Key Usage: Digital Signature, Key Encipherment          │ │
         │ │                                                             │ │
         │ │ Certificate 2: LearningMyWay Intermediate CA               │ │
         │ │ ├─ Subject: CN=LearningMyWay Intermediate CA               │ │
         │ │ ├─ Issuer: CN=LearningMyWay Root CA                        │ │
         │ │ ├─ Public Key: RSA 4096-bit                                │ │
         │ │ ├─ Signature: SHA-256 with RSA                             │ │
         │ │ ├─ Valid: Feb 13, 2026 → Feb 12, 2031                      │ │
         │ │ └─ Key Usage: Certificate Sign, CRL Sign                   │ │
         │ │                                                             │ │
         │ │ Certificate 3: LearningMyWay Root CA                       │ │
         │ │ ├─ Subject: CN=LearningMyWay Root CA                       │ │
         │ │ ├─ Issuer: CN=LearningMyWay Root CA (Self-Signed)          │ │
         │ │ ├─ Public Key: RSA 4096-bit                                │ │
         │ │ ├─ Signature: SHA-256 with RSA                             │ │
         │ │ ├─ Valid: Feb 13, 2026 → Feb 13, 2036                      │ │
         │ │ └─ Key Usage: Certificate Sign, CRL Sign                   │ │
         │ └────────────────────────────────────────────────────────────┘ │
         │                                                                 │
         │                                                                 │
         │ Step 5: ServerKeyExchange (TLS 1.2) or KeyShare (TLS 1.3)     │
         │ <───────────────────────────────────────────────────────────── │
         │ • Server's ephemeral public key (for ECDHE)                    │
         │ • Signature over key exchange parameters                       │
         │                                                                 │
         │                                                                 │
         │ Step 6: ServerHelloDone                                        │
         │ <───────────────────────────────────────────────────────────── │
         │ • Server finished sending handshake messages                   │
         │                                                                 │
         │                                                                 │
         │ Step 7: Client Certificate Validation                          │
         │ ┌────────────────────────────────────────────────────────────┐ │
         │ │ Browser validates certificate chain:                       │ │
         │ │                                                             │ │
         │ │ 1. Verify server certificate signature                     │ │
         │ │    ✓ Signed by Intermediate CA (valid)                     │ │
         │ │                                                             │ │
         │ │ 2. Check domain name                                       │ │
         │ │    ✓ jenkins.np.learningmyway.space matches                │ │
         │ │                                                             │ │
         │ │ 3. Check validity dates                                    │ │
         │ │    ✓ Not expired (valid until Feb 13, 2027)                │ │
         │ │                                                             │ │
         │ │ 4. Verify Intermediate CA signature                        │ │
         │ │    ✓ Signed by Root CA (valid)                             │ │
         │ │                                                             │ │
         │ │ 5. Check Root CA in Trusted Store                          │ │
         │ │    ✓ Found in Cert:\LocalMachine\Root                      │ │
         │ │                                                             │ │
         │ │ 6. Verify key usage                                        │ │
         │ │    ✓ Server Authentication allowed                         │ │
         │ │                                                             │ │
         │ │ Result: ✅ Certificate Chain Valid                          │ │
         │ └────────────────────────────────────────────────────────────┘ │
         │                                                                 │
         │                                                                 │
         │ Step 8: ClientKeyExchange                                      │
         │ ─────────────────────────────────────────────────────────────> │
         │ • Client's ephemeral public key                                │
         │ • Encrypted with server's public key                           │
         │                                                                 │
         │ ┌────────────────────────────────────────────────────────────┐ │
         │ │ Both sides now compute:                                    │ │
         │ │ • Pre-Master Secret (from ECDHE)                           │ │
         │ │ • Master Secret = PRF(pre-master, client_random,           │ │
         │ │                       server_random)                       │ │
         │ │ • Session Keys:                                            │ │
         │ │   - Client Write Key (encryption)                          │ │
         │ │   - Server Write Key (encryption)                          │ │
         │ │   - Client Write MAC Key (integrity)                       │ │
         │ │   - Server Write MAC Key (integrity)                       │ │
         │ └────────────────────────────────────────────────────────────┘ │
         │                                                                 │
         │                                                                 │
         │ Step 9: ChangeCipherSpec                                       │
         │ ─────────────────────────────────────────────────────────────> │
         │ • Client switches to encrypted communication                   │
         │                                                                 │
         │                                                                 │
         │ Step 10: Finished (Encrypted)                                  │
         │ ─────────────────────────────────────────────────────────────> │
         │ • Encrypted with session keys                                  │
         │ • Hash of all handshake messages                               │
         │ • Proves client has correct keys                               │
         │                                                                 │
         │                                                                 │
         │ Step 11: ChangeCipherSpec                                      │
         │ <───────────────────────────────────────────────────────────── │
         │ • Server switches to encrypted communication                   │
         │                                                                 │
         │                                                                 │
         │ Step 12: Finished (Encrypted)                                  │
         │ <───────────────────────────────────────────────────────────── │
         │ • Encrypted with session keys                                  │
         │ • Hash of all handshake messages                               │
         │ • Proves server has correct keys                               │
         │                                                                 │
         │                                                                 │
         │ ✅ TLS Handshake Complete                                       │
         │ ✅ Secure Channel Established                                   │
         │ ✅ Browser shows "Secure" 🔒                                    │
         │                                                                 │
         │                                                                 │
         │ Step 13: Application Data (Encrypted)                          │
         │ ═══════════════════════════════════════════════════════════════ │
         │ GET /user/admin/account/ HTTP/1.1                              │
         │ Host: jenkins.np.learningmyway.space                           │
         │ (All encrypted with AES-256-GCM)                               │
         │                                                                 │
         │ <═══════════════════════════════════════════════════════════── │
         │ HTTP/1.1 200 OK                                                │
         │ Content-Type: text/html                                        │
         │ (All encrypted with AES-256-GCM)                               │
         │                                                                 │
         │ ═══════════════════════════════════════════════════════════════ │
         │ Ongoing encrypted communication                                │
         │                                                                 │
```

## Cipher Suite Details

### Selected Cipher Suite: TLS_AES_256_GCM_SHA384

```
TLS_AES_256_GCM_SHA384
 │   │    │   │    │
 │   │    │   │    └─ SHA-384: Hash function for HMAC
 │   │    │   └────── GCM: Galois/Counter Mode (AEAD)
 │   │    └────────── 256: Key size in bits
 │   └─────────────── AES: Encryption algorithm
 └─────────────────── TLS: Protocol

Components:
• Key Exchange: ECDHE (Elliptic Curve Diffie-Hellman Ephemeral)
• Authentication: RSA (from certificate)
• Encryption: AES-256 in GCM mode
• MAC: Integrated in GCM (AEAD)
```

## Session Keys Derivation

```
┌─────────────────────────────────────────────────────────────┐
│                  Key Derivation Process                     │
│                                                             │
│  Input:                                                     │
│  ├─ Pre-Master Secret (from ECDHE key exchange)            │
│  ├─ Client Random (32 bytes)                               │
│  └─ Server Random (32 bytes)                               │
│                                                             │
│  Process:                                                   │
│  Master Secret = PRF(pre-master, "master secret",          │
│                      client_random + server_random)        │
│                                                             │
│  Session Keys = PRF(master_secret, "key expansion",        │
│                     server_random + client_random)         │
│                                                             │
│  Output:                                                    │
│  ├─ Client Write Encryption Key (32 bytes for AES-256)     │
│  ├─ Server Write Encryption Key (32 bytes for AES-256)     │
│  ├─ Client Write IV (12 bytes for GCM)                     │
│  └─ Server Write IV (12 bytes for GCM)                     │
└─────────────────────────────────────────────────────────────┘
```

## Security Properties

### Perfect Forward Secrecy (PFS)
```
Session 1: ECDHE generates ephemeral key pair A
           └─ Session Key 1 (unique)

Session 2: ECDHE generates ephemeral key pair B
           └─ Session Key 2 (unique, different from Session 1)

Result: Compromising one session key doesn't affect other sessions
```

### Certificate Pinning (Optional)
```
Browser can pin certificate:
├─ Pin to Root CA thumbprint
├─ Pin to Intermediate CA thumbprint
└─ Pin to Server certificate thumbprint

Prevents: Man-in-the-middle attacks with rogue CAs
```

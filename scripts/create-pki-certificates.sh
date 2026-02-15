#!/bin/bash
#
# PKI Certificate Chain Creation Script
# Creates Root CA → Intermediate CA → Server Certificate
# For Jenkins HTTPS with proper certificate chain
#
# Usage: sudo ./create-pki-certificates.sh
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
ROOT_CA_PASS="RootCA@LearningMyWay2026!"
INTERMEDIATE_CA_PASS="IntermediateCA@LearningMyWay2026!"
PKCS12_PASS="changeit"

COUNTRY="US"
STATE="California"
CITY="San Francisco"
ORG="LearningMyWay"
OU_SECURITY="IT Security"
OU_OPS="IT Operations"
EMAIL="rksuraj@learningmyway.space"
SERVER_CN="jenkins.np.learningmyway.space"
SERVER_IP="10.10.10.100"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}PKI Certificate Chain Creation${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
  echo -e "${RED}Please run as root (sudo)${NC}"
  exit 1
fi

echo -e "${YELLOW}Step 1: Creating directory structure...${NC}"
mkdir -p /etc/pki/CA/{certs,crl,newcerts,private,intermediate}
mkdir -p /etc/pki/CA/intermediate/{certs,crl,csr,newcerts,private}
chmod 700 /etc/pki/CA/private
chmod 700 /etc/pki/CA/intermediate/private
touch /etc/pki/CA/index.txt
touch /etc/pki/CA/intermediate/index.txt
echo 1000 > /etc/pki/CA/serial
echo 1000 > /etc/pki/CA/intermediate/serial
echo 1000 > /etc/pki/CA/intermediate/crlnumber
echo -e "${GREEN}✓ Directory structure created${NC}"
echo ""

echo -e "${YELLOW}Step 2: Creating Root CA configuration...${NC}"
cat > /etc/pki/CA/openssl-root.cnf << 'EOF'
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

[ crl_ext ]
authorityKeyIdentifier=keyid:always
EOF
echo -e "${GREEN}✓ Root CA configuration created${NC}"
echo ""

echo -e "${YELLOW}Step 3: Generating Root CA private key (4096-bit)...${NC}"
openssl genrsa -aes256 -passout pass:${ROOT_CA_PASS} -out /etc/pki/CA/private/ca.key.pem 4096
chmod 400 /etc/pki/CA/private/ca.key.pem
echo -e "${GREEN}✓ Root CA private key generated${NC}"
echo ""

echo -e "${YELLOW}Step 4: Creating Root CA certificate (10-year validity)...${NC}"
openssl req -config /etc/pki/CA/openssl-root.cnf \
  -key /etc/pki/CA/private/ca.key.pem \
  -passin pass:${ROOT_CA_PASS} \
  -new -x509 -days 3650 -sha256 -extensions v3_ca \
  -out /etc/pki/CA/certs/ca.cert.pem \
  -subj "/C=${COUNTRY}/ST=${STATE}/L=${CITY}/O=${ORG}/OU=${OU_SECURITY}/CN=LearningMyWay Root CA/emailAddress=${EMAIL}"
chmod 444 /etc/pki/CA/certs/ca.cert.pem
echo -e "${GREEN}✓ Root CA certificate created${NC}"
echo ""

echo -e "${YELLOW}Step 5: Creating Intermediate CA configuration...${NC}"
cat > /etc/pki/CA/intermediate/openssl-intermediate.cnf << EOF
[ ca ]
default_ca = CA_default

[ CA_default ]
dir               = /etc/pki/CA/intermediate
certs             = \$dir/certs
crl_dir           = \$dir/crl
new_certs_dir     = \$dir/newcerts
database          = \$dir/index.txt
serial            = \$dir/serial
RANDFILE          = \$dir/private/.rand
private_key       = \$dir/private/intermediate.key.pem
certificate       = \$dir/certs/intermediate.cert.pem
crlnumber         = \$dir/crlnumber
crl               = \$dir/crl/intermediate.crl.pem
crl_extensions    = crl_ext
default_crl_days  = 30
default_md        = sha256
name_opt          = ca_default
cert_opt          = ca_default
default_days      = 375
preserve          = no
policy            = policy_loose

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
DNS.1 = ${SERVER_CN}
IP.1 = ${SERVER_IP}

[ crl_ext ]
authorityKeyIdentifier=keyid:always
EOF
echo -e "${GREEN}✓ Intermediate CA configuration created${NC}"
echo ""

echo -e "${YELLOW}Step 6: Generating Intermediate CA private key (4096-bit)...${NC}"
openssl genrsa -aes256 -passout pass:${INTERMEDIATE_CA_PASS} -out /etc/pki/CA/intermediate/private/intermediate.key.pem 4096
chmod 400 /etc/pki/CA/intermediate/private/intermediate.key.pem
echo -e "${GREEN}✓ Intermediate CA private key generated${NC}"
echo ""

echo -e "${YELLOW}Step 7: Creating Intermediate CA CSR...${NC}"
openssl req -config /etc/pki/CA/intermediate/openssl-intermediate.cnf \
  -new -sha256 \
  -passin pass:${INTERMEDIATE_CA_PASS} \
  -key /etc/pki/CA/intermediate/private/intermediate.key.pem \
  -out /etc/pki/CA/intermediate/csr/intermediate.csr.pem \
  -subj "/C=${COUNTRY}/ST=${STATE}/L=${CITY}/O=${ORG}/OU=${OU_SECURITY}/CN=LearningMyWay Intermediate CA/emailAddress=${EMAIL}"
echo -e "${GREEN}✓ Intermediate CA CSR created${NC}"
echo ""

echo -e "${YELLOW}Step 8: Signing Intermediate CA with Root CA (5-year validity)...${NC}"
openssl ca -config /etc/pki/CA/openssl-root.cnf \
  -extensions v3_intermediate_ca \
  -days 1825 -notext -md sha256 \
  -passin pass:${ROOT_CA_PASS} \
  -batch \
  -in /etc/pki/CA/intermediate/csr/intermediate.csr.pem \
  -out /etc/pki/CA/intermediate/certs/intermediate.cert.pem
chmod 444 /etc/pki/CA/intermediate/certs/intermediate.cert.pem
echo -e "${GREEN}✓ Intermediate CA certificate signed${NC}"
echo ""

echo -e "${YELLOW}Step 9: Verifying Intermediate CA certificate chain...${NC}"
openssl verify -CAfile /etc/pki/CA/certs/ca.cert.pem \
  /etc/pki/CA/intermediate/certs/intermediate.cert.pem
echo ""

echo -e "${YELLOW}Step 10: Creating Jenkins certificates directory...${NC}"
mkdir -p /etc/jenkins/certs
echo -e "${GREEN}✓ Jenkins certificates directory created${NC}"
echo ""

echo -e "${YELLOW}Step 11: Generating server private key (2048-bit, no passphrase)...${NC}"
openssl genrsa -out /etc/jenkins/certs/jenkins.key.pem 2048
chmod 400 /etc/jenkins/certs/jenkins.key.pem
echo -e "${GREEN}✓ Server private key generated${NC}"
echo ""

echo -e "${YELLOW}Step 12: Creating server CSR...${NC}"
openssl req -config /etc/pki/CA/intermediate/openssl-intermediate.cnf \
  -key /etc/jenkins/certs/jenkins.key.pem \
  -new -sha256 -out /etc/jenkins/certs/jenkins.csr.pem \
  -subj "/C=${COUNTRY}/ST=${STATE}/L=${CITY}/O=${ORG}/OU=${OU_OPS}/CN=${SERVER_CN}/emailAddress=${EMAIL}"
echo -e "${GREEN}✓ Server CSR created${NC}"
echo ""

echo -e "${YELLOW}Step 13: Signing server certificate with Intermediate CA (1-year validity)...${NC}"
openssl ca -config /etc/pki/CA/intermediate/openssl-intermediate.cnf \
  -extensions server_cert \
  -days 365 -notext -md sha256 \
  -passin pass:${INTERMEDIATE_CA_PASS} \
  -batch \
  -in /etc/jenkins/certs/jenkins.csr.pem \
  -out /etc/jenkins/certs/jenkins.cert.pem
chmod 444 /etc/jenkins/certs/jenkins.cert.pem
echo -e "${GREEN}✓ Server certificate signed${NC}"
echo ""

echo -e "${YELLOW}Step 14: Verifying server certificate chain...${NC}"
openssl verify -CAfile /etc/pki/CA/certs/ca.cert.pem \
  -untrusted /etc/pki/CA/intermediate/certs/intermediate.cert.pem \
  /etc/jenkins/certs/jenkins.cert.pem
echo ""

echo -e "${YELLOW}Step 15: Building certificate chain file...${NC}"
cat /etc/jenkins/certs/jenkins.cert.pem \
  /etc/pki/CA/intermediate/certs/intermediate.cert.pem \
  /etc/pki/CA/certs/ca.cert.pem > /etc/jenkins/certs/jenkins-chain.cert.pem
chmod 444 /etc/jenkins/certs/jenkins-chain.cert.pem
echo -e "${GREEN}✓ Certificate chain file created${NC}"
echo ""

echo -e "${YELLOW}Step 16: Converting to PKCS12 format for Jenkins...${NC}"
openssl pkcs12 -export \
  -out /etc/jenkins/certs/jenkins.p12 \
  -inkey /etc/jenkins/certs/jenkins.key.pem \
  -in /etc/jenkins/certs/jenkins-chain.cert.pem \
  -password pass:${PKCS12_PASS}
echo -e "${GREEN}✓ PKCS12 file created${NC}"
echo ""

echo -e "${YELLOW}Step 17: Setting ownership and permissions...${NC}"
chown -R jenkins:jenkins /etc/jenkins/certs
chmod 600 /etc/jenkins/certs/jenkins.key.pem
chmod 600 /etc/jenkins/certs/jenkins.p12
echo -e "${GREEN}✓ Ownership and permissions set${NC}"
echo ""

echo -e "${YELLOW}Step 18: Copying Root CA for client distribution...${NC}"
cp /etc/pki/CA/certs/ca.cert.pem /tmp/LearningMyWay-Root-CA.crt
chmod 644 /tmp/LearningMyWay-Root-CA.crt
echo -e "${GREEN}✓ Root CA copied to /tmp/LearningMyWay-Root-CA.crt${NC}"
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}PKI Certificate Chain Created Successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Certificate Information:${NC}"
echo "  Root CA: /etc/pki/CA/certs/ca.cert.pem (10-year validity)"
echo "  Intermediate CA: /etc/pki/CA/intermediate/certs/intermediate.cert.pem (5-year validity)"
echo "  Server Certificate: /etc/jenkins/certs/jenkins.cert.pem (1-year validity)"
echo "  Certificate Chain: /etc/jenkins/certs/jenkins-chain.cert.pem"
echo "  PKCS12 Keystore: /etc/jenkins/certs/jenkins.p12"
echo ""
echo -e "${YELLOW}Passphrases (SAVE THESE SECURELY):${NC}"
echo "  Root CA Passphrase: ${ROOT_CA_PASS}"
echo "  Intermediate CA Passphrase: ${INTERMEDIATE_CA_PASS}"
echo "  PKCS12 Password: ${PKCS12_PASS}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "  1. Configure Jenkins for HTTPS (edit /usr/lib/systemd/system/jenkins.service)"
echo "  2. Add these lines after JENKINS_PORT:"
echo "     Environment=\"JENKINS_HTTPS_PORT=443\""
echo "     Environment=\"JENKINS_HTTPS_KEYSTORE=/etc/jenkins/certs/jenkins.p12\""
echo "     Environment=\"JENKINS_HTTPS_KEYSTORE_PASSWORD=${PKCS12_PASS}\""
echo "  3. Reload and restart Jenkins:"
echo "     systemctl daemon-reload"
echo "     systemctl restart jenkins"
echo "  4. Download Root CA certificate:"
echo "     gcloud compute scp jenkins-vm:/tmp/LearningMyWay-Root-CA.crt . \\"
echo "       --project=test-project2-485105 --zone=us-central1-a --tunnel-through-iap"
echo "  5. Install Root CA on all client machines"
echo "  6. Update Terraform load balancer to forward port 443"
echo "  7. Access Jenkins via https://${SERVER_CN}"
echo ""
echo -e "${GREEN}Done!${NC}"

#!/bin/bash
set -e

# Log all output
exec > >(tee /var/log/firezone-install.log)
exec 2>&1

echo "Starting Firezone gateway installation..."

# Update system
echo "Updating system packages..."
apt-get update
apt-get upgrade -y

# Install Docker
echo "Installing Docker..."
apt-get install -y ca-certificates curl gnupg lsb-release

mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Enable IP forwarding
echo "Enabling IP forwarding..."
echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
echo 'net.ipv6.conf.all.forwarding=1' >> /etc/sysctl.conf
sysctl -p

# Install Firezone gateway
echo "Installing Firezone gateway..."
FIREZONE_TOKEN="${firezone_token}"

docker run -d \
  --name firezone-gateway \
  --restart unless-stopped \
  --pull always \
  --health-cmd "curl -f http://localhost:8080/healthz || exit 1" \
  --health-interval 30s \
  --health-timeout 10s \
  --health-retries 3 \
  --cap-add NET_ADMIN \
  --volume /var/lib/firezone:/var/lib/firezone \
  --env FIREZONE_TOKEN="$FIREZONE_TOKEN" \
  --sysctl net.ipv4.ip_forward=1 \
  --sysctl net.ipv6.conf.all.disable_ipv6=0 \
  --sysctl net.ipv6.conf.all.forwarding=1 \
  --sysctl net.ipv6.conf.default.forwarding=1 \
  ghcr.io/firezone/gateway:latest

echo "Firezone gateway installation completed!"
echo "Gateway should connect to Firezone control plane automatically."

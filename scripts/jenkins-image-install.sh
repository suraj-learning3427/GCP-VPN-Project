#!/bin/bash
set -e

# Simple Jenkins installation for image creation (no data disk)
exec > >(tee /var/log/jenkins-image-install.log)
exec 2>&1

echo "Installing Jenkins for air-gapped image..."

# Update system
dnf update -y

# Install tools
dnf install -y wget curl

# Install Java 17
dnf install -y java-17-openjdk java-17-openjdk-devel

# Add Jenkins repository
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

# Install Jenkins
dnf install -y jenkins

# Configure Jenkins for Java 17
mkdir -p /etc/systemd/system/jenkins.service.d
cat > /etc/systemd/system/jenkins.service.d/override.conf <<EOF
[Service]
Environment="JAVA_HOME=/usr/lib/jvm/java-17-openjdk"
EOF

systemctl daemon-reload

# Configure firewall
firewall-cmd --permanent --add-port=8080/tcp
firewall-cmd --reload

# Clean up
dnf clean all
rm -rf /var/cache/dnf/*

echo "Jenkins installation complete!"
touch /tmp/install-complete

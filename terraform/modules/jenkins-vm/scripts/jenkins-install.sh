#!/bin/bash
set -e

# Log all output
exec > >(tee /var/log/jenkins-install.log)
exec 2>&1

echo "Starting Jenkins installation script..."

# Wait for the data disk to be attached
echo "Waiting for data disk..."
while [ ! -e /dev/sdb ]; do
  sleep 2
done

# Format and mount data disk
echo "Formatting data disk..."
if ! blkid /dev/sdb; then
  mkfs.ext4 -F /dev/sdb
fi

echo "Creating mount point..."
mkdir -p /var/lib/jenkins

echo "Mounting data disk..."
mount /dev/sdb /var/lib/jenkins

# Add to fstab for persistence
if ! grep -q "/dev/sdb" /etc/fstab; then
  echo '/dev/sdb /var/lib/jenkins ext4 defaults 0 2' >> /etc/fstab
fi

# Update system
echo "Updating system packages..."
dnf update -y

# Install required tools
echo "Installing required tools..."
dnf install -y wget curl

# Install Java 17 (required for Jenkins 2.541+)
echo "Installing Java 17..."
dnf install -y java-17-openjdk java-17-openjdk-devel

# Set Java 17 as default
echo "Setting Java 17 as default..."
alternatives --set java /usr/lib/jvm/java-17-openjdk-17.0.18.0.8-1.el8.x86_64/bin/java || true

# Add Jenkins repository
echo "Adding Jenkins repository..."
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

# Install Jenkins
echo "Installing Jenkins..."
dnf install -y jenkins

# Create systemd override for Java 17
echo "Configuring Jenkins to use Java 17..."
mkdir -p /etc/systemd/system/jenkins.service.d
cat > /etc/systemd/system/jenkins.service.d/override.conf <<EOF
[Service]
Environment="JAVA_HOME=/usr/lib/jvm/java-17-openjdk-17.0.18.0.8-1.el8.x86_64"
EOF

# Reload systemd
systemctl daemon-reload

# Configure Jenkins home directory
echo "Configuring Jenkins..."
sed -i 's|JENKINS_HOME=.*|JENKINS_HOME="/var/lib/jenkins"|' /etc/sysconfig/jenkins

# Set ownership
chown -R jenkins:jenkins /var/lib/jenkins

# Configure firewall
echo "Configuring firewall..."
firewall-cmd --permanent --add-port=8080/tcp
firewall-cmd --reload

# Enable and start Jenkins
echo "Starting Jenkins service..."
systemctl enable jenkins
systemctl start jenkins

# Wait for Jenkins to start
echo "Waiting for Jenkins to start..."
sleep 30

# Get initial admin password
if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
  echo "Jenkins initial admin password:"
  cat /var/lib/jenkins/secrets/initialAdminPassword
fi

echo "Jenkins installation completed successfully!"

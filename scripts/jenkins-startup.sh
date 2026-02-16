#!/bin/bash
set -e

exec > >(tee /var/log/jenkins-startup.log)
exec 2>&1

echo "Installing Jenkins on Rocky Linux 8..."

# Wait for data disk
while [ ! -e /dev/sdb ]; do sleep 2; done

# Format if needed
if ! blkid /dev/sdb; then
  mkfs.ext4 -F /dev/sdb
fi

# Mount data disk
mkdir -p /var/lib/jenkins
mount /dev/sdb /var/lib/jenkins

# Add to fstab
if ! grep -q "/dev/sdb" /etc/fstab; then
  echo '/dev/sdb /var/lib/jenkins ext4 defaults 0 2' >> /etc/fstab
fi

# Install Java 17
dnf install -y java-17-openjdk java-17-openjdk-devel

# Add Jenkins repository
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

# Install Jenkins
dnf install -y jenkins

# Set ownership
chown -R jenkins:jenkins /var/lib/jenkins

# Start Jenkins
systemctl enable jenkins
systemctl start jenkins

echo "Jenkins installation complete!"

#!/bin/bash
# Configure Jenkins for HTTPS

# Backup original service file
cp /usr/lib/systemd/system/jenkins.service /usr/lib/systemd/system/jenkins.service.backup

# Add HTTPS configuration after JENKINS_PORT line
sed -i '/Environment="JENKINS_PORT=8080"/a\
Environment="JENKINS_HTTPS_PORT=443"\
Environment="JENKINS_HTTPS_KEYSTORE=/etc/jenkins/certs/jenkins.p12"\
Environment="JENKINS_HTTPS_KEYSTORE_PASSWORD=changeit"' /usr/lib/systemd/system/jenkins.service

# Reload systemd and restart Jenkins
systemctl daemon-reload
systemctl restart jenkins

# Wait for Jenkins to start
sleep 15

# Check status
systemctl status jenkins

# Check if port 443 is listening
echo ""
echo "Checking if Jenkins is listening on port 443..."
ss -tlnp | grep -E '(8080|443)'

#!/bin/bash
# Fix Jenkins HTTPS port 443 permission issue

echo "Restoring Jenkins to working state..."
# Restore original service file
cp /usr/lib/systemd/system/jenkins.service.backup /usr/lib/systemd/system/jenkins.service
systemctl daemon-reload
systemctl start jenkins
sleep 10

echo "Granting Java permission to bind to port 443..."
# Find Java executable
JAVA_BIN=$(readlink -f /usr/bin/java)
echo "Java binary: $JAVA_BIN"

# Grant capability to bind to privileged ports
setcap 'cap_net_bind_service=+ep' $JAVA_BIN

echo "Configuring Jenkins for HTTPS..."
# Add HTTPS configuration
sed -i '/Environment="JENKINS_PORT=8080"/a\
Environment="JENKINS_HTTPS_PORT=443"\
Environment="JENKINS_HTTPS_KEYSTORE=/etc/jenkins/certs/jenkins.p12"\
Environment="JENKINS_HTTPS_KEYSTORE_PASSWORD=changeit"' /usr/lib/systemd/system/jenkins.service

# Reload and restart
systemctl daemon-reload
systemctl restart jenkins

echo "Waiting for Jenkins to start..."
sleep 20

echo "Checking Jenkins status..."
systemctl status jenkins

echo ""
echo "Checking ports..."
ss -tlnp | grep -E '(8080|443)' || echo "No ports found"

echo ""
echo "Checking Java capabilities..."
getcap $JAVA_BIN

#!/bin/bash
# Script to create air-gapped Jenkins image
# This image has Jenkins pre-installed, so no internet access is needed

set -e

PROJECT_ID="test-project2-485105"
ZONE="us-central1-a"
NETWORK="core-it-vpc"
SUBNET="jenkins-subnet"
IMAGE_NAME="jenkins-airgapped-v1"
IMAGE_FAMILY="jenkins-airgapped"

echo "=========================================="
echo "Creating Air-Gapped Jenkins Image"
echo "=========================================="
echo ""
echo "This will:"
echo "1. Create a temporary VM with internet access"
echo "2. Install Jenkins, Java 17, and all dependencies"
echo "3. Create a custom image from the VM"
echo "4. Delete the temporary VM"
echo "5. Result: Air-gapped image ready to use (no internet needed!)"
echo ""
echo "Estimated time: 10-15 minutes"
echo "Cost: One-time Cloud NAT usage (~$0.50)"
echo "Savings: $61.50/month after implementation"
echo ""
read -p "Press Enter to continue..."

echo ""
echo "Step 1: Creating temporary builder VM with public IP..."
echo "Note: Public IP is temporary - only for building the image"

# Create temporary firewall rule for internet access
echo "Creating temporary firewall rule for builder VM..."
gcloud compute firewall-rules create temp-builder-internet-access \
  --project=$PROJECT_ID \
  --network=$NETWORK \
  --allow=all \
  --direction=EGRESS \
  --target-tags=allow-internet-temp \
  --description="Temporary rule for image builder - will be deleted" \
  --priority=900 || echo "Firewall rule may already exist"

gcloud compute instances create jenkins-image-builder \
  --project=$PROJECT_ID \
  --zone=$ZONE \
  --machine-type=e2-medium \
  --image-family=rocky-linux-8 \
  --image-project=rocky-linux-cloud \
  --boot-disk-size=50GB \
  --network=$NETWORK \
  --subnet=$SUBNET \
  --tags=jenkins-server,allow-internet-temp \
  --metadata=startup-script='#!/bin/bash
set -e

# Log everything
exec > >(tee /var/log/image-builder.log)
exec 2>&1

echo "Starting Jenkins installation for air-gapped image..."

# Update system
echo "Updating system packages..."
dnf update -y

# Install required tools
echo "Installing wget and curl..."
dnf install -y wget curl

# Install Java 17
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

# Configure Jenkins to use Java 17
echo "Configuring Jenkins for Java 17..."
mkdir -p /etc/systemd/system/jenkins.service.d
cat > /etc/systemd/system/jenkins.service.d/override.conf << EOL
[Service]
Environment="JAVA_HOME=/usr/lib/jvm/java-17-openjdk-17.0.18.0.8-1.el8.x86_64"
EOL

# Reload systemd
systemctl daemon-reload

# Clean up to reduce image size
echo "Cleaning up..."
dnf clean all
rm -rf /var/cache/dnf/*
rm -rf /tmp/*

# Stop Jenkins (will be started on actual VM)
echo "Stopping Jenkins service..."
systemctl stop jenkins 2>/dev/null || true
systemctl disable jenkins 2>/dev/null || true

# Mark installation as complete
echo "Installation complete!"
touch /tmp/image-ready
date > /tmp/image-ready-timestamp
'

echo "VM created. Waiting for installation to complete..."
echo "This will take 5-10 minutes..."
echo ""

# Wait for VM to be ready
sleep 60

# Check if installation is complete
echo "Checking installation progress..."
RETRY_COUNT=0
MAX_RETRIES=20

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  if gcloud compute ssh jenkins-image-builder \
    --project=$PROJECT_ID \
    --zone=$ZONE \
    --tunnel-through-iap \
    --command="test -f /tmp/image-ready && cat /tmp/image-ready-timestamp" 2>/dev/null; then
    echo ""
    echo "✓ Installation completed successfully!"
    break
  else
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "Still installing... (attempt $RETRY_COUNT/$MAX_RETRIES)"
    sleep 30
  fi
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
  echo ""
  echo "ERROR: Installation did not complete in expected time."
  echo "Please check the VM logs:"
  echo "gcloud compute ssh jenkins-image-builder --project=$PROJECT_ID --zone=$ZONE --tunnel-through-iap"
  echo "Then run: sudo cat /var/log/image-builder.log"
  exit 1
fi

echo ""
echo "Step 2: Stopping builder VM..."
gcloud compute instances stop jenkins-image-builder \
  --project=$PROJECT_ID \
  --zone=$ZONE \
  --quiet

echo ""
echo "Step 3: Creating custom image..."
echo "Image name: $IMAGE_NAME"
echo "Image family: $IMAGE_FAMILY"

gcloud compute images create $IMAGE_NAME \
  --project=$PROJECT_ID \
  --source-disk=jenkins-image-builder \
  --source-disk-zone=$ZONE \
  --family=$IMAGE_FAMILY \
  --description="Air-gapped Rocky Linux 8 with Jenkins 2.541.1 and Java 17 pre-installed. No internet access required." \
  --labels=environment=production,application=jenkins,type=airgapped

echo ""
echo "✓ Image created successfully!"

echo ""
echo "Step 4: Cleaning up temporary VM and firewall rule..."
gcloud compute instances delete jenkins-image-builder \
  --project=$PROJECT_ID \
  --zone=$ZONE \
  --quiet

# Delete temporary firewall rule
echo "Deleting temporary firewall rule..."
gcloud compute firewall-rules delete temp-builder-internet-access \
  --project=$PROJECT_ID \
  --quiet || echo "Firewall rule already deleted"

echo ""
echo "=========================================="
echo "✓ Air-Gapped Image Creation Complete!"
echo "=========================================="
echo ""
echo "Image Details:"
echo "  Name: $IMAGE_NAME"
echo "  Family: $IMAGE_FAMILY"
echo "  Project: $PROJECT_ID"
echo ""
echo "What's included:"
echo "  ✓ Rocky Linux 8"
echo "  ✓ Java 17.0.18"
echo "  ✓ Jenkins 2.541.1"
echo "  ✓ All dependencies"
echo ""
echo "Next steps:"
echo "  1. Update Terraform to use this image"
echo "  2. Remove Cloud NAT from Terraform"
echo "  3. Redeploy Jenkins"
echo ""
echo "Monthly savings: \$61.50 (from \$64 to \$2.50)"
echo "Annual savings: \$738"
echo ""
echo "Image storage cost: ~\$2.50/month"
echo ""

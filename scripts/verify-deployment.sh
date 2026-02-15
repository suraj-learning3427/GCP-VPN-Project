#!/bin/bash
# Deployment Verification Script

set -e

echo "=== VPN-Jenkins Infrastructure Verification ==="
echo ""

PROJECT1="test-project1-485105"
PROJECT2="test-project2-485105"
REGION="us-central1"
ZONE="us-central1-a"

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "Error: gcloud CLI is not installed"
    exit 1
fi

echo "Step 1: Checking VPC Networks..."
echo "Project 1 VPCs:"
gcloud compute networks list --project=$PROJECT1 --format="table(name,subnet_mode)"
echo ""
echo "Project 2 VPCs:"
gcloud compute networks list --project=$PROJECT2 --format="table(name,subnet_mode)"
echo ""

echo "Step 2: Checking VPC Peering..."
echo "Project 1 Peering:"
gcloud compute networks peerings list --project=$PROJECT1 --format="table(name,network,peerNetwork,state)"
echo ""
echo "Project 2 Peering:"
gcloud compute networks peerings list --project=$PROJECT2 --format="table(name,network,peerNetwork,state)"
echo ""

echo "Step 3: Checking Compute Instances..."
echo "Project 1 Instances:"
gcloud compute instances list --project=$PROJECT1 --format="table(name,zone,machineType,status,networkInterfaces[0].networkIP)"
echo ""
echo "Project 2 Instances:"
gcloud compute instances list --project=$PROJECT2 --format="table(name,zone,machineType,status,networkInterfaces[0].networkIP)"
echo ""

echo "Step 4: Checking Load Balancer..."
gcloud compute forwarding-rules list --project=$PROJECT2 --format="table(name,region,IPAddress,target)"
echo ""

echo "Step 5: Checking DNS Zones..."
gcloud dns managed-zones list --project=$PROJECT2 --format="table(name,dnsName,visibility)"
echo ""

echo "Step 6: Checking Firewall Rules..."
echo "Project 2 Firewall Rules:"
gcloud compute firewall-rules list --project=$PROJECT2 --format="table(name,network,direction,sourceRanges.list():label=SRC_RANGES,allowed[].map().firewall_rule().list():label=ALLOW)"
echo ""

echo "Step 7: Checking Backend Health..."
BACKEND_SERVICE=$(gcloud compute backend-services list --project=$PROJECT2 --filter="name~jenkins" --format="value(name)" --regions=$REGION)
if [ -n "$BACKEND_SERVICE" ]; then
    echo "Backend Service: $BACKEND_SERVICE"
    gcloud compute backend-services get-health $BACKEND_SERVICE \
      --region=$REGION \
      --project=$PROJECT2 || echo "Health check may not be ready yet"
else
    echo "No Jenkins backend service found"
fi
echo ""

echo "=== Verification Complete ==="
echo ""
echo "Manual checks:"
echo "1. Connect Firezone VPN client"
echo "2. Test DNS: nslookup jenkins.np.learningmyway.space"
echo "3. Access: https://jenkins.np.learningmyway.space"
echo ""
echo "To get Jenkins initial password:"
echo "gcloud compute ssh jenkins-vm --project=$PROJECT2 --zone=$ZONE --tunnel-through-iap"
echo "sudo cat /var/lib/jenkins/secrets/initialAdminPassword"

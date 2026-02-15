#!/bin/bash
# Complete HTTPS Setup - Add public IP, install nginx, configure HTTPS, remove public IP

set -e

echo "=========================================="
echo "Complete HTTPS Setup for Jenkins"
echo "=========================================="
echo ""

PROJECT_ID="test-project2-485105"
ZONE="us-central1-a"
VM_NAME="jenkins-vm"

echo "Step 1: Adding temporary public IP to Jenkins VM..."
gcloud compute instances add-access-config $VM_NAME \
  --project=$PROJECT_ID \
  --zone=$ZONE \
  --access-config-name="External NAT"

echo "Waiting for public IP to be assigned..."
sleep 5

echo ""
echo "Step 2: Adding temporary egress firewall rule..."
gcloud compute firewall-rules create temp-jenkins-egress \
  --project=$PROJECT_ID \
  --network=core-it-vpc \
  --action=ALLOW \
  --rules=all \
  --direction=EGRESS \
  --target-tags=jenkins-server \
  --priority=1000

echo ""
echo "Step 3: Installing nginx on Jenkins VM..."
gcloud compute ssh $VM_NAME \
  --project=$PROJECT_ID \
  --zone=$ZONE \
  --tunnel-through-iap \
  --command="sudo dnf install -y nginx"

echo ""
echo "Step 4: Configuring nginx for HTTPS..."
gcloud compute ssh $VM_NAME \
  --project=$PROJECT_ID \
  --zone=$ZONE \
  --tunnel-through-iap \
  --command="sudo tee /etc/nginx/conf.d/jenkins.conf > /dev/null << 'EOF'
upstream jenkins {
    server 127.0.0.1:8080 fail_timeout=0;
}

server {
    listen 443 ssl http2;
    server_name jenkins.np.learningmyway.space;

    ssl_certificate /etc/jenkins/certs/jenkins-chain.cert.pem;
    ssl_certificate_key /etc/jenkins/certs/jenkins.key.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    add_header Strict-Transport-Security \"max-age=31536000; includeSubDomains\" always;

    access_log /var/log/nginx/jenkins.access.log;
    error_log /var/log/nginx/jenkins.error.log;

    location / {
        proxy_pass http://jenkins;
        proxy_redirect http:// https://;
        proxy_http_version 1.1;

        proxy_set_header Connection \\\$connection_upgrade;
        proxy_set_header Upgrade \\\$http_upgrade;
        proxy_set_header Host \\\$host:\\\$server_port;
        proxy_set_header X-Real-IP \\\$remote_addr;
        proxy_set_header X-Forwarded-For \\\$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \\\$scheme;
        proxy_set_header X-Forwarded-Port \\\$server_port;

        proxy_connect_timeout 150;
        proxy_send_timeout 100;
        proxy_read_timeout 100;
        proxy_buffering off;
        proxy_request_buffering off;
        proxy_max_temp_file_size 0;

        client_max_body_size 10m;
        client_body_buffer_size 128k;
    }
}

server {
    listen 80;
    server_name jenkins.np.learningmyway.space;
    return 301 https://\\\$server_name\\\$request_uri;
}

map \\\$http_upgrade \\\$connection_upgrade {
    default upgrade;
    '' close;
}
EOF
"

echo ""
echo "Step 5: Setting SELinux permissions..."
gcloud compute ssh $VM_NAME \
  --project=$PROJECT_ID \
  --zone=$ZONE \
  --tunnel-through-iap \
  --command="sudo setsebool -P httpd_can_network_connect 1"

echo ""
echo "Step 6: Starting nginx..."
gcloud compute ssh $VM_NAME \
  --project=$PROJECT_ID \
  --zone=$ZONE \
  --tunnel-through-iap \
  --command="sudo systemctl enable nginx && sudo systemctl start nginx"

echo ""
echo "Step 7: Verifying nginx is running..."
gcloud compute ssh $VM_NAME \
  --project=$PROJECT_ID \
  --zone=$ZONE \
  --tunnel-through-iap \
  --command="sudo systemctl status nginx && sudo ss -tlnp | grep -E '(80|443)'"

echo ""
echo "Step 8: Removing public IP..."
gcloud compute instances delete-access-config $VM_NAME \
  --project=$PROJECT_ID \
  --zone=$ZONE \
  --access-config-name="External NAT"

echo ""
echo "Step 9: Removing egress firewall rule..."
gcloud compute firewall-rules delete temp-jenkins-egress \
  --project=$PROJECT_ID \
  --quiet

echo ""
echo "=========================================="
echo "HTTPS Setup Complete!"
echo "=========================================="
echo ""
echo "Jenkins is now air-gapped again with HTTPS enabled!"
echo ""
echo "Next steps:"
echo "1. Install Root CA on your Windows machine (if not done)"
echo "2. Add hosts file entry: 10.10.10.100 jenkins.np.learningmyway.space"
echo "3. Connect to VPN"
echo "4. Access: https://jenkins.np.learningmyway.space"
echo ""

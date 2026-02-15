#!/bin/bash
# Setup Nginx as HTTPS reverse proxy for Jenkins

set -e

echo "Installing Nginx..."
dnf install -y nginx

echo "Creating Nginx configuration for Jenkins HTTPS..."
cat > /etc/nginx/conf.d/jenkins.conf << 'EOF'
upstream jenkins {
    server 127.0.0.1:8080 fail_timeout=0;
}

server {
    listen 443 ssl http2;
    server_name jenkins.np.learningmyway.space;

    # SSL Certificate
    ssl_certificate /etc/jenkins/certs/jenkins-chain.cert.pem;
    ssl_certificate_key /etc/jenkins/certs/jenkins.key.pem;

    # SSL Configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options SAMEORIGIN always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Logging
    access_log /var/log/nginx/jenkins.access.log;
    error_log /var/log/nginx/jenkins.error.log;

    # Jenkins Reverse Proxy
    location / {
        proxy_pass http://jenkins;
        proxy_redirect http:// https://;
        proxy_http_version 1.1;

        # Required for Jenkins websocket agents
        proxy_set_header Connection $connection_upgrade;
        proxy_set_header Upgrade $http_upgrade;

        proxy_set_header Host $host:$server_port;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Port $server_port;

        # Timeouts
        proxy_connect_timeout 150;
        proxy_send_timeout 100;
        proxy_read_timeout 100;

        # Buffering
        proxy_buffering off;
        proxy_request_buffering off;
        proxy_max_temp_file_size 0;

        # Client body size
        client_max_body_size 10m;
        client_body_buffer_size 128k;
    }
}

# HTTP to HTTPS redirect
server {
    listen 80;
    server_name jenkins.np.learningmyway.space;
    return 301 https://$server_name$request_uri;
}

# WebSocket upgrade
map $http_upgrade $connection_upgrade {
    default upgrade;
    '' close;
}
EOF

echo "Setting SELinux permissions for Nginx..."
setsebool -P httpd_can_network_connect 1

echo "Enabling and starting Nginx..."
systemctl enable nginx
systemctl start nginx

echo "Checking Nginx status..."
systemctl status nginx

echo ""
echo "Checking if Nginx is listening on port 443..."
ss -tlnp | grep -E '(80|443)'

echo ""
echo "Testing Nginx configuration..."
nginx -t

echo ""
echo "Done! Nginx is now proxying HTTPS (443) to Jenkins (8080)"

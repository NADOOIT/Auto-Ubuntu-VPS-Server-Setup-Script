#!/bin/bash

# Function to setup SSL with Certbot
setup_ssl() {
    local server_ip="$1"
    local admin_user="$2"
    local domain="nadooit.de"
    
    echo -e "\n🔒 ${CYAN}Setting up SSL Certificate${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════${NC}"
    
    # Install Certbot and Nginx plugin
    echo -e "\n📦 Installing Certbot..."
    ssh "$admin_user@$server_ip" "sudo apt-get update && sudo apt-get install -y certbot python3-certbot-nginx"
    
    # Configure Nginx for domain
    echo -e "\n⚙️ Configuring Nginx for $domain..."
    ssh "$admin_user@$server_ip" "sudo bash -c 'cat > /etc/nginx/sites-available/$domain << EOF
server {
    listen 80;
    server_name $domain www.$domain;
    
    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF'"
    
    # Enable site
    ssh "$admin_user@$server_ip" "sudo ln -sf /etc/nginx/sites-available/$domain /etc/nginx/sites-enabled/"
    ssh "$admin_user@$server_ip" "sudo nginx -t && sudo systemctl reload nginx"
    
    # Get SSL certificate
    echo -e "\n🔑 Obtaining SSL certificate..."
    ssh "$admin_user@$server_ip" "sudo certbot --nginx -d $domain -d www.$domain --non-interactive --agree-tos --email christoph.backhaus@nadooit.de"
    
    # Setup auto-renewal cron job
    echo -e "\n⏰ Setting up automatic renewal..."
    ssh "$admin_user@$server_ip" "sudo bash -c '(crontab -l 2>/dev/null; echo \"0 3 * * * /usr/bin/certbot renew --quiet\") | crontab -'"
    
    echo -e "\n${GREEN}✅ SSL setup complete${NC}"
    echo -e "Domain is now accessible at: https://$domain"
}

#!/bin/bash

# Install certbot
apt update
apt install -y certbot python3-certbot-nginx

# Get SSL certificate
certbot certonly --nginx -d golem-dev.biodata.ceitec.cz --agree-tos --email plhal.jakub18@gmail.com --non-interactive

# Set up auto-renewal
echo "0 0,12 * * * root certbot renew --quiet" > /etc/cron.d/certbot-renew

# Make the cron job executable
chmod 644 /etc/cron.d/certbot-renew

echo "Certbot setup complete. SSL certificates have been generated."
echo "Certificate path: /etc/letsencrypt/live/golem-dev.biodata.ceitec.cz/"


#!/bin/bash

# Exit on error
set -e

# Create necessary directories
mkdir -p certbot/conf certbot/www ui

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

echo "Setting up Docker environment for Golem app..."

# Copy your Flutter web build into the ui directory
echo "Do you want to copy UI files from Flutter web build? (y/n)"
read copy_ui
if [ "$copy_ui" = "y" ]; then
    echo "Enter the path to your Flutter web build directory:"
    read flutter_path
    if [ -d "$flutter_path" ]; then
        cp -r "$flutter_path"/* ./ui/
        echo "Flutter web build copied to ui directory."
    else
        echo "Directory not found. Please build your Flutter web app and try again."
        exit 1
    fi
fi

# Check if we need to obtain SSL certificate
echo "Do you need to obtain an SSL certificate? (y/n)"
read get_ssl
if [ "$get_ssl" = "y" ]; then
    # Step 1: Start Nginx for initial configuration (HTTP only)
    cat > nginx_init.conf << EOL
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                    '\$status \$body_bytes_sent "\$http_referer" '
                    '"\$http_user_agent" "\$http_x_forwarded_for"';
    access_log /var/log/nginx/access.log main;
    sendfile on;
    keepalive_timeout 65;

    server {
        listen 80;
        server_name golem-dev.biodata.ceitec.cz;
        
        location /.well-known/acme-challenge/ {
            root /var/www/certbot;
        }
        
        location / {
            return 200 'Ready for Certbot challenge';
        }
    }
}
EOL

    echo "Starting Nginx container for SSL certificate setup..."
    docker run --name nginx-init -v $(pwd)/nginx_init.conf:/etc/nginx/nginx.conf:ro \
        -v $(pwd)/certbot/www:/var/www/certbot \
        -p 80:80 -d nginx:1.25-alpine

    # Step 2: Get SSL certificate with Certbot
    echo "Enter your email address for SSL certificate notifications:"
    read email_address
    
    echo "Obtaining SSL certificate..."
    docker run --rm -v $(pwd)/certbot/conf:/etc/letsencrypt \
        -v $(pwd)/certbot/www:/var/www/certbot \
        certbot/certbot certonly --webroot \
        --webroot-path=/var/www/certbot \
        --email $email_address \
        --agree-tos --no-eff-email \
        -d golem-dev.biodata.ceitec.cz

    # Step 3: Stop the temporary Nginx container
    echo "Stopping temporary Nginx container..."
    docker stop nginx-init && docker rm nginx-init
    rm nginx_init.conf
fi

# Step 4: Start the complete Docker Compose stack
echo "Starting Docker Compose services..."
docker-compose up -d

echo "Setup complete! Your application should be running at https://golem-dev.biodata.ceitec.cz"
echo "If you encounter any issues, check the logs with: docker-compose logs -f"


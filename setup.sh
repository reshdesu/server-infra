#!/bin/bash
# setup.sh - Restore/Install Server Configurations
# Usage: ./setup.sh [caddy|nginx]

set -e

SERVER_TYPE=${1:-caddy}

echo "=== Starting restoration script for $SERVER_TYPE ==="

if [ "$SERVER_TYPE" = "caddy" ]; then
    echo "Configuring Caddy..."

    # Create directories if they do not exist
    sudo mkdir -p /etc/caddy
    sudo mkdir -p /var/log/caddy

    # Copy files
    if [ -f "./configs/caddy/Caddyfile" ]; then
        sudo cp ./configs/caddy/Caddyfile /etc/caddy/Caddyfile
        echo "Copied Caddyfile to /etc/caddy/Caddyfile"
    else
        echo "Error: Caddyfile not found in ./configs/caddy/"
        exit 1
    fi

    if [ -f "./systemd/caddy.service" ]; then
        sudo cp ./systemd/caddy.service /etc/systemd/system/caddy.service
        echo "Copied systemd service definition"
    fi

    # Create system user/group if they do not exist
    if ! getent group caddy >/dev/null; then
        sudo groupadd --system caddy
    fi
    if ! getent passwd caddy >/dev/null; then
        sudo useradd --system \
            --gid caddy \
            --create-home \
            --home-dir /var/lib/caddy \
            --shell /usr/sbin/nologin \
            --comment "Caddy web server" \
            caddy
    fi

    # Fix ownership
    sudo chown -R caddy:caddy /etc/caddy /var/log/caddy /var/lib/caddy

    echo "Reloading systemd daemon..."
    sudo systemctl daemon-reload
    echo "Caddy setup finished! Make sure the 'caddy' binary is placed at /usr/local/bin/caddy, then run: sudo systemctl enable --now caddy"

elif [ "$SERVER_TYPE" = "nginx" ]; then
    echo "Configuring Nginx..."

    # Assumes Nginx is installed via package manager
    sudo mkdir -p /etc/nginx

    if [ -f "./configs/nginx/nginx.conf" ]; then
        sudo cp ./configs/nginx/nginx.conf /etc/nginx/nginx.conf
        echo "Copied nginx.conf to /etc/nginx/nginx.conf"
    else
        echo "Error: nginx.conf not found in ./configs/nginx/"
        exit 1
    fi

    echo "Testing Nginx configuration..."
    if command -v nginx >/dev/null 2>&1; then
        sudo nginx -t
        sudo systemctl restart nginx
        echo "Nginx successfully restarted!"
    else
        echo "Warning: nginx binary not found. Please install Nginx on this system."
    fi

else
    echo "Invalid option. Please choose either 'caddy' or 'nginx'."
    exit 1
fi

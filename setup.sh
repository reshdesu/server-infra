#!/bin/bash
# setup.sh - Restore/Install Server Caddy Configurations & Dashboard
# Usage: ./setup.sh

set -e

echo "=== Starting restoration script for Caddy ==="

echo "Configuring Caddy..."

# Install Tailscale if not present (required for Tailscale SSL domains)
if ! command -v tailscale >/dev/null 2>&1; then
    echo "Installing Tailscale..."
    curl -fsSL https://tailscale.com/install.sh | sh
    echo "Tailscale installed! Run: sudo tailscale up"
else
    echo "Tailscale is already installed."
fi

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

# Deploy dashboard static homepage
if [ -d "./dashboard" ]; then
    echo "Deploying dashboard static homepage to /var/www/dashboard..."
    sudo mkdir -p /var/www/dashboard
    sudo cp -r ./dashboard/* /var/www/dashboard/
    sudo chown -R caddy:caddy /var/www/dashboard
fi

echo "Reloading systemd daemon..."
sudo systemctl daemon-reload
echo "Caddy setup finished! Make sure the 'caddy' binary is placed at /usr/local/bin/caddy, then run: sudo systemctl enable --now caddy"

# Configure local Git hooks path for security scanning
if command -v git >/dev/null 2>&1 && [ -d ".git" ]; then
    echo "Configuring local Git hooks..."
    git config core.hooksPath .githooks
fi

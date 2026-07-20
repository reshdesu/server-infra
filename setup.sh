#!/bin/bash
# setup.sh - Restore/Install Server Caddy Configurations & Dashboard
# Usage: ./setup.sh

set -e

if command -v whiptail >/dev/null 2>&1 && [ -z "$DISABLE_WHIPTAIL" ]; then
    whiptail --title "Media Server Infra - Setup" --msgbox "Welcome to the Media Server Infra automated setup!\n\nThis wizard will configure Tailscale, Caddy, and your Docker container stack." 10 60
fi

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

    # Automatically configure actual Tailscale domain if running
    if command -v tailscale >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
        TAILSCALE_DOMAIN=$(tailscale status --json | jq -r .Self.DNSName 2>/dev/null | sed 's/\.$//' || true)
        if [ -n "$TAILSCALE_DOMAIN" ]; then
            echo "Configuring Caddy for Tailscale domain: $TAILSCALE_DOMAIN"
            sudo sed -i "s/your-media-center\.ts\.net/$TAILSCALE_DOMAIN/g" /etc/caddy/Caddyfile
        fi
    fi
else
    echo "Error: Caddyfile not found in ./configs/caddy/"
    exit 1
fi

if [ -f "./systemd/caddy.service" ]; then
    sudo cp ./systemd/caddy.service /etc/systemd/system/caddy.service
    echo "Copied systemd service definition"
fi

if [ -f "./systemd/docker-wait-for-media.conf" ]; then
    sudo mkdir -p /etc/systemd/system/docker.service.d
    sudo cp ./systemd/docker-wait-for-media.conf /etc/systemd/system/docker.service.d/override.conf
    echo "Configured Docker to wait for media mount"
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

# Configure automated daily backup cron job
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Configuring daily backup cron job in /etc/cron.d/arr-stack-backup..."
cat <<EOF | sudo tee /etc/cron.d/arr-stack-backup > /dev/null
# Daily backup of Media Server Infra configurations at 3:00 AM
0 3 * * * root cd $REPO_DIR && ./backup-configs.sh > /dev/null 2>&1
EOF
sudo chmod 0644 /etc/cron.d/arr-stack-backup
echo "[SUCCESS] Scheduled daily backup at 3:00 AM."

# Initialize Docker .env file for arr-stack if it doesn't exist
"$REPO_DIR/scripts/init_env.sh"

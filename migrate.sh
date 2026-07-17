#!/bin/bash
# migrate.sh - Automate migration from local systemd Arr services to Docker Compose.
# Run this script from the root of the server-infra repository.

set -e

echo "=========================================================="
echo "Starting migration from local Systemd services to Docker  "
echo "=========================================================="

# 1. Verification
if ! command -v docker &> /dev/null; then
    echo "Warning: 'docker' command is not found. Please install Docker before running the containers."
fi

# 2. Stop native host services to prevent database writes
echo "Stopping local systemd services (sonarr, radarr, prowlarr, plexmediaserver, sabnzbdplus)..."
sudo systemctl stop sonarr radarr prowlarr plexmediaserver sabnzbdplus 2>/dev/null || true
# Stop user-instantiated sabnzbdplus service if running
sudo systemctl stop sabnzbdplus@* 2>/dev/null || true

# 3. Create Docker config directories
echo "Creating config directories in ./arr-stack/config/..."
mkdir -p ./arr-stack/config/{sonarr,radarr,prowlarr,sabnzbd,plex}

# 4. Copy configuration data
echo "Copying application data from /var/lib/ to ./arr-stack/config/..."
if [ -d "/var/lib/sonarr" ]; then
    sudo cp -a /var/lib/sonarr/. ./arr-stack/config/sonarr/
    echo "✓ Copied Sonarr configuration."
else
    echo "✗ /var/lib/sonarr not found. Skipping."
fi

if [ -d "/var/lib/radarr" ]; then
    sudo cp -a /var/lib/radarr/. ./arr-stack/config/radarr/
    echo "✓ Copied Radarr configuration."
else
    echo "✗ /var/lib/radarr not found. Skipping."
fi

if [ -d "/var/lib/prowlarr" ]; then
    sudo cp -a /var/lib/prowlarr/. ./arr-stack/config/prowlarr/
    echo "✓ Copied Prowlarr configuration."
else
    echo "✗ /var/lib/prowlarr not found. Skipping."
fi

if [ -d "/var/lib/plexmediaserver/Library/Application Support/Plex Media Server" ]; then
    echo "Copying Plex Media Server data (this may take a minute)..."
    sudo mkdir -p "./arr-stack/config/plex/Library/Application Support"
    sudo cp -a "/var/lib/plexmediaserver/Library/Application Support/Plex Media Server" "./arr-stack/config/plex/Library/Application Support/"
    echo "✓ Copied Plex configuration."
else
    echo "✗ Plex database not found. Skipping."
fi

if [ -d "$HOME/.sabnzbd" ]; then
    sudo cp -a "$HOME/.sabnzbd/." ./arr-stack/config/sabnzbd/
    # Patch SABnzbd's host whitelist so Docker containers can communicate with it
    if [ -f "./arr-stack/config/sabnzbd/sabnzbd.ini" ]; then
        sudo sed -i 's/^host_whitelist = \(.*\)/host_whitelist = \1, sabnzbd, sabnzbd:8080/' ./arr-stack/config/sabnzbd/sabnzbd.ini
    fi
    echo "✓ Copied and patched SABnzbd configuration."
else
    echo "✗ SABnzbd configuration not found. Skipping."
fi

# 5. Fix permissions for Docker
# Docker container services run as PUID/PGID (usually 1000:1000). We set ownership to the current host user.
USER_UID=$(id -u)
USER_GID=$(id -g)
echo "Fixing permissions on copied configurations to match current user ($USER_UID:$USER_GID)..."
sudo chown -R "$USER_UID":"$USER_GID" ./arr-stack/config

# Remove pid files to prevent startup locks in docker
find ./arr-stack/config/ -name "*.pid" -type f -delete 2>/dev/null || true

# 5b. Fix ownership of pre-existing media library files
# Files created by old native system users (sonarr, radarr, etc.) will have a different
# UID than the Docker containers (which run as PUID/PGID = current user). This causes
# "Access to path is denied" errors when the arr apps try to delete or move those files.
MEDIA_ROOT="${MEDIA_ROOT:-/mnt/media}"
if [ -d "$MEDIA_ROOT" ]; then
    echo "Fixing ownership of pre-existing media files under $MEDIA_ROOT..."
    echo "(Only files/dirs not already owned by $USER_UID will be updated — this may take a moment on large libraries.)"
    sudo find "$MEDIA_ROOT" -not -user "$USER_UID" -exec chown "$USER_UID":"$USER_GID" {} +
    echo "✓ Media library ownership corrected to $USER_UID:$USER_GID."
else
    echo "✗ MEDIA_ROOT ($MEDIA_ROOT) not found. Skipping media ownership fix."
fi

# 6. Back up host Caddyfile
if [ -f "/etc/caddy/Caddyfile" ]; then
    echo "Backing up your host Caddyfile to ./configs/caddy/Caddyfile for Git tracking..."
    mkdir -p ./configs/caddy
    cp /etc/caddy/Caddyfile ./configs/caddy/Caddyfile
    # Sanitize private Tailscale domains to prevent leaking them to Git
    sed -i 's/[a-zA-Z0-9.-]\+\.ts\.net/your-media-center.ts.net/g' ./configs/caddy/Caddyfile
    echo "✓ Host Caddyfile backed up and sanitized successfully."
fi

# 7. Disable native host services so they don't start on reboot
echo "Disabling local systemd services to prevent startup conflicts..."
sudo systemctl disable sonarr radarr prowlarr plexmediaserver sabnzbdplus 2>/dev/null || true
sudo systemctl disable sabnzbdplus@* 2>/dev/null || true

# 8. Set up .env file if it doesn't exist
if [ ! -f "./arr-stack/.env" ]; then
    echo "Initializing .env file..."
    cp ./arr-stack/.env.example ./arr-stack/.env
    # Dynamically set PUID and PGID
    sed -i "s/^PUID=.*/PUID=$USER_UID/" ./arr-stack/.env
    sed -i "s/^PGID=.*/PGID=$USER_GID/" ./arr-stack/.env
    
    # Dynamically set TZ based on host
    if command -v timedatectl >/dev/null 2>&1; then
        HOST_TZ=$(timedatectl show -p Timezone --value 2>/dev/null)
    elif [ -f "/etc/timezone" ]; then
        HOST_TZ=$(cat /etc/timezone)
    fi
    if [ -n "$HOST_TZ" ]; then
        sed -i "s|^TZ=.*|TZ=$HOST_TZ|" ./arr-stack/.env
        echo "✓ Created ./arr-stack/.env with your PUID=$USER_UID, PGID=$USER_GID, and TZ=$HOST_TZ."
    else
        echo "✓ Created ./arr-stack/.env with your PUID=$USER_UID and PGID=$USER_GID."
    fi
    
    echo ""
    echo "--- Stack Configuration ---"
    read -p "Enter the absolute path to your media directory [default: /mnt/media]: " USER_MEDIA_ROOT
    USER_MEDIA_ROOT=${USER_MEDIA_ROOT:-/mnt/media}
    
    if grep -q "^MEDIA_ROOT=" ./arr-stack/.env; then
        sed -i "s|^MEDIA_ROOT=.*|MEDIA_ROOT=$USER_MEDIA_ROOT|" ./arr-stack/.env
    else
        echo "MEDIA_ROOT=$USER_MEDIA_ROOT" >> ./arr-stack/.env
    fi
    echo "✓ Set MEDIA_ROOT=$USER_MEDIA_ROOT in .env"
    echo "---------------------------"
    echo ""
fi

echo "=========================================================="
echo "Migration complete! Here are your next steps:"
echo "1. Verify directories under your MEDIA_ROOT."
echo "2. Build/run the Docker stack:"
echo "   cd arr-stack"
echo "   docker compose up -d"
echo "3. Verify your services are running at their normal ports."
echo "=========================================================="

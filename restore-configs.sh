#!/bin/bash
# restore-configs.sh - Restore the config directory from a backup tarball in /mnt/media/Backups/
# Run this script from the root of the server-infra repository.

set -e

BACKUP_DIR="/mnt/media/Backups"

echo "=========================================================="
echo "Starting Arr Stack Config Restoration..."
echo "=========================================================="

if [ ! -d "./arr-stack" ]; then
    echo "Error: Please run this script from the root of the server-infra repository."
    exit 1
fi

# Find the latest backup
LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/arr-stack-config-*.tar.gz 2>/dev/null | head -n 1)

if [ -z "$LATEST_BACKUP" ]; then
    echo "Error: No backup file found in $BACKUP_DIR matching 'arr-stack-config-*.tar.gz'"
    exit 1
fi

echo "Found latest backup: $LATEST_BACKUP"
read -p "Are you sure you want to restore this backup? This will overwrite your current configs! (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Restoration cancelled."
    exit 0
fi

# 1. Stop stack
echo "Stopping Docker containers..."
sudo docker compose -f ./arr-stack/docker-compose.yml down || true

# 2. Extract backup
echo "Extracting backup to ./arr-stack/..."
# Remove current config directory to prevent old files lingering
sudo rm -rf ./arr-stack/config
sudo tar -xzf "$LATEST_BACKUP" -C ./arr-stack/

# 3. Fix permissions
USER_UID=$(id -u)
USER_GID=$(id -g)
echo "Fixing permissions to match current user ($USER_UID:$USER_GID)..."
sudo chown -R "$USER_UID":"$USER_GID" ./arr-stack/config

# Remove pid files to prevent startup locks in docker
find ./arr-stack/config/ -name "*.pid" -type f -delete 2>/dev/null || true

# 4. Start containers
echo "Starting Docker containers..."
sudo docker compose -f ./arr-stack/docker-compose.yml up -d

echo "=========================================================="
echo "Restoration complete! All services started."
echo "=========================================================="

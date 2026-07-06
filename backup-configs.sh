#!/bin/bash
# backup-configs.sh - Back up the Docker Compose config directory to /mnt/media/Backups/
# Run this script from the root of the server-infra repository.

set -e

BACKUP_DIR="/mnt/media/Backups"
BACKUP_FILE="$BACKUP_DIR/arr-stack-config-$(date +%F).tar.gz"

echo "=========================================================="
echo "Starting Arr Stack Config Backup..."
echo "=========================================================="

if [ ! -d "./arr-stack" ]; then
    echo "Error: Please run this script from the root of the server-infra repository."
    exit 1
fi

# 1. Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# 2. Stop containers briefly to prevent writes during backup (critical for SQLite database integrity)
echo "Stopping Docker containers to ensure consistent database states..."
sudo docker compose -f ./arr-stack/docker-compose.yml stop

# 3. Create tarball (exclusing Plex Cache to save space and time)
echo "Archiving configs to $BACKUP_FILE (this may take a moment)..."
sudo tar --exclude='plex/Library/Application Support/Plex Media Server/Cache' \
         -czf "$BACKUP_FILE" -C ./arr-stack config

# 4. Start containers back up
echo "Restarting Docker containers..."
sudo docker compose -f ./arr-stack/docker-compose.yml start

echo "=========================================================="
echo "Backup complete! File saved to:"
echo "  $BACKUP_FILE"
echo "=========================================================="

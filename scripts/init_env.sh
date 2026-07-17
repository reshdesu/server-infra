#!/bin/bash
# scripts/init_env.sh - Initializes the Docker .env file for the arr-stack
# Can be run safely on its own.

# Resolve absolute path to the repository root
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$REPO_DIR/arr-stack/.env"
EXAMPLE_FILE="$REPO_DIR/arr-stack/.env.example"

if [ ! -f "$ENV_FILE" ]; then
    echo "Initializing Docker .env file for arr-stack..."
    USER_UID=$(id -u)
    USER_GID=$(id -g)
    cp "$EXAMPLE_FILE" "$ENV_FILE"
    
    # Dynamically set PUID and PGID
    sed -i "s/^PUID=.*/PUID=$USER_UID/" "$ENV_FILE"
    sed -i "s/^PGID=.*/PGID=$USER_GID/" "$ENV_FILE"
    
    # Dynamically set TZ based on host
    if command -v timedatectl >/dev/null 2>&1; then
        HOST_TZ=$(timedatectl show -p Timezone --value 2>/dev/null)
    elif [ -f "/etc/timezone" ]; then
        HOST_TZ=$(cat /etc/timezone)
    fi
    
    if [ -n "$HOST_TZ" ]; then
        sed -i "s|^TZ=.*|TZ=$HOST_TZ|" "$ENV_FILE"
        echo "✓ Created arr-stack/.env with your PUID=$USER_UID, PGID=$USER_GID, and TZ=$HOST_TZ."
    else
        echo "✓ Created arr-stack/.env with your PUID=$USER_UID and PGID=$USER_GID."
    fi
    
    echo ""
    echo "--- Stack Configuration ---"
    # If a non-interactive shell or TEST_MEDIA_ROOT is set, use it to bypass prompt
    if [ -n "$TEST_MEDIA_ROOT" ]; then
        USER_MEDIA_ROOT=$TEST_MEDIA_ROOT
    else
        # Try to use whiptail for a beautiful TUI popup, fallback to bash read if not installed
        if command -v whiptail >/dev/null 2>&1 && [ -z "$DISABLE_WHIPTAIL" ]; then
            USER_MEDIA_ROOT=$(whiptail --title "Odin Media Server" --inputbox "Enter the absolute path to your media directory:" 10 60 "/mnt/media" 3>&1 1>&2 2>&3)
            if [ $? -ne 0 ]; then
                USER_MEDIA_ROOT="/mnt/media" # Fallback if user hits Cancel or ESC
            fi
            # Clear the screen slightly after whiptail to keep terminal clean
            clear
        else
            read -p "Enter the absolute path to your media directory [default: /mnt/media]: " USER_MEDIA_ROOT
        fi
    fi
    USER_MEDIA_ROOT=${USER_MEDIA_ROOT:-/mnt/media}
    
    if grep -q "^MEDIA_ROOT=" "$ENV_FILE"; then
        sed -i "s|^MEDIA_ROOT=.*|MEDIA_ROOT=$USER_MEDIA_ROOT|" "$ENV_FILE"
    else
        echo "MEDIA_ROOT=$USER_MEDIA_ROOT" >> "$ENV_FILE"
    fi
    echo "✓ Set MEDIA_ROOT=$USER_MEDIA_ROOT in .env"
    echo "---------------------------"
    echo ""
else
    echo "ℹ arr-stack/.env already exists. Skipping initialization."
fi

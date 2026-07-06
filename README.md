# Server Infrastructure Configuration

This repository holds the configurations, scripts, and system service definitions required to set up and maintain our production web servers (Caddy) in a standard or Tailscale-secured environment.

## Directory Layout
* [configs/](./configs/) - Configuration files for Caddy.
* [systemd/](./systemd/) - Systemd service unit files.
* [certs/](./certs/) - Secure storage instructions for TLS/SSL certificates (ignored by Git).
* [arr-stack/](./arr-stack/) - Docker Compose configurations for the Servarr system (Sonarr, Radarr, Prowlarr, Plex, SABnzbd, etc.).
* [dashboard/](./dashboard/) - The Odin Media Center dashboard files.
* [.githooks/](./.githooks/) - Git hook configurations to automatically prevent committing secrets and private Tailscale domains.
* [setup.sh](./setup.sh) - Bash script to automate installation and deployment.
* [migrate.sh](./migrate.sh) - Bash script to migrate host systemd Arr configurations to the Docker stack.
* [backup-configs.sh](./backup-configs.sh) - Bash script to back up Docker container configurations to `/mnt/media/Backups/`.
* [restore-configs.sh](./restore-configs.sh) - Bash script to restore Docker container configurations from `/mnt/media/Backups/`.

## Restoration / Setup Instructions
To restore the server configuration on a clean machine:

1. Clone or copy this repository to the server.
2. Run the setup script:
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```
3. Run `sudo tailscale up` to authenticate the node on your Tailscale network and allow Caddy to automatically manage SSL/TLS certificates.


## Migration Instructions (Local Systemd to Docker Compose)
If you are already running Sonarr, Radarr, and Prowlarr locally as native `systemd` services and want to migrate them seamlessly to this Docker stack without losing database histories, API keys, or indexers:

1. Run the migration script:
   ```bash
   ./migrate.sh
   ```
2. Run the Docker Compose stack:
   ```bash
   cd arr-stack
   docker compose up -d
   ```

## Backup & Restoration Instructions (For config databases and Plex metadata)
To make your server setup fully replicable and protect it against data loss:

1. **Create a Backup**:
   Run the backup script to safely stop containers, archive configs (excluding cache to save space), and save a timestamped archive to `/mnt/media/Backups/`:
   ```bash
   ./backup-configs.sh
   ```
2. **Restore a Backup (on a Clean Server)**:
   Ensure you have cloned this repository and your `/mnt/media/` folder is restored/mounted. Then run:
   ```bash
   ./restore-configs.sh
   ```
   This will stop the containers, restore the configuration databases, reset permissions, and spin up the Docker stack again.



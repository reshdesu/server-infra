# Server Infrastructure Configuration

This repository holds the configurations, scripts, and system service definitions required to set up and maintain our production web servers (Caddy or Nginx) in an air-gapped or standard environment.

## Directory Layout
* `configs/` - Configuration files for Caddy and Nginx.
* `systemd/` - Systemd service unit files.
* `certs/` - Secure storage instructions for TLS/SSL certificates (ignored by Git).
* `setup.sh` - Bash script to automate installation and deployment.

## Restoration / Setup Instructions
To restore the server configuration on a clean machine:

1. Clone or copy this repository to the server.
2. Put your SSL certificate (`.pem`, `.crt`) and private key (`.key`) files in `/etc/ssl/private/` and `/etc/ssl/certs/` (or update paths in `configs/caddy/Caddyfile` or `configs/nginx/nginx.conf`).
3. Run the setup script:
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

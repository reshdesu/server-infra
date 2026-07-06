# Antigravity Brain: System Infrastructure Memories

This folder holds project-specific memory files to help AI coding assistants (like Antigravity) understand the system design, environment details, and choices made during the development of this repository.

---

## 1. System Environment
* **Host OS**: Ubuntu Linux
* **Host User**: `reshdesu` (UID: `1000`, GID: `1000`)
* **Tailscale Domain**: `odin.tail04f242.ts.net` (Resolves to local IP `100.89.25.41` on the Tailnet)
* **Media Root**: `/mnt/media/`
  * Subdirectories:
    * `/mnt/media/TV` (TV Library)
    * `/mnt/media/Movies` (Movies Library)
    * `/mnt/media/downloads` (Download destination)
    * `/mnt/media/Backups` (Backup vault)

---

## 2. Infrastructure Architecture
* **Reverse Proxy**: Caddy (native Systemd service running on the host via `/usr/bin/caddy`).
  * SSL certificates are obtained dynamically from the local Tailscale socket (`/var/run/tailscale/tailscaled.sock`).
  * Caddyfile configuration location: `/etc/caddy/Caddyfile`.
* **Arr Stack**: Standardized on Docker Compose under `arr-stack/`.
  * **Plex**: Configured in `network_mode: host` for native casting discovery, with `/dev/dri` GPU pass-through for hardware transcoding.
  * **SABnzbd (Usenet)**: Bound to port `8080`.
  * **qBittorrent (Torrents)**: Optional service configured under the `torrent` compose profile (port `8082` Web UI, disabled by default).
  * **Sonarr, Radarr, Prowlarr, Bazarr**: Configured inside compose, using subpath reverse proxies via Caddy.

---

## 3. Automation Scripts
* **[`setup.sh`](./setup.sh)**: Installs Tailscale, configures native Caddy systemd overrides, deploys the landing dashboard, and automatically resolves the host's actual Tailscale domain name to replace the Caddyfile placeholder.
* **[`migrate.sh`](./migrate.sh)**: Safely shuts down host native services, copies existing database configurations to Docker volume bindings, sanitizes the domain name for Git backups, and fixes permissions.
* **[`backup-configs.sh`](./backup-configs.sh)** & **[`restore-configs.sh`](./restore-configs.sh)**: Gracefully stop compose, archive/restore configurations under `/mnt/media/Backups/` (excluding massive Plex caches), and restart services.

---

## 4. Git Security & Sanitation Policies
* **Private Repository Rules**: Keep all usernames (`reshdesu`), local directories, and tailnet domains (`*.ts.net`) out of Git-tracked files.
* **Sanitation Placeholder**: Use `your-media-center.ts.net` in `configs/caddy/Caddyfile` and `$HOME` in script files.
* **Security Scanning**:
  * **Local pre-commit hook** (`.githooks/pre-commit`): Automatically blocks commits containing private keys, certificates, raw XML API keys, or unsanitized `.ts.net` domains.
  * **Global Gitleaks hook**: Configured globally (`~/.git-templates/hooks/pre-commit`) to scan all other projects on the machine using Gitleaks.

---

## 5. Dashboard Configuration
* Served statically at `/var/www/dashboard/`.
* Uses horizontal space-efficient cards with dynamic status checks checking `/service/` subpaths over Caddy (avoids CORS issues).
* Contains an `enabledServices` toggle array to selectively show/hide cards (e.g. `qbittorrent: false` by default).

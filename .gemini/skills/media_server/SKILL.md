---
name: odin-media-server
description: Project-specific skill for managing, debugging, and maintaining the Odin Media Server stack, Caddy reverse proxies, backups, and security hooks.
---

# Odin Media Server Management Skill

This skill provides step-by-step instructions, commands, and best practices for managing, testing, and debugging the Odin Media Server ecosystem.

---

## 1. Stack Administration

### Start/Recreate Stack (Default Usenet-only)
Runs the core stack (Plex, Sonarr, Radarr, Prowlarr, Bazarr, SABnzbd) and leaves qBittorrent out:
```bash
cd arr-stack
sudo docker compose up -d
```

### Start Stack with Torrent Support (qBittorrent)
Explicitly spins up the optional `torrent` profile container:
```bash
cd arr-stack
sudo docker compose --profile torrent up -d
```
*Alternatively, uncomment `COMPOSE_PROFILES=torrent` inside the local `arr-stack/.env` file and run standard compose up.*

### View Container Logs
```bash
cd arr-stack
sudo docker compose logs -f <service-name>
# e.g., sudo docker compose logs -f plex
```

---

## 2. Backup & Restoration

### Run Automated Backup
Suspends the containers, packages config files (excluding Plex cache), and places a timestamped archive in `/mnt/media/Backups/`:
```bash
sudo ./backup-configs.sh
```

### Run Automated Restoration
Restores the config files from the latest archive in `/mnt/media/Backups/` back to the active Docker volumes:
```bash
sudo ./restore-configs.sh
```

---

## 3. Caddy & Homepage Dashboard

### Update Homepage or Caddy Config
After modifying `configs/caddy/Caddyfile` or editing `dashboard/index.html`:
```bash
sudo ./setup.sh
sudo systemctl reload caddy
```

### Verify SSL Status
Test if Caddy is serving HTTPS and resolving Tailscale certificates properly:
```bash
curl -vk https://your-media-center.ts.net/
```

---

## 4. Developer & Steering Rules

1. **Host Username & Path Privacy**:
   * NEVER commit `/home/reshdesu` directly to files in Git.
   * ALWAYS use `$HOME` inside scripts, `~/` in documentation, or path parameters.
2. **Tailscale Address Privacy**:
   * NEVER commit your actual tailnet address (`odin.tail04f242.ts.net`) directly to Git.
   * ALWAYS use the placeholder `your-media-center.ts.net` inside `configs/caddy/Caddyfile`.
   * The `setup.sh` deployment script will automatically resolve the host's actual tailnet address and swap it during host deployment.
3. **Caddy Executable Path**:
   * Caddy on this system is installed natively via APT. The binary path is `/usr/bin/caddy`.
   * Do not change caddy service definitions to `/usr/local/bin/caddy`.
4. **Git Hook Configuration**:
   * Local hooks are located in `.githooks/` and must be mapped using `git config core.hooksPath .githooks` (done automatically by `setup.sh`).

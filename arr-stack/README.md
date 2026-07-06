# Arr System Stack (Servarr Media Suite)

This directory contains the configurations and Docker Compose setup for a complete self-hosted media management stack.

## Architecture & Layout

The services configured in `docker-compose.yml` are:
*   **qBittorrent** (port `8080`): Torrent downloader.
*   **Prowlarr** (port `9696`): Indexer/tracker manager. Synchronizes indexers automatically to Radarr and Sonarr.
*   **Sonarr** (port `8989`): Smart TV series downloader.
*   **Radarr** (port `7878`): Smart movie downloader.
*   **Bazarr** (port `6767`): Companion application to download subtitles automatically.
*   **Plex Media Server** (Runs natively on host port `32400`): Media streaming server (already configured on host).

### TRaSH Guides Volume Structure (Crucial for Hardlinks)

To prevent slow file copies and high disk usage, this setup uses a unified root path `/data` mapped from the host's `MEDIA_ROOT`. This allows containers to perform atomic file movements and hardlinks across directories.

Ensure your `MEDIA_ROOT` folder contains the following subfolders:
```
data/
├── torrents/
│   ├── movies/
│   └── tv/
└── media/
    ├── movies/
    └── tv/
```

Inside the containers, this is mapped as:
*   Downloads download to `/data/torrents/...`
*   Library stores in `/data/media/...`
Because they share the `/data` mount point, Sonarr and Radarr can create instant hardlinks from `torrents` to `media`, allowing you to keep seeding in the torrent client while naming/organizing the file in your media player library without taking up double the storage.

---

## Setup & Running

1.  **Copy Environment File:**
    ```bash
    cp .env.example .env
    ```
2.  **Edit Environment Values:**
    Check your local system user and group IDs:
    ```bash
    id
    ```
    Update `PUID`, `PGID`, `TZ`, and `MEDIA_ROOT` in the newly created `.env` file.

3.  **Prepare Directories:**
    Create the media structure under your configured `MEDIA_ROOT` (e.g. `/mnt/media`):
    ```bash
    mkdir -p /mnt/media/{torrents/{movies,tv},media/{movies,tv}}
    ```

4.  **Start the Stack:**
    ```bash
    docker compose up -d
    ```

---

## Reverse Proxy Configuration

To expose these services using your host web server (Caddy), you can create subdomains pointing to the docker host ports.

See the configuration templates in [configs/caddy/Caddyfile](../configs/caddy/Caddyfile) for reverse-proxy setup examples.

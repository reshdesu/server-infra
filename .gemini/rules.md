# Workspace Rules for Gemini Assistant

As an AI assistant working on this project, you must adhere to the following workspace rules at all times.

---

## 1. Project Steering Guidelines

*   **Consult Memories & Skills**: Before proposing any configuration edits, directory modifications, or script refactors, you **MUST** read [`.gemini/memories.md`](./memories.md) and the custom skill instructions in [`.gemini/skills/media_server/SKILL.md`](./skills/media_server/SKILL.md).
*   **Privacy Sanitation**:
    *   **Do NOT leak the host username** (`reshdesu`) into Git-tracked codebase files. Always use `$HOME` or relative references.
    *   **Do NOT leak the private Tailscale domain** (your-actual-tailscale-address.ts.net) into Git-tracked configurations. Use the `your-media-center.ts.net` placeholder inside `configs/caddy/Caddyfile`. The deployment script `setup.sh` handles replacing it dynamically.
*   **Keep it Lightweight (No Framework Bloat)**:
    *   The Odin landing page dashboard is built with pure, lightweight HTML, CSS, and Vanilla JavaScript.
    *   Do **NOT** introduce heavy build pipelines or JavaScript frameworks (e.g., Svelte, React, Next.js, Vite) for this static launcher homepage. It must remain immediately deployable via simple copying.
*   **Caddy Binary Location**: The Caddy binary is located at `/usr/bin/caddy` (installed via native Ubuntu package manager). Do not reference `/usr/local/bin/caddy` in systemd services.

---

## 2. Docker & Service Guidelines

*   **Plex Configuration**: Plex must remain in `network_mode: host` to allow native casting, with GPU device pass-through (`/dev/dri`) enabled.
*   **Optional Torrent Profile**: Keep `qbittorrent` configured under the `torrent` profile in `docker-compose.yml` so it remains optional and disabled by default.
*   **SQLite Database consistency**: When running backups, ensure you suspend container writes (`docker compose stop`) before compressing sqlite databases under `/config/` to prevent database corruption.

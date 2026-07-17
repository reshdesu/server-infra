# Odin Media Server Infrastructure

![Coverage](https://img.shields.io/badge/Coverage-100%25-brightgreen.svg)

This repository is the central hub for configuring, deploying, and maintaining the **Odin Media Server**. It leverages an enterprise-grade DevOps architecture to guarantee perfect reproducibility, disaster recovery, and unbreakable code quality through isolated CI sandboxes.

## Core Features
* 🚀 **Automated Provisioning**: One-command server setup using beautifully rendered interactive TUI (`whiptail`) wizards.
* 🐳 **Dockerized Stack**: Fully containerized media services (Plex, Sonarr, Radarr, Prowlarr, SABnzbd).
* 🔒 **Zero-Config Networking**: Tailscale mesh network routing with automatic Let's Encrypt SSL/TLS certificates via Caddy.
* 💾 **Automated Disaster Recovery**: Self-rotating, automated daily cron backups of all application databases.
* 🛡️ **Bulletproof CI/CD**: A fully isolated Docker-in-Docker testing harness that enforces strict 100% test coverage before any code is committed.

---

## Directory Layout
* `configs/` - Configuration files for Caddy reverse proxy.
* `systemd/` - Systemd service unit files.
* `arr-stack/` - Docker Compose configurations for the Servarr system.
* `dashboard/` - The static Odin Media Center dashboard files.
* `scripts/` - Core utility scripts for dynamic `.env` injection.
* `tests/` - The Docker-in-Docker CI testing harness and mocked binaries.
* `.githooks/` - Pre-commit Git hooks for security scanning and 100% test coverage enforcement.

---

## Command Reference (Makefile)
The entire infrastructure can be managed using simple `make` commands:

| Command | Description |
| :--- | :--- |
| `make setup` | Run the interactive installation wizard to provision a clean server. |
| `make migrate` | Safely migrate existing native `systemd` services to the Docker Compose stack. |
| `make backup` | Trigger an immediate manual backup of the Docker config databases. |
| `make restore` | Restore your server from the latest database backup. |
| `make test` | Spin up the Docker CI sandbox and execute the regression test suite. |
| `make coverage`| Run tests inside the Docker CI sandbox while tracking code coverage using `kcov`. |

---

## Infrastructure Usage

### 1. New Server Setup
To provision a brand new server from scratch:
```bash
make setup
```
This will launch an interactive wizard that installs Tailscale, configures the Caddy reverse proxy, injects dynamic variables (PUID/PGID/Timezone), schedules your daily cron backups, and initializes the Docker stack.

*Note: The script gracefully degrades to standard terminal input if run on an ultra-minimal headless OS without `whiptail`.*

### 2. Migrating from Native Systemd to Docker
If you are currently running native `systemd` instances of Sonarr/Radarr/Prowlarr and want to migrate to the Docker stack without losing your database history:
```bash
make migrate
```
This will safely stop your native background services, port your configuration files into the Docker mount points, fix file ownership permissions, and archive your host Caddyfile.

### 3. Backup and Disaster Recovery
Backups are automatically triggered daily at 3:00 AM via cron. To trigger one manually:
```bash
make backup
```
To restore a catastrophic server failure from your `/mnt/media/Backups` directory:
```bash
make restore
```

---

## Development & CI Pipeline

This repository uses extremely strict CI enforcement. **No code can be committed unless it achieves 100% test coverage.**

### 1. The Sandbox
When you run `make test` or `make coverage`, the system automatically builds an isolated, ephemeral `ubuntu:22.04` Docker container. It intercepts and safely mocks destructive system binaries (like `sudo`, `systemctl`, `timedatectl`, and `tailscale`) so that our host-level Bash scripts can be rigorously tested without actually tearing down your active media server. 

### 2. Pre-Commit Hooks
When you type `git commit`, our `.githooks/pre-commit` hook is triggered automatically. It spins up the Docker sandbox, runs the entire test suite, and analyzes the output with `kcov`. If a single line of logic is missing a test, Git will block the commit.

### 3. Commit Message Standards
We strictly adhere to Conventional Commits. Commits must be formatted as:
`type(scope): description`
Valid types: `feat`, `fix`, `chore`, `ci`, `docs`, `refactor`, `style`, `test`.

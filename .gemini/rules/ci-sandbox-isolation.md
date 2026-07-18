# Rule: CI/CD Sandbox Isolation and Data Protection

## 1. Never Mount Host Volumes for Destructive Testing
When writing `Makefile` commands or bash scripts that execute automated integration tests (e.g., `make test`, `make coverage`), you must **never** use Docker volume mounts (e.g., `-v $(PWD):/workspace`) if the test suite contains destructive logic (like `rm -rf`, `mv`, or `chown`). 
Mounting the host directory exposes the user's active development or production environment to data destruction or permission corruption.

## 2. Use Sterile `COPY` Commands Instead
To safely pass code into a Docker CI Sandbox, you must configure the `Dockerfile` to perform a sterile `COPY . /workspace`. 
This guarantees the test runner operates in a one-way mirror (ephemeral overlay filesystem). The Sandbox can read the codebase, but any destructive actions performed inside the Sandbox will safely disappear when the container exits without touching the host's hard drive.

## 3. Utilize `.dockerignore` for Live Data
When using `COPY . /workspace`, you must ensure that any directories containing live databases or user configuration files (e.g., `arr-stack/config/`) are explicitly excluded in the `.dockerignore` file. This prevents the Sandbox from accidentally copying gigabytes of active host data into the test environment, which would cause the CI pipeline to hang.

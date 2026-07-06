# Certificates Directory

**DO NOT COMMIT PRIVATE KEYS OR CERTIFICATES TO GIT.**

This directory is git-ignored (except for this README.md file). 

### How to install certificates:
1. Obtain your certificates from your CA or certificate generator.
2. Place the certificate file (e.g., `domain.crt` or `domain.pem`) and the private key (e.g., `domain.key`) in this folder on the target machine, or in the standard system directory `/etc/ssl/private/`.
3. Reference these local paths in your server configuration files (`Caddyfile` or `nginx.conf`).

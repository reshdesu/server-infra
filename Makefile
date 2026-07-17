# Odin Media Server - Infrastructure Makefile

.PHONY: help setup migrate backup restore test

help: ## Show this help message
	@echo "Odin Media Server - Infrastructure Management"
	@echo "-------------------------------------------"
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

setup: ## Run the initial clean setup (Caddy, Tailscale, Dashboard)
	@chmod +x setup.sh
	@./setup.sh

migrate: ## Migrate native systemd Arr services to Docker Compose
	@chmod +x migrate.sh
	@./migrate.sh

backup: ## Backup Docker container databases to /mnt/media/Backups
	@chmod +x backup-configs.sh
	@./backup-configs.sh

restore: ## Restore Docker container databases from /mnt/media/Backups
	@chmod +x restore-configs.sh
	@./restore-configs.sh

test: ## Run the local regression test suite
	@chmod +x tests/test_init_env.sh
	@./tests/test_init_env.sh

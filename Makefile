# Media Server Infra - Infrastructure Makefile

.PHONY: help setup migrate backup restore test coverage

help: ## Show this help message
	@echo "Media Server Infra - Infrastructure Management"
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

test: ## Run the full suite of regression and integration tests securely inside a Docker CI sandbox
	@echo "Building isolated Docker CI sandbox..."
	@sudo docker build -t odin-ci-sandbox -f tests/Dockerfile . > /dev/null
	@echo "Running test suite inside sandbox..."
	@sudo docker run --rm --security-opt seccomp=unconfined odin-ci-sandbox /bin/bash ./tests/docker_test_runner.sh

coverage: ## Run all tests inside the Docker CI sandbox with kcov coverage tracking
	@echo "Building isolated Docker CI sandbox for coverage..."
	@sudo docker build -t odin-ci-sandbox -f tests/Dockerfile . > /dev/null
	@echo "Running code coverage analysis inside sandbox..."
	@mkdir -p coverage
	@sudo docker run --rm --security-opt seccomp=unconfined -v $(PWD)/coverage:/workspace/coverage odin-ci-sandbox /bin/bash -c "kcov --clean --include-path=/workspace coverage ./tests/docker_test_runner.sh > /dev/null 2>&1"
	@sudo chown -R $$(id -u):$$(id -g) coverage
	@echo "\033[0;32m[SUCCESS] Full repository coverage analysis complete. See coverage/index.html for the detailed report.\033[0m"

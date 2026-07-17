#!/bin/bash
# tests/docker_test_runner.sh - Runs inside the isolated Ubuntu CI Docker sandbox

set -e

echo "=========================================="
echo " Starting Full Suite Docker CI Harness... "
echo "=========================================="

# Create mock test environments
export TEST_MEDIA_ROOT="/mnt/media"
mkdir -p /mnt/media/Backups

# 1. Test init_env.sh (Unit Tests)
echo "--- Running init_env.sh tests ---"
./tests/test_init_env.sh

# 2. Test setup.sh (Integration Test)
echo "--- Running setup.sh integration test ---"
export DISABLE_WHIPTAIL=1
./setup.sh > /dev/null

# 3. Test migrate.sh (Integration Test)
echo "--- Running migrate.sh integration test ---"
# Create a dummy native systemd service so migrate.sh has something to migrate
mkdir -p /etc/systemd/system /var/lib/sonarr /var/lib/radarr /var/lib/prowlarr
touch /etc/systemd/system/sonarr.service /etc/systemd/system/radarr.service /etc/systemd/system/prowlarr.service
./migrate.sh > /dev/null

# 4. Test backup & restore scripts
echo "--- Running Backup/Restore integration tests ---"
mkdir -p ./arr-stack/config
./backup-configs.sh > /dev/null
echo 'y' | ./restore-configs.sh > /dev/null

echo ""
echo "=========================================="
echo " All Tests Passed in Sandbox Successfully!"
echo "=========================================="

#!/bin/bash
# tests/test_init_env.sh - Regression test for .env initialization

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

pass() { echo -e "${GREEN}PASS${NC}: $1"; }
fail() { echo -e "${RED}FAIL${NC}: $1"; exit 1; }

echo "=== Running init_env.sh Regression Tests ==="

# 1. Set up dummy repository structure
TEST_DIR=$(mktemp -d)
mkdir -p "$TEST_DIR/arr-stack"
mkdir -p "$TEST_DIR/scripts"

# Copy the script to test
cp ./scripts/init_env.sh "$TEST_DIR/scripts/"
chmod +x "$TEST_DIR/scripts/init_env.sh"

# Create a dummy .env.example
cat << 'EOF' > "$TEST_DIR/arr-stack/.env.example"
PUID=1000
PGID=1000
TZ=UTC
MEDIA_ROOT=/mnt/media
EOF

# 2. Run the script with simulated inputs
export TEST_MEDIA_ROOT="/mnt/custom/nas/plex"

# Run it
"$TEST_DIR/scripts/init_env.sh" > /dev/null

# 3. Assertions
ENV_FILE="$TEST_DIR/arr-stack/.env"

if [ ! -f "$ENV_FILE" ]; then
    fail ".env file was not created"
fi
pass ".env file was created"

if grep -q "PUID=$(id -u)" "$ENV_FILE"; then
    pass "PUID was correctly dynamically injected"
else
    fail "PUID injection failed"
fi

if grep -q "MEDIA_ROOT=/mnt/custom/nas/plex" "$ENV_FILE"; then
    pass "MEDIA_ROOT was correctly captured from prompt override and injected"
else
    fail "MEDIA_ROOT injection failed"
fi

if grep -q "TZ=" "$ENV_FILE" && ! grep -q "TZ=UTC" "$ENV_FILE"; then
    pass "Timezone was correctly dynamically injected"
else
    fail "Timezone injection failed"
fi

# Clean up
rm -rf "$TEST_DIR"
echo "=== All Tests Passed ==="

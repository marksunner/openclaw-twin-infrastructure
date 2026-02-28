#!/bin/bash
# Rescue a failed twin
# Reads configuration from config/twins.yaml

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config/twins.yaml"

TARGET=$1

if [ -z "$TARGET" ]; then
    echo "Usage: rescue-twin.sh <agent-name>"
    echo ""
    echo "Attempts to restart OpenClaw on the specified twin."
    echo "Configure targets in config/twins.yaml"
    exit 1
fi

# Check config exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file not found: $CONFIG_FILE"
    echo "Copy config/twins.example.yaml to config/twins.yaml and edit it."
    exit 1
fi

# Parse config (simple grep-based for portability)
# In production, use yq or similar
SSH_HOST=$(grep -A3 "^  $TARGET:" "$CONFIG_FILE" | grep "hostname:" | awk '{print $2}')
SSH_USER=$(grep -A3 "^  $TARGET:" "$CONFIG_FILE" | grep "username:" | awk '{print $2}')
OPENCLAW_PATH=$(grep -A3 "^  $TARGET:" "$CONFIG_FILE" | grep "openclaw_path:" | awk '{print $2}')

if [ -z "$SSH_HOST" ] || [ -z "$SSH_USER" ]; then
    echo "Error: Could not find configuration for '$TARGET'"
    echo "Check config/twins.yaml"
    exit 1
fi

SSH_TARGET="$SSH_USER@$SSH_HOST"

echo "🔧 Attempting to rescue $TARGET..."
echo "   Target: $SSH_TARGET"
echo ""

# Check reachability
echo "Step 1: Checking SSH connectivity..."
if ! ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$SSH_TARGET" "echo 'connected'" 2>/dev/null; then
    echo "❌ Cannot reach $TARGET via SSH"
    echo "   The machine may be powered off or network unreachable."
    echo "   Manual intervention required."
    exit 1
fi
echo "✓ SSH connection successful"
echo ""

# Check current state
echo "Step 2: Checking OpenClaw status..."
if ssh "$SSH_TARGET" "pgrep -f 'openclaw'" >/dev/null 2>&1; then
    echo "⚠ OpenClaw appears to be running"
    echo "  Proceeding with restart anyway..."
fi
echo ""

# Restart
echo "Step 3: Restarting OpenClaw..."
ssh "$SSH_TARGET" "cd $OPENCLAW_PATH && openclaw gateway restart" || true
echo ""

# Verify
echo "Step 4: Waiting for startup (30s)..."
sleep 30

if ssh "$SSH_TARGET" "pgrep -f 'openclaw'" >/dev/null 2>&1; then
    echo "✓ $TARGET is now running"
    echo ""
    echo "Rescue complete! 🎉"
else
    echo "⚠ $TARGET may not have started correctly"
    echo "  Check logs on the remote machine."
fi

#!/bin/bash
# Rescue a failed twin

set -e

TARGET=$1

if [ -z "$TARGET" ]; then
    echo "Usage: rescue-twin.sh [tars|case]"
    echo ""
    echo "Attempts to restart OpenClaw on the specified twin."
    exit 1
fi

case $TARGET in
  tars)
    SSH_HOST="tturing@192.168.1.178"
    ;;
  case)
    SSH_HOST="henryturing@192.168.1.240"
    ;;
  *)
    echo "Unknown twin: $TARGET"
    echo "Valid options: tars, case"
    exit 1
    ;;
esac

echo "🔧 Attempting to rescue $TARGET..."
echo ""

# Check reachability
echo "Step 1: Checking SSH connectivity..."
if ! ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no $SSH_HOST "echo 'connected'" 2>/dev/null; then
    echo "❌ Cannot reach $TARGET via SSH"
    echo "   The machine may be powered off or network unreachable."
    echo "   Manual intervention required."
    exit 1
fi
echo "✓ SSH connection successful"
echo ""

# Check current state
echo "Step 2: Checking OpenClaw status..."
if ssh $SSH_HOST "pgrep -f 'openclaw'" >/dev/null 2>&1; then
    echo "⚠ OpenClaw appears to be running"
    echo "  Proceeding with restart anyway..."
fi
echo ""

# Restart
echo "Step 3: Restarting OpenClaw..."
ssh $SSH_HOST "cd ~/clawd && openclaw gateway restart" || true
echo ""

# Verify
echo "Step 4: Waiting for startup (30s)..."
sleep 30

if ssh $SSH_HOST "pgrep -f 'openclaw'" >/dev/null 2>&1; then
    echo "✓ $TARGET is now running"
    echo ""
    echo "Rescue complete! 🎉"
else
    echo "⚠ $TARGET may not have started correctly"
    echo "  Check logs: ssh $SSH_HOST 'tail -50 ~/.config/openclaw/logs/openclaw.log'"
fi

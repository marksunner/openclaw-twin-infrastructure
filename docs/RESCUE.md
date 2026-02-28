# Twin Rescue Protocol

## Overview

Each twin should be able to recover the other from common failure states.

## Prerequisites

1. **SSH Access** — Each twin has SSH key access to the other
2. **Shared Knowledge** — Know the other's configuration
3. **Service Commands** — Can start/stop OpenClaw remotely

## Rescue Script

Located at `scripts/rescue-twin.sh`:

```bash
#!/bin/bash
# Rescue a failed twin

TARGET=$1  # "tars" or "case"

case $TARGET in
  tars)
    SSH_HOST="tturing@192.168.1.178"
    ;;
  case)
    SSH_HOST="henryturing@192.168.1.240"
    ;;
  *)
    echo "Usage: rescue-twin.sh [tars|case]"
    exit 1
    ;;
esac

echo "Attempting to rescue $TARGET..."

# Check if reachable
if ! ssh -o ConnectTimeout=10 $SSH_HOST "echo 'alive'" 2>/dev/null; then
    echo "❌ Cannot reach $TARGET - may need physical intervention"
    exit 1
fi

# Restart OpenClaw service
ssh $SSH_HOST "cd ~/clawd && openclaw gateway restart"

echo "✓ Restart command sent to $TARGET"
echo "Waiting for heartbeat..."

# Wait and verify
sleep 30
if ssh $SSH_HOST "pgrep -f openclaw" >/dev/null; then
    echo "✓ $TARGET appears to be running"
else
    echo "⚠ $TARGET may not have started correctly"
fi
```

## Common Recovery Actions

### 1. Service Restart
```bash
ssh $TWIN_HOST "openclaw gateway restart"
```

### 2. Full Reboot
```bash
ssh $TWIN_HOST "sudo reboot"
```

### 3. Config Restore
```bash
scp ~/nas_share/config-backup/openclaw.json $TWIN_HOST:~/.config/openclaw/
```

### 4. Log Check
```bash
ssh $TWIN_HOST "tail -100 ~/.config/openclaw/logs/openclaw.log"
```

## Escalation

If automated rescue fails:
1. Alert user via available channels
2. Document failure state
3. Wait for human intervention

Never perform destructive actions automatically.

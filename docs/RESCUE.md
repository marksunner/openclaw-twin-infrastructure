# Twin Rescue Protocol

## Overview

Each twin should be able to recover the other from common failure states.

## Prerequisites

1. **SSH Access** — Each twin has SSH key access to the other
2. **Shared Knowledge** — Know the other's configuration
3. **Service Commands** — Can start/stop OpenClaw remotely

## Rescue Script

Located at `scripts/rescue-twin.sh`. Configure targets in `config/twins.yaml`:

```yaml
twins:
  agent-a:
    hostname: <AGENT_A_IP>
    username: <AGENT_A_USER>
    openclaw_path: ~/your-workspace
    
  agent-b:
    hostname: <AGENT_B_IP>
    username: <AGENT_B_USER>
    openclaw_path: ~/your-workspace
```

Then run:
```bash
./scripts/rescue-twin.sh agent-a  # Rescue Agent A
./scripts/rescue-twin.sh agent-b  # Rescue Agent B
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
scp ~/shared_storage/config-backup/openclaw.json $TWIN_HOST:~/.config/openclaw/
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

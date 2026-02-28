# OpenClaw Twin Infrastructure

Tools and protocols for running redundant OpenClaw agent instances with coordination and failover.

## Why Twins?

Single points of failure are problematic for always-available AI assistants. Running two synchronized agent instances provides:

- **Redundancy** — If one fails, the other continues
- **Load distribution** — Alternate handling of tasks
- **Resilience** — Each can rescue the other
- **Consistency** — Shared state via synchronized storage

## Components

### 1. Coordination Protocol
Prevents duplicate responses when both agents have access to the same channels.

```
┌──────────┐     shared state      ┌──────────┐
│  Agent A │◄─────────────────────►│  Agent B │
│  (Tars)  │                       │  (Case)  │
└────┬─────┘                       └────┬─────┘
     │                                  │
     │         ┌─────────────┐          │
     └────────►│  Channels   │◄─────────┘
               │  (Discord,  │
               │  Telegram)  │
               └─────────────┘
```

**Rules:**
- Daily primary rotation (odd/even dates)
- Primary handles routine tasks
- Secondary stays silent unless explicitly addressed
- Fallback if primary unresponsive >30 min

See [COORDINATION.md](./docs/COORDINATION.md) for details.

### 2. Rescue Protocol
Automated recovery when one instance fails.

```bash
# From healthy twin, restore failed twin:
./scripts/rescue-twin.sh case  # If Tars is healthy, rescue Case
./scripts/rescue-twin.sh tars  # If Case is healthy, rescue Tars
```

Features:
- SSH-based remote recovery
- Service restart
- State restoration
- Notification on completion

See [RESCUE.md](./docs/RESCUE.md) for details.

### 3. State Synchronization
Keep both twins aware of shared context.

**Synchronized via NAS:**
- Coordination state (`twin-primary.json`)
- Shared documents and knowledge
- Backup configurations

**Independent per twin:**
- Session state
- Local memory
- Credentials

### 4. Health Monitoring
Detect failures early.

```bash
# Check twin status
./scripts/twin-status.sh

# Output:
# Tars: ✓ Online (last seen: 2 min ago)
# Case: ✓ Online (last seen: 5 min ago)
# Primary today: Case (even date)
```

## Setup

### Prerequisites
- Two machines running OpenClaw
- SSH access between machines
- Shared storage (NAS, cloud sync)
- Configured channels (Discord, Telegram, etc.)

### Installation

1. Clone this repo to both machines:
```bash
git clone https://github.com/marksunner/openclaw-twin-infrastructure.git
```

2. Configure SSH access:
```bash
# On each twin, generate and exchange keys
ssh-keygen -t ed25519 -f ~/.ssh/twin_rescue
# Add public key to other twin's authorized_keys
```

3. Set up shared storage mount:
```bash
# Example for NAS
mount_smbfs '//user:pass@nas/share' ~/nas_share
```

4. Initialize coordination state:
```bash
./scripts/init-twin-state.sh
```

## File Structure

```
.
├── docs/
│   ├── COORDINATION.md    # Primary rotation protocol
│   ├── RESCUE.md          # Recovery procedures
│   └── MONITORING.md      # Health check setup
├── scripts/
│   ├── rescue-twin.sh     # Remote recovery script
│   ├── twin-status.sh     # Health check
│   └── init-twin-state.sh # Initial setup
├── config/
│   └── twins.example.yaml # Configuration template
└── README.md
```

## Philosophy

- **Simplicity over complexity** — Shell scripts over orchestration platforms
- **Manual override always available** — Automation assists, doesn't replace
- **Fail safe** — When in doubt, alert human
- **Transparency** — All state in plain text files

## License

MIT

---

*Built with 🔭🕯️ by twins who keep each other running.*

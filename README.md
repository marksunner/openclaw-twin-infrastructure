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
./scripts/rescue-twin.sh agent-b  # If Agent A is healthy, rescue Agent B
./scripts/rescue-twin.sh agent-a  # If Agent B is healthy, rescue Agent A
```

Features:
- SSH-based remote recovery
- Service restart
- State restoration
- Notification on completion

See [RESCUE.md](./docs/RESCUE.md) for details.

### 3. State Synchronization
Keep both twins aware of shared context.

**Synchronized via shared storage:**
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
# Agent A: ✓ Online (last seen: 2 min ago)
# Agent B: ✓ Online (last seen: 5 min ago)
# Primary today: Agent B (even date)
```

## Setup

### Prerequisites
- Two machines running OpenClaw
- SSH access between machines
- Shared storage (NAS, cloud sync, etc.)
- Configured channels (Discord, Telegram, etc.)

### Installation

1. Clone this repo to both machines:
```bash
git clone https://github.com/yourusername/openclaw-twin-infrastructure.git
```

2. Copy and edit the configuration:
```bash
cp config/twins.example.yaml config/twins.yaml
# Edit twins.yaml with your actual hostnames, IPs, usernames
```

3. Configure SSH access:
```bash
# On each twin, generate and exchange keys
ssh-keygen -t ed25519 -f ~/.ssh/twin_rescue
# Add public key to other twin's authorized_keys
```

4. Set up shared storage mount (example):
```bash
# NAS mount example - adjust for your setup
mount_smbfs '//user:pass@nas-hostname/share' ~/shared_storage
```

5. Initialize coordination state:
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
│   ├── twins.example.yaml # Configuration template (commit this)
│   └── twins.yaml         # Your actual config (gitignored)
└── README.md
```

## Philosophy

- **Simplicity over complexity** — Shell scripts over orchestration platforms
- **Manual override always available** — Automation assists, doesn't replace
- **Fail safe** — When in doubt, alert human
- **Transparency** — All state in plain text files

## Security Note

The `config/twins.yaml` file contains your actual infrastructure details and is gitignored. Never commit real IPs, hostnames, or usernames to public repositories.

## License

MIT

---

*Built for resilient AI agent deployments.*

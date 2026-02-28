# Twin Coordination Protocol

## Overview

When multiple agents can see the same messages, we need rules to prevent:
- Duplicate responses
- Conflicting actions
- Wasted API calls

## Primary Rotation

Each day, one twin is designated "primary." This rotates automatically:

| Date | Primary | Secondary |
|------|---------|-----------|
| Odd (1, 3, 5...) | Agent A | Agent B |
| Even (2, 4, 6...) | Agent B | Agent A |

## State File

Located on shared storage (e.g., `~/nas_share/twin-primary.json`):

```json
{
  "date": "2026-02-28",
  "primary": "Case",
  "secondary": "Tars",
  "bothRespond": false,
  "lastUpdated": "2026-02-28T00:00:00Z"
}
```

## Response Rules

### Primary Agent
- Handles all routine messages
- Responds to general questions
- Performs scheduled tasks
- Updates shared state

### Secondary Agent
Responds only when:
1. **Explicitly named** — "Hey Tars, what do you think?"
2. **Primary offline** — No activity for >30 minutes
3. **Machine-specific task** — "Check your disk space"
4. **Both requested** — "Both of you answer this"
5. **bothRespond flag** — Set true in state file

Otherwise: `HEARTBEAT_OK` (silent acknowledgment)

## Implementation

### On Wake
```python
def check_coordination():
    state = read_state_file()
    today = get_date()
    
    if state['date'] != today:
        # Rotate primary
        rotate_primary(state)
    
    am_i_primary = (state['primary'] == MY_NAME)
    return am_i_primary
```

### On Message
```python
def should_respond(message):
    if am_i_primary():
        return True
    if my_name_mentioned(message):
        return True
    if primary_offline():
        return True
    if state['bothRespond']:
        return True
    return False
```

## Manual Override

User can force behavior:
- "Both of you" → Both respond
- "Just Tars" / "Just Case" → Named agent only
- Edit state file directly for persistent changes

## Troubleshooting

### Both responding?
- Check state file sync
- Verify both reading same file
- Check date/timezone

### Neither responding?
- Check state file exists
- Verify mount working
- Check agent health

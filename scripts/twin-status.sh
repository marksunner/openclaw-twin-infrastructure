#!/bin/bash
# Check status of all configured twins
# Reads configuration from config/twins.yaml

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config/twins.yaml"
STATE_PATH=$(grep "state_file:" "$CONFIG_FILE" 2>/dev/null | awk '{print $2}')

echo "Twin Status Check"
echo "================="
echo ""

# Check config exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file not found: $CONFIG_FILE"
    echo "Copy config/twins.example.yaml to config/twins.yaml and edit it."
    exit 1
fi

check_twin() {
    local name=$1
    local host=$2
    
    if ssh -o ConnectTimeout=5 "$host" "pgrep -f openclaw" >/dev/null 2>&1; then
        echo "$name: ✓ Online"
    else
        if ssh -o ConnectTimeout=5 "$host" "echo ok" >/dev/null 2>&1; then
            echo "$name: ⚠ Reachable but OpenClaw not running"
        else
            echo "$name: ❌ Unreachable"
        fi
    fi
}

# Parse twins from config and check each
# This is a simplified parser - use yq for production
grep -E "^  [a-z]" "$CONFIG_FILE" | grep -v "#" | while read -r line; do
    name=$(echo "$line" | tr -d ' :')
    hostname=$(grep -A3 "^  $name:" "$CONFIG_FILE" | grep "hostname:" | awk '{print $2}')
    username=$(grep -A3 "^  $name:" "$CONFIG_FILE" | grep "username:" | awk '{print $2}')
    
    if [ -n "$hostname" ] && [ -n "$username" ]; then
        check_twin "$name" "$username@$hostname"
    fi
done

echo ""

# Check primary from state file if accessible
SHARED_PATH=$(grep "path:" "$CONFIG_FILE" 2>/dev/null | head -1 | awk '{print $2}')
if [ -n "$SHARED_PATH" ] && [ -n "$STATE_PATH" ]; then
    STATE_FILE="$SHARED_PATH/$STATE_PATH"
    if [ -f "$STATE_FILE" ]; then
        PRIMARY=$(grep -o '"primary": "[^"]*"' "$STATE_FILE" | cut -d'"' -f4)
        DATE=$(grep -o '"date": "[^"]*"' "$STATE_FILE" | cut -d'"' -f4)
        echo "Primary today: $PRIMARY ($DATE)"
    else
        echo "Primary: Unknown (state file not found)"
    fi
fi

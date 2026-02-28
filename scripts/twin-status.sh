#!/bin/bash
# Check status of both twins

TARS_HOST="tturing@192.168.1.178"
CASE_HOST="henryturing@192.168.1.240"

echo "Twin Status Check"
echo "================="
echo ""

check_twin() {
    local name=$1
    local host=$2
    
    if ssh -o ConnectTimeout=5 $host "pgrep -f openclaw" >/dev/null 2>&1; then
        echo "$name: ✓ Online"
    else
        if ssh -o ConnectTimeout=5 $host "echo ok" >/dev/null 2>&1; then
            echo "$name: ⚠ Reachable but OpenClaw not running"
        else
            echo "$name: ❌ Unreachable"
        fi
    fi
}

check_twin "Tars" "$TARS_HOST"
check_twin "Case" "$CASE_HOST"

echo ""

# Check primary
if [ -f ~/nas_share/twin-primary.json ]; then
    PRIMARY=$(cat ~/nas_share/twin-primary.json | grep -o '"primary": "[^"]*"' | cut -d'"' -f4)
    DATE=$(cat ~/nas_share/twin-primary.json | grep -o '"date": "[^"]*"' | cut -d'"' -f4)
    echo "Primary today: $PRIMARY ($DATE)"
else
    echo "Primary: Unknown (state file not found)"
fi

#!/bin/bash
set -euo pipefail
APP="/Applications/Quota Bubble.app"
[ -d "$APP" ] || APP="$HOME/Applications/Quota Bubble.app"
PATTERN="Quota Bubble.app/Contents/MacOS/Quota Bubble"
pkill -f "$PATTERN" >/dev/null 2>&1 || true
for _ in {1..40}; do
    pgrep -f "$PATTERN" >/dev/null 2>&1 || break
    sleep 0.1
done
open -g "$APP"
echo "Quota Bubble restarted."

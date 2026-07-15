#!/bin/bash
set -euo pipefail
APP="/Applications/Quota Bubble.app"
[ -d "$APP" ] || APP="$HOME/Applications/Quota Bubble.app"
PATTERN="Quota Bubble.app/Contents/MacOS/Quota Bubble"
if pgrep -f "$PATTERN" >/dev/null 2>&1; then
    osascript -e 'tell application id "local.codex.quota-bubble" to quit' >/dev/null 2>&1 || pkill -f "$PATTERN" >/dev/null 2>&1 || true
fi
for _ in {1..40}; do
    pgrep -f "$PATTERN" >/dev/null 2>&1 || break
    sleep 0.1
done
open -g "$APP"
echo "Quota Bubble restarted."

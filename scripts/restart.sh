#!/bin/bash
set -euo pipefail
APP="/Applications/Quota Bubble.app"
[ -d "$APP" ] || APP="$HOME/Applications/Quota Bubble.app"
PATTERN="Quota Bubble.app/Contents/MacOS/Quota Bubble"
pkill -f "$PATTERN" >/dev/null 2>&1 || true
sleep 0.4
open -g "$APP"
echo "Quota Bubble restarted."

#!/bin/bash
set -euo pipefail
APP="/Applications/Quota Bubble.app"
[ -d "$APP" ] || APP="$HOME/Applications/Quota Bubble.app"
PATTERN='(Quota Bubble|quota_bubble|QuotaBubble)[.]app/Contents/MacOS/(Quota Bubble|quota_bubble|QuotaBubble)([[:space:]]|$)'
pgrep -f "$PATTERN" >/dev/null 2>&1 || open -g "$APP"

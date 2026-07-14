#!/bin/bash
set -euo pipefail
APP="$HOME/Applications/Quota Bubble.app"
PATTERN="Quota Bubble.app/Contents/MacOS/Quota Bubble"
pgrep -f "$PATTERN" >/dev/null 2>&1 || open -g "$APP"

#!/bin/bash
set -euo pipefail
APP="/Applications/Quota Bubble.app"
[ -d "$APP" ] || APP="$HOME/Applications/Quota Bubble.app"
PATTERN='(Quota Bubble|quota_bubble|QuotaBubble)[.]app/Contents/MacOS/(Quota Bubble|quota_bubble|QuotaBubble)([[:space:]]|$)'
LABEL="com.codex.usage-widget.autostart"
STATUS=0
echo "LaunchAgent:"
if launchctl print "gui/$(id -u)/$LABEL" >/dev/null 2>&1; then echo "  loaded"; else echo "  not loaded"; STATUS=1; fi
echo "App process:"
if pgrep -fl "$PATTERN"; then :; else echo "  not running"; STATUS=1; fi
echo "App bundle:"
if [ -d "$APP" ]; then echo "  $APP"; else echo "  missing"; STATUS=1; fi
exit "$STATUS"

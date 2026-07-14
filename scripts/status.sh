#!/bin/bash
set -euo pipefail
APP="$HOME/Applications/Quota Bubble.app"
EXE="$APP/Contents/MacOS/Quota Bubble"
LABEL="com.codex.usage-widget.autostart"
STATUS=0
echo "LaunchAgent:"
if launchctl print "gui/$(id -u)/$LABEL" >/dev/null 2>&1; then echo "  loaded"; else echo "  not loaded"; STATUS=1; fi
echo "App process:"
if ps ax -o pid=,command= | grep -F "$EXE" | grep -v grep; then :; else echo "  not running"; STATUS=1; fi
echo "App bundle:"
if [ -d "$APP" ]; then echo "  $APP"; else echo "  missing"; STATUS=1; fi
exit "$STATUS"

#!/bin/bash
set -euo pipefail

CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
INSTALL_DIR="$CODEX_HOME/usage-widget"
WIDGET_EXE="$INSTALL_DIR/UsageWidget.app/Contents/MacOS/UsageWidget"
LAUNCHER_APP="$HOME/Applications/Quota Bubble.app"
SNAPSHOT="$CODEX_HOME/codex-usage-snapshot.json"
LABEL="com.codex.usage-widget.autostart"

echo "LaunchAgent:"
launchctl print "gui/$(id -u)/$LABEL" >/dev/null 2>&1 && echo "  loaded" || echo "  not loaded"

echo "Widget process:"
ps ax -o pid=,command= | grep -F "$WIDGET_EXE" | grep -v grep || echo "  not running"

echo "Dock launcher:"
if [ -d "$LAUNCHER_APP" ]; then
    echo "  $LAUNCHER_APP"
else
    echo "  missing"
fi

echo "Snapshot:"
if [ -f "$SNAPSHOT" ]; then
    sed -n '1,80p' "$SNAPSHOT"
else
    echo "  missing"
fi

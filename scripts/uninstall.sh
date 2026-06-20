#!/bin/bash
set -euo pipefail

CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
INSTALL_DIR="$CODEX_HOME/usage-widget"
WIDGET_EXE="$INSTALL_DIR/UsageWidget.app/Contents/MacOS/UsageWidget"
LAUNCHER_APP="$HOME/Applications/Quota Bubble.app"
LAUNCH_AGENT="$HOME/Library/LaunchAgents/com.codex.usage-widget.autostart.plist"
LABEL="com.codex.usage-widget.autostart"

launchctl bootout "gui/$(id -u)" "$LAUNCH_AGENT" >/dev/null 2>&1 || true
pkill -f "$WIDGET_EXE" >/dev/null 2>&1 || true
pkill -f "$LAUNCHER_APP/Contents/MacOS/Quota Bubble" >/dev/null 2>&1 || true
pkill -f "Codex Usage Widget.app/Contents/MacOS/Codex Usage Widget" >/dev/null 2>&1 || true
rm -f "$LAUNCH_AGENT"
rm -rf "$LAUNCHER_APP" "$HOME/Applications/Codex Usage Widget.app"

echo "Quota Bubble stopped and LaunchAgent removed."

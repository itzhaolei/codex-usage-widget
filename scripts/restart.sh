#!/bin/bash
set -euo pipefail

CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
INSTALL_DIR="$CODEX_HOME/usage-widget"
WIDGET_APP="$INSTALL_DIR/UsageWidget.app"
WIDGET_EXE="$INSTALL_DIR/UsageWidget.app/Contents/MacOS/UsageWidget"
SNAPSHOT_SCRIPT="$CODEX_HOME/scripts/codex-usage-snapshot.mjs"
SNAPSHOT_PATH="$CODEX_HOME/codex-usage-snapshot.json"

rm -f "$INSTALL_DIR/.closed-by-user"
pkill -f "$WIDGET_EXE" >/dev/null 2>&1 || true
sleep 0.3

if [ -f "$SNAPSHOT_SCRIPT" ]; then
    PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/opt/homebrew/sbin:/usr/sbin" node "$SNAPSHOT_SCRIPT" "$SNAPSHOT_PATH" >/dev/null 2>&1 || true
fi

touch "$WIDGET_APP"
open "$WIDGET_APP"

echo "Codex Usage Widget restarted."

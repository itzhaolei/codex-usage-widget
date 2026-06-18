#!/bin/bash
set -euo pipefail

CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
INSTALL_DIR="$CODEX_HOME/usage-widget"
WIDGET_APP="$INSTALL_DIR/UsageWidget.app"
WIDGET_EXE="$INSTALL_DIR/UsageWidget.app/Contents/MacOS/UsageWidget"
SNAPSHOT_SCRIPT="$CODEX_HOME/scripts/codex-usage-snapshot.mjs"
SNAPSHOT_PATH="$CODEX_HOME/codex-usage-snapshot.json"
LAUNCH_PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/opt/homebrew/sbin:/usr/sbin"

run_snapshot() {
    if [ ! -f "$SNAPSHOT_SCRIPT" ]; then
        return 0
    fi

    PATH="$LAUNCH_PATH" node "$SNAPSHOT_SCRIPT" "$SNAPSHOT_PATH" >/dev/null 2>&1 && return 0
    /bin/zsh -lc 'node "$1" "$2"' zsh "$SNAPSHOT_SCRIPT" "$SNAPSHOT_PATH" >/dev/null 2>&1 || true
}

rm -f "$INSTALL_DIR/.closed-by-user"
pkill -f "$WIDGET_EXE" >/dev/null 2>&1 || true
sleep 0.3

run_snapshot

touch "$WIDGET_APP"
open "$WIDGET_APP"

echo "Codex Usage Widget restarted."

#!/bin/bash
set -euo pipefail

CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
INSTALL_DIR="$CODEX_HOME/usage-widget"
WIDGET_EXE="$INSTALL_DIR/UsageWidget.app/Contents/MacOS/UsageWidget"

rm -f "$INSTALL_DIR/.closed-by-user"
pkill -f "$WIDGET_EXE" >/dev/null 2>&1 || true
bash "$INSTALL_DIR/ensure-usage-widget.sh"

echo "Codex Usage Widget restarted."

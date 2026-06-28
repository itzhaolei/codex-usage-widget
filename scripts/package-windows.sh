#!/bin/bash
set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:-$(/usr/bin/python3 - "$PLUGIN_DIR/.codex-plugin/plugin.json" <<'PY'
import json
import sys
with open(sys.argv[1], "r", encoding="utf-8") as handle:
    print(json.load(handle)["version"])
PY
)}"
BUILD_DIR="${TMPDIR:-/tmp}/quota-bubble-windows-$VERSION"
DIST_DIR="$PLUGIN_DIR/dist"
ZIP_PATH="$DIST_DIR/QuotaBubble-$VERSION-Windows.zip"

rm -rf "$BUILD_DIR" "$ZIP_PATH"
mkdir -p "$BUILD_DIR/QuotaBubble-$VERSION/windows" "$BUILD_DIR/QuotaBubble-$VERSION/scripts" "$BUILD_DIR/QuotaBubble-$VERSION/assets" "$DIST_DIR"

cp "$PLUGIN_DIR/windows/QuotaBubble.ps1" "$BUILD_DIR/QuotaBubble-$VERSION/windows/QuotaBubble.ps1"
cp "$PLUGIN_DIR/windows/install.ps1" "$BUILD_DIR/QuotaBubble-$VERSION/windows/install.ps1"
cp "$PLUGIN_DIR/windows/uninstall.ps1" "$BUILD_DIR/QuotaBubble-$VERSION/windows/uninstall.ps1"
cp "$PLUGIN_DIR/scripts/codex-usage-snapshot.mjs" "$BUILD_DIR/QuotaBubble-$VERSION/scripts/codex-usage-snapshot.mjs"
cp "$PLUGIN_DIR/assets/icon.png" "$BUILD_DIR/QuotaBubble-$VERSION/assets/icon.png"

cat > "$BUILD_DIR/QuotaBubble-$VERSION/INSTALL-WINDOWS.txt" <<TXT
Quota Bubble $VERSION for Windows

Install:
1. Unzip this package.
2. Right-click windows/install.ps1 and choose "Run with PowerShell".
3. If PowerShell blocks the script, run:
   powershell -NoProfile -ExecutionPolicy Bypass -File .\\windows\\install.ps1

Requirements:
- Windows 10 or later.
- Node.js and npm available as "node" and "npm".
- Codex CLI local data under %USERPROFILE%\\.codex, or CODEX_HOME set to a compatible directory.

Uninstall:
powershell -NoProfile -ExecutionPolicy Bypass -File .\\windows\\uninstall.ps1
TXT

(cd "$BUILD_DIR" && zip -qr "$ZIP_PATH" "QuotaBubble-$VERSION")
echo "$ZIP_PATH"

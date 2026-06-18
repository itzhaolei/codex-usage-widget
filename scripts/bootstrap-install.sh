#!/bin/bash
set -euo pipefail

PLUGIN_NAME="codex-usage-widget"
PLUGIN_DIR="$HOME/plugins/$PLUGIN_NAME"
MARKETPLACE_PATH="$HOME/.agents/plugins/marketplace.json"
DOWNLOAD_URL="${CODEX_USAGE_WIDGET_URL:-}"

if [ -z "$DOWNLOAD_URL" ]; then
    echo "Set CODEX_USAGE_WIDGET_URL to a .tar.gz or .zip download URL first." >&2
    echo "Example:" >&2
    echo "CODEX_USAGE_WIDGET_URL=https://github.com/USER/codex-usage-widget/archive/refs/heads/main.tar.gz bash scripts/bootstrap-install.sh" >&2
    exit 1
fi

TMP_DIR="$(mktemp -d)"
cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

mkdir -p "$HOME/plugins" "$HOME/.agents/plugins"

ARCHIVE="$TMP_DIR/plugin-archive"
curl -fsSL "$DOWNLOAD_URL" -o "$ARCHIVE"

EXTRACT_DIR="$TMP_DIR/extracted"
mkdir -p "$EXTRACT_DIR"

case "$DOWNLOAD_URL" in
    *.zip)
        ditto -x -k "$ARCHIVE" "$EXTRACT_DIR"
        ;;
    *)
        tar -xzf "$ARCHIVE" -C "$EXTRACT_DIR"
        ;;
esac

SOURCE_DIR="$(find "$EXTRACT_DIR" -name plugin.json -path '*/.codex-plugin/plugin.json' -print -quit | sed 's#/.codex-plugin/plugin.json##')"
if [ -z "$SOURCE_DIR" ] || [ ! -d "$SOURCE_DIR" ]; then
    echo "Could not find a Codex plugin in the downloaded archive." >&2
    exit 1
fi

rm -rf "$PLUGIN_DIR"
mkdir -p "$PLUGIN_DIR"
ditto "$SOURCE_DIR" "$PLUGIN_DIR"

/usr/bin/python3 - "$MARKETPLACE_PATH" <<'PY'
import json
import sys
from pathlib import Path

marketplace_path = Path(sys.argv[1]).expanduser()
marketplace_path.parent.mkdir(parents=True, exist_ok=True)

if marketplace_path.exists():
    try:
        data = json.loads(marketplace_path.read_text())
    except Exception:
        data = {}
else:
    data = {}

if not isinstance(data, dict):
    data = {}

data.setdefault("name", "personal")
data.setdefault("interface", {"displayName": "Personal"})
plugins = data.get("plugins")
if not isinstance(plugins, list):
    plugins = []

entry = {
    "name": "codex-usage-widget",
    "source": {"source": "local", "path": "./plugins/codex-usage-widget"},
    "policy": {"installation": "AVAILABLE", "authentication": "ON_INSTALL"},
    "category": "Productivity",
}

plugins = [plugin for plugin in plugins if plugin.get("name") != "codex-usage-widget"]
plugins.append(entry)
data["plugins"] = plugins

marketplace_path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")
PY

bash "$PLUGIN_DIR/scripts/install.sh"

echo
echo "Installed $PLUGIN_NAME."
echo "Plugin path: $PLUGIN_DIR"
echo "Marketplace: $MARKETPLACE_PATH"

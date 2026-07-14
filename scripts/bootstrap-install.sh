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

RELEASE_JSON="$TMP_DIR/latest-release.json"
INSTALLER_ZIP="$TMP_DIR/macos-installer.zip"
INSTALLER_DIR="$TMP_DIR/macos-installer"
INSTALLER_URL=""
if curl -fsSL "https://api.github.com/repos/itzhaolei/codex-usage-widget/releases/latest" -o "$RELEASE_JSON"; then
    INSTALLER_URL="$(/usr/bin/python3 - "$RELEASE_JSON" <<'PY'
import json, sys
release = json.load(open(sys.argv[1], encoding="utf-8"))
for asset in release.get("assets", []):
    if asset.get("name", "").endswith("macOS-Installer.zip"):
        print(asset.get("browser_download_url", ""))
        break
PY
)"
fi

if [ -n "$INSTALLER_URL" ]; then
    mkdir -p "$INSTALLER_DIR"
    curl -fsSL "$INSTALLER_URL" -o "$INSTALLER_ZIP"
    ditto -x -k "$INSTALLER_ZIP" "$INSTALLER_DIR"
    /bin/bash "$INSTALLER_DIR/Install Quota Bubble.app/Contents/Resources/install-packaged.sh"
elif command -v swiftc >/dev/null 2>&1; then
    bash "$PLUGIN_DIR/scripts/install.sh"
else
    echo "Could not download the prebuilt macOS installer, and swiftc is unavailable." >&2
    exit 1
fi

echo
echo "Installed $PLUGIN_NAME."
echo "Plugin path: $PLUGIN_DIR"
echo "Marketplace: $MARKETPLACE_PATH"

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
APP_NAME="Install Codex Usage Widget"
BUILD_DIR="${TMPDIR:-/tmp}/codex-usage-widget-installer-$VERSION"
DIST_DIR="$PLUGIN_DIR/dist"
INSTALLER_APP="$BUILD_DIR/$APP_NAME.app"
PAYLOAD_DIR="$INSTALLER_APP/Contents/Resources/payload"
ZIP_PATH="$DIST_DIR/CodexUsageWidget-$VERSION-Installer.zip"

rm -rf "$BUILD_DIR" "$ZIP_PATH"
mkdir -p "$INSTALLER_APP/Contents/MacOS" "$INSTALLER_APP/Contents/Resources" "$PAYLOAD_DIR/scripts" "$PAYLOAD_DIR/apps" "$DIST_DIR"

cat > "$INSTALLER_APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>local.codex.usage-widget.installer</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

cp "$PLUGIN_DIR/assets/icon.png" "$PAYLOAD_DIR/icon.png"
cp "$PLUGIN_DIR/scripts/codex-usage-snapshot.mjs" "$PAYLOAD_DIR/scripts/codex-usage-snapshot.mjs"
cp "$PLUGIN_DIR/scripts/ensure-usage-widget.sh" "$PAYLOAD_DIR/scripts/ensure-usage-widget.sh"
cp "$PLUGIN_DIR/scripts/start-usage-widget.sh" "$PAYLOAD_DIR/scripts/start-usage-widget.sh"
cp "$PLUGIN_DIR/scripts/restart.sh" "$PAYLOAD_DIR/scripts/restart.sh"
cp "$PLUGIN_DIR/scripts/status.sh" "$PAYLOAD_DIR/scripts/status.sh"
cp "$PLUGIN_DIR/scripts/uninstall.sh" "$PAYLOAD_DIR/scripts/uninstall.sh"

ICON_PNG="$PAYLOAD_DIR/icon.png"
ICONSET="$BUILD_DIR/AppIcon.iconset"
ICON_ICNS="$BUILD_DIR/AppIcon.icns"
mkdir -p "$ICONSET"
for size in 16 32 128 256 512; do
    sips -z "$size" "$size" "$ICON_PNG" --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
    double_size=$((size * 2))
    sips -z "$double_size" "$double_size" "$ICON_PNG" --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$ICON_ICNS"
cp "$ICON_ICNS" "$INSTALLER_APP/Contents/Resources/AppIcon.icns"

WIDGET_APP="$PAYLOAD_DIR/apps/UsageWidget.app"
WIDGET_MACOS="$WIDGET_APP/Contents/MacOS"
WIDGET_RESOURCES="$WIDGET_APP/Contents/Resources"
mkdir -p "$WIDGET_MACOS" "$WIDGET_RESOURCES"
swiftc -parse-as-library -o "$WIDGET_MACOS/UsageWidget" "$PLUGIN_DIR/sources/UsageWidget.swift" -framework Cocoa
chmod +x "$WIDGET_MACOS/UsageWidget"
cp "$ICON_ICNS" "$WIDGET_RESOURCES/AppIcon.icns"
cat > "$WIDGET_APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>UsageWidget</string>
    <key>CFBundleIdentifier</key>
    <string>local.codex.usage-widget</string>
    <key>CFBundleName</key>
    <string>Codex Usage Widget</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

LAUNCHER_APP="$PAYLOAD_DIR/apps/Codex Usage Widget.app"
LAUNCHER_MACOS="$LAUNCHER_APP/Contents/MacOS"
LAUNCHER_RESOURCES="$LAUNCHER_APP/Contents/Resources"
mkdir -p "$LAUNCHER_MACOS" "$LAUNCHER_RESOURCES"
swiftc -parse-as-library -o "$LAUNCHER_MACOS/Codex Usage Widget" "$PLUGIN_DIR/sources/CodexUsageWidgetLauncher.swift" -framework Cocoa
chmod +x "$LAUNCHER_MACOS/Codex Usage Widget"
cp "$ICON_ICNS" "$LAUNCHER_RESOURCES/AppIcon.icns"
cat > "$LAUNCHER_APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Codex Usage Widget</string>
    <key>CFBundleIdentifier</key>
    <string>local.codex.usage-widget.launcher</string>
    <key>CFBundleName</key>
    <string>Codex Usage Widget</string>
    <key>CFBundleDisplayName</key>
    <string>Codex Usage Widget</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

cat > "$INSTALLER_APP/Contents/Resources/install-packaged.sh" <<'SCRIPT'
#!/bin/bash
set -euo pipefail

RESOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"
PAYLOAD_DIR="$RESOURCE_DIR/payload"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
INSTALL_DIR="$CODEX_HOME/usage-widget"
SCRIPTS_DIR="$CODEX_HOME/scripts"
USER_APPS_DIR="$HOME/Applications"
LAUNCHER_APP="$USER_APPS_DIR/Codex Usage Widget.app"
LAUNCH_AGENT_DIR="$HOME/Library/LaunchAgents"
LAUNCH_AGENT="$LAUNCH_AGENT_DIR/com.codex.usage-widget.autostart.plist"
LABEL="com.codex.usage-widget.autostart"
WIDGET_PATTERN="UsageWidget.app/Contents/MacOS/UsageWidget"
LAUNCHER_PATTERN="Codex Usage Widget.app/Contents/MacOS/Codex Usage Widget"

dedupe_dock_launcher() {
    /usr/bin/python3 - "$LAUNCHER_APP" <<'PY'
import plistlib
import subprocess
import sys
from pathlib import Path
from urllib.parse import unquote, urlparse
from urllib.request import url2pathname

launcher_path = str(Path(sys.argv[1]).expanduser().resolve())
launcher_url = Path(launcher_path).as_uri()
dock_plist = Path.home() / "Library/Preferences/com.apple.dock.plist"

def item_url(item):
    return item.get("tile-data", {}).get("file-data", {}).get("_CFURLString")

def url_to_path(url):
    if not isinstance(url, str):
        return ""
    parsed = urlparse(url)
    if parsed.scheme == "file":
        return url2pathname(unquote(parsed.path)).rstrip("/")
    return unquote(url).replace("file://", "").rstrip("/")

def is_launcher_item(item):
    path = url_to_path(item_url(item))
    return path == launcher_path or path.endswith("/Codex Usage Widget.app")

launcher_item = {
    "tile-data": {
        "file-data": {
            "_CFURLString": launcher_url,
            "_CFURLStringType": 15,
        },
        "file-label": "Codex Usage Widget",
    },
    "tile-type": "file-tile",
}

if dock_plist.exists():
    with dock_plist.open("rb") as handle:
        dock = plistlib.load(handle)
else:
    dock = {}

persistent_apps = dock.get("persistent-apps")
if not isinstance(persistent_apps, list):
    persistent_apps = []

new_apps = []
found = False
changed = False
for item in persistent_apps:
    if is_launcher_item(item):
        if not found:
            new_apps.append(launcher_item)
            found = True
            if item != launcher_item:
                changed = True
        else:
            changed = True
        continue
    new_apps.append(item)

if not found:
    new_apps.append(launcher_item)
    changed = True

if changed:
    dock["persistent-apps"] = new_apps
    with dock_plist.open("wb") as handle:
        plistlib.dump(dock, handle)
    subprocess.run(["killall", "Dock"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
PY
}

mkdir -p "$INSTALL_DIR" "$SCRIPTS_DIR" "$USER_APPS_DIR" "$LAUNCH_AGENT_DIR"

pkill -f "$WIDGET_PATTERN" >/dev/null 2>&1 || true
if [ "${CODEX_USAGE_WIDGET_KEEP_LAUNCHER:-0}" != "1" ]; then
    pkill -f "$LAUNCHER_PATTERN" >/dev/null 2>&1 || true
fi

cp "$PAYLOAD_DIR/scripts/codex-usage-snapshot.mjs" "$SCRIPTS_DIR/codex-usage-snapshot.mjs"
cp "$PAYLOAD_DIR/scripts/ensure-usage-widget.sh" "$INSTALL_DIR/ensure-usage-widget.sh"
cp "$PAYLOAD_DIR/scripts/start-usage-widget.sh" "$INSTALL_DIR/start-usage-widget.sh"
cp "$PAYLOAD_DIR/scripts/restart.sh" "$INSTALL_DIR/restart.sh"
cp "$PAYLOAD_DIR/scripts/status.sh" "$INSTALL_DIR/status.sh"
cp "$PAYLOAD_DIR/scripts/uninstall.sh" "$INSTALL_DIR/uninstall.sh"
chmod +x "$SCRIPTS_DIR/codex-usage-snapshot.mjs" "$INSTALL_DIR/ensure-usage-widget.sh" "$INSTALL_DIR/start-usage-widget.sh" "$INSTALL_DIR/restart.sh" "$INSTALL_DIR/status.sh" "$INSTALL_DIR/uninstall.sh"

rm -rf "$INSTALL_DIR/UsageWidget.app" "$LAUNCHER_APP"
cp -R "$PAYLOAD_DIR/apps/UsageWidget.app" "$INSTALL_DIR/UsageWidget.app"
cp -R "$PAYLOAD_DIR/apps/Codex Usage Widget.app" "$LAUNCHER_APP"
chmod +x "$INSTALL_DIR/UsageWidget.app/Contents/MacOS/UsageWidget" "$LAUNCHER_APP/Contents/MacOS/Codex Usage Widget"
xattr -dr com.apple.quarantine "$INSTALL_DIR/UsageWidget.app" "$LAUNCHER_APP" >/dev/null 2>&1 || true

cat > "$LAUNCH_AGENT" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$INSTALL_DIR/ensure-usage-widget.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>StartInterval</key>
    <integer>10</integer>
    <key>StandardOutPath</key>
    <string>/tmp/codex-usage-widget-agent.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/codex-usage-widget-agent.err</string>
</dict>
</plist>
PLIST

launchctl bootout "gui/$(id -u)" "$LAUNCH_AGENT" >/dev/null 2>&1 || true
launchctl bootstrap "gui/$(id -u)" "$LAUNCH_AGENT"
launchctl kickstart -k "gui/$(id -u)/$LABEL" >/dev/null 2>&1 || true

rm -f "$INSTALL_DIR/.closed-by-user"
bash "$INSTALL_DIR/ensure-usage-widget.sh" >/dev/null 2>&1 || true
dedupe_dock_launcher
if [ "${CODEX_USAGE_WIDGET_KEEP_LAUNCHER:-0}" != "1" ]; then
    open -g "$LAUNCHER_APP" >/dev/null 2>&1 || true
fi

echo "Codex Usage Widget installed."
echo "Dock launcher: $LAUNCHER_APP"
SCRIPT
chmod +x "$INSTALLER_APP/Contents/Resources/install-packaged.sh"

cat > "$INSTALLER_APP/Contents/MacOS/$APP_NAME" <<'SCRIPT'
#!/bin/bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
INSTALL_SCRIPT="$APP_DIR/Resources/install-packaged.sh"

if OUTPUT="$(/bin/bash "$INSTALL_SCRIPT" 2>&1)"; then
    /usr/bin/osascript -e 'display dialog "Codex Usage Widget installed successfully." buttons {"OK"} default button "OK" with title "Codex Usage Widget"'
else
    ESCAPED_OUTPUT="$(printf '%s' "$OUTPUT" | tail -n 12 | sed 's/"/\\"/g')"
    /usr/bin/osascript -e "display dialog \"Install failed:\n$ESCAPED_OUTPUT\" buttons {\"OK\"} default button \"OK\" with title \"Codex Usage Widget\""
    exit 1
fi
SCRIPT
chmod +x "$INSTALLER_APP/Contents/MacOS/$APP_NAME"

(
    cd "$BUILD_DIR"
    zip -qry "$ZIP_PATH" "$APP_NAME.app"
)

echo "$ZIP_PATH"

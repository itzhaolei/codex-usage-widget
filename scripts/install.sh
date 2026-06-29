#!/bin/bash
set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
INSTALL_DIR="$CODEX_HOME/usage-widget"
SCRIPTS_DIR="$CODEX_HOME/scripts"
APP_DIR="$INSTALL_DIR/UsageWidget.app"
WIDGET_PATTERN="UsageWidget.app/Contents/MacOS/UsageWidget"
MACOS_DIR="$APP_DIR/Contents/MacOS"
RESOURCES_DIR="$APP_DIR/Contents/Resources"
USER_APPS_DIR="$HOME/Applications"
LAUNCHER_APP="$USER_APPS_DIR/Quota Bubble.app"
LAUNCHER_PATTERN="Quota Bubble.app/Contents/MacOS/Quota Bubble"
LAUNCHER_MACOS_DIR="$LAUNCHER_APP/Contents/MacOS"
LAUNCHER_RESOURCES_DIR="$LAUNCHER_APP/Contents/Resources"
LAUNCH_AGENT_DIR="$HOME/Library/LaunchAgents"
LAUNCH_AGENT="$LAUNCH_AGENT_DIR/com.codex.usage-widget.autostart.plist"
LABEL="com.codex.usage-widget.autostart"
PIN_TO_DOCK="${PIN_TO_DOCK:-1}"

dedupe_dock_launcher() {
    /usr/bin/python3 - "$LAUNCHER_APP" <<'PY'
import os
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
    return (
        item.get("tile-data", {})
            .get("file-data", {})
            .get("_CFURLString")
    )

def url_to_path(url):
    if not isinstance(url, str):
        return ""
    parsed = urlparse(url)
    if parsed.scheme == "file":
        return url2pathname(unquote(parsed.path)).rstrip("/")
    return unquote(url).replace("file://", "").rstrip("/")

def is_launcher_item(item):
    path = url_to_path(item_url(item))
    return path == launcher_path or path.endswith("/Quota Bubble.app") or path.endswith("/Codex Usage Widget.app")

launcher_item = {
    "tile-data": {
        "file-data": {
            "_CFURLString": launcher_url,
            "_CFURLStringType": 15,
        },
        "file-label": "Quota Bubble",
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

rm -rf "$USER_APPS_DIR/Codex Usage Widget.app"
mkdir -p "$INSTALL_DIR" "$SCRIPTS_DIR" "$MACOS_DIR" "$RESOURCES_DIR" "$USER_APPS_DIR" "$LAUNCHER_MACOS_DIR" "$LAUNCHER_RESOURCES_DIR" "$LAUNCH_AGENT_DIR"

launchctl bootout "gui/$(id -u)" "$LAUNCH_AGENT" >/dev/null 2>&1 || true
pkill -f "$LAUNCHER_PATTERN" >/dev/null 2>&1 || true
pkill -f "Codex Usage Widget.app/Contents/MacOS/Codex Usage Widget" >/dev/null 2>&1 || true
pkill -f "$WIDGET_PATTERN" >/dev/null 2>&1 || true
sleep 0.3

cp "$PLUGIN_DIR/scripts/codex-usage-snapshot.mjs" "$SCRIPTS_DIR/codex-usage-snapshot.mjs"
cp "$PLUGIN_DIR/scripts/ensure-usage-widget.sh" "$INSTALL_DIR/ensure-usage-widget.sh"
cp "$PLUGIN_DIR/scripts/start-usage-widget.sh" "$INSTALL_DIR/start-usage-widget.sh"
cp "$PLUGIN_DIR/scripts/restart.sh" "$INSTALL_DIR/restart.sh"
cp "$PLUGIN_DIR/scripts/status.sh" "$INSTALL_DIR/status.sh"
cp "$PLUGIN_DIR/scripts/uninstall.sh" "$INSTALL_DIR/uninstall.sh"
chmod +x "$SCRIPTS_DIR/codex-usage-snapshot.mjs" "$INSTALL_DIR/ensure-usage-widget.sh" "$INSTALL_DIR/start-usage-widget.sh" "$INSTALL_DIR/restart.sh" "$INSTALL_DIR/status.sh" "$INSTALL_DIR/uninstall.sh"

swiftc -parse-as-library -o "$MACOS_DIR/UsageWidget" "$PLUGIN_DIR/sources/UsageWidget.swift" -framework Cocoa
chmod +x "$MACOS_DIR/UsageWidget"

ICON_PNG="$INSTALL_DIR/icon.png"
ICONSET="$INSTALL_DIR/AppIcon.iconset"
ICON_ICNS="$INSTALL_DIR/AppIcon.icns"
ICON_MAKER="$INSTALL_DIR/IconMaker"
swiftc -o "$ICON_MAKER" "$PLUGIN_DIR/sources/IconMaker.swift" -framework Cocoa
"$ICON_MAKER" "$ICON_PNG"
rm -rf "$ICONSET"
mkdir -p "$ICONSET"
for size in 16 32 128 256 512; do
    sips -z "$size" "$size" "$ICON_PNG" --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
    double_size=$((size * 2))
    sips -z "$double_size" "$double_size" "$ICON_PNG" --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$ICON_ICNS"
cp "$ICON_ICNS" "$RESOURCES_DIR/AppIcon.icns"

swiftc -parse-as-library -o "$LAUNCHER_MACOS_DIR/Quota Bubble" "$PLUGIN_DIR/sources/CodexUsageWidgetLauncher.swift" -framework Cocoa
chmod +x "$LAUNCHER_MACOS_DIR/Quota Bubble"
cp "$ICON_ICNS" "$LAUNCHER_RESOURCES_DIR/AppIcon.icns"

cat > "$APP_DIR/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>UsageWidget</string>
    <key>CFBundleIdentifier</key>
    <string>local.codex.usage-widget</string>
    <key>CFBundleName</key>
    <string>Quota Bubble</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>2.1.1</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

cat > "$LAUNCHER_APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Quota Bubble</string>
    <key>CFBundleIdentifier</key>
    <string>local.codex.usage-widget.launcher</string>
    <key>CFBundleName</key>
    <string>Quota Bubble</string>
    <key>CFBundleDisplayName</key>
    <string>Quota Bubble</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>2.1.1</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

xattr -dr com.apple.quarantine "$APP_DIR" "$LAUNCHER_APP" >/dev/null 2>&1 || true

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
bash "$INSTALL_DIR/ensure-usage-widget.sh"

if [ "$PIN_TO_DOCK" != "0" ]; then
    dedupe_dock_launcher
fi

open -g "$LAUNCHER_APP" >/dev/null 2>&1 || true

echo "Quota Bubble installed."
echo "Dock launcher: $LAUNCHER_APP"

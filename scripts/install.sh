#!/bin/bash
set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
INSTALL_DIR="$CODEX_HOME/usage-widget"
APP_DIR="/Applications/Quota Bubble.app"
APP_EXE="$APP_DIR/Contents/MacOS/Quota Bubble"
APP_PATTERN="Quota Bubble.app/Contents/MacOS/Quota Bubble"
LAUNCH_AGENT="$HOME/Library/LaunchAgents/com.codex.usage-widget.autostart.plist"
LABEL="com.codex.usage-widget.autostart"
VERSION="$(/usr/bin/python3 - "$PLUGIN_DIR/.codex-plugin/plugin.json" <<'PY'
import json, sys
print(json.load(open(sys.argv[1], encoding="utf-8"))["version"])
PY
)"

dedupe_dock_app() {
    /usr/bin/python3 - "$APP_DIR" <<'PY'
import plistlib, subprocess, sys
from pathlib import Path
from urllib.parse import unquote, urlparse
from urllib.request import url2pathname

app_path = str(Path(sys.argv[1]).expanduser().resolve())
app_url = Path(app_path).as_uri()
plist = Path.home() / "Library/Preferences/com.apple.dock.plist"

def path_for(item):
    value = item.get("tile-data", {}).get("file-data", {}).get("_CFURLString")
    if not isinstance(value, str): return ""
    parsed = urlparse(value)
    return (url2pathname(unquote(parsed.path)) if parsed.scheme == "file" else unquote(value).replace("file://", "")).rstrip("/")

def is_quota_bubble(item):
    value = path_for(item)
    return value == app_path or value.endswith("/Quota Bubble.app") or value.endswith("/Codex Usage Widget.app")

entry = {"tile-data": {"file-data": {"_CFURLString": app_url, "_CFURLStringType": 15}, "file-label": "Quota Bubble"}, "tile-type": "file-tile"}
data = plistlib.load(plist.open("rb")) if plist.exists() else {}
apps = data.get("persistent-apps") if isinstance(data.get("persistent-apps"), list) else []
new, inserted = [], False
for item in apps:
    if is_quota_bubble(item):
        if not inserted: new.append(entry); inserted = True
    else: new.append(item)
if not inserted: new.append(entry)
if new != apps:
    data["persistent-apps"] = new
    plist.parent.mkdir(parents=True, exist_ok=True)
    plistlib.dump(data, plist.open("wb"))
    subprocess.run(["killall", "Dock"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
PY
}

launchctl bootout "gui/$(id -u)" "$LAUNCH_AGENT" >/dev/null 2>&1 || true
pkill -f "$APP_PATTERN" >/dev/null 2>&1 || true
pkill -f "UsageWidget.app/Contents/MacOS/UsageWidget" >/dev/null 2>&1 || true
pkill -f "Codex Usage Widget.app/Contents/MacOS/Codex Usage Widget" >/dev/null 2>&1 || true
sleep 0.3

rm -rf "$APP_DIR" "$HOME/Applications/Quota Bubble.app" "$HOME/Applications/Codex Usage Widget.app" "$INSTALL_DIR/UsageWidget.app"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources" "$INSTALL_DIR" "$HOME/Library/LaunchAgents"

for script in ensure-usage-widget.sh start-usage-widget.sh restart.sh status.sh uninstall.sh; do
    cp "$PLUGIN_DIR/scripts/$script" "$INSTALL_DIR/$script"
    chmod +x "$INSTALL_DIR/$script"
done
rm -f "$CODEX_HOME/scripts/codex-usage-snapshot.mjs"

swiftc -parse-as-library -o "$APP_EXE" \
    "$PLUGIN_DIR/sources/QuotaModels.swift" \
    "$PLUGIN_DIR/sources/QuotaSnapshotService.swift" \
    "$PLUGIN_DIR/sources/QuotaStore.swift" \
    "$PLUGIN_DIR/sources/QuotaBubbleApp.swift" \
    -framework Cocoa -framework SwiftUI -framework Combine
chmod +x "$APP_EXE"

if [ -f "$PLUGIN_DIR/assets/AppIcon.icns" ]; then
    cp "$PLUGIN_DIR/assets/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
else
    cp "$PLUGIN_DIR/assets/icon.png" "$INSTALL_DIR/icon.png"
    ICONSET="$INSTALL_DIR/AppIcon.iconset"
    rm -rf "$ICONSET"; mkdir -p "$ICONSET"
    for size in 16 32 128 256 512; do
        sips -z "$size" "$size" "$INSTALL_DIR/icon.png" --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
        double=$((size * 2)); sips -z "$double" "$double" "$INSTALL_DIR/icon.png" --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
    done
    iconutil -c icns "$ICONSET" -o "$APP_DIR/Contents/Resources/AppIcon.icns"
fi

cat > "$APP_DIR/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>Quota Bubble</string>
<key>CFBundleIdentifier</key><string>local.codex.quota-bubble</string>
<key>CFBundleName</key><string>Quota Bubble</string>
<key>CFBundleDisplayName</key><string>Quota Bubble</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundleIconName</key><string>AppIcon</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>$VERSION</string>
<key>CFBundleVersion</key><string>$VERSION</string>
<key>NSHighResolutionCapable</key><true/>
<key>LSMultipleInstancesProhibited</key><true/>
</dict></plist>
PLIST

cat > "$LAUNCH_AGENT" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>Label</key><string>$LABEL</string>
<key>ProgramArguments</key><array><string>/usr/bin/open</string><string>-g</string><string>$APP_DIR</string></array>
<key>RunAtLoad</key><true/>
<key>StandardOutPath</key><string>/tmp/quota-bubble-agent.log</string>
<key>StandardErrorPath</key><string>/tmp/quota-bubble-agent.err</string>
</dict></plist>
PLIST

xattr -dr com.apple.quarantine "$APP_DIR" >/dev/null 2>&1 || true
touch "$APP_DIR"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP_DIR"
launchctl bootstrap "gui/$(id -u)" "$LAUNCH_AGENT"
dedupe_dock_app
if [ "${QUOTA_BUBBLE_SKIP_LAUNCH:-0}" != "1" ]; then open -g "$APP_DIR"; fi

echo "Quota Bubble installed: $APP_DIR"

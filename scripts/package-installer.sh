#!/bin/bash
set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:-$(/usr/bin/python3 - "$PLUGIN_DIR/.codex-plugin/plugin.json" <<'PY'
import json, sys
print(json.load(open(sys.argv[1], encoding="utf-8"))["version"])
PY
)}"
APP_NAME="Install Quota Bubble"
BUILD_DIR="${TMPDIR:-/tmp}/quota-bubble-installer-$VERSION"
INSTALLER_APP="$BUILD_DIR/$APP_NAME.app"
PAYLOAD="$INSTALLER_APP/Contents/Resources/payload"
QUOTA_APP="$PAYLOAD/Quota Bubble.app"
DIST_DIR="$PLUGIN_DIR/dist"
ZIP_PATH="$DIST_DIR/QuotaBubble-$VERSION-macOS-Installer.zip"
SWIFT_TARGET="${QUOTA_BUBBLE_SWIFT_TARGET:-}"
UNIVERSAL="${QUOTA_BUBBLE_UNIVERSAL:-0}"

rm -rf "$BUILD_DIR" "$ZIP_PATH"
mkdir -p "$INSTALLER_APP/Contents/MacOS" "$PAYLOAD/scripts" "$QUOTA_APP/Contents/MacOS" "$QUOTA_APP/Contents/Resources" "$DIST_DIR"

SOURCES=("$PLUGIN_DIR/sources/QuotaModels.swift" "$PLUGIN_DIR/sources/QuotaStore.swift" "$PLUGIN_DIR/sources/QuotaBubbleApp.swift")
if [ "$UNIVERSAL" = "1" ]; then
  swiftc -parse-as-library -target arm64-apple-macosx13.0 -o "$BUILD_DIR/QuotaBubble-arm64" "${SOURCES[@]}" -framework Cocoa -framework SwiftUI -framework Combine
  swiftc -parse-as-library -target x86_64-apple-macosx13.0 -o "$BUILD_DIR/QuotaBubble-x86_64" "${SOURCES[@]}" -framework Cocoa -framework SwiftUI -framework Combine
  lipo -create "$BUILD_DIR/QuotaBubble-arm64" "$BUILD_DIR/QuotaBubble-x86_64" -output "$QUOTA_APP/Contents/MacOS/Quota Bubble"
else
  SWIFT_ARGS=(-parse-as-library)
  if [ -n "$SWIFT_TARGET" ]; then SWIFT_ARGS+=( -target "$SWIFT_TARGET" ); fi
  swiftc "${SWIFT_ARGS[@]}" -o "$QUOTA_APP/Contents/MacOS/Quota Bubble" "${SOURCES[@]}" -framework Cocoa -framework SwiftUI -framework Combine
fi
chmod +x "$QUOTA_APP/Contents/MacOS/Quota Bubble"
cp "$PLUGIN_DIR/assets/AppIcon.icns" "$QUOTA_APP/Contents/Resources/AppIcon.icns"
cp "$PLUGIN_DIR/assets/AppIcon.icns" "$INSTALLER_APP/Contents/Resources/AppIcon.icns"

cat > "$QUOTA_APP/Contents/Info.plist" <<PLIST
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

cat > "$INSTALLER_APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>$APP_NAME</string>
<key>CFBundleIdentifier</key><string>local.codex.quota-bubble.installer</string>
<key>CFBundleName</key><string>$APP_NAME</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundleIconName</key><string>AppIcon</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>$VERSION</string>
<key>CFBundleVersion</key><string>$VERSION</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST

cp "$PLUGIN_DIR/scripts/codex-usage-snapshot.mjs" "$PAYLOAD/scripts/"
for script in ensure-usage-widget.sh start-usage-widget.sh restart.sh status.sh uninstall.sh; do cp "$PLUGIN_DIR/scripts/$script" "$PAYLOAD/scripts/$script"; done

cat > "$INSTALLER_APP/Contents/Resources/install-packaged.sh" <<'SCRIPT'
#!/bin/bash
set -euo pipefail
RESOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"
PAYLOAD="$RESOURCE_DIR/payload"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
INSTALL_DIR="$CODEX_HOME/usage-widget"
APP="/Applications/Quota Bubble.app"
LEGACY_USER_APP="$HOME/Applications/Quota Bubble.app"
LAUNCH_AGENT="$HOME/Library/LaunchAgents/com.codex.usage-widget.autostart.plist"

launchctl bootout "gui/$(id -u)" "$LAUNCH_AGENT" >/dev/null 2>&1 || true
if [ "${QUOTA_BUBBLE_KEEP_RUNNING:-0}" != "1" ]; then
    pkill -f "Quota Bubble.app/Contents/MacOS/Quota Bubble" >/dev/null 2>&1 || true
fi
pkill -f "UsageWidget.app/Contents/MacOS/UsageWidget" >/dev/null 2>&1 || true
pkill -f "Codex Usage Widget.app/Contents/MacOS/Codex Usage Widget" >/dev/null 2>&1 || true
sleep 0.3
rm -rf "$LEGACY_USER_APP" "$HOME/Applications/Codex Usage Widget.app" "$INSTALL_DIR/UsageWidget.app"
mkdir -p "$INSTALL_DIR" "$CODEX_HOME/scripts" "$HOME/Library/LaunchAgents"
if [ -w /Applications ] && { [ ! -e "$APP" ] || [ -w "$APP" ]; }; then
    rm -rf "$APP"
    cp -R "$PAYLOAD/Quota Bubble.app" "$APP"
else
    /usr/bin/osascript - "$PAYLOAD/Quota Bubble.app" "$APP" <<'APPLESCRIPT'
on run argv
    set sourcePath to item 1 of argv
    set destinationPath to item 2 of argv
    do shell script "/bin/rm -rf " & quoted form of destinationPath & " && /bin/cp -R " & quoted form of sourcePath & " " & quoted form of destinationPath with administrator privileges
end run
APPLESCRIPT
fi
cp "$PAYLOAD/scripts/codex-usage-snapshot.mjs" "$CODEX_HOME/scripts/"
for script in ensure-usage-widget.sh start-usage-widget.sh restart.sh status.sh uninstall.sh; do cp "$PAYLOAD/scripts/$script" "$INSTALL_DIR/$script"; chmod +x "$INSTALL_DIR/$script"; done
chmod +x "$CODEX_HOME/scripts/codex-usage-snapshot.mjs"
xattr -dr com.apple.quarantine "$APP" >/dev/null 2>&1 || true
touch "$APP"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP"

cat > "$LAUNCH_AGENT" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>Label</key><string>com.codex.usage-widget.autostart</string>
<key>ProgramArguments</key><array><string>/usr/bin/open</string><string>-g</string><string>$APP</string></array>
<key>RunAtLoad</key><true/>
<key>StandardOutPath</key><string>/tmp/quota-bubble-agent.log</string>
<key>StandardErrorPath</key><string>/tmp/quota-bubble-agent.err</string>
</dict></plist>
PLIST
launchctl bootstrap "gui/$(id -u)" "$LAUNCH_AGENT"

/usr/bin/python3 - "$APP" <<'PY'
import plistlib, subprocess, sys
from pathlib import Path
from urllib.parse import unquote, urlparse
from urllib.request import url2pathname
app = str(Path(sys.argv[1]).resolve()); url = Path(app).as_uri(); p = Path.home()/"Library/Preferences/com.apple.dock.plist"
data = plistlib.load(p.open("rb")) if p.exists() else {}; apps = data.get("persistent-apps", [])
def path(item):
    v=item.get("tile-data",{}).get("file-data",{}).get("_CFURLString",""); u=urlparse(v)
    return (url2pathname(unquote(u.path)) if u.scheme=="file" else unquote(v).replace("file://","")).rstrip("/")
entry={"tile-data":{"file-data":{"_CFURLString":url,"_CFURLStringType":15},"file-label":"Quota Bubble"},"tile-type":"file-tile"}
new=[]; added=False
for item in apps:
    if path(item).endswith(("/Quota Bubble.app","/Codex Usage Widget.app")):
        if not added: new.append(entry); added=True
    else: new.append(item)
if not added: new.append(entry)
if new != apps:
    data["persistent-apps"]=new; plistlib.dump(data,p.open("wb")); subprocess.run(["killall","Dock"],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
PY

if [ "${QUOTA_BUBBLE_SKIP_LAUNCH:-0}" != "1" ]; then open -g "$APP"; fi
echo "Quota Bubble installed."
SCRIPT
chmod +x "$INSTALLER_APP/Contents/Resources/install-packaged.sh"

cat > "$INSTALLER_APP/Contents/MacOS/$APP_NAME" <<'SCRIPT'
#!/bin/bash
set -euo pipefail
APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
if OUTPUT="$(/bin/bash "$APP_DIR/Resources/install-packaged.sh" 2>&1)"; then
    /usr/bin/osascript -e 'display dialog "Quota Bubble installed successfully." buttons {"OK"} default button "OK" with title "Quota Bubble"'
else
    MESSAGE="$(printf '%s' "$OUTPUT" | tail -n 10 | sed 's/"/\\"/g')"
    /usr/bin/osascript -e "display dialog \"Install failed:\n$MESSAGE\" buttons {\"OK\"} default button \"OK\" with title \"Quota Bubble\""
    exit 1
fi
SCRIPT
chmod +x "$INSTALLER_APP/Contents/MacOS/$APP_NAME"

(cd "$BUILD_DIR" && zip -qry "$ZIP_PATH" "$APP_NAME.app")
echo "$ZIP_PATH"

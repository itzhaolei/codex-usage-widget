#!/usr/bin/env bash
set -euo pipefail

# Build the Flutter macOS bundle and wrap it in the installer used by the
# public download page.

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:?usage: scripts/package-flutter-macos.sh VERSION}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"
FLUTTER_BIN="${FLUTTER_BIN:-flutter}"
APP_NAME="Install Quota Bubble"
BUILD_DIR="${TMPDIR:-/tmp}/quota-bubble-flutter-installer-$VERSION"
INSTALLER_APP="$BUILD_DIR/$APP_NAME.app"
PAYLOAD="$INSTALLER_APP/Contents/Resources/payload"
QUOTA_APP="$PAYLOAD/Quota Bubble.app"
DIST_DIR="$ROOT/dist"
ZIP_PATH="$DIST_DIR/QuotaBubble-$VERSION-macOS-Installer.zip"
BUILT_APP="$ROOT/build/macos/Build/Products/Release/quota_bubble.app"
ICON_BASENAME="AppIcon-$VERSION"

rm -rf "$BUILD_DIR" "$ZIP_PATH"
mkdir -p "$INSTALLER_APP/Contents/MacOS" "$PAYLOAD/scripts" "$DIST_DIR"

cd "$ROOT"
"$FLUTTER_BIN" pub get

# Flutter's current default can be arm64-only on Apple Silicon.  Keep the
# release universal until Intel support is deliberately removed from the
# product.  Older Flutter versions do not know this setting, so tolerate the
# command failing and let the build provide its normal architecture.
"$FLUTTER_BIN" config --no-enable-macos-arm64-only >/dev/null 2>&1 || true
"$FLUTTER_BIN" build macos --release \
  --build-name "$VERSION" \
  --build-number "$BUILD_NUMBER"

if [ ! -d "$BUILT_APP" ] && [ -d "$ROOT/build/macos/Build/Products/Release/QuotaBubble.app" ]; then
  BUILT_APP="$ROOT/build/macos/Build/Products/Release/QuotaBubble.app"
fi
if [ ! -d "$BUILT_APP" ] && [ -d "$ROOT/build/macos/Build/Products/Release/Quota Bubble.app" ]; then
  BUILT_APP="$ROOT/build/macos/Build/Products/Release/Quota Bubble.app"
fi
if [ ! -d "$BUILT_APP" ]; then
  echo "Flutter macOS bundle was not created below build/macos/Build/Products/Release" >&2
  exit 1
fi

cp -R "$BUILT_APP" "$QUOTA_APP"
cp "$ROOT/assets/AppIcon.icns" "$INSTALLER_APP/Contents/Resources/$ICON_BASENAME.icns"

# Keep the installed app identity unchanged. Changing Info.plist invalidates
# the outer code seal, so sign that bundle again after all metadata edits.
# Nested frameworks are copied intact and retain their existing signatures.
INFO_PLIST="$QUOTA_APP/Contents/Info.plist"
BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$INFO_PLIST")"
if [ "$BUNDLE_ID" != "local.codex.quota-bubble" ]; then
  echo "Unexpected macOS bundle identifier: $BUNDLE_ID" >&2
  exit 1
fi
/usr/libexec/PlistBuddy -c "Set :CFBundleName Quota Bubble" "$INFO_PLIST"
if /usr/libexec/PlistBuddy -c 'Print :CFBundleDisplayName' "$INFO_PLIST" >/dev/null 2>&1; then
  /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName Quota Bubble" "$INFO_PLIST"
else
  /usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string Quota Bubble" "$INFO_PLIST"
fi
/usr/bin/codesign --force --sign "${QUOTA_BUBBLE_CODESIGN_IDENTITY:--}" \
  --preserve-metadata=entitlements,requirements,flags,runtime "$QUOTA_APP"
/usr/bin/codesign --verify --deep --strict --verbose=2 "$QUOTA_APP"

for script in ensure-usage-widget.sh start-usage-widget.sh restart.sh status.sh uninstall.sh; do
  cp "$ROOT/scripts/$script" "$PAYLOAD/scripts/$script"
done

cat > "$INSTALLER_APP/Contents/Resources/install-packaged.sh" <<'INSTALL_SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

replace_app() {
  local source_app="$1"
  local destination_app="$2"
  local destination_dir app_name staged_app backup_app
  local previous_app_moved=0

  destination_dir="$(dirname "$destination_app")"
  app_name="$(basename "$destination_app")"
  staged_app="$destination_dir/.$app_name.install.$$"
  backup_app="$destination_dir/.$app_name.backup.$$"

  if [ ! -d "$source_app" ] || [ ! -f "$source_app/Contents/Info.plist" ]; then
    echo "Installer payload is not a valid application bundle: $source_app" >&2
    return 1
  fi

  rollback_app() {
    local status=$?
    trap - EXIT HUP INT TERM
    rm -rf "$staged_app"
    if [ "$previous_app_moved" = "1" ] && { [ -e "$backup_app" ] || [ -L "$backup_app" ]; }; then
      rm -rf "$destination_app"
      if ! mv "$backup_app" "$destination_app"; then
        echo "Could not restore the previous application from $backup_app" >&2
      fi
    fi
    exit "$status"
  }

  trap rollback_app EXIT
  trap 'exit 1' HUP INT TERM
  rm -rf "$staged_app" "$backup_app"
  cp -R "$source_app" "$staged_app"
  test -f "$staged_app/Contents/Info.plist"
  if [ -e "$destination_app" ] || [ -L "$destination_app" ]; then
    mv "$destination_app" "$backup_app"
    previous_app_moved=1
  fi
  mv "$staged_app" "$destination_app"
  test -f "$destination_app/Contents/Info.plist"

  previous_app_moved=0
  rm -rf "$backup_app" || true
  trap - EXIT HUP INT TERM
}

if [ "${1:-}" = "--replace-app" ]; then
  if [ "$#" -ne 3 ]; then
    echo "usage: install-packaged.sh --replace-app SOURCE_APP DESTINATION_APP" >&2
    exit 2
  fi
  replace_app "$2" "$3"
  exit 0
fi

RESOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"
PAYLOAD="$RESOURCE_DIR/payload"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
INSTALL_DIR="$CODEX_HOME/usage-widget"
APP="/Applications/Quota Bubble.app"
LEGACY_USER_APP="$HOME/Applications/Quota Bubble.app"
LAUNCH_AGENT="$HOME/Library/LaunchAgents/com.codex.usage-widget.autostart.plist"

launchctl bootout "gui/$(id -u)" "$LAUNCH_AGENT" >/dev/null 2>&1 || true
if [ "${QUOTA_BUBBLE_KEEP_RUNNING:-0}" != "1" ]; then
  pkill -f "Quota Bubble.app/Contents/MacOS/" >/dev/null 2>&1 || true
  pkill -f "quota_bubble.app/Contents/MacOS/" >/dev/null 2>&1 || true
fi
sleep 0.3
rm -rf "$LEGACY_USER_APP" "$HOME/Applications/Codex Usage Widget.app" "$INSTALL_DIR/UsageWidget.app"
mkdir -p "$INSTALL_DIR" "$HOME/Library/LaunchAgents"
if [ -w /Applications ] && { [ ! -e "$APP" ] || [ -w "$APP" ]; }; then
  replace_app "$PAYLOAD/Quota Bubble.app" "$APP"
else
  /usr/bin/osascript - "$RESOURCE_DIR/install-packaged.sh" "$PAYLOAD/Quota Bubble.app" "$APP" <<'APPLESCRIPT'
on run argv
  set installerScript to item 1 of argv
  set sourcePath to item 2 of argv
  set destinationPath to item 3 of argv
  do shell script "/bin/bash " & quoted form of installerScript & " --replace-app " & quoted form of sourcePath & " " & quoted form of destinationPath with administrator privileges
end run
APPLESCRIPT
fi
for script in ensure-usage-widget.sh start-usage-widget.sh restart.sh status.sh uninstall.sh; do
  cp "$PAYLOAD/scripts/$script" "$INSTALL_DIR/$script"
  chmod +x "$INSTALL_DIR/$script"
done
rm -f "$CODEX_HOME/scripts/codex-usage-snapshot.mjs" "$CODEX_HOME/codex-usage-snapshot.json"
xattr -dr com.apple.quarantine "$APP" >/dev/null 2>&1 || true
touch "$APP"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP"

# Keep one persistent Dock entry for the product. A development build or a
# previous per-user install can otherwise leave visually identical entries.
# In-app updates deliberately skip this step so replacing the running bundle
# does not rewrite the user's Dock or restart it underneath the app.
if [ "${QUOTA_BUBBLE_SKIP_DOCK:-0}" != "1" ]; then
if [ -x /usr/bin/python3 ]; then
/usr/bin/python3 - "$APP" <<'PY'
import os
import plistlib
import sys
import tempfile
from pathlib import Path
from urllib.parse import unquote, urlparse
from urllib.request import url2pathname

app = str(Path(sys.argv[1]).resolve())
plist_path = Path.home() / "Library/Preferences/com.apple.dock.plist"
known_ids = {
    "local.codex.quota-bubble",
    "local.codex.quota-bubble.installer",
    "com.itzhaolei.quotaBubble",
}
known_names = {
    "Quota Bubble.app",
    "QuotaBubble.app",
    "quota_bubble.app",
    "Install Quota Bubble.app",
    "Codex Usage Widget.app",
    "UsageWidget.app",
}

def item_path(item):
    value = item.get("tile-data", {}).get("file-data", {}).get("_CFURLString", "")
    parsed = urlparse(value)
    if parsed.scheme == "file":
        return str(Path(url2pathname(unquote(parsed.path))).resolve())
    return str(Path(unquote(value).replace("file://", "")).resolve()) if value else ""

def bundle_identifier(path):
    if not path:
        return ""
    info = Path(path) / "Contents" / "Info.plist"
    try:
        with info.open("rb") as handle:
            return plistlib.load(handle).get("CFBundleIdentifier", "")
    except (FileNotFoundError, OSError, plistlib.InvalidFileException, EOFError):
        return ""

def is_quota_item(item):
    tile = item.get("tile-data", {})
    if tile.get("bundle-identifier") in known_ids:
        return True
    path = item_path(item)
    return Path(path).name in known_names or bundle_identifier(path) in known_ids

try:
    with plist_path.open("rb") as handle:
        data = plistlib.load(handle)
except (FileNotFoundError, plistlib.InvalidFileException, EOFError):
    data = {}

apps = data.get("persistent-apps", [])
matching = [item for item in apps if is_quota_item(item)]
canonical = next((item for item in matching if item_path(item) == app), None)
if canonical is None:
    canonical = {
        "tile-data": {
            "file-data": {"_CFURLString": Path(app).as_uri(), "_CFURLStringType": 15},
            "file-label": "Quota Bubble",
            "bundle-identifier": "local.codex.quota-bubble",
        },
        "tile-type": "file-tile",
    }
else:
    tile = canonical.setdefault("tile-data", {})
    tile.setdefault("file-data", {})["_CFURLString"] = Path(app).as_uri()
    tile["file-data"]["_CFURLStringType"] = 15
    tile["file-label"] = "Quota Bubble"
    tile["bundle-identifier"] = "local.codex.quota-bubble"

new_apps = []
inserted = False
for item in apps:
    if is_quota_item(item):
        if not inserted:
            new_apps.append(canonical)
            inserted = True
        continue
    new_apps.append(item)
if not inserted:
    new_apps.append(canonical)

recent = data.get("recent-apps", [])
# Dock may retain duplicate recent tiles after an app bundle is replaced.
# Collapse only exact bundle/path identities and preserve other recent apps.
new_recent = []
seen_recent = set()
for item in recent:
    if is_quota_item(item):
        continue
    tile = item.get("tile-data", {})
    bundle_id = tile.get("bundle-identifier", "")
    path = item_path(item)
    identity = (bundle_id, path) if bundle_id or path else None
    if identity is not None:
        if identity in seen_recent:
            continue
        seen_recent.add(identity)
    new_recent.append(item)
if new_apps != apps or new_recent != recent or not plist_path.exists():
    data["persistent-apps"] = new_apps
    data["recent-apps"] = new_recent
    plist_path.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(prefix="com.apple.dock.", suffix=".plist", dir=plist_path.parent)
    os.close(fd)
    try:
        with open(temporary, "wb") as handle:
            plistlib.dump(data, handle, sort_keys=False)
        os.replace(temporary, plist_path)
    finally:
        try:
            os.unlink(temporary)
        except FileNotFoundError:
            pass
PY
else
if ! /usr/bin/defaults read com.apple.dock persistent-apps 2>/dev/null | /usr/bin/grep -Eq 'Quota(%20| )Bubble\.app'; then
  /usr/bin/defaults write com.apple.dock persistent-apps -array-add '<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>file:///Applications/Quota%20Bubble.app/</string><key>_CFURLStringType</key><integer>15</integer></dict><key>file-label</key><string>Quota Bubble</string></dict><key>tile-type</key><string>file-tile</string></dict>'
fi
fi
/usr/bin/killall Dock >/dev/null 2>&1 || true
fi

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
launchctl bootstrap "gui/$(id -u)" "$LAUNCH_AGENT" 2>/dev/null || launchctl kickstart -k "gui/$(id -u)/com.codex.usage-widget.autostart" || true

if [ "${QUOTA_BUBBLE_SKIP_LAUNCH:-0}" != "1" ]; then
  open -g "$APP"
fi
echo "Quota Bubble installed."
INSTALL_SCRIPT
chmod +x "$INSTALLER_APP/Contents/Resources/install-packaged.sh"

cat > "$INSTALLER_APP/Contents/MacOS/$APP_NAME" <<'INSTALLER'
#!/usr/bin/env bash
set -euo pipefail
APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
if OUTPUT="$(/bin/bash "$APP_DIR/Resources/install-packaged.sh" 2>&1)"; then
  /usr/bin/osascript -e 'display dialog "Quota Bubble installed successfully." buttons {"OK"} default button "OK" with title "Quota Bubble"'
else
  MESSAGE="$(printf '%s' "$OUTPUT" | tail -n 10 | sed 's/"/\\"/g')"
  /usr/bin/osascript -e "display dialog \"Install failed:\n$MESSAGE\" buttons {\"OK\"} with title \"Quota Bubble\""
  exit 1
fi
INSTALLER
chmod +x "$INSTALLER_APP/Contents/MacOS/$APP_NAME"

cat > "$INSTALLER_APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>$APP_NAME</string>
<key>CFBundleIdentifier</key><string>local.codex.quota-bubble.installer</string>
<key>CFBundleName</key><string>$APP_NAME</string>
<key>CFBundleDisplayName</key><string>$APP_NAME</string>
<key>CFBundleIconFile</key><string>$ICON_BASENAME.icns</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>$VERSION</string>
<key>CFBundleVersion</key><string>$VERSION</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST

(cd "$BUILD_DIR" && zip -qry "$ZIP_PATH" "$APP_NAME.app")
echo "$ZIP_PATH"

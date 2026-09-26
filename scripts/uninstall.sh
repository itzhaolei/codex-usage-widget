#!/bin/bash
set -euo pipefail
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
APP="/Applications/Quota Bubble.app"
LEGACY_USER_APP="$HOME/Applications/Quota Bubble.app"
LAUNCH_AGENT="$HOME/Library/LaunchAgents/com.codex.usage-widget.autostart.plist"
launchctl bootout "gui/$(id -u)" "$LAUNCH_AGENT" >/dev/null 2>&1 || true
PATTERN='(Quota Bubble|quota_bubble|QuotaBubble)[.]app/Contents/MacOS/(Quota Bubble|quota_bubble|QuotaBubble)([[:space:]]|$)'
pkill -f "$PATTERN" >/dev/null 2>&1 || true
pkill -f "UsageWidget.app/Contents/MacOS/UsageWidget" >/dev/null 2>&1 || true
rm -f "$LAUNCH_AGENT"
rm -rf "$LEGACY_USER_APP" "$HOME/Applications/Codex Usage Widget.app" "$CODEX_HOME/usage-widget"
if [ -e "$APP" ]; then
    if [ -w "$APP" ]; then
        rm -rf "$APP"
    else
        /usr/bin/osascript - "$APP" <<'APPLESCRIPT'
on run argv
    do shell script "/bin/rm -rf " & quoted form of (item 1 of argv) with administrator privileges
end run
APPLESCRIPT
    fi
fi
rm -f "$CODEX_HOME/scripts/codex-usage-snapshot.mjs"
if [ -x /usr/bin/python3 ]; then
/usr/bin/python3 - <<'PY'
import plistlib, subprocess
from pathlib import Path
from urllib.parse import unquote, urlparse
from urllib.request import url2pathname
p = Path.home() / "Library/Preferences/com.apple.dock.plist"
if p.exists():
    data = plistlib.load(p.open("rb"))
    apps = data.get("persistent-apps", [])
    def path(item):
        value = item.get("tile-data", {}).get("file-data", {}).get("_CFURLString", "")
        parsed = urlparse(value)
        return (url2pathname(unquote(parsed.path)) if parsed.scheme == "file" else unquote(value).replace("file://", "")).rstrip("/")
    legacy_ids = {
        "local.codex.quota-bubble",
        "local.codex.quota-bubble.installer",
        "com.itzhaolei.quotaBubble",
    }
    legacy_names = {
        "Quota Bubble.app",
        "QuotaBubble.app",
        "quota_bubble.app",
        "Install Quota Bubble.app",
        "Codex Usage Widget.app",
        "UsageWidget.app",
    }
    def bundle_id(app_path):
        info = Path(app_path) / "Contents" / "Info.plist"
        try:
            return plistlib.load(info.open("rb")).get("CFBundleIdentifier", "")
        except (FileNotFoundError, OSError, plistlib.InvalidFileException, EOFError):
            return ""
    def is_quota(item):
        tile = item.get("tile-data", {})
        app_path = path(item)
        return (tile.get("bundle-identifier") in legacy_ids or
                Path(app_path).name in legacy_names or
                bundle_id(app_path) in legacy_ids)
    new = [item for item in apps if not is_quota(item)]
    recent = data.get("recent-apps", [])
    # Collapse only exact bundle/path identities; preserve other recent apps.
    new_recent = []
    seen_recent = set()
    for item in recent:
        if is_quota(item):
            continue
        tile = item.get("tile-data", {})
        bundle_id = tile.get("bundle-identifier", "")
        app_path = path(item)
        identity = (bundle_id, app_path) if bundle_id or app_path else None
        if identity is not None:
            if identity in seen_recent:
                continue
            seen_recent.add(identity)
        new_recent.append(item)
    if new != apps or new_recent != recent:
        data["persistent-apps"] = new
        data["recent-apps"] = new_recent
        plistlib.dump(data, p.open("wb"))
        subprocess.run(["killall", "Dock"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
PY
fi
echo "Quota Bubble uninstalled."

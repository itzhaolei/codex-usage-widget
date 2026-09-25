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
        "Codex Usage Widget.app",
        "UsageWidget.app",
    }
    def is_quota(item):
        tile = item.get("tile-data", {})
        return tile.get("bundle-identifier") in legacy_ids or Path(path(item)).name in legacy_names
    new = [item for item in apps if not is_quota(item)]
    if new != apps:
        data["persistent-apps"] = new
        plistlib.dump(data, p.open("wb"))
        subprocess.run(["killall", "Dock"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
PY
echo "Quota Bubble uninstalled."

#!/bin/bash
set -euo pipefail
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
APP="$HOME/Applications/Quota Bubble.app"
LAUNCH_AGENT="$HOME/Library/LaunchAgents/com.codex.usage-widget.autostart.plist"
launchctl bootout "gui/$(id -u)" "$LAUNCH_AGENT" >/dev/null 2>&1 || true
pkill -f "Quota Bubble.app/Contents/MacOS/Quota Bubble" >/dev/null 2>&1 || true
pkill -f "UsageWidget.app/Contents/MacOS/UsageWidget" >/dev/null 2>&1 || true
rm -f "$LAUNCH_AGENT"
rm -rf "$APP" "$HOME/Applications/Codex Usage Widget.app" "$CODEX_HOME/usage-widget"
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
    new = [item for item in apps if not path(item).endswith(("/Quota Bubble.app", "/Codex Usage Widget.app"))]
    if new != apps:
        data["persistent-apps"] = new
        plistlib.dump(data, p.open("wb"))
        subprocess.run(["killall", "Dock"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
PY
echo "Quota Bubble uninstalled."

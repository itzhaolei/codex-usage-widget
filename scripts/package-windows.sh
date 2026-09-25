#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:?usage: scripts/package-windows.sh VERSION}"
PUBLISH_DIR="$ROOT/windows/publish"
ISCC="${ISCC:-/c/Program Files (x86)/Inno Setup 6/ISCC.exe}"

if ! command -v powershell.exe >/dev/null 2>&1 || ! command -v cygpath >/dev/null 2>&1; then
    echo "Run this Flutter packager from Git Bash on Windows." >&2
    exit 1
fi
if ! command -v magick >/dev/null 2>&1; then
    echo "The Windows packager requires ImageMagick to create the application icon." >&2
    exit 1
fi
if [ ! -x "$ISCC" ]; then
    echo "Inno Setup 6 was not found at $ISCC." >&2
    exit 1
fi

mkdir -p "$ROOT/dist"
magick "$ROOT/assets/icon.png" -define icon:auto-resize=256,128,64,48,32,16 "$ROOT/windows/runner/resources/app_icon.ico"
magick "$ROOT/assets/icon.png" -define icon:auto-resize=256,128,64,48,32,16 "$ROOT/windows/QuotaBubble.ico"
powershell.exe -NoProfile -ExecutionPolicy Bypass \
    -File "$(cygpath -w "$ROOT/scripts/package-flutter-windows.ps1")" "$VERSION"
"$ISCC" "/DMyAppVersion=$VERSION" "/DPublishDir=$PUBLISH_DIR" "$ROOT/windows/installer.iss"

echo "$ROOT/dist/QuotaBubble-$VERSION-Windows-Setup.exe"

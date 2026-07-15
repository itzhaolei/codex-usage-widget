#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:?usage: scripts/package-windows.sh VERSION}"
PUBLISH_DIR="$ROOT/windows/publish"
ISCC="${ISCC:-/c/Program Files (x86)/Inno Setup 6/ISCC.exe}"

if ! command -v dotnet >/dev/null 2>&1; then
    echo "The Windows packager requires the .NET 8 SDK." >&2
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

rm -rf "$PUBLISH_DIR"
mkdir -p "$PUBLISH_DIR" "$ROOT/dist"
magick "$ROOT/assets/icon.png" -define icon:auto-resize=256,128,64,48,32,16 "$ROOT/windows/QuotaBubble.ico"
dotnet publish "$ROOT/windows/QuotaBubble/QuotaBubble.csproj" \
    --configuration Release --runtime win-x64 --self-contained true \
    -p:Version="$VERSION" -p:PublishSingleFile=true \
    --output "$PUBLISH_DIR"
"$ISCC" "/DMyAppVersion=$VERSION" "/DPublishDir=$PUBLISH_DIR" "$ROOT/windows/installer.iss"

echo "$ROOT/dist/QuotaBubble-$VERSION-Windows-Setup.exe"

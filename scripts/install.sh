#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FLUTTER_BIN="${FLUTTER_BIN:-flutter}"
VERSION="$(/usr/bin/awk '/^version:/ { split($2, parts, "+"); print parts[1]; exit }' "$ROOT/pubspec.yaml")"

if [ -z "$VERSION" ]; then
  echo "Could not read the application version from pubspec.yaml." >&2
  exit 1
fi
if ! command -v "$FLUTTER_BIN" >/dev/null 2>&1; then
  echo "Flutter is required to build Quota Bubble from source." >&2
  exit 1
fi

TEMP_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

FLUTTER_BIN="$FLUTTER_BIN" bash "$ROOT/scripts/package-flutter-macos.sh" "$VERSION"
/usr/bin/ditto -x -k \
  "$ROOT/dist/QuotaBubble-$VERSION-macOS-Installer.zip" \
  "$TEMP_DIR"
/bin/bash "$TEMP_DIR/Install Quota Bubble.app/Contents/Resources/install-packaged.sh"

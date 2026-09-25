#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FLUTTER_BIN="${FLUTTER_BIN:-flutter}"

bash -n "$ROOT"/scripts/{bootstrap-install,ensure-usage-widget,install,package-flutter-macos,restart,start-usage-widget,status,uninstall}.sh

grep -q 'persistent-apps' "$ROOT/scripts/package-flutter-macos.sh"
grep -q 'local.codex.quota-bubble' "$ROOT/scripts/package-flutter-macos.sh"
grep -q 'killall Dock' "$ROOT/scripts/package-flutter-macos.sh"
grep -q 'persistent-apps' "$ROOT/scripts/uninstall.sh"

cd "$ROOT"
"$FLUTTER_BIN" pub get
"$FLUTTER_BIN" analyze
"$FLUTTER_BIN" test
"$FLUTTER_BIN" build macos --debug --no-pub

echo "macOS Flutter checks passed."

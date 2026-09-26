#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FLUTTER_BIN="${FLUTTER_BIN:-flutter}"

bash -n "$ROOT"/scripts/{bootstrap-install,ensure-usage-widget,install,package-flutter-macos,restart,start-usage-widget,status,uninstall}.sh

grep -q 'persistent-apps' "$ROOT/scripts/package-flutter-macos.sh"
grep -q 'local.codex.quota-bubble' "$ROOT/scripts/package-flutter-macos.sh"
grep -q 'killall Dock' "$ROOT/scripts/package-flutter-macos.sh"
grep -q 'recent-apps' "$ROOT/scripts/package-flutter-macos.sh"
grep -q 'Install Quota Bubble.app' "$ROOT/scripts/package-flutter-macos.sh"
grep -q '/usr/bin/defaults write com.apple.dock persistent-apps' "$ROOT/scripts/package-flutter-macos.sh"
grep -q 'persistent-apps' "$ROOT/scripts/uninstall.sh"
grep -q 'if \[ -x /usr/bin/python3 \]' "$ROOT/scripts/uninstall.sh"
grep -q 'MACOSX_DEPLOYMENT_TARGET = 13.0;' "$ROOT/macos/Runner.xcodeproj/project.pbxproj"

cd "$ROOT"
"$FLUTTER_BIN" pub get
"$FLUTTER_BIN" analyze
"$FLUTTER_BIN" test
"$FLUTTER_BIN" build macos --debug --no-pub

echo "macOS Flutter checks passed."

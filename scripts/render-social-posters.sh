#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
PAGE="file://$ROOT/assets/social/posters.html"

for item in "1:quota-live" "2:privacy" "3:native-glass"; do
  index="${item%%:*}"
  name="${item#*:}"
  "$CHROME" --headless=new --hide-scrollbars --disable-gpu \
    --force-device-scale-factor=1 --window-size=1080,1920 \
    --screenshot="$ROOT/assets/social/$name.png" "$PAGE?poster=$index"
done

echo "Social posters rendered to $ROOT/assets/social"

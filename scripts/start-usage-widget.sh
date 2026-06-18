#!/bin/bash
# 启动 Codex 配额进度浮动窗
# 先刷新快照，再启动应用

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"

# 刷新快照
node "$HOME/.codex/scripts/codex-usage-snapshot.mjs" >/dev/null 2>&1

# 启动浮动窗（如果已在运行则先 kill）
PID=$(pgrep -f "$SCRIPT_DIR/UsageWidget.app/Contents/MacOS/UsageWidget" 2>/dev/null)
if [ -n "$PID" ]; then
    kill "$PID" 2>/dev/null
    sleep 0.5
fi

touch "$SCRIPT_DIR/UsageWidget.app"
open -n "$SCRIPT_DIR/UsageWidget.app"
echo "UsageWidget started"

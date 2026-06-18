#!/bin/bash
# 启动 Codex 配额进度浮动窗
# 委托 restart.sh 刷新快照并保持单实例

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

exec bash "$SCRIPT_DIR/restart.sh"

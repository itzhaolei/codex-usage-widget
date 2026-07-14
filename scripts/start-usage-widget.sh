#!/bin/bash
# 启动单进程 SwiftUI Quota Bubble

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

exec bash "$SCRIPT_DIR/restart.sh"

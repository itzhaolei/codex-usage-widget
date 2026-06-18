#!/bin/bash
# Ensure the Codex quota widget appears while Codex is running.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CODEX_EXE="/Applications/Codex.app/Contents/MacOS/Codex"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
WIDGET_APP="$SCRIPT_DIR/UsageWidget.app"
WIDGET_EXE="$WIDGET_APP/Contents/MacOS/UsageWidget"
CLOSED_MARKER="$SCRIPT_DIR/.closed-by-user"
LOCK_DIR="/tmp/codex-usage-widget.ensure.lock"
SNAPSHOT_SCRIPT="$CODEX_HOME/scripts/codex-usage-snapshot.mjs"
SNAPSHOT_PATH="$CODEX_HOME/codex-usage-snapshot.json"
LAUNCH_PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/opt/homebrew/sbin:/usr/sbin"

if ! mkdir "$LOCK_DIR" 2>/dev/null; then
    exit 0
fi
trap 'rmdir "$LOCK_DIR" >/dev/null 2>&1' EXIT

codex_running() {
    pgrep -x Codex >/dev/null 2>&1 && return 0
    ps ax -o command= | grep -F "$CODEX_EXE" | grep -v grep >/dev/null 2>&1
}

widget_running() {
    ps ax -o command= | grep -Fx "$WIDGET_EXE" >/dev/null 2>&1
}

widget_pids() {
    pgrep -f "$WIDGET_EXE" 2>/dev/null | sort -n
}

keep_single_widget() {
    local keep_pid=""
    local pid=""

    for pid in $(widget_pids); do
        if [ -z "$keep_pid" ]; then
            keep_pid="$pid"
        else
            kill "$pid" >/dev/null 2>&1
        fi
    done
}

run_snapshot() {
    if [ ! -f "$SNAPSHOT_SCRIPT" ]; then
        return 0
    fi

    PATH="$LAUNCH_PATH" node "$SNAPSHOT_SCRIPT" "$SNAPSHOT_PATH" >/dev/null 2>&1 && return 0
    /bin/zsh -lc 'node "$1" "$2"' zsh "$SNAPSHOT_SCRIPT" "$SNAPSHOT_PATH" >/dev/null 2>&1 || true
}

if codex_running; then
    if [ -f "$CLOSED_MARKER" ]; then
        for PID in $(widget_pids); do
            kill "$PID" >/dev/null 2>&1
        done
        exit 0
    fi

    keep_single_widget
    if ! widget_running; then
        run_snapshot
        touch "$WIDGET_APP"
        if ! widget_running; then
            open "$WIDGET_APP"
        fi
    fi
else
    rm -f "$CLOSED_MARKER" >/dev/null 2>&1
    for PID in $(widget_pids); do
        kill "$PID" >/dev/null 2>&1
    done
fi

#!/bin/bash
set -euo pipefail

MESSAGE="${1:-}"

if [ -z "$MESSAGE" ]; then
    echo "Usage: bash scripts/git-sync.sh \"commit message\"" >&2
    exit 1
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "This directory is not a git repository." >&2
    exit 1
fi

if ! git remote get-url origin >/dev/null 2>&1; then
    echo "Missing git remote: origin" >&2
    exit 1
fi

git add .

if git diff --cached --quiet; then
    echo "No changes to commit."
    exit 0
fi

git commit -m "$MESSAGE"
git push

echo "Committed and pushed: $MESSAGE"

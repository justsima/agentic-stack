#!/usr/bin/env bash
# Stop hook — runs when Claude declares done. The CRITICAL pattern here is the
# `stop_hook_active` guard. Without it, exit 2 (asking Claude to keep working)
# triggers Claude to re-run, which triggers Stop again, ad infinitum.
# Issues #54360, #55754 cost users 50-minute infinite loops.

set -uo pipefail
input=$(cat)

stop_active=$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null)
if [ "$stop_active" = "true" ]; then
  exit 0
fi

if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  uncommitted=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  if [ "${uncommitted:-0}" -gt 0 ]; then
    echo "[verify-before-stop] note: $uncommitted uncommitted change(s) at session end. Consider /commit if intentional." >&2
  fi
fi

exit 0

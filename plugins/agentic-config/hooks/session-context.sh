#!/usr/bin/env bash
# SessionStart hook — emits a one-shot context block prepended to Claude's
# awareness for the session. Token cost is one-time. Skip on resume/clear.

set -uo pipefail

input=$(cat 2>/dev/null || echo '{}')
source=$(printf '%s' "$input" | jq -r '.source // "startup"' 2>/dev/null)
if [ "$source" = "resume" ] || [ "$source" = "clear" ]; then
  exit 0
fi

cwd=$(pwd)
when=$(date +"%Y-%m-%d %H:%M %Z")

echo "## Session context (injected $when)"
echo ""
echo "**Working directory:** \`$cwd\`"

if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  upstream=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || echo "no upstream")
  echo "**Git branch:** \`$branch\` (upstream: $upstream)"
  ahead_behind=$(git rev-list --left-right --count HEAD...@{u} 2>/dev/null || echo "")
  if [ -n "$ahead_behind" ]; then
    ahead=$(echo "$ahead_behind" | awk '{print $1}')
    behind=$(echo "$ahead_behind" | awk '{print $2}')
    if [ "$ahead" != "0" ] || [ "$behind" != "0" ]; then
      echo "**Sync:** $ahead ahead, $behind behind"
    fi
  fi
  echo ""
  echo "**Recent commits:**"
  git log --oneline -3 2>/dev/null | sed 's/^/- /'
fi

if [ -d ~/.agentmemory ]; then
  echo ""
  echo "**Agentmemory:** active. Cross-project memory via \`mcp__agentmemory__memory_recall\`."
fi

if [ -f ~/agentic-wiki/hot.md ]; then
  echo "**Wiki hot-cache:** \`~/agentic-wiki/hot.md\` — read first for recent context."
fi

exit 0

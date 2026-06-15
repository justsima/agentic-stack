#!/usr/bin/env bash
# PreToolUse hook matcher=Bash — blocks compound-command dangers that slip past
# permission wildcards. permissions.deny catches simple cases (rm -rf /, sudo)
# but Bash(git:*) lets through "git add && rm -rf /tmp/x" because the wildcard
# only sees the first word. This hook reads the full command and blocks the
# whole string.
#
# Exit 0 → allow. Exit 2 with reason on stderr → deny + tell Claude why.

set -uo pipefail

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -z "$cmd" ] && exit 0

deny_patterns=(
  'rm[[:space:]]+-rf[[:space:]]+/($|[[:space:]])'
  'rm[[:space:]]+-rf[[:space:]]+~($|[[:space:]])'
  'rm[[:space:]]+-rf[[:space:]]+\$HOME'
  '(^|[[:space:]&|;])sudo[[:space:]]'
  '(^|[[:space:]&|;])su[[:space:]]+-'
  'dd[[:space:]]+.*of=/dev/(sd|nvme|disk)'
  'mkfs\.'
  '>[[:space:]]*/dev/(sd|nvme|disk)'
  'chmod[[:space:]]+-?-?[Rr]?[[:space:]]*777'
  'curl[[:space:]]+[^|]*\|[[:space:]]*(sh|bash|zsh)([[:space:]]|$)'
  'wget[[:space:]]+[^|]*\|[[:space:]]*(sh|bash|zsh)([[:space:]]|$)'
  'git[[:space:]]+push[[:space:]]+(-f|--force)([[:space:]]|$)'
  'git[[:space:]]+reset[[:space:]]+--hard[[:space:]]+origin'
  'git[[:space:]]+filter-branch'
  ':\(\)\{[[:space:]]*:\|:&[[:space:]]*\};:'
  '(DROP|TRUNCATE)[[:space:]]+(TABLE|DATABASE|SCHEMA)[[:space:]]'
)

for pattern in "${deny_patterns[@]}"; do
  if printf '%s' "$cmd" | grep -qE -- "$pattern"; then
    echo "BLOCKED by ~/.claude/hooks/block-dangerous.sh: command matches pattern \`$pattern\`" >&2
    echo "If you genuinely need to run this, do it manually in a terminal — not through Claude." >&2
    exit 2
  fi
done

exit 0

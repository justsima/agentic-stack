#!/usr/bin/env bash
# PreToolUse hook matcher=Edit|Write|Bash — blocks reads from or writes to
# secret-bearing files, and scans inline content for obvious secret patterns
# before they get committed to disk or echoed to a shell history.

set -uo pipefail
input=$(cat)
tool=$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)

path=""
case "$tool" in
  Edit|Write)
    path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
    ;;
  Bash)
    path=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
    ;;
esac

secret_path_patterns=(
  '\.env(\.[a-z0-9_-]+)?($|[[:space:]])'
  '/\.ssh/'
  '/\.aws/credentials'
  '/\.gnupg/'
  '/secrets/'
  'credentials\.json'
  'service-account.*\.json'
  'id_rsa($|[^.])'
  'id_ed25519($|[^.])'
)

for pattern in "${secret_path_patterns[@]}"; do
  if printf '%s' "$path" | grep -qE -- "$pattern"; then
    # Allow-list for sample/template env files
    if printf '%s' "$path" | grep -qE '\.env\.example|\.env\.template|\.env\.sample'; then
      continue
    fi
    # Allow-list for purpose-built CI deploy keypair (Wave 0 setup; per-name, narrow)
    if printf '%s' "$path" | grep -qE 'kingdomgive_deploy(\.pub)?($|[^a-zA-Z0-9_])'; then
      continue
    fi
    echo "BLOCKED by ~/.claude/hooks/block-secrets.sh: path matches secret pattern \`$pattern\`" >&2
    echo "Touched path: $path" >&2
    exit 2
  fi
done

content=""
case "$tool" in
  Edit)   content=$(printf '%s' "$input" | jq -r '.tool_input.new_string // empty' 2>/dev/null) ;;
  Write)  content=$(printf '%s' "$input" | jq -r '.tool_input.content // empty' 2>/dev/null) ;;
esac

if [ -n "$content" ]; then
  if ! printf '%s' "$path" | grep -qE '/(test|tests|__tests__|fixtures|examples|docs)/|\.test\.|\.spec\.|\.example\.|\.md$'; then
    secret_content_patterns=(
      'sk-(ant|proj)?[a-zA-Z0-9_-]{30,}'
      'sk_(test|live)_[a-zA-Z0-9]{20,}'
      'ghp_[a-zA-Z0-9]{30,}'
      'github_pat_[a-zA-Z0-9_]{50,}'
      'AKIA[0-9A-Z]{16}'
      'AIza[0-9A-Za-z_-]{30,}'
      '-----BEGIN[[:space:]]+(RSA|OPENSSH|EC|DSA|PGP)?[[:space:]]*PRIVATE KEY'
      'xox[baprs]-[0-9]{10,}-[0-9]{10,}-[a-zA-Z0-9]{20,}'
      'glpat-[a-zA-Z0-9_-]{20,}'
    )
    for pattern in "${secret_content_patterns[@]}"; do
      if printf '%s' "$content" | grep -qE -- "$pattern"; then
        echo "BLOCKED by ~/.claude/hooks/block-secrets.sh: content matches secret pattern \`$pattern\`" >&2
        echo "Don't hardcode secrets — use env vars + .env files (which Claude is blocked from reading)." >&2
        exit 2
      fi
    done
  fi
fi

exit 0

#!/usr/bin/env bash
# Copy the SKILL.md-based skills to another agent's skills directory.
# The "Agent Skills" SKILL.md format is shared across Claude Code, Cursor,
# Codex, Copilot & Gemini — only the install LOCATION differs per tool.
#
# Usage:   ./sync-skills.sh <target-skills-dir>
#   Codex:    ~/.agents/skills            (or a repo's .agents/skills/)
#   Cursor:   check your Cursor version's skills/rules dir
#   Copilot:  per GitHub Copilot docs
#
# (ultradeep is a slash-command + sub-agents, not a single SKILL.md, so it's
#  Claude-Code-only for now. market-scout/llm-council/adhd/job-application-helper
#  are portable.)
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="${1:?usage: sync-skills.sh <target-skills-dir>}"
mkdir -p "$TARGET"
for s in market-scout llm-council adhd job-application-helper; do
  src="$REPO_DIR/plugins/$s/skills/$s"
  if [ -d "$src" ]; then cp -R "$src" "$TARGET/" && echo "✓ copied $s -> $TARGET/$s"; fi
done
echo "Done. Restart your agent to pick up the skills."

#!/usr/bin/env bash
# Install the portable skills into ANY agent that supports the open Agent Skills
# (SKILL.md) standard. Just name your tool — the script picks the right folder.
#
# Usage:
#   ./sync-skills.sh <tool>            tool = claude | cursor | codex | antigravity | gemini | copilot
#   ./sync-skills.sh <path>            or pass a literal target skills directory
#
# Examples:
#   ./sync-skills.sh antigravity       -> ~/.gemini/antigravity/skills/
#   ./sync-skills.sh codex             -> ~/.agents/skills/
#   ./sync-skills.sh cursor            -> ./.cursor/skills/   (project-scoped)
#   ./sync-skills.sh ~/custom/skills   -> that exact dir
#
# Portable: market-scout, llm-council, adhd, job-application-helper.
# (ultradeep is a Claude Code slash-command + sub-agents → Claude Code only.)
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOL="${1:?usage: sync-skills.sh <claude|cursor|codex|antigravity|gemini|copilot|/path>}"

case "$TOOL" in
  claude)       DIR="$HOME/.claude/skills" ;;
  codex)        DIR="$HOME/.agents/skills" ;;
  antigravity)  DIR="$HOME/.gemini/antigravity/skills" ;;
  gemini)       DIR="$HOME/.gemini/skills" ;;
  cursor)       DIR="$(pwd)/.cursor/skills" ;;     # Cursor skills are project-scoped
  copilot)      DIR="$HOME/.config/github-copilot/skills" ;;
  /*|./*|~*)    DIR="${TOOL/#\~/$HOME}" ;;          # literal path
  *) echo "Unknown tool '$TOOL'. Use: claude|cursor|codex|antigravity|gemini|copilot, or a path." >&2; exit 2 ;;
esac

echo "Installing portable skills -> $DIR"
mkdir -p "$DIR"
n=0
for s in market-scout llm-council adhd job-application-helper; do
  src="$REPO_DIR/plugins/$s/skills/$s"
  if [ -d "$src" ]; then cp -R "$src" "$DIR/" && echo "  ✓ $s" && n=$((n+1)); fi
done
echo "Done — $n skills installed. Restart $TOOL to pick them up."
echo "Don't forget the MCP servers (Exa · agentmemory · Context7) in $TOOL's MCP settings — see the repo README."

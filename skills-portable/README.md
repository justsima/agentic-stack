# Cross-tool usage (Cursor · Codex · Copilot · Gemini)

These skills use the open **Agent Skills** `SKILL.md` standard, so they run on more
than Claude Code — only the install *location* changes per tool.

| Tool | Where skills live | Invoke |
|---|---|---|
| **Claude Code** | `~/.claude/skills/` (or via this plugin marketplace) | `/skill-name` |
| **Codex CLI** | `~/.agents/skills/` or repo `.agents/skills/` | `$skill-name` |
| **Cursor** | your Cursor version's skills/rules dir | per Cursor UI |
| **Copilot / Gemini** | per each tool's docs | per tool |

## Quick sync

```bash
# copy the portable skills into another agent's skills dir
./sync-skills.sh ~/.agents/skills        # example: Codex
```

Portable skills: **market-scout**, **llm-council**, **adhd**, **job-application-helper**.

> `ultradeep` is a slash-command plus sub-agents (not a single `SKILL.md`), so it's
> Claude Code-only for now. The MCP servers it relies on (Exa, agentmemory, etc.) are
> standard MCP and work in any MCP-compatible tool — install them the same way there.

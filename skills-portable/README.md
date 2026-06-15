# Use agentic-stack in any tool (Claude Code · Cursor · Codex · Antigravity · Gemini)

The skills use the open **Agent Skills** (`SKILL.md`) standard and the **MCP** standard —
both portable across modern agents. Setup is two pieces everywhere:

1. **Skills** — copy the skill folders into your tool's skills directory (use the helper below).
2. **MCP servers** — add Exa · agentmemory · Context7 in your tool's MCP settings.

## 1. Install the skills — one command

```bash
./sync-skills.sh <tool>     # claude | cursor | codex | antigravity | gemini | copilot
```

| Tool | Skills directory | Invoke |
|---|---|---|
| **Claude Code** | `~/.claude/skills/` *(or the plugin marketplace)* | `/skill-name` |
| **Cursor** | `.cursor/skills/` *(project root)* | per Cursor UI |
| **Codex CLI** | `~/.agents/skills/` *(or repo `.agents/skills/`)* | `$skill-name` |
| **Antigravity** | `~/.gemini/antigravity/skills/` *(global)* or `./.agent/skills/` *(workspace)* | per Antigravity UI |
| **Gemini CLI** | `~/.gemini/skills/` | `activate_skill` |
| **Copilot** | per GitHub Copilot docs | per tool |

Portable skills: **market-scout · llm-council · adhd · job-application-helper**.
`ultradeep` is a Claude Code slash-command + sub-agents → Claude Code only.

## 2. Add the MCP servers (any MCP-compatible tool)

All three are free; Exa & Context7 need no key.

| Server | Transport | Endpoint / command |
|---|---|---|
| **exa** | HTTP | `https://mcp.exa.ai/mcp` |
| **context7** | HTTP | `https://mcp.context7.com/mcp` |
| **agentmemory** | stdio | `npx -y @agentmemory/agentmemory` |

- **Claude Code / Codex:** `… mcp add --transport http exa https://mcp.exa.ai/mcp` (see each CLI's `mcp add`).
- **Cursor:** Settings → MCP → add the HTTP URL / stdio command.
- **Antigravity:** Settings → MCP servers → add local (stdio) or remote (HTTP). [Antigravity MCP docs](https://codelabs.developers.google.com/getting-started-google-antigravity).
- **Gemini CLI:** add to your `~/.gemini` MCP config.

# agentic-stack

A portable **agentic research stack for Claude Code** — the skills, agents, and
config that turn Claude Code into a research-and-decision machine. Built to be
installed in one command, shareable, and free.

> **Evidence in, judgment out.** The research tools separate *evidence-gathering*
> (LLM + parallel sub-agents) from *judgment* (deterministic scoring / adversarial
> red-team), so conclusions are grounded, not vibes. They file into an optional
> Obsidian wiki and get smarter over time.

## What's inside

| Plugin | What it does |
|---|---|
| **ultradeep** | Multi-agent deep research: adaptive parallel explorers → STORM-style questioning → adversarial red-team → tiered search (Exa/SearXNG/WebSearch) → optional wiki filing + knowledge graph. Tunable via `program.md`. |
| **market-scout** | "Best X on the market" research across major retailers. Parallel explorers + a **deterministic Python decision-matrix engine** + red-team → a ranked, segment-aware buying report. |
| **llm-council** | 5 advisors, each using a distinct **reasoning method** (inversion, decomposition, analogy, naive questioning, dependency graphing) → anonymized peer review → chairman synthesis. For high-stakes decisions. |
| **adhd** | Parallel **divergent ideation** — N isolated idea branches under different cognitive frames, scored, pruned, deepened. For open-ended design/naming/strategy problems. |
| **job-application-helper** | Natural, tailored application answers from **your own** profile (a private, git-ignored `profile.md` you create from the template). |
| **agentic-config** | Safety hooks (block dangerous bash, block secret leaks), a session-context hook, a verify-before-stop hook + a recommended-settings fragment. **No secrets.** |

## Install (one command)

```bash
git clone https://github.com/justsima/agentic-stack.git
cd agentic-stack
./install.sh
```

The installer asks what you want, sets up the **required** MCP servers automatically
(**Exa public · agentmemory · Context7** — all free, no keys), offers the optional
ones (SearXNG, Jina, the claude-obsidian wiki engine, graphify), and creates an empty
wiki scaffold. Re-runnable and `sudo`-free. (`./install.sh -y` for non-interactive.)

### Or install via the plugin marketplace (inside Claude Code)

```
/plugin marketplace add justsima/agentic-stack
/plugin install ultradeep@agentic-stack
/plugin install market-scout@agentic-stack
/plugin install llm-council@agentic-stack
/plugin install adhd@agentic-stack
/plugin install agentic-config@agentic-stack
```

Then add the required MCP servers:

```
claude mcp add --scope user --transport http exa https://mcp.exa.ai/mcp
claude mcp add --scope user agentmemory -- npx -y @agentmemory/agentmemory
claude mcp add --scope user --transport http context7 https://mcp.context7.com/mcp
```

## Requirements

- **Claude Code** (the primary target). For other tools see `skills-portable/`.
- **node / npx** — for the agentmemory (+ optional SearXNG) MCP.
- **Docker** *(optional)* — only if you want self-hosted unlimited SearXNG.
- **Required MCPs:** Exa (public, free, rate-limited), agentmemory, Context7. The
  installer wires these. Everything else is optional and the skills degrade gracefully.

## Use it

```
/ultradeep <a hard, multi-source research question>
/market-scout best <product category>
/llm-council <a decision with real tradeoffs>
/adhd <an open-ended design / naming / strategy problem>
```

## Other tools (Cursor / Codex / Copilot)

The skills use the open **Agent Skills** `SKILL.md` standard. See
[`skills-portable/`](skills-portable/README.md) and run `sync-skills.sh <dir>`.

## Tuning

- **ultradeep:** edit `plugins/ultradeep/deep-research/program.md` (priorities, depth,
  source policy, search backends, model/effort). The "Domain Notes" section grows itself.
- **market-scout:** edit `plugins/market-scout/skills/market-scout/references/criteria.json`
  (categories + weight profiles) and `program.md`.

## Privacy & security

- **No secrets** are committed. MCP keys (where needed) stay on your machine.
- Your **wiki and memory are empty scaffolds** — the engine, not anyone's data.
- `job-application-helper` reads a **git-ignored** `profile.md` you create locally.
- See [`docs/SECURITY.md`](docs/SECURITY.md).

## License

MIT — see [`LICENSE`](LICENSE). Built by [justsima](https://github.com/justsima).
Companion tools (claude-obsidian, graphify, agentmemory) are separate open-source
projects installed from their own repos.

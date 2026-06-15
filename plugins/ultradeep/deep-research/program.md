# Deep Research Program

Configurable defaults for `/ultradeep` (a custom deep-research command — renamed from `/deep-research` on 2026-06-03 to avoid collision with Anthropic's bundled `/deep-research` workflow). The slash command reads this before every run.

Edit this file to tune the system to your domain and style without touching the orchestrator.

---

## Priorities (in order)

1. **Discoverability** — maximize source diversity and breadth. Cast wide before going deep.
2. **Deep critical reasoning** — challenge claims, surface contradictions, demand evidence.
3. **Decisiveness** — the final report takes a position. No hedging unless evidence demands it.
4. **Token usage** — safety net only. Use the hard budget caps below. Otherwise spend freely on quality.

---

## Search Objectives

Every research session must:

- Find authoritative primary sources (prefer .edu, peer-reviewed papers, official docs, primary research, established publications)
- Extract key entities (people, orgs, products, tools, papers)
- Extract key concepts, frameworks, methodologies
- Surface contradictions between sources — name them, judge them
- Identify open questions, gaps, weak evidence
- Track recency: prefer sources from the last 18 months unless the topic is foundational

---

## Confidence Scoring

Every non-trivial claim in the final report must carry a confidence label:

- **high** — multiple independent authoritative sources agree
- **medium** — single strong source, or sources partially agree
- **low** — speculation, single informal source, or unverifiable

Note source date for factual claims. Mark claims from sources >3 years old as potentially stale unless the topic is foundational.

---

## Source Preferences

**Strong preference for:**
- arXiv, peer-reviewed venues, conference proceedings
- Official documentation and source code repos
- Engineering blogs from primary actors (Anthropic, OpenAI, HuggingFace, etc.)
- Author-attributed long-form pieces with citations

**Use only as leads to primary sources (never cite alone):**
- Reddit, Hacker News threads
- Twitter/X threads
- Generic news aggregators
- LLM-generated summaries

**Exclude entirely:**
- Undated web pages
- SEO content farms (low-effort listicles, recycled summaries)
- Sources that don't cite their own claims

---

## Budget Caps (safety net only) + Depth Defaults

**Updated 2026-06-03:** you run a high-tier plan (e.g. Claude Max) on a strong model. Token budget is NOT a constraint — depth and thoroughness are the goal. Bias toward MORE breadth, MORE gap rounds, MORE verification. Stop only on genuine saturation, never on cost.

**Depth defaults (the new normal — was conservative, now exhaustive):**
- **Default explorers in round 1: 8-10** (was ~6). Cast as wide as the topic's distinct angles allow. Only go below 8 for genuinely narrow factual questions.
- **Default gap-analysis rounds: aim 3-5** (was "stop at 3"). Keep going while each round surfaces material new findings. A round that returns nothing new is the signal to stop — not a round counter.
- **Sub-questions: bias to 8-10** even for standard topics. Discoverability is priority #1.
- **Red-team: always run; escalate to 2 cycles** whenever the first pass finds Critical issues, not just on a Fail verdict.

**Safety-net caps (only to prevent runaway loops, not to limit depth):**
- Max wall time per run: **no hard cap** — depth-driven. Absent a runaway, let it run.
- Max parallel subagents per round: **10** (Agent-tool concurrency limit). For runs that need more than 10 parallel workers, escalate to a dynamic workflow (see "Claude Code Primitives" below — workflows allow up to 16 concurrent / 1,000 total per run).
- Max gap-analysis rounds: **no hard cap** — justify each round beyond 5 in writing with the specific uncovered gap it targets.
- Max tool calls per subagent: **100** (was 50; raised for depth)
- Max total tool calls per run: **2000** (was 800; raised for exhaustive runs)

The lead enforces budget by JUSTIFYING extensions in the run plan, not by limiting blindly. If the 10-parallel Agent cap is the bottleneck, that's the trigger to re-platform the run as a dynamic workflow. **Never stop early on time or token grounds** — only on coverage-checklist satisfied OR information saturation (no new material in the last round).

---

## Output Style

- Declarative, present tense, no hedging
- Inline citations: footnote-style `[^source-slug]`
- Use callouts for uncertainty: `> [!gap] This claim is weakly supported.`
- Pages under 300 lines — split if longer
- Include a 3-sentence executive summary at the top
- The Recommendations section must take a position — no "it depends"

---

## Domain Notes (self-learning — append after every run)

Phase 9.5 of the orchestrator appends a transferable, reusable lesson here after
every run (which source won, which metric needs triangulation, which mirror worked)
— not run summaries. This is how the system compounds over time.

_(Empty on a fresh install — your research lessons accumulate here.)_

## Wiki Integration

**Destination for final reports**: `~/agentic-wiki/research-reports/`
(this folder already exists — file directly, don't ask)

**Wiki structure (default layout)**:
- `wiki/hot.md` — recent context (~500 words). Read FIRST during pre-search.
- `wiki/index.md` — navigation. Read SECOND if hot.md doesn't have relevant context.
- `wiki/log.md` — append-only activity log. Update AFTER filing.
- `wiki/research-reports/` — final reports go here
- `wiki/concepts/`, `wiki/sources/`, `wiki/notes/` — drill in for related material

**Pre-search (Phase 0.5)**:
- Always read `wiki/hot.md` first
- Then `wiki/index.md`
- Then check `wiki/research-reports/` for related prior work — if exists, factor into plan ("we already covered X; this run focuses on gaps Y, Z")
- Use `claude-obsidian:wiki-query` skill if available for semantic query

**Post-filing (Phase 9)**:
- File report to `wiki/research-reports/<topic-slug>.md` with proper Obsidian frontmatter
- Append one line to `wiki/log.md` at the TOP: `## [YYYY-MM-DD] ultradeep | <topic> → [[research-reports/<slug>]]`
- Update `wiki/hot.md` with a 2-3 line summary of the new research
- Use `[[wikilink]]` cross-references to existing pages in `wiki/concepts/`, `wiki/sources/`, etc.
- Optionally invoke `claude-obsidian:wiki-lint` for orphan/dead-link check

---

## Search Backends — Tiered Exa strategy (depth-first, free-fallback)

**The tiering rule:**

1. **Depth-needed angles → keyed Exa FIRST** (`mcp__exa-key__*`). For any angle that genuinely needs deep multi-hop synthesis — the hard, central, contested, or multi-source-cross-check angles — open with the keyed deep tools:
   - `mcp__exa-key__deep_search_exa` (`type: "deep-reasoning"`) — multi-angle synthesis with citations
   - `mcp__exa-key__deep_researcher_start` + `_check` (`exa-research-pro` for the hardest) — async agentic deep research
   - `mcp__exa-key__web_search_advanced_exa` — full filter control (date ranges, domains, categories)
   - `mcp__exa-key__get_code_context_exa` — semantic code search for any code/library/SDK angle (strictly better than web search for code)
2. **Routine angles + everything after a rate-limit → free/shared tier.** Use `mcp__exa__web_search_exa` (shared neural search) and `mcp__searxng__searxng_web_search` (local, unlimited) for breadth angles, background context, and any angle that doesn't need agentic depth.
3. **Rate-limit / credit fallback chain (hard rule).** The keyed pool is finite and CAN run dry mid-run (it returned HTTP 402 "credits exceeded" on 2026-06-03 — fell back to shared exa successfully, zero data loss). On any `402`/`429` from a tier, **immediately fall back down the chain, do not retry the exhausted tier:**
   `exa-key (deep)` → `exa (shared neural)` → **`searxng (local, UNLIMITED — the default floor)`** → `WebSearch (built-in, can't-fail final)`
   Note the downgrade in the explorer's notes so the synthesis knows which angles got depth-tier vs. fallback-tier coverage.

   **SearXNG is the default safety-net** because it's self-hosted (local Docker, `mcp__searxng__searxng_web_search`, port 8888) and **cannot rate-limit** — verified working 2026-06-03. When both Exa tiers are exhausted, route ALL remaining breadth searches to SearXNG rather than rationing. SearXNG also has `mcp__searxng__web_url_read` for free URL→markdown extraction.
   **One dependency caveat:** SearXNG needs its Docker container running. If `mcp__searxng__*` returns a network error (`fetch failed` = container down), bring it up — `open -a OrbStack` (the `searxng` container auto-starts with it) or `docker start searxng`, wait ~5s — then resume. If it can't be revived mid-run, fall through to `WebSearch` (the only tier with zero dependencies) and note it.

**Per-angle routing (within whichever tier is live):**

| Angle type | Depth tier (try first if angle needs depth) | Free/shared + fallback | Cross-check |
|---|---|---|---|
| General web research | `mcp__exa-key__deep_search_exa` | `mcp__exa__web_search_exa` → `searxng` → `WebSearch` | — |
| Academic / papers | `mcp__exa-key__deep_search_exa` (deep-reasoning) | `mcp__huggingface__paper_search` + shared exa | arXiv direct |
| Code / library / SDK | `mcp__exa-key__get_code_context_exa` | `mcp__plugin_context7_context7__query-docs` + `gh api` | official repo README + CHANGELOG |
| OSS project | `mcp__github-plugin__*` + `mcp__zread__*` | shared exa for external coverage | README + CHANGELOG + issues |
| HF model / dataset | `mcp__huggingface__hf_doc_search` + `hub_repo_details` | shared exa for context | — |
| Hard / contested / multi-hop | `mcp__exa-key__deep_researcher_start` (`exa-research-pro`) | shared exa breadth + manual synthesis | triangulate 3+ unrelated sources |
| News / current events | `mcp__exa-key__web_search_advanced_exa` (date-filtered) | shared exa (date filter) → searxng | 3+ unrelated outlets |

**Always**: invoke `claude-obsidian:defuddle` on noisy fetched pages before extraction. For X.com, skip direct fetch (HTTP 402) — go to nitter / threadreaderapp / absorb.md mirrors.

**Cost discipline:** keyed Exa is ~1,000 calls/month — spend it on the angles that NEED depth (deep_researcher, deep_search deep-reasoning, get_code_context), not on breadth that shared exa or searxng handle free. A typical run might use the keyed pool for 1-3 core angles and the free tier for the rest.

---

## Knowledge Graph (Phase 8 — optional)

Toggle: **on by default** (set 2026-06-03). Phase 8 runs on every `/ultradeep` unless you pass `--no-graph` in the prompt, or the topic is a narrow single-angle factual question where a graph adds nothing. Set `KG_DEFAULT: off` below to return to opt-in (`--graph` per run). graphify v0.7.5 verified callable at `~/.local/bin/graphify`.

When enabled:
- After Phase 7 (filing), run `graphify` skill on `$SCRATCH_DIR` + the final report
- Output: `$SCRATCH_DIR/graphify-out/` with knowledge graph
- The graph captures entity/concept relationships across all explored angles
- Useful for: complex multi-domain research, long-running research programs, building a queryable memory of a topic

Skip for: narrow factual questions, single-angle topics, time-pressured runs.

`KG_DEFAULT`: on

---

## Memory & Context (optional patterns)

These come from your auto-memory and should be respected:

- **Workflow pattern**: research → MD plan → orchestrator + action-takers. The `/ultradeep` command IS this pattern — honor it. The plan.md IS the MD plan; explorers ARE the action-takers.
- **Wiki traversal**: hot.md → index.md → drill in. Phase 0.5 follows this exactly.
- **Permission mode**: set to your preference (inherits from session).

---

## Model & Effort Strategy

- **Lead orchestrator**: inherits session model (currently Opus 4.8, 1M context) — keeps full reasoning power for planning + synthesis
- **Explorer subagents**: `effort: high` (frontmatter) — deep enough to evaluate sources, not max because they're parallel and many
- **Red-team subagent**: `effort: max` (frontmatter) — adversarial reasoning needs every clock cycle
- **No model overrides** — let everything inherit the session model. Your "no token worry" stance unlocks this.
- Model refs here are descriptive, not pinned — update when the session default changes; nothing in the pipeline hard-codes a model ID.

---

## Claude Code Primitives (the orchestration layers available, added 2026-06-03)

This skill predates several Claude Code orchestration primitives that shipped late-May/June 2026. They are now available layers the orchestrator can reach for. Both `CLAUDE_CODE_WORKFLOWS=1` and `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` are already set in your settings.json, and the session runs Opus 4.8 (supports `ultracode`/`xhigh`).

**Pick the layer by who holds the plan:**

| Layer | Who orchestrates | Scale | Use in deep-research when |
|---|---|---|---|
| **Subagents** (Agent tool) | The lead, turn-by-turn; results land in lead's context | Up to 10 parallel | **Default.** Phase 3/4 explorers. Each result returns to the lead for synthesis. |
| **Agent Teams** (`SendMessage`, shared task list) | Lead + teammates self-coordinate; teammates message each other | A handful | When explorers must **challenge each other's findings mid-run** (competing-hypothesis debates) rather than just report back. Heavier tokens; reserve for genuinely collaborative angles. |
| **Dynamic Workflows** (`/workflows`, a JS script Claude writes) | A script holds the loop/branching; only the final answer hits context | **Up to 16 concurrent / 1,000 total per run**, background, **resumable** | When a run needs **more than 10 parallel workers**, must **survive interruptions/rate-limits** (resumes from checkpoint), or wants the orchestration **codified + rerunnable**. This is the scale-up path past the subagent cap. |

**Quality patterns dynamic workflows make cheap** (compose these into deep runs): fan-out-and-synthesize, adversarial verification (one verifier per finding), generate-and-filter, tournament/pairwise-judging, loop-until-done (stop when a round finds nothing new), and disjoint-evidence hypothesis panels. These are the SAME patterns this skill already does by hand in Phases 3-6 — a workflow just runs them at 10× the agent count.

**Companion commands:**
- **`/goal`** — set a hard completion condition; Claude keeps working across turns until met. Pair with deep-research for "don't stop until every checklist item is covered AND red-team passes."
- **`/loop`** — run a workflow at intervals. Pair for standing/monitoring research (e.g., weekly re-scan of a fast-moving topic).
- **Forked subagents** (`CLAUDE_CODE_FORK_SUBAGENT=1`) — a subagent that inherits the full conversation instead of starting fresh. Use for a side-investigation that needs all the context already gathered, without re-briefing.

**Anthropic ships its own official `/deep-research` workflow** (built on dynamic workflows, fan-out → fetch → adversarially verify → cited report). It does NOT integrate with your Obsidian wiki, program.md tuning, or the Phase 9.5 self-learning loop. **This custom command's edge is exactly that integration** — keep it for wiki-filed, tunable, compounding research; use Anthropic's official one for throwaway one-off questions where filing doesn't matter.

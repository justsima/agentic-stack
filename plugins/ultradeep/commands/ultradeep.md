---
description: Robust multi-agent deep research. Orchestrator-worker pattern with adaptive parallelism (1-10 explorers using Exa/HF/Context7/GitHub/zread as relevant), STORM-style perspective questioning, hybrid stopping rule (coverage checklist + budget cap), adversarial red-team verification, wiki pre-search and post-filing integration with ~/agentic-wiki/, and optional knowledge-graph generation. Inspired by Anthropic Research, GPT Researcher, Stanford STORM, Tavily, MCP-Agent Deep Orchestrator. Reads ~/.claude/deep-research/program.md.
---

# Deep Research — Master Orchestrator (`/ultradeep`)

**Invoked as `/ultradeep`.** Renamed from `/deep-research` on 2026-06-03 to avoid collision with Anthropic's bundled `/deep-research` dynamic-workflow. This is your custom, wiki-integrated, self-tuning orchestrator — its edge over the bundled one is Obsidian wiki pre-search + post-filing, `program.md` tuning, and the Phase 9.5 self-learning loop. Use the bundled `/deep-research` for throwaway one-offs; use `/ultradeep` when the result should be filed, cited, and compound over time.

You are the lead researcher orchestrating a multi-agent deep research session.

This is an orchestrator-worker pipeline modeled on Anthropic's production Research feature, augmented with STORM's perspective-guided question asking, Tavily's production guardrails, adversarial verification, and Obsidian wiki integration (pre-search for prior knowledge, post-filing into the user's permanent knowledge base).

**Subagents available:**
- `deep-research-explorer` — parallel exploration (8-10 per round default, effort: high)
- `deep-research-redteam` — adversarial review (1+ final passes, effort: max)

**Orchestration layers (escalate as scale demands — see program.md "Claude Code Primitives"):**
- **Subagents** (default) — turn-by-turn parallel explorers, up to 10 concurrent.
- **Agent Teams** (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`, already on) — when explorers must challenge each other mid-run, not just report back.
- **Dynamic Workflows** (`CLAUDE_CODE_WORKFLOWS=1`, already on; ask for a workflow / `ultracode`) — when a run needs >10 parallel agents, must resume across rate-limits, or wants the orchestration codified. Up to 16 concurrent / 1,000 total, background, resumable.
- **`/goal`** — set "don't stop until all checklist items covered AND red-team passes." **`/loop`** — standing/monitoring re-runs.

**Skills to invoke at specific phases:**
- `claude-obsidian:wiki-query` — Phase 0.5 (pre-search existing wiki)
- `claude-obsidian:defuddle` — Phase 3+ (clean noisy pages before extracting)
- `claude-obsidian:obsidian-markdown` — Phase 7 (proper wiki page format)
- `superpowers:dispatching-parallel-agents` — Phase 3+ (ensure parallelism discipline)
- `graphify` — Phase 8 (optional, knowledge graph)
- `claude-obsidian:wiki-lint` — Phase 9 (optional, post-filing health check)

**Memory context** — these are your documented patterns; respect them:
- His workflow is "research → MD plan → orchestrator + action-takers". This command IS that pattern.
- Wiki traversal: hot.md → index.md → drill in.
- Permission mode: bypassPermissions (inherited from session).

The topic to research is `$ARGUMENTS`. If `$ARGUMENTS` is empty, ask: **"What topic should I research?"** — do NOT improvise a topic.

---

## Setup — do this first, every time

1. **Read `~/.claude/deep-research/program.md`** in full. This defines objectives, source preferences, confidence rules, budget caps, and output style. Internalize before proceeding.

2. **Create the scratch directory**:
   ```
   SCRATCH_DIR=~/research/<topic-slug>-<YYYY-MM-DD-HHMM>
   ```
   Slug the topic to kebab-case. Run `mkdir -p` to create.

3. **Write `$SCRATCH_DIR/session.md`**: topic, start time, full topic statement, and the priorities from program.md.

Announce to the user: "Starting deep research on `<topic>`. Audit trail at `$SCRATCH_DIR/`. Estimated 15-45 min."

---

## PHASE 0.5 — Wiki Pre-Search (always run)

Before planning, leverage existing knowledge in the wiki. This prevents duplicate research and grounds the plan in what you already know.

1. **Read `~/agentic-wiki/hot.md`** (~500 words, recent context). Does it touch the topic?
2. **Read `~/agentic-wiki/index.md`** for navigation. Identify relevant sections.
3. **Check `~/agentic-wiki/research-reports/`** — list files. Does a prior report cover this topic or an overlapping one? If yes, READ that report.
4. **Invoke `claude-obsidian:wiki-query` skill** if available: query for the topic. The skill drills into related pages, sources, concepts, and notes.
5. **Glob `~/agentic-wiki/**/*.md`** for filename matches if the wiki-query skill isn't enough.

**Write `$SCRATCH_DIR/prior-knowledge.md`** with:
- Existing wiki coverage of this topic (summarize what's already there)
- Open gaps that prior research left
- Cross-references to leverage (`[[wikilink]]`s the new report should connect to)
- Decision: is this a "fresh research" run or an "extend prior work" run?

If a prior report covers the topic substantially, your plan in Phase 2 should focus on GAPS, NEW DEVELOPMENTS, and DIFFERENT ANGLES — not redo what's done.

---

## PHASE 1 — Clarify + scope confirmation (always confirm, clarify only if vague)

**Always do a one-line scope confirmation before dispatching explorers** — even for a concrete topic. Burning 6+ parallel explorers on a mis-framed scope is the single most expensive mistake this pipeline makes. State your interpretation in one or two lines and the angles you intend to cover, then proceed unless corrected:

> "Reading this as: `<one-line interpretation>`. Planned angles: `<3-6 word list>`. Correcting course now if that's off — otherwise dispatching."

This is a confirmation, not an interrogation. Do NOT block waiting for a reply on a concrete topic; state the interpretation and continue. Only hard-stop for input when the topic is genuinely ambiguous (below).

**Hard-stop and ask 1-3 questions only when the topic is vague:**
- Topic is a noun without context ("crypto", "the economy")
- Multiple equally-plausible scopes exist ("write about Apple" → company? fruit? specific product?)
- User's likely intent is unclear (deep dive? competitive analysis? state-of-the-art? historical?)

If clarifying: ask the minimum 1-3 questions to disambiguate. Don't interrogate.

Write the final brief (interpretation + confirmed/assumed scope) to `$SCRATCH_DIR/brief.md`.

---

## PHASE 2 — Plan

Write `$SCRATCH_DIR/plan.md` with all of these sections:

### 2a. Sub-questions (adaptive 1-10, biased high)

Decompose the topic into sub-questions, scaled to complexity:
- Narrow factual question → 1-3 sub-questions
- Standard topic with multiple angles → 4-7 sub-questions
- Broad exploratory or comparative topic → 8-10 sub-questions

**Bias toward more sub-questions when in doubt.** Discoverability is the top priority — favor breadth.

### 2b. Perspectives (STORM-style)

For each sub-question, identify 1-3 distinct perspectives worth exploring. Examples:
- For "agent architectures": engineering perspective (implementation), researcher perspective (limits/theory), product perspective (UX/cost)
- For contentious topics: proponent view, critic view, neutral analyst view
- For technical comparisons: official/marketing perspective vs. user-reported perspective vs. third-party benchmark perspective

Different perspectives → different search angles → richer coverage.

### 2c. Subagent task specs (4-field per Anthropic)

For each (sub-question, perspective) pair, write a complete task spec:
- **Objective**: what specifically to answer
- **Output format**: structured summary shape (refer the explorer to its own SKILL for details)
- **Tools & sources**: **MATCH to angle type per program.md's "Search Backends" table**:
  - General web research → Exa search + fetch (primary)
  - Academic/papers angle → Exa + `mcp__huggingface__paper_search`
  - Library/framework/SDK angle → `mcp__plugin_context7_context7__*` first, then Exa for community
  - OSS project angle → `mcp__github-plugin__*` + `mcp__zread__*` for repo, Exa for external
  - HF models/datasets → `mcp__huggingface__hf_doc_search` + `hub_repo_details`
  - Always: invoke `claude-obsidian:defuddle` on noisy pages
- **Boundaries**: explicit list of what OTHER explorers are handling — so this one doesn't duplicate

### 2d. Coverage checklist

List every concrete piece of information the final report must contain. This drives the stopping rule.

Example for a tech topic:
- [ ] Definition with 2+ authoritative sources
- [ ] Timeline of evolution / key milestones
- [ ] Top 3-5 implementations and their tradeoffs
- [ ] Known failure modes / limitations
- [ ] Recent (last 6mo) developments
- [ ] Open research questions / where the field is heading

### 2e. Verify the plan before dispatching

Sanity-check:
- Do the sub-questions collectively answer the original topic?
- Is there meaningful overlap between explorer task specs? (There shouldn't be.)
- Does the checklist cover everything a reader would expect in a research report?
- Are perspectives diverse enough to avoid all explorers returning to the same source pool?

If the plan fails any check, rewrite. Don't dispatch a bad plan.

---

## PHASE 3 — Parallel exploration (round 1)

**CRITICAL: Dispatch all explorers in a SINGLE assistant message with multiple `Agent` tool calls.** This is the only way to achieve true concurrency. Sequential dispatch (one Agent call per message) serializes them and defeats the architecture.

If unsure, invoke the `superpowers:dispatching-parallel-agents` skill before dispatching to enforce parallel discipline.

For each subagent task in the plan:

```
Agent(
  subagent_type="deep-research-explorer",
  description="Explore: <angle-slug>",
  prompt="""
SCRATCH_DIR=<full-scratch-dir-path>
Original research topic: <topic>

Objective: <from plan>
Output format: Structured summary + notes file at SCRATCH_DIR/sub-<angle-slug>.md.
                Follow the explorer subagent's filing template exactly.
                DATE-STAMP every source: record each source's publication/fetch date
                next to its claim. For any metric that changes over time (stars,
                downloads, prices, counts, rankings), note the AS-OF date explicitly.
                If the research has a time window, flag any source or datapoint that
                falls outside it.
Tools & sources: <preferences from program.md and plan>
Boundaries: Other explorers are handling: <explicit list of their angles>.
            You handle ONLY: <this angle>.
            If you discover information relevant to another angle, note it as
            a cross-reference and move on.

Confidence rules and exclusions: see ~/.claude/deep-research/program.md.
"""
)
```

Wait for all explorers to return their structured summaries.

**Depth defaults (per program.md):** dispatch **8-10 explorers** in round 1 for any non-trivial topic — cast as wide as the distinct angles allow. Drop below 8 only for genuinely narrow factual questions.

**Tiered Exa discipline (per program.md "Search Backends"):** depth-needed angles open with the keyed pool (`mcp__exa-key__deep_search_exa` / `deep_researcher` / `get_code_context_exa`); breadth angles use free/shared (`mcp__exa__*`, `searxng`). On any `402`/`429`, fall DOWN the chain (exa-key → exa shared → searxng → WebSearch) and never retry the exhausted tier — note the downgrade in the explorer's notes.

**Scale-up trigger:** if a round genuinely needs **more than 10 parallel workers**, or the topic is huge (a corpus sweep, a many-source cross-check that won't fit in ~10 angles), escalate this run to a **dynamic workflow** instead of serializing explorers: ask for a workflow (or use `ultracode`) so the orchestration runs as a background script with up to 16 concurrent / 1,000 total agents, resumable across rate-limits. The workflow runs the same fan-out → verify → synthesize shape this skill defines, just at higher agent count. Keep the wiki pre-search (Phase 0.5) and post-filing (Phases 7/9/9.5) around it — those are this command's edge over Anthropic's generic workflow `/deep-research`.

---

## PHASE 4 — Gap analysis loop (aim 3-5 rounds; keep going while findings are material)

After explorers return:

1. Read the coverage checklist from `plan.md`
2. Read every `sub-*.md` notes file (don't rely on return summaries alone)
3. For each checklist item: mark covered ✓ or gap ✗
4. Also look for: unresolved contradictions, weakly-evidenced claims, missing perspectives identified by explorers as cross-refs
5. If gaps exist AND budget remains: dispatch follow-up explorers (same single-message parallel pattern as Phase 3) targeting ONLY the gaps. Be explicit in boundaries: "Other explorers covered X, Y. You handle ONLY Z."

Repeat until (saturation, not a counter):
- All checklist items covered, OR
- A full round returns **no material new findings** (the real stop signal), OR
- Beyond round 5, each additional round is justified in writing by the specific uncovered gap it targets (per program.md — no hard round cap; depth-driven)

Write `$SCRATCH_DIR/coverage-final.md` showing covered vs. gap items. Remaining gaps will be acknowledged in the report's Open Questions section.

---

## PHASE 5 — Synthesize

Write `$SCRATCH_DIR/report-draft.md`. **Read the actual `sub-*.md` notes files for evidence — don't synthesize from return summaries alone.**

Structure:

```markdown
---
type: deep-research
topic: <topic>
date: YYYY-MM-DD
duration_min: <N>
sources_consulted: <N>
sources_cited: <N>
explorers_dispatched: <N>
rounds: <N>
---

# Deep Research: <Topic>

## Executive Summary
[3 sentences. Take a position. No hedging.]

## Key Findings
- **<finding>** [high] [^src1] [^src2]
- **<finding>** [medium] [^src3]
- ...

## Detailed Analysis

### <Sub-question 1>
[Discussion with inline citations. Synthesize across explorers who touched this area.]

### <Sub-question 2>
...

## Entities & Concepts
- **<Entity>**: role, why it matters [^src]
- **<Concept>**: one-line definition [^src]

## Contradictions & Tensions
- [^srcA] says X; [^srcB] says Y. **Judgment**: <which is stronger and why>.

## Open Questions
- <question> — <why this research couldn't fully answer it>

## Recommendations / Implications
[Take a stance. What should change in the reader's understanding or behavior as a result of this research? No hedging.]

## Sources
[^src1]: <Author>, "<Title>", <Venue>, <Date>. <URL>.
[^src2]: ...
```

**Synthesis rules:**
- Every non-trivial claim has a citation
- **Triangulation gate** — before labeling any quantitative or load-bearing claim `[high]`, confirm 2+ independent sources support it. A single source caps the claim at `[medium]`. Enforce this DURING synthesis, not after — it's cheaper than red-team rework.
- **Temporal-boundary check** — if the research has a time window, every datapoint carries its as-of date, and anything outside the window is explicitly labeled out-of-window (not silently quoted as current). Time-varying metrics (stars, prices, counts) always state the as-of date.
- Quote source language when wording matters; paraphrase only when accuracy is preserved
- When sources conflict: state both, render judgment with reasoning (see council escalation in Phase 6 for genuinely high-stakes contested calls)
- Recommendations section: take positions, no "it depends"
- Honest confidence labeling — don't inflate

---

## PHASE 6 — Adversarial red team

Dispatch the red-team subagent:

```
Agent(
  subagent_type="deep-research-redteam",
  description="Attack the draft report",
  prompt="""
Draft report: <SCRATCH_DIR>/report-draft.md
Scratch directory with explorer notes: <SCRATCH_DIR>/
Original research question: <topic>
Coverage checklist: <SCRATCH_DIR>/plan.md

Attack the report on all 6 axes per your skill definition. Return structured assessment.
"""
)
```

Save the red-team output to `$SCRATCH_DIR/redteam.md`.

**Apply red-team feedback:**
- **Critical issues** → fix in `report-draft.md`. Re-cite, downgrade confidence, or remove unsupported claims.
- **Important issues** → fix if feasible; otherwise add to Open Questions with the red team's framing.
- **Minor issues** → judgment call. Fix if cheap, log in a `changelog:` field of the report frontmatter if not.

If red-team verdict is **Fail**: loop back to Phase 4 for one more gap-fill round targeting the specific weaknesses, then re-synthesize and re-red-team. **Hard cap: 2 red-team cycles total.**

### Council escalation (optional — for genuinely contested high-stakes findings)

If the report's **Contradictions & Tensions** section contains a call that is BOTH high-stakes (a recommendation or conclusion the reader will act on) AND genuinely contested (strong evidence on both sides, the red-team flagged the judgment as weak, or you rendered the judgment with low confidence), do not just pick a side silently. Hand it to a council for multi-perspective adjudication:

- `llm-council` (5 distinct reasoning methods → peer review → chairman synthesis) — best for analytical/strategic contested calls.
- `personal-council` / `/think-tank` (3-lineage debate) — best when cross-model diversity matters.

Pass the council the contested claim, the evidence for each side from the scratch notes, and ask for a verdict. Fold the council's verdict back into the report's judgment with attribution ("Council adjudication: …"). This is OPT-IN per finding — skip it for clear-cut contradictions you can resolve from evidence alone. Cost is real (~11 sub-agent calls for llm-council); reserve it for calls that actually matter.

---

## PHASE 7 — File to wiki + scratch

The reviewed draft becomes the final report. Invoke the `claude-obsidian:obsidian-markdown` skill for proper wiki page format.

1. **Polished report → Obsidian wiki**:
   - Target: `~/agentic-wiki/research-reports/<topic-slug>.md` (the folder exists — file directly)
   - Add Obsidian-style frontmatter (type, date, status, tags, related)
   - Use `[[wikilink]]` cross-references to entities/concepts surfaced in `wiki/concepts/`, `wiki/sources/`, etc. (glob those folders for matching pages)
   - For entities/concepts that DON'T have a wiki page yet but are substantial, optionally create stub pages in `wiki/concepts/` or `wiki/entities/` with confidence-tagged claims

2. **Scratch dir stays**: `$SCRATCH_DIR/` retains the full audit trail (prior-knowledge, brief, plan, sub-*, coverage-final, draft, redteam). Never delete it.

---

## PHASE 8 — Knowledge graph (optional, controlled by program.md)

`KG_DEFAULT` is **`on`** (set 2026-06-03), so **run this phase by default.** Skip ONLY if: the user passed `--no-graph` in `$ARGUMENTS`, OR `KG_DEFAULT` has been set back to `off` and no `--graph` flag was passed, OR the topic is a narrow single-angle factual question where a graph adds no navigation value (note the skip in the final summary).

When running (default):
1. Invoke the `graphify` skill on `$SCRATCH_DIR` (it'll process the sub-*.md notes + final report)
2. Output lands at `$SCRATCH_DIR/graphify-out/`
3. The graph captures entity/concept relationships across the explored angles
4. Mention the graph location in the final summary so the user can navigate it

Skip for narrow factual questions. Enable for complex multi-domain research where a graph aids navigation.

---

## PHASE 9 — Wiki post-update

After filing the report:

1. **Append to `wiki/log.md` at the TOP** (newest first):
   ```
   ## [YYYY-MM-DD HH:MM] ultradeep | <Topic>
   - Report: [[research-reports/<slug>]]
   - Scratch: <SCRATCH_DIR>
   - Sources: <N> | Explorers: <N> | Rounds: <N>
   - Headline: <one-sentence top finding>
   - Red team: <verdict>
   ```

2. **Update `wiki/hot.md`**: prepend a 2-3 line note about the new research at the top. Keep hot.md under ~500 words total — trim oldest entries if needed.

3. **Optionally update `wiki/index.md`**: if there's a "Research Reports" section or similar, add the new entry. If unclear where it belongs, skip — don't pollute the index.

4. **Optional lint**: invoke `claude-obsidian:wiki-lint` skill to scan for new orphans, dead links, or missing cross-references that the new report created. Report any findings to the user but don't auto-fix.

---

## PHASE 9.5 — Self-improvement (always run; this is what makes the methodology compound)

The point of `program.md`'s Domain Notes is to get smarter every run. Nothing improves if you never write back. So after filing, reflect for 30 seconds and append ONE concrete, transferable lesson to the relevant `### <domain>` subsection of `~/.claude/deep-research/program.md` under `## Domain Notes`.

A good lesson is specific and reusable next time — not a summary of this run's findings. Examples:
- "For tiny-VLM / edge-ML topics, Hugging Face model cards + the paper's own GitHub issues beat blog coverage; Medium tutorials were noise."
- "For YC/startup-batch topics, AgentMarketCap is single-source — always triangulate batch stats against TechCrunch + the official YC RFS."
- "X.com returns HTTP 402 to WebFetch; go straight to nitter/threadreaderapp/absorb.md mirrors, don't waste a fetch on x.com."

Rules:
- Append under the matching `### <domain>` heading; create a new one if no domain fits.
- One or two lines max. If you have no genuinely new lesson, write nothing — do NOT pad.
- Lessons about TOOLS/BACKENDS (which source won, which mirror worked) are the most valuable — they directly tune future `## Search Backends` routing.
- If a lesson contradicts an existing note, update the existing note rather than appending a duplicate.

This closes the loop: program.md is the long-term memory, and each run leaves it a little sharper.

---

## PHASE 10 — Report to user

Print a concise summary:

```
✓ Deep Research complete: <Topic>

Duration: <N> min | Explorers: <N> | Rounds: <N> | Sources cited: <N>

Final report:    ~/agentic-wiki/research-reports/<topic-slug>.md
Audit trail:     <SCRATCH_DIR>/
Knowledge graph: <SCRATCH_DIR>/graphify-out/    (if Phase 8 ran)
Wiki updated:    hot.md, log.md

Prior knowledge used: <yes/no — was there existing wiki coverage?>
Coverage: <N/N checklist items addressed>
Red team verdict: <Pass | Pass with revisions | Fail-recovered>
Council escalation: <none | which finding went to which council + verdict>
Lesson filed to program.md: <the one-line lesson, or "none this run">

Headline findings:
- <finding 1>
- <finding 2>
- <finding 3>

Open questions filed: <N>
```

---

## Budget enforcement (always-on safety net)

At the start of each phase, check elapsed wall time and total tool calls against the caps in `program.md`. If the next phase would exceed cap:
- Finalize what's gathered
- Skip directly to Phase 5 (synthesis) with what you have
- Note the budget exhaustion in the report's frontmatter

Budget is a SAFETY NET, not an optimization target. Use it only when something has gone wrong (loop, runaway searches, etc.).

---

## Failure modes to avoid

1. **Vague subagent tasks** → duplicate work + gaps. Every explorer gets a full 4-field spec.
2. **Serial dispatch** → no concurrency. ALL Agent calls in Phase 3/4 must be in ONE assistant message.
3. **Synthesizing from return summaries alone** → loses evidence. Always read the `sub-*.md` files.
4. **Skipping red team** → loses the decisive-reasoning sharpening. Always run it.
5. **Untraceable claims** → every claim in the report maps to a source URL in scratch notes. No exceptions.
6. **Over-running budget** → respect the caps. Quality over completeness when budget is exhausted; file what you have.
7. **Skipping Phase 0.5 wiki pre-search** → duplicate research, missed cross-references, isolated knowledge. Always check the wiki first.
8. **Single-backend tunnel vision** → all explorers using only Exa misses paper-search-specific results, library docs, OSS repos. Match the backend to the angle (see program.md table).
9. **Filing without `[[wikilinks]]`** → the report becomes an island, not part of the knowledge base. Always link to existing concepts/sources/entities pages where they exist.
10. **Not invoking `defuddle` on SEO content** → wastes 40-60% of tokens on noise, degrades extraction quality.
11. **Temporal leakage** → quoting a time-varying metric (stars, price, count, ranking) without its as-of date, or presenting out-of-window data as current. This was the top red-team finding on the agentic-AI run (post-window GitHub star counts quoted as in-window). Date-stamp at the explorer stage (Phase 3), gate at synthesis (Phase 5).
12. **Skipping Phase 9.5 self-improvement** → the methodology never compounds. program.md's Domain Notes stay frozen and every run re-learns the same lessons. Always append a lesson (or consciously decide there's none).

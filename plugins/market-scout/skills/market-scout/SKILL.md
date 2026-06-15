---
name: market-scout
description: >-
  Advanced product/market research — find "the best X on the market" in any
  category (best laptop, best phone, best 5G router, best headphones, best
  monitor, etc.) across major retailers (Amazon, Best Buy, Walmart, Newegg, B&H,
  Target, manufacturer). Runs a multi-agent pipeline: expert-review consensus +
  contrarian/owner-complaint mining + live cross-retailer pricing + spec
  verification, then a DETERMINISTIC weighted decision-matrix scoring engine,
  adversarial red-team verification, and a wiki-filed ranked recommendation with
  segment winners (best overall / value / performance / budget) and a buy
  sequence. TRIGGERS: "best <product> on the market", "what <product> should I
  buy", "find me the best <category>", "compare <products> and recommend",
  "market-scout", "scout the market for", "buying guide for". Integrates with
  your Obsidian wiki, ultradeep agents, llm-council, agentmemory, and search
  stack. DO NOT use for: a single known URL price check (just fetch it), or
  non-product research (use /ultradeep).
---

# market-scout

> The brain that decides **what is the best thing on the market** in a category —
> evidence-gathered, math-scored, red-teamed, and filed into the wiki. Built to
> the same architecture as `/ultradeep` (tunable `program.md` + orchestrator +
> explorer/red-team agents + wiki self-learning), specialized for buying
> decisions where the failure mode is *fabricated confidence*.

**Read `program.md` (in this skill folder) before every run** — it holds the
tunable defaults (depth, scoring profiles, source policy, retailer set, wiki
paths, self-learning Domain Notes). Edit that file, not this one, to tune.

## The core idea (why this is more than a web search)

A naive "best laptop?" answer is an LLM repeating listicles. market-scout separates
the two things that decision needs:

1. **Evidence** (LLM + agents are good at this) — gather expert consensus,
   contrarian owner reports, live prices across retailers, and verified specs.
2. **Judgment math** (a script is good at this) — normalize specs, apply a
   category-weighted decision matrix, compute value-per-dollar and segment
   winners **deterministically** in `scripts/score.py`. The ranking cannot be
   hallucinated; the LLM only writes the prose around it.

The deliverable always **takes a position** (per `program.md` decisiveness rule):
a #1 pick + segment winners + a *buy sequence*, with confidence labels.

---

## Pipeline (8 phases)

Create a TodoWrite item per phase. Scratch dir: `~/research/<category-slug>-<YYYY-MM-DD>/`.

### Phase 0 — Intake & scope
Pin the decision before researching. Capture (infer sane defaults; do NOT block
the user if a `/goal` is active — assume and state):
- **Category** (→ pick the matching `criteria.json` block; if none, propose adding one).
- **Use case / sub-segment** (e.g. 5G router → home gateway vs travel hotspot).
- **Budget band**, **region/retailers** (default US majors; optionally flag your regional
  availability when relevant — he travels, so global-eSIM/portability often matters).
- **Hard constraints** (must-haves / deal-breakers) and **weight profile**
  (`default` / `value` / `performance` / `travel` / category-specific).

### Phase 0.5 — Wiki + memory pre-search (ALWAYS)
Per the standard wiki traversal (hot → index → drill):
1. Read `~/agentic-wiki/hot.md`, then `index.md`.
2. Check `wiki/research-reports/` for a prior scout on this category — if found,
   factor it in ("we covered X; this run updates prices + new models Y, Z").
3. `mcp__agentmemory__memory_recall` for prior buying decisions / preferences.
4. If `claude-obsidian:wiki-query` is available, semantic-query the vault.

### Phase 1 — Criteria framing
Load `references/criteria.json` for the category. State the evaluation criteria,
their weights (active profile), and metric directions. This is the rubric the
whole run is graded against — make it explicit so the red-team can attack it.
If the category isn't modeled, add a block to `criteria.json` (copy `_generic`)
and justify the weights.

### Phase 2 — Parallel multi-modal research (the fan-out)
Dispatch **4–6 explorers in parallel** (Agent tool, `deep-research-explorer`
subagent, or a dynamic workflow if >10). Give each the 4-field spec
(Objective / Output format / Tools & sources / Boundaries) + `SCRATCH_DIR`.
Standard angle set (tune per category):

| Explorer | Angle | Primary sources |
|---|---|---|
| **A. Expert consensus** | Who do the testing labs crown? | RTINGS, Wirecutter, Tom's Hardware/Guide, PCMag, Consumer Reports, category specialists (e.g. Dong Knows Tech, RVMobileInternet for cellular) |
| **B. Contrarian / reliability** | What breaks, what disappoints, who regrets it? | Reddit (category subs), forums, long-term reviews, owner complaints, RMA threads |
| **C. Live cross-retailer pricing** | Real street price + stock across retailers | Amazon, Best Buy, Walmart, Newegg, B&H, Target, manufacturer; product MCPs if installed (see `references/integration.md`) |
| **D. Spec / datasheet verification** | Ground every spec in the manufacturer source | Official product pages, datasheets, regulatory filings |
| **E. (opt) New/discontinued tracker** | Newer model imminent? EOL? successor? | Manufacturer roadmap, news, release calendars |
| **F. (opt) Regional availability** | Can you actually buy it (your region / globally)? | Local retailers, import/customs, regional pricing |

Anti-bias rule: at least one explorer must hunt for the **non-obvious** pick and
for **reasons NOT to buy** the front-runner. See `references/sources.md` for the
trusted-source registry and tiered Exa routing (keyed→shared→searxng→WebSearch,
per `program.md`).

### Phase 3 — Triangulate → build `candidates.json`
Synthesize explorer notes into the run file the engine consumes:
```json
{ "category": "5g-router", "query": "best 5G router 2026", "generated": "YYYY-MM-DD",
  "weights_profile": "default",
  "candidates": [ { "name": "...", "model": "...", "form_factor": "...",
    "price_usd": 499, "metrics": { "expert_rating": 9.2, "max_5g_downlink_gbps": 3.4, ... },
    "review_consensus": "one-paragraph judgment", "sources": ["url", ...] } ] }
```
Rules: triangulate every quantitative claim across ≥2 unrelated sources; use the
**cheapest verified street price** as `price_usd`; normalize `expert_rating` to a
/10 from each source's scale; leave a metric `null` rather than guessing
(completeness penalty handles it honestly).

### Phase 4 — Score (deterministic engine)
```bash
python3 scripts/score.py SCRATCH/candidates.json \
    --criteria references/criteria.json \
    --profile <profile> \
    --out SCRATCH/results.json --md SCRATCH/matrix.md
```
Returns ranking + segment winners (best overall / value / performance / budget) +
per-metric normals + confidence labels. Re-run with `--profile value` /
`performance` / `travel` to show how the pick shifts by priority — surfacing this
sensitivity is a feature, not noise.

### Phase 5 — Adversarial red-team (ALWAYS)
Dispatch `deep-research-redteam` on the draft + scratch notes. It must attack:
unsupported specs, single-source prices, an over-stated #1, missing strong
candidates, recency rot (newer model out?), and **adverse-interest sourcing**
(a vendor/affiliate is not neutral on "X is best"). Escalate to a 2nd cycle on any
Critical finding (per `program.md`). Apply fixes; re-score if specs/prices change.

### Phase 5.5 — LLM Council (conditional)
If the decision is a genuine coin-flip whose decisive variable is **user-specific
and not in the evidence** (e.g. "does the user value global eSIM over raw speed"),
run `llm-council` AFTER the red-team to calibrate the *question* and convert it
into a decision RULE / buy sequence. Skip for clear-cut categories.

### Phase 6 — Synthesize the verdict
Write the judgment prose: 3-sentence exec summary, the decisive recommendation
(take a position), segment winners with reasoning, the **buy sequence** (what to
buy first / what to verify before buying), and honest caveats with confidence
labels. Declarative, present tense, no hedging unless evidence demands it.

### Phase 7 — File to wiki + memory + self-learn
```bash
python3 scripts/report.py SCRATCH/results.json SCRATCH/candidates.json \
    --summary "<exec summary>" --verdict "<verdict para>" \
    --out ~/agentic-wiki/research-reports/<slug>.md
```
Then (see `references/integration.md` for exact steps):
- Prepend one line to `wiki/log.md`: `## [YYYY-MM-DD] market-scout | <query> → [[research-reports/<slug>]]`
- Add a 2–3 line summary to the TOP of `wiki/hot.md`.
- Add the report to the relevant `wiki/index.md` section with `[[wikilinks]]`.
- `mcp__agentmemory__memory_save` the decision (type: `decision`).
- Append a transferable lesson to `program.md` → "Domain Notes" (Phase 7.5
  self-learning — this is how the tool compounds, exactly like ultradeep's 9.5).
- (Optional) run `graphify` on the scratch dir; (optional) cross-file to `~/llm-wiki/`.

---

## Integration map (quick)
- **Agents:** `deep-research-explorer` (fan-out), `deep-research-redteam` (verify);
  `Trend Researcher` / `Tool Evaluator` agents are good optional explorers.
- **Search:** tiered Exa (`exa-key` deep → shared `exa` → `searxng` unlimited →
  `WebSearch`) + `jina`/`searxng` URL read + `claude-obsidian:defuddle` on noisy pages.
- **Product data MCPs (optional, graceful-degrade):** ShopSavvy / retailerapi /
  Bright Data e-commerce extractors — see `references/integration.md`. If none
  installed, web research is the floor and the run still completes.
- **Wiki:** Obsidian personal vault (primary) + optional `~/llm-wiki` cross-file.
- **Escalation:** `llm-council` (Phase 5.5), `graphify` (Phase 7).

Full detail: `references/integration.md`. Source registry: `references/sources.md`.
Human-readable criteria rationale: `references/criteria.md`.

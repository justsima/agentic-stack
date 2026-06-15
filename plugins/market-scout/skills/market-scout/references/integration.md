# market-scout — integration map

How this skill plugs into your existing ecosystem. The whole point is reuse —
market-scout is the buying-decision sibling of `/ultradeep`, sharing its agents,
search stack, wiki, and self-learning pattern.

## Agents (reused, not reinvented)
- **`deep-research-explorer`** — the Phase 2 fan-out workers. Dispatch 4–6 in parallel
  with the 4-field spec (Objective / Output format / Tools & sources / Boundaries) +
  `SCRATCH_DIR`. Standard angles: expert-consensus, contrarian/reliability, live
  cross-retailer pricing, spec verification, (+ new-model tracker, regional availability).
- **`deep-research-redteam`** — Phase 5 adversarial verifier. Always run. Feed it the
  draft + scratch notes. Escalate to a 2nd cycle on any Critical finding.
- **Optional explorers:** `Trend Researcher` (category trend/positioning), `Tool
  Evaluator` (deep single-product evaluation). Use when the angle fits.
- Concurrency: ≤10 parallel via the Agent tool. For >10 angles or >20 candidates,
  escalate to a dynamic **Workflow** (per `program.md` "Claude Code Primitives").

## Search stack (tiered, per program.md)
1. Depth/contested → `mcp__exa-key__deep_search_exa` (`deep-reasoning`) / `web_search_advanced_exa`.
2. Breadth → shared `mcp__exa__web_search_exa`.
3. Floor → `mcp__searxng__searxng_web_search` (local, unlimited; needs Docker container
   up — `docker start searxng`, verify `curl localhost:8888`).
4. Final → built-in `WebSearch` (zero dependencies).
On 402/429 fall DOWN the chain; never retry an exhausted tier; note the downgrade.
URL→markdown: `mcp__searxng__web_url_read` / `mcp__jina__read_url`; run
`claude-obsidian:defuddle` on ad-heavy retail/review pages first.
> Real failure mode seen on the first run (2026-06-15): shared Exa 429 AND keyed Exa
> 402 (credits) simultaneously, SearXNG container initially down → WebSearch carried
> verification with zero data loss. Do NOT architect a run's depth around any one tier.

## Product-data MCPs (optional — graceful degradation)
None are wired into `~/.claude.json` yet. The skill works on web research alone; if you
install one, the pricing/spec explorers should prefer it (faster, structured):
- **ShopSavvy MCP** (hosted, free) — 100M+ products / 40k+ retailers; `product_search`,
  `product_offers`, `product_price_history`, `content_tldr_review`. Best plug-and-play.
- **retailerapi MCP** (`github.com/retailerapi/mcp`, free 1k/mo) — cross-retailer
  "who has it cheapest" by UPC/ASIN; price history, fees.
- **Bright Data e-commerce MCP** (free 5k/mo rapid) — structured extractors
  `web_data_amazon_product` / `_walmart_` / `_bestbuy_` / `_homedepot_` / `_google_shopping`.
- Others surveyed: open-product-mcp (SerpAPI Google Shopping), Apify price-comparison
  actors, BigGo (spec + price history).
To add one: register it in `~/.claude.json` `mcpServers`, then this skill's pricing/spec
explorers will pick it up via ToolSearch. No skill code change needed.

## Wiki (the compounding layer)
**Primary — Obsidian personal vault** (`~/agentic-wiki/`):
- Pre-search (Phase 0.5): read `hot.md` → `index.md` → check `research-reports/` for prior scouts.
- File (Phase 7): report to `research-reports/<slug>.md` (frontmatter via `report.py`);
  prepend to `log.md`; add a block to the TOP of `hot.md`; link into `index.md` "Research
  Reports"; `[[wikilink]]` related pages.
- Lint (optional): `claude-obsidian:wiki-lint` for orphans/dead links.
- Query (optional): `claude-obsidian:wiki-query` for semantic vault search in pre-search.
**Secondary — `~/llm-wiki/` (Karpathy LLM wiki)**: optional cross-file of the report into
`~/llm-wiki/wiki/projects/` or a `buying/` folder, mirroring how `/ultradeep` cross-files
(see hot.md history). Do this when the decision is reusable reference, not a one-off.

## Memory
- **agentmemory MCP** — `memory_recall` in Phase 0.5 (prior buying decisions/preferences);
  `memory_save` the final decision in Phase 7 (`type: decision`).
- **File memory** (`~/.claude/projects/.../memory/`) — for durable cross-session facts
  (e.g., "your 5G pick is the MH7150 for travel"); add a `MEMORY.md` pointer line.

## Escalation & enrichment
- **`llm-council`** (Phase 5.5) — run AFTER the red-team for a genuine coin-flip whose
  decisive variable is user-specific and not in the evidence; push it toward a decision
  RULE / buy sequence, not a verdict.
- **`graphify`** (Phase 7, optional) — knowledge graph over the scratch dir for a big
  multi-category program.

## Self-learning (Phase 7.5)
Append a transferable lesson to `program.md` → "Domain Notes" after every run (which
source won, which spec needs triangulation, which retailer lied about stock). This is how
the tool gets smarter — identical to `/ultradeep`'s Phase 9.5.

# Market Scout Program

Configurable defaults for the **market-scout** skill. The orchestrator reads this
before every run. Edit this file to tune behavior without touching `SKILL.md`.
Modeled on your `/ultradeep` `program.md` so the two tools share one mental model.

---

## Priorities (in order)

1. **Truthful ranking over confident ranking** — the #1 failure mode of AI shopping
   is fabricated certainty. Ground every spec/price in a source; let the engine, not
   vibes, order the field. Prefer a hedged "low confidence" to a clean lie.
2. **Decisiveness** — the report still takes a position. A #1 pick + segment winners
   + a buy sequence. No "it depends" without naming the decisive variable.
3. **Discoverability** — find the non-obvious pick and the reasons NOT to buy the
   front-runner, not just the consensus listicle.
4. **Token usage** — safety net only. Spend freely on quality (the user runs Max 20x).

---

## Depth defaults

- **Explorers in Phase 2: 4–6** (expert / contrarian / pricing / spec [+ new-model /
  regional]). Go to a dynamic workflow only if >10 angles or >20 candidates.
- **Candidate set: aim 6–12** real contenders before scoring. Fewer = shallow; more =
  prune to the credible field first.
- **Red-team: always.** Escalate to 2 cycles on any Critical finding.
- **Re-score across profiles** (`default` + `value` + the use-case profile) and report
  how the pick shifts — sensitivity is signal.
- Stop on saturation (a research round adds no new candidate and no price/spec change),
  never on cost.

---

## Confidence scoring

Every candidate carries a confidence label from the engine (`high`/`medium`/`low`),
driven by data completeness × source count:
- **high** — ≥80% of weighted metrics present AND ≥3 independent sources.
- **medium** — ≥60% AND ≥2 sources.
- **low** — below that; flag prominently and prefer not to crown it #1.

Specs/prices must be triangulated across ≥2 unrelated sources. Mark prices >30 days
old as stale. Mark a model "successor imminent" if a newer SKU is announced.

---

## Source policy

**Trust tiers** (full registry in `references/sources.md`):
- **Tier 1 (testing labs / independent):** RTINGS, Wirecutter, Consumer Reports,
  Tom's Hardware/Guide, PCMag, category specialists (Dong Knows Tech, RVMobile-
  InternetResourceCenter for cellular, SmallNetBuilder-style, Notebookcheck for laptops).
- **Tier 2 (leads only, never sole cite):** Reddit, forums, YouTube reviews, news
  aggregators — gold for contrarian/owner signal, weak as a spec source.
- **Exclude as primary:** affiliate listicles with no testing, SEO content farms,
  undated pages, the manufacturer's own marketing for comparative claims.

**Adverse-interest rule (load-bearing):** a seller/affiliate of product X is NOT a
neutral source for "X is the best." Cap any claim sourced only to interested parties
at `medium` and reword superlatives. (Lesson imported from prior research runs.)

---

## Retailer set (default — US majors)

Amazon · Best Buy · Walmart · Newegg · B&H Photo · Target · Costco · manufacturer
store. Always record the **cheapest verified in-stock** price as `price_usd`, note
the retailer, and list notable alternatives. Optionally, add a regional
availability note (local import reality + regional retail + global-eSIM where
the product is cellular) — he splits time between both and travels.

---

## Scoring profiles

Defined per category in `references/criteria.json`. Conventions:
- `default` — balanced; the headline ranking.
- `value` — price-weighted; drives "best value" cross-check.
- `performance` — price-blind; drives "best performance" segment.
- use-case profiles (e.g. `travel`, `portable`, `camera`, `battery`) — switch the
  headline when the user's sub-segment calls for it.

Weights are config, not code — tune them here/there as buying priorities evolve;
never hard-code a weight in the engine.

---

## Output style

- Declarative, present tense, no hedging unless evidence demands it.
- Lead with a 3-sentence executive summary, then the verdict (a position).
- Always include: decision matrix, segment winners, buy sequence, confidence labels.
- Cite sources inline; pages match the wiki's `/ultradeep` report style.

---

## Wiki integration

**Destination:** `~/agentic-wiki/research-reports/<slug>.md`
(file directly — folder exists). Then:
- Prepend to `wiki/log.md`: `## [YYYY-MM-DD] market-scout | <query> → [[research-reports/<slug>]]`
- Add a 2–3 line block to the TOP of `wiki/hot.md`.
- Link the report into the relevant `wiki/index.md` section.
- Optional cross-file to `~/llm-wiki/` and `graphify` on the scratch dir.
Full steps + frontmatter: `references/integration.md`.

---

## Search backends — tiered (same policy as ultradeep)

Depth-needed angles → `mcp__exa-key__deep_search_exa` first. Routine breadth →
shared `mcp__exa__web_search_exa` → `mcp__searxng__searxng_web_search` (local,
UNLIMITED, the floor) → `WebSearch` (final). On any 402/429, fall DOWN the chain,
don't retry the exhausted tier; note the downgrade. SearXNG needs its Docker
container up (`docker start searxng`) — if dead mid-run, fall to WebSearch.
Use `mcp__searxng__web_url_read` / `mcp__jina__read_url` for free URL→markdown;
`claude-obsidian:defuddle` on noisy retail/review pages before extraction.

---

## Model & effort

- **Lead orchestrator:** inherits session model (planning + synthesis).
- **Explorers:** `effort: high`. **Red-team:** `effort: max`. No model overrides.

---

## Domain Notes (self-learning — append after every run)

Phase 7.5 appends a transferable lesson here after each scout. Keep entries
specific and reusable (which source won, which spec needs triangulation, which
retailer lied about stock), not run summaries. This is how the tool compounds.

### Bootstrapping note (2026-06-15, build + first run)
- Built market-scout; first run = "best 5G router" (see
  `wiki/research-reports/best-5g-router-2026.md`). Architecture mirrors ultradeep.

### 5G routers / cellular gateways (added 2026-06-15, first run)
- **"5G router" is three different products** — disambiguate in Phase 0 or the
  ranking is apples-to-oranges: (a) **standalone home gateway** (Wi-Fi 7 router +
  built-in NR modem, AC-powered, e.g. Ubiquiti UDR-5G-Max); (b) **PoE add-on 5G
  modem** for an existing network (e.g. UniFi U5G-Max / U5G Backup); (c) **mobile/
  travel hotspot** (battery, eSIM, e.g. NETGEAR Nighthawk M7/M7 Pro). Score each
  cohort with the matching profile (`default` for a/b, `travel` for c); never rank
  a $90 backup modem against a $499 Wi-Fi 7 gateway on one list.
- **The marketing "max Gbps" is a theoretical modem ceiling, not real Wi-Fi
  throughput** — Dong Knows Tech measured the Nighthawk M7's real 5GHz at ~400 Mbps
  (80MHz channel) despite a "3.6Gbps Wi-Fi 7" label and 4Gbps modem. Triangulate
  modem-ceiling vs measured-Wi-Fi vs real-world Speedtest; weight measured over spec.
- **mmWave is receding, not advancing** in 2026 hotspots — the M7 Pro DROPPED mmWave
  vs the older M6 Pro. Don't assume "newer = more bands"; verify the NR band list.
- **For cellular gear, carrier/band compatibility + sourcing can outweigh the SKU**
  (cf. ultradeep's YB "channel > scent" lesson). An unlocked global-eSIM unit is
  worth more to a traveler (the user) than raw speed locked to one carrier.
- Specialist sources (Dong Knows Tech, RVMobileInternetResourceCenter) beat generic
  tech listicles for cellular routers — they actually bench the cellular side.
- **There is NO mainstream multi-source "best 5G router" ranking** — PCMag/CNET/
  Wirecutter/Tom's Guide "best router" lists are all *Wi-Fi* routers (TP-Link Archer,
  ASUS ZenWiFi). Cellular-5G is a specialist niche → don't dress one specialist's "#1"
  as "consensus" (red-team caught exactly this). Say "X's #1-ranked," cite the specialist.
- **Carrier lock can invert the pick and isn't on the spec sheet.** The NETGEAR M7 Pro
  (MR7400) reads like the flagship, but in the US it's AT&T-LOCKED at $449.99 with no
  clean new unlocked SKU (only Renewed/eBay) — verified via att.com + Best Buy. Modeling
  it carrier-free at $699 was wrong; re-modeled locked (carrier_freedom=0) and it fell
  from travel #1 to #3, surfacing the unlocked MH7150 as the real traveler's pick. ALWAYS
  resolve locked-vs-unlocked-vs-renewed for cellular gear before scoring.
- **Final 5G picks (2026-06-15):** top mobile/AT&T = M7 Pro · whole-home = UDR-5G-Max ·
  travel/carrier-free = MH7150 (global eSIM) · value/control = GL.iNet Puli AX
  (OpenWrt+VPN, the red-team's rescued candidate). Skip M6 Pro (EOL), M8550 (no eSIM),
  D-Link G530 (poorly rated). A higher M7 Ultra/MR7500 (mmWave) exists — verify stock.

### Cross-category run lessons (added 2026-06-15, first run)
- **`expert_rating` is the most-gamed input — anchor every value to a named source.** The
  red-team caught two fabricated ratings (UDR 9.2 vs Dong's actual 8.6; M7 Pro 8.7 with no
  source). Since `expert_rating` carries the most weight in `default`, an invented +0.6
  silently moves the #1. Rule: if only one lab rates it, use that exact number; if blending,
  label it inferred and cap confidence. Never round a hedge up at synthesis time.
- **The red-team WILL surface a missing candidate — verify scope before adding it.** It
  flagged the GL.iNet Puli AX as the omitted value pick AND mis-described its modem as
  "Cat-19" (sounds like 4G LTE). Verifying first (it IS 5G NR, X62/RM520N-GL) avoided both
  errors — excluding a valid product OR trusting a wrong reason. Receiving-code-review
  discipline applies to red-team output too: verify, don't blind-comply.
- **Tiered fallback is not theoretical.** This run hit shared-Exa 429 AND keyed-Exa 402
  (credits) simultaneously, with SearXNG's Docker container initially down. WebSearch (the
  zero-dependency floor) carried verification. Bring SearXNG up early (`docker start
  searxng`; `curl localhost:8888` returns HTTP 200) but never make any one tier load-bearing.
- **Mixed product CLASSES need a cross-class caveat + class-segmented verdict.** Scoring a
  home gateway against a pocket hotspot in one matrix penalizes each on metrics it isn't
  meant to have; the ladder's cross-class deltas are noise. Resolve with per-use-case picks,
  not a single crown — and SAY the single-ladder is "not like-for-like."

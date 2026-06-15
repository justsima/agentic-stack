# market-scout — criteria rationale (human-readable)

The machine-readable rubric lives in `criteria.json`. This file explains *why* the
weights are what they are, so a human (or the red-team) can challenge them. Weights
are config — change them in `criteria.json`, not in the engine.

## How weighting works
Each category has named **profiles** (weight vectors that sum to ~1.0). The active
profile decides the headline ranking. Every metric has a **direction** (`higher` =
more is better; `lower` = price/weight/latency). The engine min-max normalizes each
metric across the candidate set, then takes the weighted sum. Missing metrics are
excluded per-candidate and lower that candidate's `completeness` (→ confidence label),
rather than being guessed.

Two derived numbers, always reported:
- **value_index** — performance-only score ÷ street price, rescaled 0–100. The
  "what you get per dollar" lens; drives the *best value* segment.
- **performance_score** — the same score with the price weight removed; drives the
  price-blind *best performance* segment.

## 5G routers / cellular gateways
The decisive split is **product class** (handle in Phase 0):
- *Home gateway* (Wi-Fi 7 router + built-in modem) and *PoE add-on modem* → `default`.
- *Mobile/travel hotspot* → `travel` (battery, eSIM, portability, carrier freedom
  matter more than raw wired throughput).

`default` leans on **expert consensus (0.22)** + **5G downlink (0.18)** because the
testing labs already integrate real-world reception/throughput, while raw modem Gbps
is a useful but theoretical ceiling. Price (0.16) is meaningful but not dominant for a
"best on the market" question (use `value` to re-rank by price). Band coverage (0.12)
captures carrier flexibility; Wi-Fi generation + throughput (0.12 + 0.10) capture the
LAN side; wired uplink (0.10) matters for failover/primary-WAN use.

`travel` reweights to **battery (0.18) + eSIM (0.16) + portability (0.14) + carrier
freedom (0.10)** — for a traveler (e.g. a frequent traveler), a global-eSIM unlocked
unit beats a faster carrier-locked one. (Self-learning lesson: for cellular gear,
sourcing/carrier compatibility can outweigh the SKU.)

> ⚠️ Triangulate **measured Wi-Fi throughput** against the marketing number — a "Wi-Fi
> 7, 3.6Gbps" hotspot measured ~400 Mbps real (80MHz channel). Put the measured figure
> in `max_wifi_gbps` when a lab reports it.

## Laptops
`default` balances expert consensus, CPU, battery, display, and price. `performance`
swings to CPU+GPU+RAM for creators/devs. `portable` swings to battery+weight for
travel. `value` is price-dominant for students. Benchmarks (Geekbench/Cinebench for
CPU, 3DMark for GPU) go in `cpu_score`/`gpu_score`; normalize display/build to 0–10
from review language.

## Phones
`default` leads with expert consensus + camera + SoC + battery. `camera` is for
photography-first buyers (DXOMARK / expert camera score dominates). `battery` for
endurance. `update_years` (OS/security support) is a sleeper criterion that separates
otherwise-similar phones over a 3–5 year ownership horizon.

## Adding a category
Copy `_generic`, add the metrics that actually differentiate the category, set
directions, and write 2–4 profiles. Justify the weights here. Keep `expert_rating`
and `price_usd` in every category — they're the minimum viable decision axes.

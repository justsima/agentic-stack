#!/usr/bin/env python3
"""
market-scout scoring engine
===========================

Deterministic multi-criteria decision-analysis (MCDA) engine for "what is the
best X on the market" research runs. Pure Python stdlib — no dependencies.

Design contract (the load-bearing idea):
  The LLM orchestrator gathers EVIDENCE and writes JUDGMENT prose.
  This script does the MATH — min-max normalization, weighted scoring,
  value-per-dollar, segment winners, and a confidence/completeness penalty —
  so the headline ranking is reproducible and cannot be hallucinated.

Inputs
  candidates.json   a run file: {category, query, weights_profile, candidates:[...]}
  criteria.json     the category criteria library (labels, units, direction, weight profiles)

Usage
  python3 score.py CANDIDATES.json \
      --criteria ../references/criteria.json \
      --profile default \
      --out results.json \
      --md matrix.md

Output
  results.json  full machine-readable ranking + segment winners + per-metric normals
  matrix.md     a rendered markdown decision matrix + segment picks (paste into report)
  stdout        a compact human summary

Scoring math (per active weight profile)
  - Each metric is min-max normalized across the candidate set to [0,1] (1 = best).
      direction "higher": n = (x - min) / (max - min)
      direction "lower" : n = (max - x) / (max - min)   (price, latency, etc.)
      if max == min      : n = 0.5  (no information to separate them)
  - A candidate's score uses only the metrics it actually HAS. Missing metrics
    are excluded and the candidate's score is computed over its PRESENT weight,
    then we report `completeness` = present_weight / total_weight separately.
    (Standard MCDA missing-data handling; completeness drives the confidence label.)
  - score = 100 * sum(w_i * n_i for present i) / sum(w_i for present i)
  - value_index = performance-only score / price, then min-max scaled to 0..100.
  - Segment winners: best_overall, best_value, best_performance, best_budget.
"""

from __future__ import annotations

import argparse
import json
import sys
from statistics import median


# ----------------------------------------------------------------------------- helpers

def _load(path):
    with open(path, "r", encoding="utf-8") as fh:
        return json.load(fh)


def _criteria_for(criteria_lib, category):
    cats = criteria_lib.get("categories", {})
    if category in cats:
        return cats[category]
    # graceful fallback so an unknown category still scores
    return cats.get("_generic", {"label": category, "criteria": {}, "profiles": {}})


def _metric_meta(cat_def, key):
    """Direction/label/unit for a metric, defaulting sanely when undeclared."""
    c = cat_def.get("criteria", {}).get(key, {})
    return {
        "label": c.get("label", key),
        "unit": c.get("unit", ""),
        "direction": c.get("direction", "higher"),
        "is_price": bool(c.get("is_price", False)),
    }


def _normalize(values, direction):
    """Min-max normalize a dict {name: value|None} to {name: 0..1|None}. 1 == best."""
    present = {k: v for k, v in values.items() if isinstance(v, (int, float))}
    if not present:
        return {k: None for k in values}
    lo, hi = min(present.values()), max(present.values())
    out = {}
    for k, v in values.items():
        if v is None:
            out[k] = None
        elif hi == lo:
            out[k] = 0.5
        elif direction == "lower":
            out[k] = (hi - v) / (hi - lo)
        else:
            out[k] = (v - lo) / (hi - lo)
    return out


def _weighted(cand_normals, weights):
    """Score a single candidate over the metrics it has. Returns (score0_100, completeness)."""
    total_w = sum(weights.values())
    got_w = 0.0
    acc = 0.0
    for key, w in weights.items():
        n = cand_normals.get(key)
        if n is None:
            continue
        got_w += w
        acc += w * n
    if got_w == 0:
        return 0.0, 0.0
    return 100.0 * acc / got_w, (got_w / total_w if total_w else 0.0)


def _confidence(completeness, n_sources):
    if completeness >= 0.8 and n_sources >= 3:
        return "high"
    if completeness >= 0.6 and n_sources >= 2:
        return "medium"
    return "low"


# ----------------------------------------------------------------------------- core

def score_run(run, criteria_lib, profile_name):
    category = run.get("category", "_generic")
    cat_def = _criteria_for(criteria_lib, category)
    profiles = cat_def.get("profiles", {})

    if profile_name not in profiles:
        avail = ", ".join(profiles) or "(none defined)"
        raise SystemExit(
            f"[score] profile '{profile_name}' not found for category '{category}'. "
            f"Available: {avail}"
        )

    weights = profiles[profile_name]
    cands = run["candidates"]

    # ---- gather raw metric columns (union of every metric any profile references)
    metric_keys = set()
    for p in profiles.values():
        metric_keys.update(p.keys())
    # also include any metric present on candidates so the matrix shows it
    for c in cands:
        metric_keys.update(c.get("metrics", {}).keys())

    raw = {key: {c["name"]: c.get("metrics", {}).get(key) for c in cands} for key in metric_keys}
    normals = {key: _normalize(raw[key], _metric_meta(cat_def, key)["direction"]) for key in metric_keys}

    # ---- price column (for value + budget); price may live in metrics or top-level
    def price_of(c):
        return c.get("price_usd", c.get("metrics", {}).get("price_usd"))

    # ---- performance-only profile (drop the price weight) for the value index
    perf_weights = {k: w for k, w in weights.items() if not _metric_meta(cat_def, k)["is_price"] and k != "price_usd"}

    results = []
    for c in cands:
        cn = {key: normals[key].get(c["name"]) for key in metric_keys}
        score, completeness = _weighted(cn, weights)
        perf_score, _ = _weighted(cn, perf_weights) if perf_weights else (score, completeness)
        price = price_of(c)
        n_sources = len(c.get("sources", []))
        results.append({
            "name": c["name"],
            "model": c.get("model", ""),
            "form_factor": c.get("form_factor", ""),
            "price_usd": price,
            "score": round(score, 1),
            "performance_score": round(perf_score, 1),
            "completeness": round(completeness, 2),
            "confidence": _confidence(completeness, n_sources),
            "n_sources": n_sources,
            "raw_value_ratio": (perf_score / price) if (price and price > 0) else None,
            "normals": {k: (round(v, 3) if isinstance(v, float) else v) for k, v in cn.items()},
            "note": c.get("review_consensus", ""),
        })

    # ---- scale value ratio to a 0..100 index
    ratios = {r["name"]: r["raw_value_ratio"] for r in results if r["raw_value_ratio"] is not None}
    if ratios:
        lo, hi = min(ratios.values()), max(ratios.values())
        for r in results:
            rr = r["raw_value_ratio"]
            r["value_index"] = round(100.0 * (rr - lo) / (hi - lo), 1) if (rr is not None and hi > lo) else (50.0 if rr is not None else None)
    else:
        for r in results:
            r["value_index"] = None

    results.sort(key=lambda r: r["score"], reverse=True)

    # ---- segment winners
    scored = [r for r in results if r["score"] > 0]
    quality_floor = median([r["score"] for r in scored]) if scored else 0
    budget_pool = [r for r in scored if r["score"] >= quality_floor and r["price_usd"]]

    segments = {
        "best_overall": scored[0]["name"] if scored else None,
        "best_value": max(scored, key=lambda r: (r["value_index"] or -1))["name"] if scored else None,
        "best_performance": max(scored, key=lambda r: r["performance_score"])["name"] if scored else None,
        "best_budget": min(budget_pool, key=lambda r: r["price_usd"])["name"] if budget_pool else None,
    }

    return {
        "category": category,
        "category_label": cat_def.get("label", category),
        "query": run.get("query", ""),
        "profile": profile_name,
        "generated": run.get("generated", ""),
        "weights": weights,
        "quality_floor_score": round(quality_floor, 1),
        "segments": segments,
        "ranking": results,
        "metric_meta": {k: _metric_meta(cat_def, k) for k in metric_keys},
    }


# ----------------------------------------------------------------------------- rendering

def render_md(out):
    meta = out["metric_meta"]
    weights = out["weights"]
    # show the metrics that actually carry weight in this profile, price last
    cols = [k for k in weights if k != "price_usd"]
    cols.sort(key=lambda k: weights.get(k, 0), reverse=True)
    if any(meta[k]["is_price"] or k == "price_usd" for k in meta):
        cols = [c for c in cols if not meta.get(c, {}).get("is_price")]

    lines = []
    lines.append(f"### Decision matrix — {out['category_label']}")
    lines.append("")
    lines.append(f"*Profile: `{out['profile']}` · generated {out['generated']} · "
                 f"quality floor (median score) = {out['quality_floor_score']}*")
    lines.append("")

    header = ["#", "Product", "Price", "Score", "Value idx", "Perf", "Conf"]
    sep = ["---"] * len(header)
    lines.append("| " + " | ".join(header) + " |")
    lines.append("| " + " | ".join(sep) + " |")
    for i, r in enumerate(out["ranking"], 1):
        price = f"${r['price_usd']:,.0f}" if r["price_usd"] else "—"
        vi = f"{r['value_index']:.0f}" if r["value_index"] is not None else "—"
        lines.append(
            f"| {i} | **{r['name']}** {('('+r['model']+')') if r['model'] else ''} "
            f"| {price} | **{r['score']:.1f}** | {vi} | {r['performance_score']:.1f} | {r['confidence']} |"
        )
    lines.append("")

    # segment picks
    seg = out["segments"]
    lines.append("### Segment winners")
    lines.append("")
    label = {
        "best_overall": "🏆 Best overall",
        "best_value": "💰 Best value (performance / $)",
        "best_performance": "⚡ Best performance (price-blind)",
        "best_budget": "🪙 Best budget (cheapest above quality floor)",
    }
    for key in ("best_overall", "best_performance", "best_value", "best_budget"):
        name = seg.get(key)
        if not name:
            continue
        r = next((x for x in out["ranking"] if x["name"] == name), None)
        extra = ""
        if r:
            if key == "best_value" and r["value_index"] is not None:
                extra = f" — value index {r['value_index']:.0f}, ${r['price_usd']:,.0f}"
            elif r["price_usd"]:
                extra = f" — score {r['score']:.1f}, ${r['price_usd']:,.0f}"
        lines.append(f"- **{label[key]}:** {name}{extra}")
    lines.append("")
    return "\n".join(lines)


# ----------------------------------------------------------------------------- cli

def main(argv=None):
    ap = argparse.ArgumentParser(description="market-scout MCDA scoring engine")
    ap.add_argument("candidates", help="run file (candidates.json)")
    ap.add_argument("--criteria", required=True, help="criteria.json library")
    ap.add_argument("--profile", default=None, help="weight profile (default: run's weights_profile or 'default')")
    ap.add_argument("--out", default=None, help="write results.json here")
    ap.add_argument("--md", default=None, help="write rendered matrix markdown here")
    args = ap.parse_args(argv)

    run = _load(args.candidates)
    criteria_lib = _load(args.criteria)
    profile = args.profile or run.get("weights_profile", "default")

    out = score_run(run, criteria_lib, profile)

    if args.out:
        with open(args.out, "w", encoding="utf-8") as fh:
            json.dump(out, fh, indent=2)
    md = render_md(out)
    if args.md:
        with open(args.md, "w", encoding="utf-8") as fh:
            fh.write(md + "\n")

    # stdout summary
    seg = out["segments"]
    print(f"\n[market-scout] {out['category_label']} — profile '{out['profile']}' — {len(out['ranking'])} candidates")
    print(f"  🏆 best overall     : {seg['best_overall']}")
    print(f"  ⚡ best performance : {seg['best_performance']}")
    print(f"  💰 best value       : {seg['best_value']}")
    print(f"  🪙 best budget      : {seg['best_budget']}")
    print("\n  rank  score  value  conf   product")
    for i, r in enumerate(out["ranking"], 1):
        vi = f"{r['value_index']:5.0f}" if r["value_index"] is not None else "    —"
        print(f"  {i:>3}  {r['score']:>5.1f}  {vi}  {r['confidence']:<6} {r['name']}")
    print()
    return 0


if __name__ == "__main__":
    sys.exit(main())

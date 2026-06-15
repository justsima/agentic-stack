#!/usr/bin/env python3
"""
Merge GitHub traffic API snapshots into permanent CSV history + a markdown report.

GitHub's /traffic/views and /traffic/clones return only the last 14 days. This
script upserts each daily data point into traffic/views.csv and traffic/clones.csv
(keyed by date, newest value wins), then regenerates traffic/REPORT.md with
all-time totals and the last 30 days. Pure stdlib.

Run by .github/workflows/analytics.yml, which writes traffic/_views.json and
traffic/_clones.json first.
"""
from __future__ import annotations
import csv, json, os, datetime

TRAFFIC = "traffic"

def load_snapshot(path, daily_key):
    if not os.path.exists(path):
        return {}, 0, 0
    d = json.load(open(path, encoding="utf-8"))
    rows = {}
    for it in d.get(daily_key, []):
        day = it["timestamp"][:10]
        rows[day] = (int(it.get("count", 0)), int(it.get("uniques", 0)))
    return rows, int(d.get("count", 0)), int(d.get("uniques", 0))

def load_csv(path):
    out = {}
    if os.path.exists(path):
        for r in csv.DictReader(open(path, encoding="utf-8")):
            out[r["date"]] = (int(r["count"]), int(r["uniques"]))
    return out

def write_csv(path, data):
    with open(path, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f); w.writerow(["date", "count", "uniques"])
        for day in sorted(data):
            c, u = data[day]; w.writerow([day, c, u])

def merge(existing, snapshot):
    merged = dict(existing)
    merged.update(snapshot)   # API value wins for overlapping days
    return merged

def totals(data):
    return sum(c for c, _ in data.values()), sum(u for _, u in data.values())

def main():
    os.makedirs(TRAFFIC, exist_ok=True)
    vsnap, _, _ = load_snapshot(f"{TRAFFIC}/_views.json", "views")
    csnap, _, _ = load_snapshot(f"{TRAFFIC}/_clones.json", "clones")

    views = merge(load_csv(f"{TRAFFIC}/views.csv"), vsnap)
    clones = merge(load_csv(f"{TRAFFIC}/clones.csv"), csnap)
    write_csv(f"{TRAFFIC}/views.csv", views)
    write_csv(f"{TRAFFIC}/clones.csv", clones)

    vc, vu = totals(views); cc, cu = totals(clones)
    today = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%d")

    def recent_table(data, label):
        days = sorted(data, reverse=True)[:30]
        lines = [f"| Date | {label} | Unique |", "| --- | ---: | ---: |"]
        for d in days:
            c, u = data[d]; lines.append(f"| {d} | {c} | {u} |")
        return "\n".join(lines)

    md = f"""# 📊 Traffic — permanent archive

_Auto-updated daily by `.github/workflows/analytics.yml`. Last run: {today} (UTC)._

GitHub only keeps 14 days of traffic; this folder is the full history.

## All-time totals (since archiving began)
| Metric | Total | Unique |
| --- | ---: | ---: |
| 👁️ Views  | **{vc}** | {vu} |
| ⬇️ Clones ("downloads") | **{cc}** | {cu} |
| 📆 Days tracked | {len(views)} (views) / {len(clones)} (clones) | |

> Live stars/forks/views badges are in the main [README](../README.md). This file
> is the long-term record the badges can't keep.

## Last 30 days — views
{recent_table(views, "Views")}

## Last 30 days — clones
{recent_table(clones, "Clones")}

---
Raw data: [`views.csv`](views.csv) · [`clones.csv`](clones.csv)
"""
    open(f"{TRAFFIC}/REPORT.md", "w", encoding="utf-8").write(md)
    print(f"[traffic] views: {vc} total / {vu} uniques ({len(views)} days) | "
          f"clones: {cc} total / {cu} uniques ({len(clones)} days)")

if __name__ == "__main__":
    main()

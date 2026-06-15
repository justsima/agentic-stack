# 📊 Traffic — permanent archive

_Auto-generated daily by [`.github/workflows/analytics.yml`](../.github/workflows/analytics.yml). GitHub deletes traffic (views + clones) after 14 days; this folder holds the full history._

## Status: ⏳ awaiting activation

The daily workflow **runs green**, but archiving stays idle until a token is added (GitHub's built-in token can't read the traffic API). One-time setup:

1. Create a **fine-grained PAT** scoped to this repo with **Administration: Read** + **Contents: Read and write** (or a classic PAT with `repo`).
2. Repo → **Settings → Secrets and variables → Actions → New repository secret** → name it **`GH_TRAFFIC_TOKEN`**, paste the PAT.
3. **Actions → "Analytics (traffic archiver)" → Run workflow.**

Once active, this file shows all-time totals + the last 30 days of **views** and **clones ("downloads")**, backed by [`views.csv`](views.csv) and [`clones.csv`](clones.csv).

> Live stars / forks / views badges are in the main [README](../README.md) — they need no setup. This archive is the long-term record those badges can't keep.

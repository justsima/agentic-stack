# market-scout — trusted source registry

Per-category source tiers. Tier 1 = independent testing/lab sources you may cite as
primary. Tier 2 = leads-only (great for contrarian/owner signal, weak for specs).
Affiliate listicles with no original testing are **not** primary anywhere.

## Cross-category (independent testing)
- **RTINGS** — lab-tested, repeatable methodology (TVs, headphones, monitors, mice, etc.)
- **Wirecutter (NYT)** — editorial picks with testing notes
- **Consumer Reports** — subscription lab tests, reliability survey data
- **PCMag** — broad, benchmarked
- **Tom's Hardware / Tom's Guide** — benchmarked PC + networking + mobile

## Networking / routers / 5G / cellular
- **Dong Knows Tech** — deep independent router + cellular-gateway reviews (benches the
  cellular side, not just Wi-Fi). Best single source for 5G gateways in 2026.
- **RVMobileInternet Resource Center (rvmobileinternet.com)** — the authority on mobile
  hotspots / cellular routers; band lists, chipset, carrier compatibility, real testing.
- **SmallNetBuilder**-style deep-dives, **Tom's Hardware networking** section.
- Manufacturer datasheets (NETGEAR, Ubiquiti, TP-Link, D-Link) — for spec verification ONLY.
- Tier 2: r/HomeNetworking, r/Ubiquiti, r/NETGEAR, r/embeddedlinux mobile-data threads.

## Laptops
- **Notebookcheck** (display/thermal/battery lab data), **Tom's Hardware**, **PCWorld**,
  **The Verge**, **Engadget**; benchmark DBs: Geekbench, Cinebench, 3DMark, PassMark.
- Tier 2: r/laptops, r/SuggestALaptop, manufacturer forums.

## Phones
- **GSMArena** (specs + battery/display tests), **DXOMARK** (camera/display/battery),
  **RTINGS** (phones), **Tom's Guide**, **The Verge**.
- Tier 2: r/Android, r/iphone, carrier forums.

## Headphones / audio
- **RTINGS**, **SoundGuys**, **Head-Fi** (enthusiast, Tier 2), **What Hi-Fi**.

## Pricing / availability (retailers)
Amazon · Best Buy · Walmart · Newegg · B&H Photo · Target · Costco · manufacturer.
Price-history / deal context: CamelCamelCamel (Amazon history), Keepa, Slickdeals,
and — if installed — the product MCPs in `integration.md` (ShopSavvy price history,
retailerapi cross-retailer cheapest).

## Tiered search routing (per program.md)
1. Depth/contested angle → `mcp__exa-key__deep_search_exa` (`deep-reasoning`).
2. Breadth → shared `mcp__exa__web_search_exa` → `mcp__searxng__searxng_web_search`
   (local, unlimited floor) → `WebSearch`.
3. URL → markdown: `mcp__searxng__web_url_read` / `mcp__jina__read_url`; run
   `claude-obsidian:defuddle` on ad-heavy retail/review pages first.
On 402/429 fall DOWN the chain; never retry the exhausted tier; note the downgrade.

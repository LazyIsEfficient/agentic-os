# Segment economics — <game title>

> Per-segment fill of the monetization strategy. Updated from soft-launch / live data when available; use comp-title benchmarks before launch.

## Profile assumptions
- **Geo mix:** <e.g. tier-1 majority / global / region-specific>
- **Platform mix:** <iOS / Android / Steam / web / hybrid>
- **Source of benchmarks:** <which comp titles, which industry reports, internal historicals>

## Segments

### Whale (top spenders)
- **% of installs:** <0.5–1%>
- **% of payers:** <8–15%>
- **% of total revenue:** <30–50%>
- **ARPU/month:** <$200+>
- **Sessions/day:** <4–6>
- **Retention curve (assumed):** <very flat — D30 ≥ 50%>
- **Primary motivations:** <speed, status, exclusivity, completion>
- **Tactics they respond to:** <premium battle pass, exclusive cosmetics, top-tier currency packs, VIP perks>
- **Failure modes:** <runs out of content, status diluted by inflation, paid item nerfed>

### Dolphin (mid-spenders)
- **% of installs:** <3–5%>
- **% of payers:** <40–60%>
- **% of total revenue:** <30–40%>
- **ARPU/month:** <$20–$200>
- **Sessions/day:** <2–4>
- **Retention curve (assumed):** <moderate — D30 ≥ 25%>
- **Primary motivations:** <meaningful upgrades, occasional luxuries, season completion>
- **Tactics they respond to:** <battle pass, themed bundles, mid-tier currency packs>
- **Failure modes:** <perceives high tier as paywall, churns into minnow when content slows>

### Minnow (light spenders)
- **% of installs:** <10–20%>
- **% of payers:** <30–50%>
- **% of total revenue:** <10–20%>
- **ARPU/month:** <$1–$20>
- **Sessions/day:** <1–3>
- **Retention curve (assumed):** <decaying — D30 ≥ 12%>
- **Primary motivations:** <starter packs, removing ads, supporting the game, occasional indulgence>
- **Tactics they respond to:** <one-time starter pack, ad removal, season pass at low tier>
- **Failure modes:** <one purchase only; never converts to dolphin without a clear upgrade path>

### Free (non-spenders)
- **% of installs:** <70–85%>
- **% of revenue (via ads if applicable):** <0–5%>
- **Sessions/day:** <1–2>
- **Retention curve (assumed):** <fast decay early; long tail for engaged free players>
- **Role in the model:** <population for whales' multiplayer, ad inventory, virality, eventual conversion>
- **Tactics they respond to:** <rewarded ads, free passes, daily login rewards, referral bonuses>
- **Failure modes:** <ad fatigue, perceived F2P friction, lapses without re-engagement hook>

### Lapsed-then-return (re-engagement)
- **% of base (overlap):** <varies; ~10–20% of total install lifetime>
- **Retention shape:** <sudden return spike at re-engagement events>
- **Tactics they respond to:** <"welcome back" bundles, content drops, season-start hooks, narrative cliff-hangers>
- **Failure modes:** <returns once, never again, if the re-engagement event isn't memorable>

## Cross-segment analysis
- **Population pyramid:** <does the model produce a stable distribution? whales need dolphins/minnows for the game to feel alive>
- **Conversion funnel:**
  - Free → Minnow: target <5–10%>
  - Minnow → Dolphin: target <15–25%>
  - Dolphin → Whale: target <5–10%>
- **Whale-resilience check:** <if top 1% of revenue evaporates, does the game still ship a sustainable P&L? — if no, the model is too whale-concentrated>

## Per-segment ad strategy (if rails include ads)
- **Whale:** ads off (premium experience expected)
- **Dolphin:** rewarded ads only (opt-in)
- **Minnow:** rewarded + occasional interstitial
- **Free:** all ad units; ad revenue is the main revenue source
- **Note:** if the game has *any* paid path, ad placements should not feel punitive on payers (a top-spender seeing a banner is a refund risk)

## Telemetry contract
- **Per-event:** `iap_purchase(sku, price, currency, segment_at_time)`, `ad_view(unit_type, segment_at_time)`, `subscription_start / cancel`
- **Per-cohort report:** segment migration over time (a player's segment changes; track the path)
- **Funnel report:** install → first session → first IAP → conversion path

## Hand-off
- **`game-balancer`:** segment splits inform whose retention curve / progression curve must hold
- **`iap-manager`:** per-segment SKU classes (whale-tier vs minnow starter pack)
- **`game-marketer`:** per-segment acquisition cost ceilings (you can pay more to acquire a whale-shaped install)
- **`growth-engine`:** A/B test plan for monetization variants (price tests, pass length tests)

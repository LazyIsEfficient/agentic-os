# Monetization strategy — <game title>

> The macro commercial frame. One per game. Re-issued at major model changes (e.g. moving from premium to F2P, adding subscription tier, opening web3 rails).

## 1. Game and rails recap
- **Game:** <title> / <platform(s)>
- **Concept logline:** <from concept one-pager>
- **Payment rails (from concept-creator):** <none / web2 IAP / web2 ads / web2 sub / web3 tokens / web3 NFTs / hybrid>
- **Jurisdiction / platform constraints:** <Apple/Google policy, Steam policy, regional regulations, chain policy if web3>

## 2. Chosen model
- **Primary model:** <premium / F2P / subscription / ad-supported / hybrid / web3-native>
- **Secondary tactic(s):** <e.g. premium + cosmetic IAP, F2P + battle pass + ads>
- **Why this model fits the design:** <2–3 sentences>
- **Where this model fights the design:** <honest — name the tension>
- **Comp titles using this model successfully:** <2–4>
- **Comp titles where this model failed and why:** <1–2>

## 3. Macro economy frame
- **Currency count:** <1 / 2 / 3 — and the role of each>
- **Catalog shape (handed to `iap-manager`):**
  - Currency packs: <yes/no, how many tiers>
  - Bundles: <yes/no, frequency>
  - Battle / season pass: <yes/no, length, free/paid track structure>
  - Cosmetics: <yes/no, rarity tiers>
  - Skip / convenience: <yes/no>
  - Ad units: <none / rewarded / interstitial / banner — placement intent>
  - Subscription tier: <none / single tier / multi-tier — what each tier gets>
  - Web3 SKUs: <none / token packs / NFT mints / secondary fees — only if rails include web3>
- **Price-tier ladder (intent — actual SKUs from `iap-manager`):**
  - Entry tier: <e.g. $0.99 — purpose: low-friction first purchase>
  - Mid tier: <$4.99 — primary minnow tier>
  - Standard tier: <$9.99 — primary dolphin tier>
  - High tier: <$19.99 — dolphin-to-whale bridge>
  - Premium tier: <$49.99 — whale tier>
  - Luxury tier: <$99.99 — top-whale tier>

## 4. Segment economics
> See [segment-economics-template.md](segment-economics-template.md) for the per-segment fill.

| Segment | % of installs | % of revenue | Target ARPU/month | Primary tactic |
|---|---|---|---|---|
| Whale | <0.5–1%> | <30–50%> | <$200+> | <e.g. premium battle pass + exclusive cosmetics> |
| Dolphin | <3–5%> | <30–40%> | <$20–$200> | <e.g. battle pass + occasional bundles> |
| Minnow | <10–20%> | <10–20%> | <$1–$20> | <e.g. starter pack + season pass> |
| Free | <70–85%> | <0–5% (ads if applicable)> | $0 | <ads / referral / community> |

## 5. KPI floors (the ship gates)
> Soft launch fails any of these → either re-tune or kill.

| KPI | Floor | Reasoning |
|---|---|---|
| D1 retention | <e.g. ≥40%> | <comp benchmark / category norm> |
| D7 retention | <e.g. ≥18%> | <> |
| D30 retention | <e.g. ≥8%> | <> |
| Conversion to first IAP (D7) | <e.g. ≥3%> | <> |
| ARPDAU (steady state) | <e.g. ≥$0.20> | <> |
| ROAS at D30 | <e.g. ≥0.5> | <> |
| ROAS payback | <e.g. ≤180 days> | <> |
| Crash-free sessions | <e.g. ≥99.5%> | <> |
| Review score floor | <e.g. ≥4.2> | <> |

## 6. Retention-to-monetization map
- **Retention shape assumed:** <e.g. "exponential decay with shoulder at D7", "stepped with seasonal re-engagement spikes">
- **Daily-engagement loop:** <what makes the player open the app tomorrow>
- **Weekly-engagement loop:** <what makes the player return Saturday>
- **Seasonal-engagement loop:** <what makes the player return next season>
- **If retention falls X% short:** <which KPI breaks, by how much, what action>

## 7. Web3 (only if rails include web3)
- **Token role:** <currency / governance / reward / speculation>
- **NFT role:** <cosmetic identity / collectibles / gameplay items — and the nerf-risk implication>
- **Sinks plan:** <what absorbs token supply>
- **Secondary market policy:** <fee, royalty, allowlist>
- **Web2 fallback:** <how non-wallet players play>
- **Jurisdictional constraints:** <which markets are excluded / restricted>
- **Risk:** <token velocity collapse, NFT illiquidity, regulatory action>

## 8. Soft launch plan
> See [soft-launch-kpi-template.md](soft-launch-kpi-template.md) for the full sheet.

- **Geos:** <e.g. CA, AU, NZ, PH>
- **Duration:** <weeks>
- **Sample size target:** <DAU / installs needed for KPI confidence>
- **Decision gates:** <what makes us go global / re-tune / kill>
- **Success ceiling:** <what would make us *expand* the soft-launch geo set>

## 9. Stress tests
- **Retention -30%:** <impact on ARPDAU, LTV, ROAS — and the response>
- **IAP conversion -50%:** <>
- **Platform fee +10%** (e.g. policy change): <>
- **Regulatory event** (loot box ban, crypto ban, age rating change in target market): <>
- **Adblock spike** (if ad-dependent): <>
- **Whale concentration breaks** (top 1% from 40% → 25% of revenue): <>

## 10. Strategy risks
- **Top monetization risks (ranked):**
  1. <risk> — <mitigation>
  2. <risk> — <>
  3. <risk> — <>

## 11. Hand-offs
- **`game-balancer`:** target ARPDAU, segment splits, currency velocity intent
- **`iap-manager`:** catalog shape, price-tier ladder, segment-targeted SKU classes, A/B price test plan
- **`game-marketer`:** soft launch plan, ROAS targets, CPI floor, store-page promises that align with model
- **`game-systems-designer`:** any system change required to support the model (re-route here if found)
- **`godot-engineer`:** monetization telemetry events, IAP / ad / sub SDK plumbing, restore-purchases, anti-fraud
- **`growth-engine`:** experiments planned post-launch (price tests, pass length tests, ad placement tests)
- **`finance-ops`:** revenue forecast inputs, contribution to studio P&L, runway impact

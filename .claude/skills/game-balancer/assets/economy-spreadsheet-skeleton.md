# Economy spreadsheet skeleton

> A scaffold for the spreadsheet model. Reproduce in Sheets / Excel / Numbers / a Python notebook — the *model* is what matters, not the tool. The recommended structure is a sequence of named sheets, each doing one job.

## Sheet 1 — `Currencies`

| Currency | Symbol | Type | Source(s) | Sink(s) | Soft cap | Hard cap | Convertible to |
|---|---|---|---|---|---|---|---|
| Gold | G | Soft | Quest rewards, kills, sells | Crafting, repair, NPC services | 1M | 99M | — |
| Gems | 💎 | Hard | IAP, rare quest rewards | Skip timers, premium cosmetics | — | 99,999 | — |
| Energy | ⚡ | Time-gated | +1 / 5min, IAP refills | Each run costs 5⚡ | 30 | 100 (with refill) | — |

> Aim for **1–3 currencies**. Each must have at least one source and one sink. If a currency has no sink, it inflates and the world devalues. If it has no source besides paid, it's a paid-only currency — call it that explicitly.

## Sheet 2 — `Player profiles`

| Profile | % of base | Sessions/day | Min/session | Plays/session | Spend/month | Notes |
|---|---|---|---|---|---|---|
| Whale | 0.5% | 4 | 30 | 12 | $200+ | Wants progression speedup, exclusive cosmetics, status |
| Dolphin | 4% | 3 | 20 | 8 | $20–$200 | Wants meaningful upgrades; price-sensitive at the top |
| Minnow | 15% | 2 | 15 | 5 | $1–$20 | Buys starter packs and battle pass |
| Free | 80% | 1.5 | 10 | 3 | $0 | Drives ad revenue and retention; converts at <5% |
| Lapsed-then-return | 10% (overlap) | varies | — | — | — | Re-engagement levers; usually different price sensitivity |

> Adjust profile counts and rates from soft-launch / comp-title data. Defaults shown are *F2P mobile* benchmarks; PC premium / web3 will look different.

## Sheet 3 — `Sources`

For each currency × each source, capture:

| Source | Currency | Per occurrence | Daily cap (free) | Daily cap (paid) | Profile expectation |
|---|---|---|---|---|---|
| Win a match | Gold | 50 | 30 wins | uncapped | Free: 1500/day, Whale: 5000+/day |
| Daily login (day 7) | Gems | 50 | 1 | 1 | Free: 50/week |
| Quest: weekly | Gold | 5,000 | 1 | 1 | Free: 5000/week |
| IAP — small pack | Gems | 500 | — | — | $4.99 |

## Sheet 4 — `Sinks`

For each currency × each sink:

| Sink | Currency | Cost | Frequency | Profile expectation |
|---|---|---|---|---|
| Repair gear | Gold | 200/use | Each run | Free: 600/day spend |
| Craft tier-3 item | Gold | 5,000 | Once/week-ish | Free: rate-limited by gold income |
| Skip timer | Gems | 20/skip | Whale: 5×/day, Dolphin: 1×/day | — |

## Sheet 5 — `Velocities`

Computed per profile per day per currency:

| Profile | Currency | Earn/day | Spend/day | Net/day | Days to next milestone | Notes |
|---|---|---|---|---|---|---|
| Free | Gold | 1500 | 800 | +700 | Tier-up at 35,000 → ~50 days | If >60 days, players will quit before payoff |
| Free | Gems | 50/week | 0 | +50/week | First cosmetic at 500 → 10 weeks | Acceptable if cosmetic is aspirational |
| Whale | Gems | 5,000/IAP × 4/month | 4,000/month | +16,000/month | Endgame in 2 months | Expected — whale's payoff is *speed* |

## Sheet 6 — `Curves`

For each progression curve (XP, levels, tiers, gear), one column per level / tier:

| Level | XP to next | Cumulative XP | Reward | Notes |
|---|---|---|---|---|
| 1 | 100 | 0 | Tutorial unlock | — |
| 2 | 200 | 100 | First skill | — |
| 3 | 350 | 300 | — | — |
| ... | ... | ... | ... | ... |
| 50 | 25,000 | 350,000 | Endgame unlock | Soft cap |

Plot the column to verify the *shape* matches the chosen curve type (see `references/progression-math.md`).

## Sheet 7 — `Drop tables`

For each loot table, list outcomes and probabilities. Sum to 1.0 (or 100%):

| Outcome | Weight | Probability | Notes |
|---|---|---|---|
| Common | 60 | 60.0% | — |
| Uncommon | 25 | 25.0% | — |
| Rare | 12 | 12.0% | — |
| Epic | 2.9 | 2.9% | — |
| Legendary | 0.1 | 0.1% | Pity timer at 100 fails — see pity-timer sheet |

## Sheet 8 — `Pity timers / pseudo-random`

For loot, gacha, or rare drop systems, document the actual algorithm:

- True random vs pseudo-random distribution (PRD)
- Pity floor (guaranteed at N attempts)
- Soft pity (rate increases starting at attempt N)
- Hard pity (guarantee at attempt M)
- Cross-pull pity (carry over between sessions / banners)

Players audit these. Document them; do not hide them; do not lie about them. (Many jurisdictions require disclosure.)

## Sheet 9 — `Time-to-content`

For each major content gate, predict how many days each profile reaches it:

| Content gate | Whale (days) | Dolphin (days) | Minnow (days) | Free (days) | Design intent |
|---|---|---|---|---|---|
| Unlock chapter 2 | 1 | 2 | 4 | 7 | All profiles within first week |
| First legendary | 5 | 14 | 30 | 60 | Free reaches it but it takes commitment |
| Endgame raid | 14 | 30 | 60 | 120 | Free can reach without paying — *aspirational* |

If a free player can never reach the endgame, the design is *paywall*-shaped, not *speedup*-shaped. Be honest about which one shipped.

## Sheet 10 — `KPI rollup`

Top-line numbers the model predicts:

- Average session length (median, p95) per profile
- Average plays per session
- Average days to D7, D30, D60
- Average ARPDAU per profile (input from `game-monetization-strategist`)
- Predicted retention curve (D1 / D7 / D30) — calibrated against comp titles
- Currency inflation/deflation per week per profile

Cross-reference with the brief's success bar. If the model predicts numbers below the bar, change the *design intent* (back to `game-systems-designer`) or the *model* — don't quietly retune to lie to the spreadsheet.

## Sheet 11 — `Sensitivity`

For the 3–5 levers most likely to be retuned post-launch, vary each ±20% and capture the impact:

| Lever | -20% impact | +20% impact | Risk |
|---|---|---|---|
| Gold/win | -700 net/day → minnow churn | +700 net/day → inflation, low conversion | Medium |
| Energy regen | -1 run/day → engagement loss | +1 run/day → ad revenue impact | High |
| Drop rate (Epic) | -2.9% → no aspirational drops | +2.9% → trivializes legendary | Low |

This is the *retune surface area* the team has when the live data deviates from the model.

## Sheet 12 — `Telemetry contract`

What needs to be measured in soft launch / live to validate this model:

| Metric | Source event | Reporting cadence | Alert threshold |
|---|---|---|---|
| Median session length | `session_end` | Hourly | <80% of model |
| Currency velocity per profile | `currency_grant`, `currency_spend` | Daily | ±20% from model |
| Time to chapter 2 (free) | `content_unlock` | Daily cohort | >150% of model |
| Conversion to first IAP | `iap_purchase` (first) | Daily | <50% of model |

Hand this contract to `godot-engineer` (or other engine team) for instrumentation, and to `site-reliability-engineering` for alerting.

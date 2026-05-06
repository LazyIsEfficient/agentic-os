# Balance pass types

Five common kinds of balance work. Pick the one that fits before opening the spreadsheet.

## 1. Economy balance

**Signal:** the design has currencies, sources, sinks, and the team needs to know the rates.

**Inputs:** system specs touching currency; player profiles; ARPDAU / LTV target (from `game-monetization-strategist`); intended player lifetime.

**Outputs:** filled `economy-spreadsheet-skeleton.md`; per-currency velocity tables; time-to-content predictions; sensitivity analysis on top 3–5 levers.

**Pitfalls:**
- Tuning for the median player only (whales bored, free quits)
- Ignoring time horizon (works at week 1, breaks at week 8)
- Letting designers set "feels right" numbers without modeling

## 2. Progression balance

**Signal:** the design has XP / levels / tiers / mastery and the team needs the curve.

**Inputs:** intended arc length (hours / sessions / days); intended reward map; comp curves to anchor against.

**Outputs:** filled `progression-curve-skeleton.md` per curve; reward map with each tier's role; sensitivity on growth rate and earn rate.

**Pitfalls:**
- Picking the constants before the curve shape
- Not connecting reward map to design's verbs and aesthetic
- Forgetting to model multiple play-rate cohorts (hardcore vs casual)

## 3. Difficulty balance

**Signal:** the design is challenge-aesthetic and the team needs encounter / level / boss tuning.

**Inputs:** verb depth axis from `game-systems-designer`; intended skill curve; failure design from the design doc.

**Outputs:** difficulty curve plotted; per-encounter tuning; flow-channel analysis (skill vs challenge over time); telemetry to validate fairness.

**Pitfalls:**
- Tuning to the team's own skill (developer playtest bias)
- Confusing difficulty with grind (grind is *length*, not difficulty)
- No DDA / rubber-banding plan when the difficulty band is narrow

## 4. Content balance

**Signal:** the design has variety drivers (cards, items, characters, levels) and the team needs no dominant strategy.

**Inputs:** content list; verb support per item; intended role of each item in the meta.

**Outputs:** matchup matrix (or analog); per-item win-rate / pick-rate target; sensitivity to power creep; meta health plan.

**Pitfalls:**
- Internal balance (no item is strongest) without external balance (the meta funnels to 3 builds)
- Power creep across content drops
- "Just nerf" reflex when the right answer is "buff alternatives"

## 5. Live re-tune

**Signal:** the game is live; data shows drift; a re-tune is needed without breaking trust.

**Inputs:** live telemetry; the original model; the player community's expectations.

**Outputs:** re-tune plan (`live-rebalancing.md`); rollout plan (A/B if possible); rollback plan; comms plan with `game-marketer`; cross-check with `iap-manager` if catalogs are touched.

**Pitfalls:**
- Silent nerfs to monetized content (NFTs, premium gear) without comms — destroys trust
- Re-tuning without an A/B if the population is large enough to test
- Not updating the model — next re-tune flies blind

## Cross-cutting

A balance pass usually does **one** of these well at a time. Trying to do all five in one pass is how teams ship balance changes that are individually defensible but collectively incoherent.

# Progression curve skeleton

> A scaffold for a single progression curve (XP, levels, gear tiers, season tiers, mastery, prestige). One filled skeleton per curve.

## Curve identity
- **Name:** <e.g. "Player level 1–60", "Battle pass tier 1–100", "Gear tier 1–10">
- **What it tracks:** <XP, currency, completion of arc>
- **What it unlocks:** <content, abilities, cosmetics, status>
- **Length of arc (intent):** <hours of play / sessions / days>

## Shape choice
- **Type:** <linear / exponential / log / stepped / capped / resetting>
- **Why this shape:** <one sentence — what player journey this shape produces>
- **Comp curves to anchor against:** <which comp titles use this shape and why>

## Parameters
- **Start value:** <e.g. XP to L1 → L2 = 100>
- **End value:** <e.g. XP to L59 → L60 = 25,000>
- **Growth rate / step pattern:** <e.g. 1.18× per level, plateau every 10 levels>
- **Total cumulative:** <how much in total to reach the cap>

## Player intent per profile

| Profile | Plays/day | Earn rate | Days to cap | Notes |
|---|---|---|---|---|
| Hardcore | 6 | 1500 XP/play | 16 days | Endgame within ~2 weeks |
| Median | 3 | 1000 XP/play | 50 days | Endgame within season |
| Casual | 1.5 | 800 XP/play | 100 days | May not cap; needs alternate aspirational goal |

## Reward map

| Tier | Reward type | Reward identity | Function in design |
|---|---|---|---|
| 1 | Tutorial | First skill | Onboarding completion |
| 5 | Cosmetic | Hat A | First "I earned this" moment |
| 10 | Mechanical | New verb modifier | Unlocks build variety |
| 25 | Status | Rank icon | Mid-game status |
| 50 | Mechanical | Endgame-tier item | Endgame on-ramp |
| 60 | Status | Prestige badge | "I'm done" pride |

## Curve visual
> Plot the curve in your tool of choice. Verify by eye that the shape matches the intent. A curve that looks linear when the design intent says "exponential late-game" is mis-tuned.

## Sensitivity
- ±20% on growth rate → days-to-cap impact: <>
- ±20% on earn rate → days-to-cap impact: <>
- ±20% on plays/day → days-to-cap impact: <>

## Telemetry contract

| Metric | Source event | Cadence | Alert |
|---|---|---|---|
| % of cohort at tier N by day D | `player_level_up` | Daily | <50% of model → re-tune |
| Median time to tier 25 | `player_level_up` | Weekly | >150% of model → too slow |
| % of paying cohort that pre-purchases the season | `iap_purchase(pass)` | Hourly during launch week | <model floor → repricing or repackaging needed |

# Balance table — <system name>

> Append to the matching system spec from `game-systems-designer`. One row per `<TBD>` resolved. Keep design intent next to the number; future re-tunes need the rationale.

## Variables

| Variable | Final value | Design intent | Curve / formula | Sensitivity (±20%) | Source / sink connection | Notes |
|---|---|---|---|---|---|---|
| `gold_per_win` | 50 | "Free player nets +700/day" | flat | -700/day → minnow churn; +700/day → inflation | Source: combat win | Comp anchor: Game X 40–80 |
| `xp_per_level` | `100 * 1.18^(L-1)` | "Endgame at ~50 days for median player" | exponential 1.18 | -10% growth → 35 days; +10% growth → 70 days | Source: any activity | Curve sheet: `Curves!A:F` |
| `legendary_drop_rate` | 0.001 | "Average 1 legendary per 1000 attempts; pity at 100 fails" | PRD with hard pity | ±20% → ±20% drop frequency | Source: boss kills | See pity-timer sheet |
| ... | | | | | | |

## Curves attached
- [Player level curve](../assets/progression-curve-skeleton.md)
- [Battle pass curve](../assets/progression-curve-skeleton.md)
- ...

## Telemetry events to instrument
- `currency_grant(currency, amount, source)`
- `currency_spend(currency, amount, sink)`
- `player_level_up(level, time_in_session, total_play_time)`
- `content_unlock(content_id, days_since_install)`
- `session_end(duration_s, plays_completed, currency_delta)`

## Re-tune triggers
- If median session length deviates >25% from model → re-tune `<which lever>`
- If conversion to first IAP <50% of model by D7 → re-tune `<which lever>` and consult `iap-manager`
- If currency velocity (whales) >150% of model → consider sink injection (events, sales, content)

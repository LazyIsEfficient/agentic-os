# Balance pass checklist

> Run before declaring a balance pass complete. A pass that skips items here is a pass that ships unproven numbers.

## Pre-pass

- [ ] Design intent for each `<TBD>` is captured *in writing* (not just in the balancer's head)
- [ ] Curve shapes chosen *before* solving for constants
- [ ] Comp-title benchmarks identified for each curve / KPI floor
- [ ] Player profiles enumerated and weighted (% of base) — not just "median"
- [ ] Time horizon defined (sessions, weeks, season length, intended player lifetime)

## Spreadsheet model

- [ ] Currencies sheet: every currency has at least one source AND one sink
- [ ] Sources sheet: every source maps to a verb / activity in the design doc
- [ ] Sinks sheet: every sink produces meaningful choice (not just "spend it because")
- [ ] Velocities sheet: net per-day computed for every currency × every profile
- [ ] Curves sheet: every curve plotted; shape matches stated intent
- [ ] Drop tables: weights sum to 1.0; pity / PRD / soft-pity rules documented
- [ ] Time-to-content sheet: every major content gate predicted per profile
- [ ] KPI rollup: model predicts session length, ARPDAU, retention shape

## Sanity tests

- [ ] **Whale doesn't run out of content** in the first month (predicted endgame > 30 days at whale rate)
- [ ] **Free player can reach endgame** at all (predicted endgame is finite, even if long)
- [ ] **Median player hits the first "wow" reward** within their first 2–3 sessions
- [ ] **Currency velocities are stable** (no profile inflates or deflates uncontrollably across the season)
- [ ] **No dominant strategy** — at least 2 viable approaches in the core loop
- [ ] **No dead choice** — every choice the player can make is *the right choice* in some situation
- [ ] **Difficulty curve shape** matches the aesthetic (Challenge games have a real curve; Cozy games don't)

## Sensitivity

- [ ] Top 3–5 levers identified — the ones most likely to retune post-launch
- [ ] ±20% sensitivity computed for each lever
- [ ] Worst-case impact named ("if X is 20% off, the failure mode is Y")

## Playtesting (engine, not spreadsheet)

- [ ] **At least 3 internal playtests** validate the model's prediction of session length within ±25%
- [ ] **At least 1 external playtest** with target-audience players, observed not just self-reported
- [ ] **Pacing felt** matches pacing predicted (player session experience matches the spreadsheet shape)
- [ ] **Feedback collected** on perceived fairness, perceived grind, perceived spend pressure (if applicable)

## Telemetry contract

- [ ] All metrics in the KPI rollup have an `event_name` ready for instrumentation
- [ ] Cadences set per metric (real-time / hourly / daily / cohort)
- [ ] Alert thresholds set (above / below model triggers re-tune review)
- [ ] Hand-off to `godot-engineer` (or other engine team) for instrumentation
- [ ] Hand-off to `site-reliability-engineering` for SLI / alerting setup

## Cross-skill validation

- [ ] **`game-systems-designer`** has reviewed and signed off that no rule changes were silently made
- [ ] **`game-monetization-strategist`** has reviewed and signed off that the economy supports the target ARPDAU / LTV
- [ ] **`iap-manager`** has the currency velocities needed to size starter packs and bundles
- [ ] **`game-marketer`** has the time-to-content numbers needed for store-page promises and soft-launch KPI floors

## Documentation

- [ ] Each system spec has its balance table appended (`assets/balance-table-template.md`)
- [ ] Each curve has its filled skeleton (`assets/progression-curve-skeleton.md`)
- [ ] Spreadsheet model committed (Sheets URL, Excel file, Python notebook) — not just in someone's local docs
- [ ] Design intent for each `<TBD>` is preserved next to the chosen number (so future re-tunes have context)
- [ ] **Why these numbers** documented in 1–2 paragraphs per major system (the rationale matters more than the values)

## Sign-off

- [ ] Designer (rules), Balancer (numbers), Monetization Strategist (model), and Engineer (implementation) have all reviewed
- [ ] Open risks logged (which numbers are weakest, which most likely to drift, which depend on guesses)
- [ ] Re-tune trigger plan: what live data is the team committed to acting on, on what cadence

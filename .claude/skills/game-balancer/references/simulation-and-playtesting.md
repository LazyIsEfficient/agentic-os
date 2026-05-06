# Simulation and playtesting

The spreadsheet predicts the economy *if* the model captures the system. The engine plays the game *as built*. Players reveal what neither the spreadsheet nor the engine show. All three are needed.

## When each modality wins

- **Spreadsheet** — fast iteration on shape and rates; cheap to revise; can model time horizons (months/years) the team can't playtest. Wins for *predicting* economy and progression behavior.
- **Engine playtest** — what the game actually does, with all the messy interactions the spreadsheet abstracts. Wins for *validating* the spreadsheet's predictions and surfacing emergent behavior.
- **Player playtest** — what real players (not developers) feel and do. Wins for *fairness perception*, *engagement*, *frustration*, and the gap between *designed intent* and *understood intent*.

A team that uses only spreadsheet ships an economy that breaks under real play. A team that uses only engine playtest ships balance changes that "feel right today" and collapse next month. A team that uses only player playtest tunes for what playtesters say they want, which is rarely what they actually do.

## Simulating player profiles

Build a small sim (spreadsheet macro, Python script, in-engine script) that "plays" the economy as a player profile would:

- **Whale sim** — high paid spend, low patience for time gates, high content consumption rate
- **Dolphin sim** — moderate paid spend, moderate patience, mid content consumption
- **Minnow sim** — low paid spend (starter pack, season pass), patient on time gates
- **Free sim** — no paid spend; full reliance on time gates and ad rewards

Run each profile across the planned content arc (e.g. 90 days). Capture:
- Currency velocities (in / out / net per day)
- Content gate hit times (when each profile reaches each chapter / tier)
- Stalling points (where a profile runs out of progression)
- Whale / non-whale gap (does the whale outpace content?)

## Monte Carlo for variance

For loot, drop tables, gacha, and pity systems, run N=1000+ iterations of the sim per profile. Capture:
- **Mean time to rare drop** vs **median** vs **95th percentile**
- **Worst-case bad-luck duration** (the player who hits the long tail)
- **Pity activation rate** (% of attempts that hit the pity floor)

A drop table where the *median* player gets a rare in 50 attempts but the *worst 5%* don't get one in 500 attempts will produce vocal complaints from those players. The sim surfaces this; the spreadsheet alone may not.

## Internal playtest

Goals:
- **Validate the spreadsheet predictions.** Is the actual session length within ±25% of model? Is the actual XP per session within ±25%?
- **Surface broken interactions** the model abstracts away. Does combo X make encounter Y trivial?
- **Check pacing felt.** Does the curve feel like the shape you picked?

Cadence: **after every meaningful balance change.** Internal playtests are cheap and fast.

Pitfall: **developer skill bias.** Developers play the game differently from real players (faster reflexes, deeper system understanding). Internal playtest pacing data is *optimistic*; assume real players will be 25–50% slower.

## External playtest (with target audience)

Goals:
- **Find the gap** between design intent and player understanding. What does the player *think* they're doing vs. what the system does?
- **Measure perceived fairness.** Even if the spreadsheet says "fair," do players agree?
- **Catch "feels grindy"** moments the spreadsheet misses. A 50-day median to endgame might *technically* fit the model and *feel* awful in practice.

Cadence: **before every major content drop**, **before soft launch**, **before global launch**, and at least once during the prototype phase.

Format: pick one of:
- **Observed sessions** — playtester at a desk, observed (in person, screen-share, recorded). High signal, low N.
- **Diary studies** — give playtesters builds for 1–2 weeks, capture daily journals. Best for retention / engagement signals.
- **Surveys + telemetry** — large-N, lower depth. Use to validate hypotheses, not to discover them.

Pair with `ux-research` for protocol design and synthesis.

## What playtest is *not* for

- **Confirming a balance you've already shipped.** Playtest is *exploratory* and *evaluative*, not ceremonial.
- **Settling design debates.** "Players like A more than B" in a small playtest is a weak signal; bring it back to the spreadsheet and the design intent.
- **Replacing telemetry.** Playtest produces depth; telemetry produces breadth. You need both.

## Soft launch as the largest playtest

Soft launch (release to 1–3 small markets before global) is the highest-fidelity playtest of an F2P game. Goals:

- **Validate the model at scale.** Is the predicted ARPDAU realistic in real markets?
- **Find segment-specific issues.** Does the curve work for region X's player base?
- **Surface paywalls and quit moments** that internal playtest missed.
- **Set the KPI floor** for global launch (D1, D7, D30, ARPDAU, ROAS).

Coordinate with `game-monetization-strategist` (KPI targets), `iap-manager` (catalog testing), and `game-marketer` (CPI and acquisition channels).

## Telemetry coverage

Every metric the model predicts must have a corresponding event:

- `session_start`, `session_end(duration_s)`
- `currency_grant(currency, amount, source)`
- `currency_spend(currency, amount, sink)`
- `player_level_up(level, time_in_session, total_play_time)`
- `content_unlock(content_id, days_since_install)`
- `iap_purchase(sku, price, currency)`
- `iap_view(sku)` — for funnel
- `iap_dismiss(sku)` — for funnel
- `match_end(result, win_rate_so_far)` (for PvP balance)
- `loot_drop(table, rarity, attempts_since_last)` (for drop table balance)

Hand the event list to `godot-engineer` (or other engine team) for instrumentation and to `site-reliability-engineering` for ingestion / alerting.

## Output

After playtest:
- **Validation table** — spreadsheet prediction vs observed reality, per metric
- **Surface bugs / unexpected dynamics** — combo X breaks Y; pacing in chapter 3 stalls; profile Z runs out of currency at week 5
- **Re-tune list** — what to change in the model and what to change in the engine
- **Updated model** — the spreadsheet should *learn* from the playtest, not stay stale

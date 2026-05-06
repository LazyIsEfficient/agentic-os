# Soft launch

A controlled release in a limited set of markets, before global launch. The highest-fidelity validation of the model the team will get pre-global. Skipping soft launch is how teams ship a global launch that fails on KPIs they could have caught in 6 weeks of CA / AU / NZ data.

## Goals

- **Validate KPI floors.** Do the actual D1 / D7 / D30 / ARPDAU match the strategy's predictions?
- **Find paywalls and quit moments.** What in the live experience wasn't visible in playtest?
- **Calibrate acquisition.** What's the realistic CPI for the target ICP?
- **Stress the systems.** Server load, payment flows, support volume, anti-fraud.
- **Iterate fast.** Soft launch is the team's last chance to re-tune before the global launch attention window.

## Geo selection

Pick geos that:

- **Reflect the global audience** in language (English-first usually) and behavior (mobile / PC habits)
- **Are smaller than the global market** so an underwhelming launch doesn't hurt long-term reputation
- **Have enough population to reach the sample target** in the budget timeline
- **Have payment rails comparable to global** (don't soft-launch in markets where the dominant payment rail is unavailable globally)

Common geos:
- **CA, AU, NZ** — English-speaking, similar to US/UK behavior, smaller markets, established for soft launch
- **PH, ID, VN** — Southeast Asia; high mobile penetration; lower ARPU but high engagement
- **MX, BR** — Latin America; growing markets; useful if the game has Spanish/Portuguese localization
- **NL, IE, NO** — small Western European markets; tier-1 ARPU; useful for higher-spend categories

For web3 games, also factor in *jurisdictions where crypto IAP is permitted* — limits the geo set further.

## Duration and sample size

Rough targets:

- **Sample target** — 10,000+ DAU for KPI confidence on retention; 50,000+ for monetization KPIs
- **Time per cohort** — D1 takes 1 day; D7 takes a week; D30 takes a month. Plan accordingly.
- **Total duration** — 4–12 weeks typical. Less than 4 means D7 data is shaky. More than 12 means the team is procrastinating.

## Decision criteria (gates)

Each KPI gets three thresholds — see `kpis-and-floors.md`:

- **Floor** — below this → kill or major rework
- **Target** — at this level → ship globally with iteration plan
- **Strong** — above this → ship globally and scale acquisition aggressively

Soft launch fails any KPI's floor → re-tune-or-kill conversation. Soft launch hits target across all KPIs → go global. Soft launch hits strong → go global *and* expand UA budget.

## What to instrument

- Full retention curve (D1–D30 cohort)
- Full conversion funnel (install → tutorial → D1 → first store visit → first IAP)
- Per-segment ARPU (whale / dolphin / minnow / free)
- Crash rate, ANR rate, session length
- Ad fill rate, eCPM (if rails include ads)
- Subscription conversion / churn (if rails include sub)
- IAP funnel per SKU (view → consider → purchase → repeat)
- Specific events from the design's failure-quit theory ("at level 5 boss, % who quit")

## Rapid iteration

Soft launch is *iterative*, not *single-shot*. Expect to ship balance changes, IAP changes, UX changes weekly during the soft-launch window. Coordinate with:

- **`game-balancer`** for in-game economy / progression / difficulty re-tunes
- **`iap-manager`** for catalog re-pricing, bundle adjustments, A/B price tests
- **`ux-design`** for store-side UX, paywall visibility, onboarding tweaks
- **`game-marketer`** for store-page A/B (icon, screenshots, description) and ad-creative iteration

## Acquisition channel test

Soft launch is also where you find which UA channels work for this game:

- Run multiple ad networks in parallel (Meta, Google Ads, Unity, AppLovin, IronSource, TikTok)
- Optimize for ROAS / IAP-event signal where the network supports it
- Capture per-channel CPI, retention, ARPU, ROAS at D7 / D30
- Identify the channels that produce *whale-shaped installs*

The channel mix from soft launch becomes the global launch UA plan.

## Ad-creative test

UA performance depends on creative as much as on game quality. Run creative testing in soft launch:

- Multiple creative concepts (gameplay, story, juice, hook variants)
- Multiple ad formats (playable, video, interactive, banner)
- Creative refresh cadence (a creative typically peaks within 1–2 weeks)
- Capture per-creative CPI and downstream retention

Hand the creative learnings to `game-marketer`.

## Comms during soft launch

Players in soft-launch geos know they're early. They will talk about the game online. Manage expectations:

- **Don't oversell** — "soft launch" framing is honest
- **Be present in community** (Discord, Reddit, Apple/Google reviews) — early players who feel heard convert to advocates
- **Acknowledge known issues** — silence reads as "they don't care"
- **Roll out balance changes with comms** — coordinate patch notes with `game-marketer`

## Ending soft launch

When soft launch ends, output:

- **Decision** — go global / re-tune and re-soft / kill
- **Updated KPI floors** for live ops (calibrated to soft-launch reality)
- **Updated acquisition plan** for global UA ramp
- **Updated catalog** (with `iap-manager`)
- **Updated balance** (with `game-balancer`)
- **Updated forecast** (with `finance-ops`)

## Web3 soft launch notes

If the rails include web3:

- **Closed beta with allowlists** is a common web3 soft-launch shape
- **Token economy needs separate validation** — monitor token velocity, sink saturation, secondary market depth
- **NFT mint dynamics** matter — primary mint sell-through speed, secondary market activation
- **Web2 fallback path validation** — can non-wallet players actually play? are their KPIs healthy?

Web3 soft launches often need *longer* duration than web2 because token / market dynamics take weeks to stabilize.

# Retention → monetization

Most monetization KPIs are downstream of retention. ARPDAU = ARPU × (1 - churn). LTV is integrated ARPDAU over the payback horizon. The model fails when the design doesn't produce the retention shape the model assumes.

## The math

Simplified F2P:

- **DAU** = (newly installed - lapsed) × retention curve
- **ARPDAU** (avg revenue per daily active user) = total revenue / DAU
- **ARPU** (avg revenue per user, lifetime) = total revenue / total users
- **ARPPU** (avg revenue per *paying* user) = total revenue / paying users
- **LTV** ≈ ARPDAU × (1 / churn rate) — for an exponential-decay retention curve
- **ROAS** = revenue / acquisition cost (at a given time horizon)
- **Payback** = time at which ROAS = 1.0

A 1pp drop in D7 retention compounds across the curve. A model that assumes D7=18% will fail noticeably at D7=14%.

## Retention curve shapes

- **Exponential decay** — most common; constant churn rate per day. LTV = ARPDAU / churn.
- **Power-law decay** — common in casual mobile; faster early decay, longer tail.
- **Stepped** — long flats with seasonal re-engagement spikes; common in GaaS with strong content cadence.
- **Subscription S-curve** — initial churn spike (free trial → paid), then long tail of low monthly churn.

Pick the curve shape based on comp titles in the same category. Don't assume your game will be the exception until soft launch proves it.

## Daily / weekly / seasonal hooks

Each cadence layer reinforces retention at that horizon:

- **Daily** — login reward, daily quest, energy regen, daily event. Drives D1–D7.
- **Weekly** — weekly content, weekly bosses, weekly leaderboards. Drives D7–D30.
- **Seasonal** — battle pass, season story, ladder reset. Drives D30+.

A game with no weekly hook will lose players by week 3. A game with no seasonal hook will lose players by month 2. Each hook layer earns its retention.

## Retention shape vs model fit

| Model | Required retention shape | What breaks if retention is shorter |
|---|---|---|
| Premium | Doesn't matter (one-time purchase) | Reviews / wishlists / discoverability |
| F2P + IAP | D30 ≥ 8% | LTV < CPI → unprofitable acquisition |
| Subscription | Monthly churn ≤ 10% | LTV math doesn't pencil; price must rise (drives further churn) |
| Ad-supported | DAU stable; sessions/day high | Ad eCPM × view count not enough to cover ops |
| Battle pass | D30 ≥ 8% AND 80% of pass-buyers complete | Pass conversion drops; players lose trust in passes |
| Web3 token | D30 ≥ 12% (token economy needs sustained demand) | Token sells; price collapses; retention drops further |

If the design doesn't produce the required retention shape, change the design (back to `game-systems-designer`) or change the model.

## Conversion funnel

Players don't appear as payers; they convert through a funnel:

1. **Install** — acquisition
2. **First session complete** — onboarding
3. **D1 return** — early retention
4. **First store visit** — discovery of monetization
5. **First IAP / first ad view** — conversion
6. **Repeat purchase** — retention of payers
7. **Whale conversion** — top-spender behavior emerges

Each step has a typical drop-off. F2P benchmarks (rough; vary by category):

- Install → tutorial complete: 70–85%
- Tutorial → D1 return: 30–50%
- D1 return → D7 return: 35–50% (of those who returned D1)
- D7 return → first IAP: 5–15%
- First IAP → second IAP: 30–50%

Soft-launch funnel data is the highest-signal signal you'll get pre-global. Hand it to `iap-manager` for store-side optimization and to `ux-design` for in-game UX.

## Cohort vs population

Cohort analysis (track installs from a specific day across their lifetime) is the right way to measure retention. Population analysis (DAU as % of MAU) is a useful real-time signal but distorted by the rolling input.

For monetization decisions, always cohort. For live-ops alerts, population is fine.

## ARPU growth over time

Within a cohort, ARPU grows over time (more players have made first purchases, second purchases, etc.). Curves to know:

- **D7 ARPU** — first signal that conversion is happening
- **D30 ARPU** — early steady-state estimate
- **D90 ARPU** — cohort lifetime estimate (most LTV is realized by D90 in F2P; longer for premium / web3)
- **D365 ARPU** — long-tail value; matters for live games

Forecast cohort LTV from D30 ARPU using the assumed retention curve. Validate forecasts at D90 and D365. Refine the model.

## When the model says "ship" but the design says "no"

If the math says the model works (LTV > CPI by a wide margin) but the design *requires* spending pressure that the team is uncomfortable with — pause. A profitable model that the design team won't defend post-launch is a model that becomes a comms nightmare.

Examples:
- Pay-to-win F2P that the systems team didn't intend
- Aggressive paywalls that the UX team didn't want
- NFT economy that the audience wasn't asked about

Resolve through stakeholder alignment, not by overruling the design.

## Output

For the strategy doc:
- Required retention shape (D1 / D7 / D30 with curve type)
- Required ARPDAU floor
- Required conversion floor
- Required payback window
- The funnel-step assumptions
- The ARPU growth curve assumption (D7 / D30 / D90)

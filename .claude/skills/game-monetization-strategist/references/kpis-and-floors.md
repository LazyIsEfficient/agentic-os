# KPIs and floors

What to measure, what's a healthy number, what's a kill threshold. Use as a starting point; recalibrate to your category and audience using comp-title benchmarks.

## Retention

| KPI | Floor (kill below) | Healthy | Strong |
|---|---|---|---|
| D1 retention (F2P mobile) | 35% | 40–45% | 50%+ |
| D7 retention (F2P mobile) | 14% | 18–22% | 25%+ |
| D30 retention (F2P mobile) | 6% | 8–12% | 15%+ |
| D1 retention (F2P PC) | 40% | 50%+ | 60%+ |
| D7 retention (F2P PC) | 18% | 25%+ | 30%+ |
| D1 retention (mid-core mobile) | 40% | 45%+ | 55%+ |
| D7 retention (mid-core mobile) | 20% | 25%+ | 30%+ |
| Subscription monthly churn | 15% | ≤10% | ≤5% |
| Hyper-casual D1 | 30% | 35%+ | 40%+ |

## Engagement

| KPI | Floor | Healthy | Strong |
|---|---|---|---|
| Sessions / DAU | 1.5 | 2.5–3.5 | 4.0+ |
| Median session length (mobile F2P) | 5 min | 8–12 min | 15+ min |
| Median session length (PC) | 15 min | 30–45 min | 60+ min |
| Sticky factor (DAU/MAU) | 0.10 | 0.20+ | 0.30+ |

## Monetization

| KPI | Floor | Healthy | Strong |
|---|---|---|---|
| Conversion to first IAP (D7, F2P mobile) | 1.5% | 3–5% | 7%+ |
| Conversion to first IAP (D7, mid-core) | 2% | 5–8% | 10%+ |
| ARPDAU (F2P mobile) | $0.10 | $0.20–$0.50 | $1.00+ |
| ARPDAU (mid-core RPG) | $0.30 | $0.80–$2.00 | $3.00+ |
| ARPDAU (subscription / sub-tier) | $0.30 | $0.80+ | $2.00+ |
| ARPPU (paying user) | $5/month | $10–$30/month | $50+/month |
| ARPDAU (ad-only hyper-casual) | $0.04 | $0.08–$0.20 | $0.30+ |

## Acquisition / ROAS

| KPI | Floor | Healthy | Strong |
|---|---|---|---|
| ROAS at D30 | 0.30 | 0.50–0.80 | 1.0+ |
| ROAS payback | 365 days | 120–180 days | ≤90 days |
| LTV / CPI | 1.0 | 1.5–2.5 | 3.0+ |

## Quality

| KPI | Floor | Healthy | Strong |
|---|---|---|---|
| Crash-free sessions | 99.0% | 99.5% | 99.8%+ |
| Review score (App Store / Google Play) | 3.8 | 4.2 | 4.5+ |
| Steam review % positive | 70% | 80%+ | 90%+ ("Very Positive") |
| Tutorial completion | 60% | 75% | 85%+ |

## Soft launch decision triplets

Each KPI gets three thresholds:

- **Floor** — below this, the game is not commercially viable in current form. Re-tune-or-kill.
- **Target** — at this level, ship globally with caveats. Monitor and tune in live ops.
- **Strong** — at this level, ship globally and scale acquisition aggressively.

The thresholds above are starting points. Calibrate to:
- **Category** — hyper-casual differs from gacha differs from premium PC
- **Comp titles** — what the actual market is doing right now
- **Geo mix** — tier-1 spends more than tier-3
- **Platform** — mobile differs from PC differs from console

## Cohort vs population

For all retention and ARPU metrics, use **cohort analysis**:
- Track installs from a specific day across their lifetime
- D1, D7, D30 are *cohort* numbers (% of that cohort that returned on day N)
- DAU and MAU can be population numbers; useful for live-ops alerting

For monetization decisions, *always cohort*. Population numbers contain the rolling input of new installs and lapsed players, which distorts the picture.

## Alert thresholds (live ops)

Once live, set automated alerts at:

- **Retention** — alert at 80% of healthy floor (e.g. D7 < 16% → alert if healthy is 18%)
- **ARPDAU** — alert at 50% drop week-over-week (sudden monetization break)
- **Conversion** — alert at 50% drop in D7 conversion week-over-week
- **Crash rate** — alert at any 0.5pp drop in crash-free sessions
- **Review score** — alert at 0.2 drop week-over-week

Hand the alert plan to `site-reliability-engineering` for SLI / alerting setup.

## What "good" looks like by category (rough)

| Category | D1 / D7 / D30 retention | ARPDAU | LTV (D365) |
|---|---|---|---|
| Hyper-casual | 35% / 14% / 5% | $0.05–$0.15 | $0.50–$2 |
| Casual puzzle | 45% / 20% / 8% | $0.10–$0.30 | $2–$10 |
| F2P mid-core | 45% / 22% / 12% | $0.50–$2.00 | $20–$100 |
| F2P RPG / gacha | 50% / 25% / 15% | $1–$3 | $50–$300 |
| Subscription MMO | n/a / 50%+ / 30%+ monthly retention | n/a | $200+ |
| Premium PC indie | n/a (one-time) | n/a | unit price + DLC |

## Output

For the strategy doc:
- KPI floor table with chosen values for *this* game
- Reasoning for any deviation from category benchmarks
- Alert thresholds for live ops
- Soft-launch decision triplets (floor / target / strong)

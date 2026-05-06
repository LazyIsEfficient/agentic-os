# Soft launch KPI sheet — <game title>

> The decision sheet for soft launch. Updated weekly during soft launch. Drives go-global / re-tune / kill calls.

## Soft launch frame
- **Geos:** <e.g. CA, AU, NZ, PH, ID>
- **Start date:** <>
- **Planned duration:** <weeks>
- **Sample target:** <DAU / install count needed for KPI confidence>
- **Marketing budget:** <to acquire the sample>
- **Acquisition channels active:** <which networks / sources>

## KPI gates

| KPI | Floor (kill below) | Target (re-tune below, ship above with action) | Strong (ship as-is) | Current value | Trend |
|---|---|---|---|---|---|
| D1 retention | 35% | 40% | ≥45% | <fill weekly> | ↑↓ |
| D7 retention | 14% | 18% | ≥22% | | |
| D30 retention | 6% | 8% | ≥12% | | |
| Conversion to first IAP (D7) | 1.5% | 3% | ≥5% | | |
| ARPDAU (W2 onwards) | $0.10 | $0.20 | ≥$0.40 | | |
| ARPPU (W2 onwards) | $5 | $10 | ≥$20 | | |
| Median session length | 5 min | 8 min | ≥12 min | | |
| Sessions/day per DAU | 2.0 | 3.0 | ≥4.0 | | |
| ROAS at D30 | 0.30 | 0.50 | ≥0.80 | | |
| ROAS payback | 365 days | 180 days | ≤120 days | | |
| Crash-free sessions | 99.0% | 99.5% | ≥99.8% | | |
| Review score | 3.8 | 4.2 | ≥4.5 | | |

> Floors are *kill thresholds* — below this, the game is not commercially viable in its current form. Re-tune-or-kill conversation triggers automatically.

## Per-segment monitoring

| Segment | KPI | Floor | Target | Current |
|---|---|---|---|---|
| Whale | Top 1% % of revenue | <30%> | <40%> | |
| Dolphin | Conversion (Minnow → Dolphin) | <5%> | <15%> | |
| Minnow | First-purchase conversion | <2%> | <4%> | |
| Free | Ad fill rate (if applicable) | <60%> | <80%> | |
| Free | Ad eCPM | <$5> | <$10> | |

## Top funnels

- **Install → First session:** <%>
- **First session → Tutorial complete:** <%>
- **Tutorial complete → D1 return:** <%>
- **D1 return → First store visit:** <%>
- **First store visit → First IAP:** <%>

Each step is a candidate for optimization. Hand drop-offs to `iap-manager` (store-side), `ux-design` (UX/UI), `game-systems-designer` (loop strength).

## Decision criteria

### Go global
- All KPIs ≥ Target
- ROAS payback ≤ 180 days
- No platform-policy / regulatory blockers
- Acquisition channel saturation manageable at global scale

### Soft-relaunch (after re-tune)
- 1–3 KPIs below Target but above Floor
- Re-tune plan in hand from `game-balancer` / `iap-manager`
- 4–6 weeks of additional soft-launch budget approved

### Kill
- ≥1 KPI below Floor for ≥3 weeks despite re-tune attempts
- ROAS payback >365 days at projected scale
- Fundamental design / model mismatch identified (re-tune won't fix)

## Weekly review template

Each week of soft launch:

1. **KPI dashboard snapshot** (the table above, with current and trend)
2. **Top 3 surprises** (positive and negative)
3. **Top 3 decisions** (re-tunes shipped, A/B tests launched, comms sent)
4. **Risk register update** (which KPIs are most at risk; what's the contingency)
5. **Decision call** (continue / re-tune / extend / kill)

## Hand-off after soft launch

- **`game-balancer`:** what to re-tune for global launch, with magnitude and predicted impact
- **`iap-manager`:** which SKUs to add / remove / re-price
- **`game-marketer`:** acquisition channel mix that worked, CPI floor that's defensible at scale, store-page changes informed by funnel data
- **`game-systems-designer`:** any *system* (not balance) issues that surfaced — route back here only if no balance / monetization fix exists
- **`finance-ops`:** updated revenue forecast for global launch P&L

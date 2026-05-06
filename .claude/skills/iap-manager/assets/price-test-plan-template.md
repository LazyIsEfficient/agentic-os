# Price test plan — <test name>

> One per A/B price test. Coordinate with `growth-engine` for stats and `game-marketer` for comms if user-facing.

## Test identity
- **SKU under test:** <e.g. `starter_pack_v1`>
- **Test ID:** <e.g. `pt_starter_2026Q2`>
- **Hypothesis:** <"Lowering the starter pack price from $4.99 to $2.99 increases conversion enough to offset the lower per-purchase revenue, raising downstream LTV.">
- **Why this SKU:** <revenue impact estimate; usually one of top 3 SKUs by revenue or by conversion sensitivity>

## Variants

| Variant | Price | Composition | Sample share |
|---|---|---|---|
| Control | $4.99 | <unchanged> | 33% |
| A — lower | $2.99 | <unchanged> | 33% |
| B — higher | $7.99 | <unchanged> | 33% |

## Population
- **Geo:** <which countries are eligible>
- **Segment slice:** <new installs only / all DAU / specific cohort>
- **Bucketing:** <persistent user-id-based hash; same user always sees same variant>
- **Exclusions:** <returning lapsed players, soft-launch markets, anyone who's seen another active price test on this SKU>

## Stats
- **Primary metric:** <revenue per cohort install at D30>
- **Guardrail metrics:** <retention D7 / D30, repeat-purchase rate, refund rate>
- **MDE (minimum detectable effect):** <e.g. 8% on revenue per install>
- **Power:** <0.80>
- **Significance threshold:** <p < 0.05>
- **Sample size required:** <calculate via power analysis; usually 5,000–50,000 per variant>
- **Test duration:** <calculate from sample target / install rate; typically 2–8 weeks>

## Decision criteria
- **A wins if:** A's primary metric > Control + MDE, with p < 0.05, no guardrail regression
- **B wins if:** same for B
- **No winner:** keep Control; insights still useful for next test
- **Kill early if:** primary metric drops > 30% in either variant after 1 week with significance (rare; protect against bad-data scenarios)

## Comms
- **Player-facing comms:** <usually none for price tests; price discovery is normal in F2P>
- **Internal comms:** <which team / Slack channel gets weekly updates>
- **Post-test write-up:** <who writes it, who it's distributed to, where it lives in the playbook>

## Implementation contract
- **Engineering:** server-driven price (no client release for variant changes)
- **Analytics:** `iap_view(sku, variant_label)`, `iap_purchase(sku, variant_label)`
- **Storefront config:** App Store Connect / Google Play / Steam server-side price flag (or equivalent)

## Schedule
- **Test start:** <date>
- **Mid-checkpoint:** <date — sanity check, not decision>
- **Test end:** <date>
- **Decision call:** <date>
- **Roll-out:** <date — winner deployed to 100%>

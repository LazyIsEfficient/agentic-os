# Choosing the Value Metric

The value metric is **what you charge per** — the unit your price multiplies against. It is the most consequential pricing decision you make, more than the number itself. Get it wrong and no amount of price tuning saves you; get it right and the price feels fair as the customer grows.

## The "scales with value" test

The right value metric increases as the customer receives more value. Apply three questions:

1. **Does the customer's bill grow as they succeed with the product?** If the metric is decoupled from value (flat per-company), you cap your upside and underprice your biggest winners. If it grows *faster* than value (per-seat on a product one admin runs for thousands), you invite gaming and churn.
2. **Can the customer predict their bill?** A metric that produces bill shock (raw compute-seconds) drives anxiety and procurement friction even when it's fair. Predictability is itself value.
3. **Is it easy to measure and hard to game?** The metric must be something both sides can see and agree on. "Value delivered" is unmeasurable; "active seats," "API calls," "GB stored," "transactions processed" are countable.

The best value metrics sit where all three align: they track value, stay predictable, and are countable.

## Common value metrics

- **Per-seat** — charge per user. Best when value scales with the number of humans using the product (collaboration tools). Fails when usage concentrates in a few power users or one admin serves many beneficiaries.
- **Usage / consumption** — charge per unit consumed (API call, GB, message, compute). Best when value is proportional to volume and usage varies widely across customers. Risk: bill unpredictability; mitigate with caps, commitments, and dashboards.
- **Per-active-user** — charge only for users who actually engage. Aligns cost with realized value better than per-seat; harder to forecast.
- **Per-transaction / outcome** — charge per unit of customer business outcome (payment processed, ticket resolved). The tightest value alignment; requires the outcome to be cleanly attributable to you.
- **Flat / per-company** — one price regardless of size. Simplest to buy; almost always leaves money on the table at the top of the market.
- **Hybrid** — a platform fee plus usage, or seats plus consumption. Captures both a predictable base and upside. The most common mature model; also the easiest to over-complicate.

## Anti-patterns

- **A metric decoupled from value.** Charging per-company when value scales 100x across customers means your enterprise whale pays the same as your smallest startup. Money left on the table by design.
- **A metric the customer can't predict.** Pure raw-usage with no caps produces bill shock, support load, and churn — even when the average bill is fair.
- **A metric the customer games.** If sharing one login avoids per-seat fees, per-seat is the wrong metric or needs enforcement you don't have.
- **Switching metrics late.** Re-platforming the value metric after launch is painful — it re-prices every existing customer. Invest in getting it right early; test it in the WTP study, not after.

## Handoff

- The **cost floor** for any metric comes from `finance-ops` — you must know the marginal cost per unit so the metric never sells below cost.
- Once the metric is chosen, the **pricing model** (per-seat / usage / tiered / freemium) and the **packaging** follow from it — see `packaging-design.md`.

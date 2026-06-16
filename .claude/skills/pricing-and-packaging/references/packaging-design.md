# Packaging, Tiering & Discounting

Packaging is how you capture **different willingness to pay from different segments with one product**. A single price serves a single segment; tiers let the price-insensitive pay more while the price-sensitive still buy. This is the lever that turns a good price into a good *price structure*.

## Good-better-best: the default

Three tiers is the default for sound reasons:

- **It anchors.** The top tier sets the reference frame; the middle reads as reasonable by comparison.
- **It offers a decoy.** A well-designed top tier makes the middle tier the obvious choice (the "compromise effect") — most buyers pick the middle.
- **It doesn't paralyze.** Three options is choosable; seven is not.

Design rule: most revenue should come from the **middle** tier by design, with the top tier doing the anchoring and the entry tier capturing the price-sensitive. If everyone buys the cheapest tier, your fences are wrong.

### Tier-design checklist

- [ ] **Three tiers, rarely more.** Four is a stretch; five+ means you're dodging a packaging decision. Collapse.
- [ ] **Each tier maps to a segment.** Name the buyer for each tier (individual / team / enterprise). A tier with no buyer is clutter.
- [ ] **The middle tier is the intended default.** Stack its value so it's the obvious pick.
- [ ] **The top tier anchors high.** It should make the middle look reasonable; a few buyers will self-select up.
- [ ] **A clear upgrade trigger between tiers.** The buyer should know exactly *when* they outgrow their tier and what they get by moving up.

## Feature fencing

A **fence** is a feature or limit that separates tiers. Fence on **value to the segment, not on cost-to-build**.

- **Good fences:** features the high-value segment needs and the low-value segment can live without (SSO, advanced permissions, audit logs, higher limits, priority support, SLAs). These let enterprise self-select up without blocking the small buyer.
- **Bad fences:** crippling a feature the entry segment genuinely needs (forcing churn), or fencing on a dimension nobody values (no upgrade pressure).
- **The SSO/security fence** is the canonical enterprise fence — high-value buyers require it, small buyers don't, and it cleanly separates the willing-to-pay segment.

Source the fences from a **conjoint study** (`wtp-research-methods.md`) — it tells you which features drive choice for which segment, which is exactly what a fence needs to know.

## Anchoring

- **Show the most expensive tier first / leftmost or visually dominant.** The first price the buyer sees sets the reference for all others.
- An un-anchored cheap price reads as the *ceiling*. The same number, anchored against a higher tier, reads as a *step up*.
- A "contact us" enterprise tier is a legitimate anchor even without a public number — it signals there's room above.

## Freemium

Freemium is a packaging choice, not a separate model: a $0 tier whose job is acquisition and conversion, not revenue.

- **Use it when:** the product has network/viral effects, low marginal cost to serve, and a clear value ceiling the free tier hits.
- **The conversion fence is everything.** Free must deliver real value (or it won't acquire) but hit a wall the engaged user needs to pass (or it won't convert). Fence on *usage growth* or a *value-unlock feature*, not on time.
- **Watch the cost-to-serve.** Free users have real marginal cost (`finance-ops` owns that number). Freemium fails when free-tier cost outruns conversion revenue.

## Discounting discipline

A discount is a **policy, not a reflex**. Every unprincipled discount trains buyers to wait and erodes the list price permanently.

- **Discount for a reason the customer earns:** annual/multi-year commit, volume, strategic logo, prepayment. Each is a *fence* that justifies the lower price.
- **Set a floor.** Below it, sales cannot go without escalation. The floor sits above the `finance-ops` cost floor.
- **Build an approval ladder.** Standard discount (rep), larger (manager), exceptional (VP). Discount depth tracks who signs off.
- **Track discount leakage.** Average realized price vs list, by segment. Creeping leakage means the list price is fiction.
- **Never discount to close a quarter.** That's the tell that the price, the packaging, or the qualification is wrong — fix the cause, don't paper it with a cut.

> Campaign *execution* of an approved discount (channels, copy, sends) belongs to `marketer` / `marketing-shaper`. This file sets the *policy*; they run the promotion.

## Revisiting and grandfathering

- **Re-test on a cadence.** WTP drifts as market, product, and competition move.
- **Grandfather deliberately.** On a price rise, decide explicitly who keeps the old price and for how long. Silent permanent grandfathering caps revenue on your earliest customers forever.

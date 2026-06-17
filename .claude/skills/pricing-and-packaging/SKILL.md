---
name: pricing-and-packaging
description: Use when deciding what to charge and how to package it — choosing a value metric, picking a pricing model (per-seat, usage, tiered, freemium), running willingness-to-pay research (Van Westendorp, Gabor-Granger, conjoint), designing good-better-best tiers with feature fencing, and setting anchoring and discounting discipline. Triggers on "pricing strategy", "willingness to pay", "WTP", "how should we price", "packaging", "pricing tiers", "good-better-best", "value metric", "freemium vs paid", "price sensitivity", or "set our prices". Not for mining sales-call pricing signals (revenue-intelligence), internal cost/burn accounting (finance-ops), in-game IAP economies (game-monetization-strategist), or running discount campaigns (marketer).
when_to_use: |
  Use when the question is what to charge and how to package it for an external market: choosing the value metric you charge per, selecting a pricing model (per-seat, usage-based, flat tiered, freemium), designing a willingness-to-pay study (Van Westendorp PSM, Gabor-Granger, conjoint) and knowing which method fits, structuring good-better-best tiers with feature fencing, setting price anchors, and imposing discounting discipline. Triggers on "pricing strategy", "willingness to pay", "WTP", "how should we price this", "packaging", "pricing tiers", "good-better-best", "value metric", "freemium vs paid", "price sensitivity", "Van Westendorp", or "we need to set our prices".

  Not when: the task is extracting "pricing was discussed" or competitor-price mentions from sales-call transcripts — use revenue-intelligence. Not when the task is internal cost modeling, burn rate, unit-cost or margin accounting, or runway — use finance-ops (this skill prices the external offer; finance-ops models the internal cost floor). Not when the task is in-game IAP, virtual-currency, or game monetization economies — use game-monetization-strategist. Not when the task is executing a discount or promotional campaign (channels, copy, sends) — use marketer (this skill sets the discounting policy; marketer runs the campaign).
---

# Pricing & Packaging

You are operating as a pricing strategist. Your concern is **what the company charges, how the offer is packaged, and what the market will actually pay** — researched from the outside in, never assumed from the inside out. You sit between product, finance, and the market: product tells you what the offer does, finance tells you the cost floor, and your job is to find the price the market will bear above that floor and the packaging that captures it.

Pricing is the single highest-leverage lever a business has. A 1% improvement in price typically beats a 1% improvement in volume or cost on profit. Yet it is the lever teams touch least and reason about worst — usually by marking up cost and hoping.

The two failure modes are equally bad:

- **Cost-plus pricing** — you compute your cost, add a margin, and call the result a price. The market does not care what it cost you to build. Price is set by value delivered and alternatives available, not by your spreadsheet. Cost is a floor, never a method.
- **Pricing by vibes** — you pick a number that "feels right," anchored on a competitor or a gut figure, and never test it against real willingness to pay. You leave money on the table at the top and lose deals at the bottom, and you never know which.

Your job is to navigate between them: ground price in researched willingness to pay, structure packaging so each segment self-selects into the tier that matches its value, and hold the line on discounting so the list price means something.

## Universal Rules

1. **Cost is the floor, not the method.** Cost-plus pricing prices the seller's effort, not the buyer's value. Use cost to know where you go bankrupt; use value and willingness to pay to set the actual number.
2. **Pick the value metric before the price.** *What* you charge per (seat, API call, GB, transaction, active user) matters more than the number. The right value metric scales with the value the customer gets — so their bill grows as they succeed, and the price feels fair the whole way up.
3. **Willingness to pay is measured, not assumed.** Every confident internal opinion about what customers will pay is a guess. Van Westendorp, Gabor-Granger, and conjoint exist because the guess is usually wrong. Run the method that fits the question (see [references/wtp-research-methods.md](references/wtp-research-methods.md)).
4. **Packaging is how you capture different willingness to pay.** One price serves one segment. Good-better-best lets the price-insensitive pay more and the price-sensitive still buy. Design the tiers so each segment self-selects (see [references/packaging-design.md](references/packaging-design.md)).
5. **Fence on value, not on cost-to-you.** A feature belongs in a higher tier when it signals or delivers more value to a willing-to-pay segment — not because it was expensive to build. Fence the features that the high-value segment needs and the low-value segment can live without.
6. **Three tiers, rarely more.** Good-better-best is the default for a reason: it anchors, it offers a decoy, and it doesn't paralyze. More than four tiers usually means you're avoiding a packaging decision, not making one. Collapse them.
7. **The anchor is the most expensive number the buyer sees first.** Show the high tier before the low one. The first price sets the reference frame for every price after it. An un-anchored cheap price reads as the ceiling, not the floor.
8. **Discounts are a policy, not a reflex.** Every unprincipled discount trains the buyer to wait and devalues the list price. Discount for a reason the customer earns (annual commit, volume, logo, multi-year) — never to close a quarter. A discount with no fence is a price cut you're too scared to put on the page.
9. **Leaving money on the table is a failure, not safety.** Underpricing feels safe and is not. If no one ever balks at your price, it is too low. A healthy win rate has *some* lost deals at the top of the range.
10. **Price is a hypothesis you revisit.** WTP shifts as the market, the product, and the competition move. A price set once and never revisited is as stale as a three-year-old roadmap. Re-test on a cadence.
11. **Grandfather deliberately, not by default.** When you raise prices, decide explicitly who keeps the old price and for how long. Silent grandfathering forever caps your revenue on your earliest, often least-strategic, customers.
12. **Simplicity is a feature of the price itself.** A pricing page the buyer can't understand in thirty seconds loses deals no discount recovers. Complexity in the value metric or the tier matrix is a tax the customer pays in confusion and you pay in lost conversions.

## Workflow

1. **Establish the cost floor** — get the unit-cost / margin floor from finance-ops. You price above it; you do not price *from* it.
2. **Choose the value metric** — what scales with customer-perceived value. Test it against the "does the bill grow as they succeed?" question (see [references/value-metric-guide.md](references/value-metric-guide.md)).
3. **Pick the pricing model** — per-seat, usage-based, flat-tiered, or freemium — driven by the value metric and the buying motion.
4. **Research willingness to pay** — select Van Westendorp, Gabor-Granger, or conjoint by what you need to learn, and design the study (see [references/wtp-research-methods.md](references/wtp-research-methods.md)).
5. **Design the packaging** — good-better-best tiers, feature fences, anchor placement (see [references/packaging-design.md](references/packaging-design.md)).
6. **Set discounting policy** — the fences that earn a discount, the floor below which sales cannot go, and the approval ladder.
7. **Instrument and revisit** — track win rate by price band, discount leakage, and tier mix; re-test on a cadence.

## Common Mistakes

- **Cost-plus.** Pricing the build, not the value. The most common and most expensive error.
- **One price for everyone.** Forgoing the segmentation that packaging exists to capture — you underprice the whale and overprice the minnow simultaneously.
- **Too many tiers.** Five-plus tiers signal an unmade decision. They paralyze buyers and dilute the anchor.
- **The wrong value metric.** Charging per a metric that doesn't track value (per-seat for a product used by one admin on behalf of thousands) caps your upside and invites gaming.
- **Discounting to close.** Unprincipled discounts train buyers to wait and erode the list price permanently.
- **Never testing.** Setting a number by gut and never running a WTP study — flying blind on the highest-leverage lever you have.
- **Anchoring low.** Leading with the cheapest tier, so every other price reads as expensive instead of as a step up.

## References

- [references/value-metric-guide.md](references/value-metric-guide.md) — how to choose what you charge per; the "scales with value" test; per-seat vs usage vs hybrid; value-metric anti-patterns.
- [references/wtp-research-methods.md](references/wtp-research-methods.md) — Van Westendorp PSM, Gabor-Granger, and conjoint compared: what each measures, when each applies, sample-size and design notes, and failure modes.
- [references/packaging-design.md](references/packaging-design.md) — good-better-best design, feature fencing, anchoring and decoy tiers, freemium-to-paid conversion, and discounting discipline as a checklist.

## Related skills

- [revenue-intelligence](../revenue-intelligence/SKILL.md) — mines sales-call transcripts for signals (including "pricing was discussed"); this skill *sets* the pricing strategy those calls reference. Hand-off, not overlap.
- [finance-ops](../finance-ops/SKILL.md) — owns the internal cost floor, margin, and burn; this skill prices the external offer *above* that floor. Pair: finance-ops supplies the floor, this skill finds the ceiling.
- [game-monetization-strategist](../game-monetization-strategist/SKILL.md) — owns in-game IAP, virtual currency, and F2P economies; this skill owns SaaS/product list-price and packaging. Different domains, similar vocabulary.
- marketer / [marketing-shaper](../marketing-shaper/SKILL.md) — execute discount and promo campaigns; this skill sets the discounting *policy* those campaigns must respect.
- [technical-product-management](../technical-product-management/SKILL.md) — owns what to build and for whom; this skill prices and packages what TPM decided to ship.

# Willingness-to-Pay Research Methods

Willingness to pay (WTP) is **measured, not assumed**. The three workhorse methods below each answer a different question. Pick by what you need to learn, not by what's familiar.

## Method comparison

| Method | Answers | When to use | Avoid when |
|---|---|---|---|
| **Van Westendorp PSM** | What price *range* is acceptable; where "too cheap" and "too expensive" cross | New/novel product, no existing price reference, you need a defensible range fast | You need a single optimal price or revenue-maximizing point |
| **Gabor-Granger** | The demand curve and revenue-maximizing price for *one* defined offer | You have a concrete offer and want the profit-maximizing point on a known SKU | The offer/feature bundle is still unsettled |
| **Conjoint (CBC)** | How buyers trade off features *and* price; what each feature is worth; how to package | Designing tiers/bundles; deciding which features to fence; multi-attribute offers | Budget/time is tight, sample is small, or you only need a single price |

## Van Westendorp Price Sensitivity Meter (PSM)

Four questions per respondent: at what price is the product *too expensive*, *expensive but worth considering*, *a bargain*, and *too cheap (quality suspect)*. Plot the cumulative curves; their intersections bound an acceptable price range and an optimal price point (OPP) / indifference price point (IPP).

- **Use it for:** a price *range* on a new product with no reference price. Fast, cheap, easy to field.
- **Sample:** ~150–300+ target buyers for stable curves.
- **Failure modes:** measures *stated* acceptability, not purchase intent — people under-report what they'd pay. It yields a range, not a revenue-optimal price. Garbage if respondents aren't real target buyers.

## Gabor-Granger

Ask purchase likelihood at a series of specific prices (ascending or randomized). Build a demand curve; multiply price × likelihood to find the revenue-maximizing price for that one offer.

- **Use it for:** the profit-maximizing point on a *single, well-defined* SKU or tier.
- **Sample:** ~100–200+ per offer tested.
- **Failure modes:** tests one offer in isolation — no feature trade-offs, no packaging insight. Anchoring/order effects bias results; randomize price order. Over-states WTP if the offer is hypothetical.

## Conjoint analysis (Choice-Based Conjoint)

Show respondents repeated choices among bundles that vary features *and* price. Decompose choices into part-worth utilities: how much each feature and each price level drives selection. The richest method for packaging.

- **Use it for:** designing good-better-best tiers, deciding which features to fence into which tier, and pricing a multi-attribute offer. The output directly feeds `packaging-design.md`.
- **Sample:** ~300–500+ for stable part-worths; more attributes/levels need more respondents.
- **Failure modes:** expensive, slow, and easy to mis-design — too many attributes overload respondents and produce noise. Requires analytic skill to run and interpret. Overkill for a single-SKU price question.

## Choosing fast

- **No reference price, need a range** → Van Westendorp.
- **One offer, need the optimal number** → Gabor-Granger.
- **Many features, need to package and fence** → Conjoint.

## Universal cautions

- **Stated WTP overstates real WTP.** Survey respondents pay more in surveys than in checkout. Treat outputs as relative signal and an upper bound, not gospel — triangulate with actual conversion data and A/B price tests where possible.
- **Sample quality dominates method choice.** A perfect method on the wrong respondents is worse than a crude method on real target buyers. Screen hard for the actual buyer/decision-maker.
- **Pricing is a hypothesis.** Whatever the study says, instrument win rate by price band post-launch and re-test on a cadence.

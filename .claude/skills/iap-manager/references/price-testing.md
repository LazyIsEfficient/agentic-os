# Price testing

A/B testing prices is one of the highest-leverage live-ops activities, but only when done with statistical discipline. Underpowered or biased tests produce false-positive winners that hurt revenue when rolled out.

## When to price-test

- A new SKU's price isn't anchored to comps; you genuinely don't know the right price
- A live SKU is underperforming and you suspect price is the cause
- Strategic question — "would lowering this convert enough to offset?"

## When not to price-test

- The SKU has too few buyers per week to reach statistical power in reasonable time
- A platform policy change is imminent (test will be invalidated)
- A live game with vocal community where price changes will leak and trigger comms storms — coordinate with `game-marketer` first
- Multiple SKUs are being changed simultaneously — you can't isolate impact

## Test design

### Variants

- **Control + 2 variants** is the standard. Adding more variants splits sample size and slows the test.
- **Variants should bracket the control** — typically a lower price (A) and higher price (B). Lopsided tests (control + 2 lower) miss the upside case.
- **Variants should be psychologically meaningful gaps** — $4.99 vs $5.99 is *not* a meaningful test; $4.99 vs $7.99 is.

### Sample size and power

Use a power analysis. For revenue tests:

- **Effect size:** the minimum detectable effect (MDE) you care about — typically 5–10% on revenue
- **Power:** 0.80 standard
- **Significance:** p < 0.05 (two-tailed for unknowns; one-tailed if you genuinely have a directional hypothesis)
- **Sample size:** computes from the above; usually 5,000–50,000 users per variant

Practical implication: tests on top SKUs (high install volume) finish in 2–4 weeks. Tests on niche SKUs may take 8+ weeks or be impractical.

### Bucketing

- **Persistent user-id-based hash** — same user always sees same variant
- **No re-bucketing on app update** (would contaminate the test)
- **Cohort-isolated** — tests on new installs only; existing users are excluded (otherwise the variant is "what they saw last time" mixed with "new variant")
- **No overlap** with other active tests on the same SKU

### Primary metric

- **Revenue per cohort install at D30** is the primary metric for most price tests (captures conversion + per-purchase + retention impact)
- Don't use "conversion rate" alone — a higher-converting lower-priced variant can lose on revenue
- Don't use "ARPPU" alone — variant might convert different mixes of users

### Guardrail metrics

Things that must not regress significantly:

- **Retention D7 / D30** — price change shouldn't break retention
- **Repeat-purchase rate** — first purchase up but no second purchase = no win
- **Refund rate** — higher refunds = trust signal
- **Review score** — players can detect price tests if they discuss in community
- **Per-segment impact** — variant that wins on average but kills whale conversion is bad

## Running the test

### Pre-launch

- **Sandbox-test** the variant configuration (price changes via server-driven config, no client release needed)
- **QA verify** the price-display flow shows the right variant
- **Telemetry verify** — events are tagged with `variant_label`
- **Comms align** — internal team knows the test is running

### Live

- **Mid-checkpoint at ~50% of planned sample** — sanity check, not decision. Don't peek with intent to stop early.
- **Pre-registered decision criteria** — the criteria are written before the test starts and don't move
- **No early stopping** unless data is catastrophically bad (>30% revenue drop with significance)
- **Hold the duration** — even if early data looks like a clear winner, hold to the planned end. Early-stopped tests are biased high.

### Post-test

- **Decision call** by date X — variant wins if primary metric > control + MDE with p < 0.05 and no guardrail regression
- **Roll out winner** to 100% of cohort; existing-user pricing handled separately
- **Document the result** in a price-test playbook for future learning
- **Update the model** — the spreadsheet's assumed price → conversion → revenue should reflect the result

## Statistical pitfalls

- **Multiple comparisons** — running 10 price tests at once and finding 1 with p < 0.05 doesn't mean the test is real; that's expected by chance. Bonferroni-correct or pre-register hypotheses.
- **Peeking** — checking results before the planned end and stopping when a variant "looks good" inflates false positives.
- **Underpowered tests** — running a test that can't detect a real 5% effect produces lots of "no significant difference" results that *don't mean* the prices are equivalent.
- **Cohort drift** — testing in a window where the user mix is unusual (holiday, sale, post-update spike) contaminates the result.
- **Selection bias** — testing only on a slice of users (e.g. only iOS) and rolling out winner to all users (including Android) assumes the result generalizes. It often doesn't.

## Coordinate with `growth-engine`

For statistical rigor, hand the test design to `growth-engine`. They run the experiment framework with proper:
- Bootstrap CI / Mann-Whitney U analysis
- Pre-registered hypotheses
- No-peeking discipline
- Multiple-comparison correction

The IAP manager *picks the SKU and variants*; `growth-engine` *runs the experiment*.

## Output

For every price test:
- Filled `price-test-plan-template.md`
- Pre-registered hypothesis and decision criteria
- Sample size calculation
- Telemetry contract
- Post-test write-up + playbook entry
- Updated model (spreadsheet reflects winning price's predicted impact)

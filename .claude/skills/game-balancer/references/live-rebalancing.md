# Live re-balancing

A re-tune of a live game without burning trust. Live balance changes are a *social* act, not just a data act. Players form attachments to the way the game played yesterday; a re-tune that ignores this loses players regardless of whether the math is right.

## When to re-tune

- **A KPI breaks the alert threshold** — D7 retention dropped 3pp, ARPDAU collapsed, conversion to first IAP halved
- **A meta degenerates** — pick rate concentration across the roster, dominant strategy in PvP, dead content
- **An economy drifts** — currency velocities outside the model's predicted band for >2 weeks
- **A new content drop misfires** — wrong difficulty, wrong drop rates, wrong price point
- **A community signal** that telemetry confirms — vocal complaint + telemetry corroboration is a re-tune trigger; vocal complaint alone is not

## When NOT to re-tune

- **A noisy week** — a holiday, a competing game launch, a server outage will distort metrics. Wait for two weeks of clean data.
- **A vocal minority's complaint without telemetry support** — the loudest players are not always the median.
- **An ongoing playtest of a new feature** — re-tuning during an experiment contaminates results.
- **Right after a previous re-tune** — players need time to *feel* a change before another one lands.

## The re-tune plan

For any live balance change:

1. **Hypothesis.** What's wrong, what telemetry shows it, what the change should do.
2. **Magnitude.** How much. Small changes are reversible; large changes look panicked.
3. **Rollout.** A/B if the population allows. If not, % rollout (5% → 25% → 100%) over days.
4. **Rollback plan.** What signal triggers a rollback; how fast can you do it.
5. **Comms plan.** Patch notes; *why*, not just *what*. Coordinate with `game-marketer`.
6. **Predicted impact** with confidence interval. From the spreadsheet model.
7. **Re-validation cadence.** When you check the change has done what was intended.

## Touching monetized content

Special care:

- **NFT / paid premium content** — *cannot* be silently nerfed. Players paid for the current behavior.
- **Battle pass contents** — players paid expecting current rates. Reduce rates only at season transitions, not mid-season.
- **Hard-currency exchange rates** — players bought currency expecting current purchasing power. A "stealth" devaluation is detected within hours and trust takes months to recover.

When you must change monetized content:
- **Compensation.** Refunds, in-game compensation, equivalent free content.
- **Disclosure ahead of time.** "In two weeks, X will change because Y."
- **Grandfather where possible.** Players who bought before the change keep the original.

## Touching the economy at scale

When inflation or deflation has accumulated, large re-tunes are tempting. Resist. Instead:

- **Sink injection** — limited-time content that absorbs excess stock (rare cosmetics, named items, anniversary events)
- **Source events** — for deflation, time-limited bonus weekends
- **New tier** — extend the curve with a new prestige/season, recalibrate at the new ceiling
- **Currency reset** — almost always a last resort; players hate it; coordinate with `game-marketer` for narrative

## A/B testing balance

When the population is large enough to A/B (typically 10,000+ DAU):

- **Holdout group** — keep a representative slice on the old balance for comparison
- **Single change per A/B** — don't bundle multiple balance changes in one experiment
- **Duration** — long enough to see weekly behavior cycles (2+ weeks for retention); not so long that the population realizes the difference
- **Metric** — define the *primary* metric (the thing the change should move) and the *guardrail* metrics (things that must not regress)
- **Pre-register the success criterion** — the change wins if metric X moves by ≥Y with p<Z; otherwise it loses. No moving the goalposts.

Coordinate with `growth-engine` for the experimental framework.

## Comms (with `game-marketer`)

Patch notes are content. The community will read them more carefully than your design doc. Rules:

- **Lead with the *why*.** "We're nerfing X because the meta is dominated by it" lands better than "X: 15% damage reduction."
- **Acknowledge what you're breaking.** If you're nerfing a fan-favorite, say so — players know either way.
- **Don't oversell.** Tentative changes should sound tentative ("we'll be watching closely").
- **Don't be defensive.** Players will critique. Listen; don't dunk on them.
- **Patch notes are read aloud on streams and YouTube.** Write them to be readable, not just informative.

## Updating the model

After every re-tune:

- Update the spreadsheet to reflect the change
- Update the predicted KPIs based on the new model
- Update the sensitivity table — this re-tune may have changed which levers are now most sensitive
- Update the telemetry contract — new metrics may be needed to validate the new balance
- Update the design intent next to the variable — *why* this is the new value

A re-tune that ships without updating the model is a re-tune that the next balancer will fly blind through.

## Output

For every live re-tune:
- Change list with magnitudes and rationale
- Predicted impact + confidence
- Rollout plan + rollback plan
- Comms plan + patch notes draft (hand to `game-marketer`)
- Updated model
- Re-validation date and the team owner

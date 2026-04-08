# Strategy Evolution

A strategy is a hypothesis about what the team should do given the current situation. The situation changes; new evidence comes in; the hypothesis turns out to be wrong in some way. The strategy has to evolve, or it goes stale and gets ignored.

This file is about *how* to evolve a strategy: when to update, when to leave alone, how to announce changes, how to supersede prior versions, and how to do it without losing the team's trust.

## The Two Failure Modes

### Strategy that never changes

A strategy from 18 months ago that the team still cites verbatim. The world has shifted; the assumptions are stale; the team is making decisions by individual judgment because the official strategy no longer applies. The strategy still exists in the wiki but it's decoration.

**Why it's bad:** the team operates without a strategy, while pretending to have one. Worse than no strategy at all because nobody knows it's broken.

### Strategy that changes every week

The strategist updates the strategy in response to every new piece of evidence. The team can never plan because the direction keeps shifting. Trust in the strategy collapses; nobody references it because it'll be different tomorrow.

**Why it's bad:** the strategy has no force. The team can't act on something that won't survive next week.

The discipline is to find the right cadence: **stable enough to be useful, flexible enough to track reality**.

## When to Update

Update the strategy when one of these is true:

### 1. The diagnosis has changed

The diagnosis is the foundation of the strategy. If it's no longer accurate — the constraint has shifted, the situation is materially different, the analysis was wrong — the strategy needs to be revisited.

Examples:

- **The bottleneck moved.** The strategy was optimized around CI/CD slowness; you fixed CI/CD; now the bottleneck is database queries. The strategy needs a new diagnosis.
- **A major incident revealed something the diagnosis missed.** A postmortem surfaces a class of risk the strategy didn't address.
- **A market shift.** A competitor launched something that changes the urgency of certain bets.
- **A leadership change.** New CTO; new priorities; the underlying conditions have changed.

### 2. An action has failed

If a major action in the strategy isn't working, the strategy should change. Either the action was wrong (replace it) or the strategy that produced it was wrong (rethink the whole thing).

Don't keep an action alive out of sunk cost. If it's not working, change.

### 3. Capacity has changed materially

If the team's engineering capacity has shifted significantly — major hiring, major attrition, a reorg — the strategy needs to be re-sized. A strategy that assumed 30 engineers doesn't work with 18.

### 4. A non-goal has become unavoidable

The strategy explicitly said "we're not doing X." Now there's a regulatory mandate, a security incident, or a customer commitment that requires X. The strategy has to change to incorporate it.

### 5. The strategy has been substantially achieved

If the team has done what the strategy committed to, the strategy is *complete*. Time for a new one. Don't keep an achieved strategy on life support; declare victory and move on.

## When to Leave Alone

The strategy should *stay put* in these cases:

### Pressure without new evidence

A stakeholder is unhappy with the strategy. They want it changed. They have no new information; they just don't like the direction. **Do not change the strategy in response.** Loud opinions are not new evidence.

### Short-term setbacks

The strategy is going well but a particular action hit a roadblock. The roadblock is solvable. Stay the course; don't change the strategy because of one bad week.

### Personal preference

The strategist has changed their mind based on... nothing in particular. Don't change the strategy on a whim. The team needs stability.

### Loud advocacy for the new shiny thing

Someone read a blog post about a new technology and wants the strategy to incorporate it. The technology has no track record, no team experience, and no specific application to the current situation. **Don't bend.**

### Disagreement that doesn't engage with the substance

A team member doesn't like the strategy but can't articulate why beyond "I'd do it differently." This isn't grounds for change. Engage with the disagreement; find out if there's substance beneath it; usually there isn't.

The pattern: **change in response to evidence, not in response to noise**.

## How to Update

### Minor revision (within the existing strategy)

If the strategy is largely right but needs a tweak:

1. **Edit the document** in place.
2. **Add a changelog entry** at the bottom or top: "2026-04-08: updated action 3 because the original approach hit a roadblock."
3. **Note it in the next team channel post** so the team knows.
4. **Don't bury the change.** Surface it.

This works for small refinements: changing a deadline, adjusting an action, refining a non-goal, updating a kill criterion.

### Major revision (new version of the existing strategy)

If the strategy is largely right but needs a substantial overhaul:

1. **Draft the new version** in a separate doc or branch.
2. **Walk through the changes** with the team — what's different, why, what's the impact.
3. **Replace the old version** when consensus is reached.
4. **Keep the old version** in version history so people can see what changed.
5. **Communicate broadly** — to leadership, product, adjacent teams.

This is the right level for: changing the diagnosis, replacing an action, adjusting capacity allocation, adding or removing a major non-goal.

### Supersession (the strategy is replaced)

If the strategy is fundamentally wrong or no longer applies:

1. **Acknowledge the failure** in writing. "We bet on X; here's what happened; here's what we learned."
2. **Draft a new strategy** from scratch — with a new diagnosis, new policy, new actions.
3. **Mark the old strategy as superseded.** Don't delete it; mark it.
4. **Communicate the change** carefully. This is a big deal; the team needs to understand why.
5. **Postmortem.** What did we learn? What would we do differently?

Supersession is rare and uncomfortable but sometimes necessary. The strategist's willingness to supersede is a sign of strength, not weakness.

## The Changelog

Every non-trivial strategy update goes in a changelog. The changelog is the history of how the strategy has evolved over time.

A useful format:

```markdown
## Changelog

### 2026-Q2 (current)
- Changed action 3 from "extract notifications service" to "extract analytics service" because notifications turned out to be less coupled than expected; analytics is a bigger pain point.
- Added action 5: "begin phasing out the legacy auth library" in response to security audit.
- Removed non-goal "no Kubernetes migration" — we're not committing to Kubernetes but we're no longer ruling it out.

### 2026-Q1
- Initial strategy.

### Pre-2026
- (No prior version; this is the first technical strategy document.)
```

The changelog is short and dated. Anyone reading the strategy can see how it has evolved and why.

For supersessions, the old strategy stays in version history with a clear marker:

```markdown
> **Status: SUPERSEDED by /docs/strategy/2026-q3-monolith-extraction.md (2026-04-08)**
>
> This strategy was superseded after the analytics extraction failed to deliver the expected velocity improvements. See the new strategy and the postmortem at <link>.
```

The reader of the old document immediately knows it's no longer the truth.

## Communicating Changes

A strategy that changes silently loses force. The team needs to know:

1. **Something changed.**
2. **What changed.**
3. **Why it changed.**
4. **What it means for them.**

The communication mirrors the original communication of the strategy:

- **Walk through the changes** in a team meeting if the change is substantial.
- **Send a one-pager** to leadership and stakeholders explaining the change.
- **Update the canonical doc** so the new version is the source of truth.
- **Cite the change in upcoming decisions** so the team sees it being applied.

For the broader patterns of communication, see [strategy-communication.md](strategy-communication.md).

## Trust and Revision

The team's trust in the strategy depends on the *pattern* of revisions, not just any individual one.

A team that sees:

- **Quarterly revision based on evidence**: trusts the strategy. They believe it tracks reality.
- **No revision for two years**: stops trusting the strategy. They believe it's stale.
- **Revision every week**: stops trusting the strategy. They believe it has no force.
- **Revision in response to loud stakeholders**: stops trusting the strategist. They believe the strategy bends to whoever shouts loudest.

The strategist builds trust over time by being **predictable in revising**: stable when there's no new evidence, willing to change when there is, transparent about why.

## Postmortems on Strategy

When a major part of a strategy fails (an action didn't work; a bet didn't pay off; the diagnosis turned out to be wrong), do a postmortem.

The postmortem of a strategy failure looks like the postmortem of a technical incident:

1. **What happened?** Specific, factual.
2. **Why did it happen?** Diagnosis of the failure mode.
3. **What did we learn?** What didn't we know that we know now?
4. **What would we do differently?** Specific changes to how we'd approach this in the future.
5. **What changes to the strategy follow?** This is where the postmortem feeds into the next revision.

The postmortem is *blameless* — see [site-reliability-engineering/references/postmortems.md](../../site-reliability-engineering/references/postmortems.md) for the blameless culture. Strategy failures are usually system failures, not personal ones.

## Revising Without Losing Momentum

A common concern: "if we revise the strategy now, the team has to adjust everything they're doing." Yes, sometimes. But the alternative — running on a strategy you no longer believe in — is worse.

Mitigations:

- **Time the revision well.** End of a quarter; between major releases; not in the middle of a launch crunch.
- **Don't change everything at once.** A strategy revision can change one action and leave the others; don't burn the whole thing down unless necessary.
- **Give the team a transition period.** "We're shifting direction; here's the new direction; we'll start applying it next sprint."
- **Be honest about the cost** of the change. Acknowledge that the team has to adjust.
- **Don't let "we just changed it" become an excuse to never revise.** The opposite of the trap.

## When the Strategy Should Be Replaced

Sometimes a strategy is so wrong that revision isn't enough. Replace when:

- **The diagnosis was fundamentally wrong.** The constraint we identified isn't actually the constraint.
- **The chosen direction isn't producing the expected outcomes.** Six months in; metrics aren't moving; the team isn't getting unstuck.
- **The situation has changed so much that the old strategy doesn't apply.** Major business pivot; major personnel change; major market shift.

Replacement is more disruptive than revision. Don't reach for it lightly. But don't avoid it when it's the right call.

## A Healthy Cadence

For most teams, a healthy strategy cadence looks like:

- **Quarterly review**: standing meeting where the strategist and the team look at the strategy, ask "is this still right?", and decide on adjustments.
- **Yearly redraft**: at the start of the calendar year (or fiscal year), the strategist redrafts the strategy from scratch. Most of it might be the same as the previous year, but the act of redrafting forces a fresh look.
- **Event-triggered revision**: when a major event happens (incident, launch, leadership change), revisit immediately rather than waiting for the next quarterly review.
- **Ongoing monitoring**: between formal reviews, the strategist watches for signals that the strategy is going stale and proposes revision when warranted.

This cadence balances stability and flexibility. The team has a strategy they can plan around; the strategy stays connected to reality.

## Anti-Patterns

- **Strategy that never changes.** Stale; ignored.
- **Strategy that changes every week.** No force; team can't plan.
- **Silent revisions.** The doc changes; nobody is told.
- **Revision in response to loud stakeholders without new evidence.** Trust collapses.
- **Revision to please leadership.** Same problem.
- **Refusing to revise out of stubbornness.** "We said we would, so we will."
- **Refusing to revise out of fear of looking wrong.** Pride costs more than admission.
- **Changing the strategy to match what already happened.** Retroactive justification, not strategy.
- **No changelog.** Can't see what changed; can't reason about evolution.
- **Superseding without postmortem.** Same mistakes repeated.
- **Reviewing without acting.** Quarterly meetings that don't produce decisions.
- **Sweeping changes without communication.** Team finds out by accident.
- **Stable strategy that's actually dead.** Nobody's revising it because nobody believes in it.
- **Constant revision masking lack of conviction.** The strategist hasn't actually committed to anything.

## Related

- [what-technical-strategy-is.md](what-technical-strategy-is.md) — the artifact being evolved
- [strategy-anti-patterns.md](strategy-anti-patterns.md) — the failure modes evolution should avoid
- [strategy-communication.md](strategy-communication.md) — communicating changes
- [strategy-as-constraint.md](strategy-as-constraint.md) — the constraints being adjusted
- [team-lead](../../team-lead/SKILL.md) — superseding ADRs follows the same lifecycle pattern
- [site-reliability-engineering/references/postmortems.md](../../site-reliability-engineering/references/postmortems.md) — the blameless postmortem culture

# Strategic Alignment Check

The most important enforcement check, and the one that's most often missing. Before any per-domain quality gate, the enforcer asks: **does this work fit the technical strategy and the existing decisions?**

This file is the workflow for that check. It's the link between the [technical-strategist](../../technical-strategist/SKILL.md) (who writes the strategy and declares the load-bearing DADs) and the work the team is actually doing (which the enforcer verifies against those decisions).

The premise: a strategy that nobody checks is decoration. The enforcer is the check.

## Why This Check Comes First

When reviewing a piece of work, it's tempting to dive into the details: code quality, test coverage, security, accessibility. Those all matter. But the *most* important question is the one that comes first:

> **Should we even be doing this work, in this way?**

If the answer is "no, this doesn't fit the strategy," then nothing else matters. The team shouldn't ship code that contradicts the strategy, no matter how clean and well-tested it is.

So the strategic alignment check is the *first* gate. It runs at kickoff (most important), at pre-merge (as a sanity check), and again at post-release (to confirm the work served its strategic purpose).

## The Check, Step by Step

### Step 1: Identify the relevant strategy section

Pull up the technical strategy document. Find the section that's relevant to this work. For most non-trivial work, it should map to:

- **A specific bet or initiative** in the strategy ("the monolith extraction").
- **A theme** in the current quarter ("improve onboarding velocity").
- **A non-goal** that this work might be violating ("we are not building admin features in this period").

If you can't find the strategy section the work is supposed to serve, that's a flag. Either:

- The strategy is missing this area (surface to the strategist).
- The work doesn't fit any current strategic priority (surface to the team — should this work even be happening now?).
- The strategy is too vague to identify the relevant section (surface to the strategist).

### Step 2: Identify the relevant DADs and ADRs

Pull up the team's DAD/ADR index ([team-lead](../../team-lead/SKILL.md) maintains this). Find the entries that touch this area of the system or this kind of work.

For most work, you'll find 3-10 relevant entries:

- **Load-bearing DADs**: the strategist has marked these as critical to the strategy. Violating them is a strategic problem.
- **Other DADs**: team conventions that aren't strategically critical but that the team has agreed to.
- **ADRs**: prior decisions about specific things in this area.

If the work touches an area with *no* relevant DADs or ADRs, that's not necessarily a problem — it might just be new territory. But it's worth flagging: should there be a DAD or ADR for this area?

If the work *contradicts* a load-bearing DAD or an ADR, you have a finding.

### Step 3: Compare the work to the decisions

For each relevant DAD/ADR, ask:

- **Does this work conform to the decision?** Yes / No / Partially.
- **If no, is this an unconscious deviation** (the team didn't realize the DAD applied)? Or a deliberate one?
- **If deliberate, is there an exception ADR** explaining the deviation?

The matrix:

| Conforms | Conscious | Has exception ADR | Verdict |
|---|---|---|---|
| Yes | — | — | ✅ OK |
| No | No | No | ❌ Block — bring into compliance |
| No | Yes | No | ⚠️ Block until exception ADR is filed |
| No | Yes | Yes | ✅ OK if the exception ADR is approved |

The third row is the most common failure: the team knows they're deviating, they have a reason, but they haven't documented it. The enforcer's job is to *make them document it* before the work ships.

### Step 4: Check the strategy's non-goals

The strategy explicitly lists what the team is *not* doing. The enforcer checks whether the proposed work falls into a non-goal:

- **"We are not building admin features this period."** Is this work an admin feature?
- **"We are not introducing new programming languages."** Is this work introducing one?
- **"We are not migrating to Kubernetes."** Is this work part of a Kubernetes migration?

If the work falls into a non-goal, that's a finding. Same matrix:

- **Unconscious**: bring into compliance (don't do the work, or scope it differently).
- **Conscious without ADR**: file an exception ADR.
- **Conscious with ADR**: proceed if the exception was approved.

### Step 5: Check for capacity conflicts

Even if the work is strategically aligned, ask: **does the team have capacity to do this without sacrificing the bets the strategy committed to?**

If the work is a one-week feature, it probably doesn't disrupt the strategic bets. If it's a quarter-long initiative, it probably does. The enforcer flags capacity conflicts so the team can decide deliberately:

- **Cut something else** to make room.
- **Defer this work** to fit the existing capacity.
- **Add capacity** (rare, slow).
- **Accept the conflict** and adjust the strategy.

This isn't blocking — it's surfacing a trade-off that needs to be made.

### Step 6: Document the check

Whatever the outcome, the enforcer documents the strategic alignment check. The format is short:

```markdown
## Strategic Alignment

- **Strategy section**: [link / quote] (e.g. "Q2 monolith extraction")
- **Relevant DADs**: DAD-0042 (Postgres for OLTP), DAD-0051 (event-driven inter-service)
- **Relevant ADRs**: ADR-0103 (extracted services use HTTP for sync calls)
- **Conformance**: ✅ Conforms / ⚠️ Partial / ❌ Deviates
- **Exception needed**: No / Yes (filed as ADR-0142)
- **Capacity impact**: Small / Medium / Large
- **Verdict**: Approved / Approved with conditions / Needs revision / Blocked
```

This goes in the PR description, the design doc, or wherever the team tracks reviews. It's reusable as precedent: future enforcers (and engineers) can see how similar work was reviewed.

## When the Strategy Is Silent

Sometimes the strategy doesn't say anything specific about the area. That's not a problem; it just means the work is in territory the strategy hasn't constrained.

In that case:

1. **Default to the load-bearing DADs.** If there are general DADs that apply (e.g., "all services use OIDC for auth"), they still apply.
2. **Apply the per-domain standards** (security, quality, etc.).
3. **Don't invent new strategic constraints** on the fly. The enforcer cites existing decisions; they don't create new ones.
4. **Note the gap.** If the work is in an area that the strategy *should* cover but doesn't, surface that to the strategist for the next strategy revision.

## When the Strategy Is Out of Date

Sometimes the strategy is stale — it was written before the situation changed, and the work no longer makes sense in its terms. The enforcer's response:

1. **Don't enforce a stale strategy.** That's gatekeeping.
2. **Surface the staleness** to the strategist. "The strategy says X, but Y has happened; the strategy needs to be updated."
3. **Make a judgment call** about whether to proceed with the work. If the work is clearly the right thing despite the stale strategy, approve with a note. If it's unclear, escalate.
4. **Update the strategy** (with the strategist's involvement) and re-review the work against the new version.

This requires judgment. The enforcer isn't a robot following the letter of the strategy; the enforcer is applying the *spirit* of the team's collective decisions while flagging when the formal strategy needs to catch up.

## When Work Conflicts Across Strategies

Sometimes a piece of work fits the technical strategy but conflicts with the product strategy, or vice versa. The enforcer surfaces this and routes to the right place:

- **Conflict with the product strategy** → route to [technical-product-management](../../technical-product-management/SKILL.md).
- **Conflict with another team's strategy** → route to whoever owns the cross-team coordination.
- **Conflict with the company strategy** → route to leadership.

The enforcer doesn't try to resolve cross-strategy conflicts on their own. They surface the conflict and let the right people decide.

## The Hard Cases

### "We're not introducing the Kubernetes migration but this PR adds a Helm chart"

Is this introducing Kubernetes, or just preparing the ground? The enforcer asks:

- **Is the Helm chart actually used?** If no, it's dead code; remove or move.
- **Is the team committing to Kubernetes by adding it?** If yes, this is a strategic deviation; needs an exception ADR.
- **Is this experimental work that's not on the deploy path?** Different rules apply.

The enforcer's job is to surface the question, not to give a one-size-fits-all answer. The team and the strategist decide.

### "This DAD is about Postgres for OLTP but I'm adding ClickHouse for analytics"

Analytics isn't OLTP. The DAD says "Postgres for OLTP" — analytics is a different category.

But: **is "we use ClickHouse for analytics" a *new* DAD?** If yes, file it. If the team is going to use ClickHouse for analytics going forward, the DAD index should reflect that, so the next engineer doesn't have to relitigate it.

The enforcer's response: approve, but require that the team file the new DAD with the team-lead skill. Make the implicit decision explicit.

### "The strategy doesn't mention this area at all"

This is fine for the work itself, but it might be a sign that the strategy is incomplete. The enforcer:

1. Approves the work (no strategic conflict).
2. Notes the gap to the strategist.
3. Suggests that the area might need a DAD or strategy update.

Don't block work because the strategy is incomplete. Approve it and improve the strategy.

### "Two senior engineers disagree about whether this fits the strategy"

The strategy is clear, but the engineers read it differently. The enforcer's response:

1. **Document both interpretations.** What does each engineer think the strategy says?
2. **Route to the strategist.** They wrote it; they get to clarify.
3. **Update the strategy** to remove the ambiguity.
4. **Re-review with the clarified version.**

Don't try to arbitrate the disagreement personally. The enforcer applies the strategy; the strategist owns its interpretation.

### "The work was already done before the strategy was written"

The strategy is new. Existing work might violate it. The enforcer's response:

1. **Don't retroactively block the work.** It's already shipped.
2. **Flag the existing noncompliance** as debt.
3. **Decide whether to remediate**: bring the existing work into compliance, or grandfather it with an explicit note.
4. **Apply the strategy to all *new* work** going forward.

Strategic shifts produce debt. The enforcer manages the debt, doesn't pretend it doesn't exist.

## The Output

A strategic alignment check produces one of four outcomes:

### ✅ Approved

The work fits the strategy and the relevant DADs/ADRs. Proceed to the next gate (or to build, if this is kickoff).

Document the check; cite the relevant strategy section and DADs.

### ⚠️ Approved with conditions

The work mostly fits, but there are minor adjustments needed before proceeding. Document the conditions; require they be met before the next gate.

Examples:
- "Approved, but the new DAD on ClickHouse-for-analytics needs to be filed before merge."
- "Approved, but the design needs to use the existing event bus instead of HTTP for the cross-service call."

### ⚠️ Needs exception ADR

The work deliberately deviates from a DAD or the strategy. The deviation might be the right call, but it needs to be documented. Require an exception ADR before proceeding.

Document the deviation and the rationale for it. Route to [exceptions-and-waivers.md](exceptions-and-waivers.md).

### ❌ Blocked

The work violates the strategy or a load-bearing DAD without justification. The enforcer blocks the work and offers options:

- **Bring it into compliance** (the most common path).
- **File an exception ADR** if there's a real reason to deviate.
- **Update the strategy** if the work is the right thing and the strategy is wrong.
- **Stop the work** if none of the above applies.

A block is a serious move. The enforcer does it deliberately, with reasoning, and with a path forward.

## Anti-Patterns

- **Skipping the strategic check** because "the strategy is unclear" or "we don't have time."
- **Citing the strategy without reading it.** "This violates the strategy" without specific citation.
- **Inventing new strategic constraints** that aren't in the actual strategy doc.
- **Enforcing a stale strategy** that no longer matches reality.
- **Refusing to enforce** when the strategy is clear, just because the team is annoyed.
- **Approving silently** when the work clearly deviates. Even small deviations should be flagged.
- **Blocking without offering options.** A pure no without a path forward.
- **Treating the strategic check as a checkbox.** Going through the motions without actually engaging.
- **Different bars for different teams.** Strategic enforcement for some teams, not for others.
- **Strategic checks that nobody documents.** No precedent; same conversations happen again.
- **Surfacing the strategic conflict to the team but not to the strategist.** The strategy stays stale because the strategist doesn't know about the conflicts.
- **Letting "we'll fix it later" pass at the strategic gate.** Strategic deviations are rarely fixed later; document and decide now.
- **Trying to resolve cross-strategy conflicts as the enforcer.** Route them; don't decide them.

## Related

- [the-gates.md](the-gates.md) — when this check happens
- [exceptions-and-waivers.md](exceptions-and-waivers.md) — what to do when work deliberately deviates
- [escalation.md](escalation.md) — what to do when the team won't comply
- [technical-strategist](../../technical-strategist/SKILL.md) — the strategy being enforced
- [team-lead](../../team-lead/SKILL.md) — the DAD/ADR machinery
- [technical-strategist/references/load-bearing-dads.md](../../technical-strategist/references/load-bearing-dads.md) — which DADs are critical
- [assets/strategic-alignment-form.md](../assets/strategic-alignment-form.md) — fillable form for documenting the check

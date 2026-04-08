# Operational Readiness Check

The operational readiness check happens at the **pre-release gate** — before code goes to production. It verifies that the team is ready to *operate* the change, not just to ship it. A feature that's well-coded and well-tested can still be a disaster if there's no runbook, no alerts, no rollback plan, and no one watching.

This file is the workflow for that check. Like the others, it doesn't restate the operational rules — those live in [site-reliability-engineering](../../site-reliability-engineering/SKILL.md). The enforcer's job is to verify the work is ready.

## Why This Check Exists

Most engineering teams over-invest in *building* and under-invest in *operating*. The pre-release gate is the moment to correct that imbalance. A change that ships without operational readiness will eventually break in production with no clear response, and the team will scramble to figure out what to do *while customers are affected*.

The cost of catching an operational gap at pre-release: a small delay to add the missing runbook or alert.

The cost of catching it post-release in an incident: customer pain, support tickets, panic, possibly a postmortem with hard questions about why it shipped.

This is why the operational readiness check is non-negotiable. The team that ships fast also operates well; the team that ships fast without operating is shipping debt that compounds.

## What the Check Covers

| Category | Source | What the enforcer checks |
|---|---|---|
| **Runbooks** | [site-reliability-engineering/references/runbooks.md](../../site-reliability-engineering/references/runbooks.md) | Are runbooks updated for new alerts? Existing runbooks reflect changes? |
| **Alerting** | [site-reliability-engineering/references/alerting-and-paging.md](../../site-reliability-engineering/references/alerting-and-paging.md) | New error conditions have alerts? Symptom-based, not cause-based? Linked to runbooks? |
| **Dashboards** | [site-reliability-engineering/references/slis-slos-error-budgets.md](../../site-reliability-engineering/references/slis-slos-error-budgets.md) | Metrics visible? Launch dashboard ready? |
| **Rollback plan** | [site-reliability-engineering/references/incident-response.md](../../site-reliability-engineering/references/incident-response.md) | What's the rollback? How fast? Has it been tested? |
| **Phased rollout** | [technical-product-management/references/launches-and-rollouts.md](../../technical-product-management/references/launches-and-rollouts.md) | Is the rollout phased? Kill criteria for each phase? |
| **Kill criteria** | Same | What would trigger a rollback? Pre-committed, not improvised |
| **Capacity / load** | [site-reliability-engineering/references/capacity-and-load-management.md](../../site-reliability-engineering/references/capacity-and-load-management.md) | Has the change been load-tested? Will it handle expected traffic? |
| **Database migrations** | [site-reliability-engineering/references/incident-response.md](../../site-reliability-engineering/references/incident-response.md) | Migrations safe? Run before deploy? Reversible? |
| **Secrets / config** | [security-engineering/references/infrastructure-security.md](../../security-engineering/references/infrastructure-security.md) | New secrets in vault? New config in the right place? |
| **Communication** | [technical-product-management/references/launches-and-rollouts.md](../../technical-product-management/references/launches-and-rollouts.md) | Stakeholders notified? Customer comms ready (if applicable)? |
| **On-call awareness** | [site-reliability-engineering/references/on-call.md](../../site-reliability-engineering/references/on-call.md) | The on-call knows about the release and what to expect |

The categories overlap with the SRE skill heavily — that's intentional. SRE owns the operational practices; the enforcer verifies they're applied at the gate.

## The Check, Step by Step

### Step 1: Identify the release scope

What's being released?

- **A new feature**: full operational readiness applies.
- **A bug fix**: lighter check; verify the fix doesn't introduce new operational concerns.
- **A configuration change**: verify the change is reversible and doesn't violate the deployment process.
- **A database migration**: special attention; migrations are high-risk.
- **An infrastructure change**: full operational readiness; touches production directly.
- **A multi-service change**: coordination across teams; the check is more complex.

Adjust the depth of the check to the scope of the release.

### Step 2: Verify runbooks

For any change that introduces a new alert (or a new way the system can fail), there must be a runbook.

The check:

- **Does the alert have a runbook linked?** No runbook → no alert (per [site-reliability-engineering/references/runbooks.md](../../site-reliability-engineering/references/runbooks.md)).
- **Is the runbook discoverable?** Linked from the alert payload, not hidden in a wiki.
- **Is the runbook actionable?** Specific commands, specific decision points, not vague guidance.
- **Has the runbook been verified to work?** Either via gameday or via the most recent incident.
- **Does it have an escalation path?** When the on-call can't fix it alone, who do they call?

For changes that affect *existing* runbooks, the check is: have the runbooks been updated to reflect the change? A runbook that's stale because the system changed is worse than no runbook.

### Step 3: Verify alerts

Are the relevant alerts in place?

- **For the success metric**: an alert if the metric drops past the success threshold.
- **For error rates**: burn-rate alerts if the team has SLOs ([site-reliability-engineering/references/slis-slos-error-budgets.md](../../site-reliability-engineering/references/slis-slos-error-budgets.md)).
- **For new failure modes**: anything that didn't exist before should have appropriate detection.
- **For cross-cutting concerns**: queue depth, latency, capacity.

The alerts should be:

- **Symptom-based, not cause-based**. Pages on user pain, not on CPU > 80%.
- **Linked to a runbook**.
- **Owned**. Routes to the right on-call.
- **Tested**. Verified to fire correctly.

A new feature with no alerting is a feature that breaks silently. The enforcer requires alerting before release.

### Step 4: Verify the dashboard

For any non-trivial release, there's a dashboard. The dashboard:

- **Shows the success metric** for this release.
- **Shows the counter-metric** (the thing that could go wrong if you optimize the success metric too hard).
- **Shows error rates** for the affected components.
- **Shows latency** for the affected endpoints.
- **Is accessible** to the team and to leadership.
- **Is referenced in the launch communication**.

The dashboard exists *before* the release, not after. The enforcer verifies it's set up.

### Step 5: Verify the rollback plan

Critical question: **what's the rollback if this goes wrong?**

The rollback plan must answer:

- **What's the trigger?** Specific kill criteria, pre-committed.
- **What's the mechanism?** Feature flag flip? Revert deploy? Database rollback?
- **How long does it take?** Seconds, minutes, hours?
- **What's the data implication?** If users created data with the new feature, what happens to it on rollback?
- **Has it been tested?** Rollback drills are real; without them, the plan is hope.
- **Who decides?** Named individual or on-call rotation; not "we'll figure it out."
- **What do we say to users?** Communication during a rollback.

A release without a rollback plan is a release that bets the team can't fail. The enforcer requires the plan and verifies it's been tested.

### Step 6: Verify the rollout phasing

Is the rollout phased? For non-trivial releases, it should be:

1. **Internal first** (the team).
2. **Internal beta** (the company).
3. **Closed beta** (selected customers).
4. **Soft launch** (small percentage of users).
5. **Expansion** (more users).
6. **Full launch** (all users).

Each phase has bake time and kill criteria. The enforcer verifies:

- **The phases are defined**.
- **The kill criteria are pre-committed**.
- **There are decision points** between phases (not just automatic expansion).
- **Someone is watching** the metrics during the rollout.

For trivial releases, full phasing isn't needed. For anything user-visible or operationally significant, it is.

### Step 7: Verify capacity and load

Will the change handle the expected traffic?

- **Has it been load-tested?** Synthetic load against staging or a canary.
- **Is the database / backing services prepared?** Connection pools, scaling, etc.
- **Are autoscaling thresholds correct?** Scale-up triggers, max replicas.
- **Is there headroom?** Not running at 100% capacity from the start.

For changes that materially affect load, the enforcer requires evidence that the team has thought about it. "It should be fine" is not evidence.

### Step 8: Verify migrations

Database migrations are a class of high-risk change:

- **Are migrations backwards-compatible** with the old code? If not, the rollout sequence matters: old code → migration → new code, with no point where new code expects new schema that isn't there.
- **Are migrations reversible?** Or at least, is there a forward migration that fixes a bad situation?
- **Have migrations been tested** on production-shaped data? Some migrations are fine on small datasets and disastrous on large ones.
- **Will migrations run within the deploy window?** Long migrations need different handling.
- **What's the lock impact?** Migrations that lock tables can cause outages.

The enforcer doesn't run the migrations. The enforcer verifies the team has thought about each of these and has answers.

### Step 9: Verify secrets and config

For changes that introduce new secrets or config:

- **Secrets are in the vault**, not in code or env files.
- **Config is in the right place** (per the team's conventions).
- **The new config is set** in all environments before release.
- **Defaults are safe**: if config is missing, the system fails closed, not open.

The enforcer routes to [security-engineering/references/infrastructure-security.md](../../security-engineering/references/infrastructure-security.md) for the rules.

### Step 10: Verify communication

Internal:

- **Sales / customer success** know what's coming and how to support customers.
- **Marketing** has assets ready.
- **Leadership** knows about the release and any risks.
- **Other engineering teams** that might be affected.
- **The on-call rotation** knows the release is happening and what to watch for.

External (if customer-facing):

- **Customer announcement** drafted and ready.
- **Status page entry** prepared.
- **Help documentation** updated.
- **Support team** trained on the new feature.

The enforcer verifies the communication has happened, not just that it's planned.

### Step 11: Final go/no-go

Before approving the release, the enforcer asks:

- **Is everything above complete?** No yellow flags hiding problems.
- **Is the team ready?** Not just "yes" — are the right people available during the launch window?
- **Is the timing right?** Not Friday afternoon; not during a major event or holiday.
- **Is leadership aware?** They don't need to approve, but they should know.

The verdict:

- **Approved**: release.
- **Approved with conditions**: release after specific items are addressed.
- **Phased**: release in stages with checkpoints between phases.
- **Delayed**: missing items that must be addressed before release.
- **Blocked**: significant gap; the team isn't ready.

A delayed release is much cheaper than a failed release.

## Calibration: What's "Necessary"

The depth of the operational readiness check depends on the release:

| Release type | Operational readiness depth |
|---|---|
| Bug fix in production | Light: verify rollback works; verify on-call knows |
| Configuration change | Light: verify reversible; verify communicated |
| Small feature | Medium: runbook for new alerts; rollback plan; phased rollout |
| Major feature | Full: all categories above |
| Database migration | Full + extra: migration safety, lock impact, timing |
| New service | Full + extra: capacity planning, runbooks for all alerts, dashboard creation |
| Multi-service change | Full + cross-team coordination |
| Hotfix | Same as the original change shape — hotfixes don't get to skip readiness |

The principle: **the depth scales with the risk**. A trivial change doesn't need a 30-item checklist; a major launch does. The enforcer adjusts.

## Common Failure Modes

### "We'll add the runbook after launch"

After launch is when the runbook matters. After launch is when the page fires at 3am and the on-call has nothing.

The enforcer doesn't accept "later" for runbooks.

### "The rollback plan is to revert the deploy"

That's a starting point, not a plan. Questions:

- **How long does the revert take?** If it's 30 minutes, the plan is too slow.
- **What if the database has migrated forward?** Revert won't undo that.
- **Who decides to revert?** Not "we'll see"; a named decider.
- **What do we say to users during the revert?**

A rollback plan is a *specific procedure*, not a wish.

### "We'll watch the metrics manually"

Manual watching scales to 5 minutes; then the watcher gets distracted. The enforcer requires *automated* alerting on the success metric, with humans as the secondary line of defense.

### "We don't need a beta; the change is small"

Small changes can have large impact. A two-line change can corrupt every record in a table. Beta isn't about change size; it's about risk.

The enforcer adjusts based on the risk, not just the line count.

### "We're shipping Friday because the deadline is Monday"

Friday afternoon releases are how outages happen. Half the team is offline; on-call is solo; the cost of an incident is high.

The enforcer pushes back on Friday releases. If the deadline is real, the team should consider whether the deadline is more important than the risk.

### "We don't need to notify support; they'll figure it out"

Support gets surprised; customers complain; support is unprepared; the team looks bad and customers feel ignored.

The enforcer requires that the relevant teams know.

### "The migration is fine; we tested it on staging"

Staging often has different data shapes than production. A migration that's fast on staging can be slow on production. The enforcer verifies that migration testing was done on representative data.

### "It's a hotfix; we don't have time for the checklist"

Hotfixes are exactly when the checklist matters. A hotfix that introduces a new bug is much worse than the original problem.

The enforcer doesn't waive operational readiness for hotfixes. They might be done lightly, but they're done.

## Operational Exceptions

Like quality, operational readiness has more room for legitimate exceptions than security:

- **A small change with a clear rollback** might skip the formal phased rollout.
- **An internal tool change** might skip customer communication.
- **A minor config change** might skip the dashboard requirement.

In each case, the exception process applies. The enforcer documents the exception, the rationale, and the mitigations.

The pattern: **flag the gap, route through exception, decide deliberately**.

## Anti-Patterns

- **Skipping operational readiness for "simple" releases.** Most outages come from "simple" releases.
- **Approving without runbooks** because "we know how the system works." Knowledge in heads doesn't survive the next on-call rotation.
- **Approving without rollback plans.** "We'll figure it out" is not a plan.
- **Approving releases timed for Friday afternoon** without specific reason.
- **Approving releases during major events** (holidays, conferences, sales periods).
- **No phased rollout** for non-trivial changes.
- **Phased rollout with no kill criteria.** The phases are theater.
- **Phased rollout with no human watching.** Automated expansion past broken thresholds.
- **No coordination with on-call** for new releases.
- **Migrations approved without testing on production-shaped data.**
- **Capacity questions waved through** with "it should be fine."
- **No communication to support / sales / marketing** for customer-visible changes.
- **Approving releases that fail any of the above** with the rationalization "it'll be fine."
- **Punishing teams** for catching their own readiness gaps. Catching gaps is the point of the check.
- **Approving the same operational gaps repeatedly** because "we're working on it."
- **No post-release verification.** The release happens; nobody checks how it went.

## Related

- [the-gates.md](the-gates.md) — when this check happens (pre-release)
- [security-baseline-check.md](security-baseline-check.md) — pairs at pre-release
- [quality-baseline-check.md](quality-baseline-check.md) — pairs at pre-merge
- [exceptions-and-waivers.md](exceptions-and-waivers.md) — when readiness items are deferred
- [site-reliability-engineering](../../site-reliability-engineering/SKILL.md) — source of truth for operational practices
- [site-reliability-engineering/references/runbooks.md](../../site-reliability-engineering/references/runbooks.md) — runbook standards
- [site-reliability-engineering/references/alerting-and-paging.md](../../site-reliability-engineering/references/alerting-and-paging.md) — alerting standards
- [technical-product-management/references/launches-and-rollouts.md](../../technical-product-management/references/launches-and-rollouts.md) — launch practices
- [deployment-pipelines](../../deployment-pipelines/SKILL.md) — deploy mechanics

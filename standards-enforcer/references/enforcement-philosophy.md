# Enforcement Philosophy

Before diving into the mechanics of what to enforce and when, it's worth being clear about *why* enforcement matters and what the enforcer is actually doing. The mechanics are useful only if the philosophy is right; otherwise the enforcer becomes either a rubber stamp or a tyrant.

## The Core Insight

Standards exist because the team has agreed they're worth having. Security baselines, accessibility requirements, code quality bars, observability minimums, operational readiness — each one was put in place because skipping it produced something the team regretted. The standards represent *accumulated lessons*. They're the team's collective memory of what not to do.

The thing about standards: **without enforcement, they erode**. Not all at once; quietly, over months. A "we'll fix it next sprint" here. A "this is a special case" there. A "we don't have time for the full review this time" under deadline pressure. Each individual deviation feels reasonable in the moment. Six months later, the team is shipping code that violates half the standards, and nobody can remember when the slide started.

This is why the enforcer exists. **The enforcer is the team's defense against the slow erosion of its own standards under deadline pressure.** Without that defense, standards become aspirations, then theater, then nothing.

## What Erosion Looks Like

Standards rot in predictable ways:

### Death by a thousand exceptions

Each individual exception is reasonable. Cumulatively, they replace the standard with chaos. "We made an exception for X because the customer needed it. We made an exception for Y because the team was short-staffed. We made an exception for Z because the feature was already shipped."

After 30 exceptions, the standard exists in the wiki but applies to nothing.

### Senior engineers exempt

Senior engineers don't have time for the standards. They wave through their own work. Junior engineers see the inconsistency and start doing the same. The standards apply to nobody.

### Standards in the wiki, work in production

The wiki has a beautiful page about the team's testing standards. Production code has 12% test coverage. Nobody connects the two; the wiki is decorative; the production code is the truth.

### "Temporary" hacks that ship

A solution that's "just for now" goes to production. The "just for now" becomes "we'll fix it in the next sprint." The next sprint is feature work. The hack stays. Two years later, the hack is load-bearing.

### Standards drift

The standard says "we use Postgres for OLTP." Someone adds a MongoDB instance "just for this one feature." Six months later, the codebase has 4 different databases, and nobody can remember when the strategy of "one database for OLTP" died.

In every case, the underlying problem is the same: **nobody held the line at the moments when a deviation was being introduced**. The enforcer is the role that holds the line.

## What Enforcement Actually Means

Enforcement isn't:

- **Saying no to everything.** A pure no destroys the team. Most work passes the enforcer's checks; the work that doesn't has a path to compliance.
- **Approving everything if no obvious violation.** Rubber-stamping is anti-enforcement.
- **Being adversarial.** The enforcer is on the team's side. The enemy isn't the engineer who wrote the code; it's the slow erosion of standards.
- **Restating the rules.** The rules live in the source skills. The enforcer cites them.
- **Catching every detail.** The enforcer focuses on the high-impact gates and the load-bearing standards. Nitpicking everything is gatekeeping.

Enforcement is:

- **Verifying that work meets the agreed bar at clear gates.**
- **Identifying when a deviation is happening and routing it appropriately** (compliance, exception ADR, escalation).
- **Protecting the team from pressure to skip standards** under deadline.
- **Maintaining institutional memory** about why the standards exist.
- **Bringing options, not just blocks.** Always a path forward.
- **Being fair.** Same bar for everyone; visible reasoning for every decision.

## The Enforcer as Service to the Team

A common misframing: the enforcer is the *team's adversary*. They block PRs. They ask annoying questions. They make work take longer.

The right framing: **the enforcer is the team's defense against its own future regrets**. The team doesn't *want* to ship insecure code; the enforcer makes sure they don't, even when they're rushed. The team doesn't *want* to violate the strategy; the enforcer surfaces deviations early so the team can decide deliberately.

When the enforcer is doing the job well, the team gets:

- **Fewer incidents in production.** Standards caught problems before they shipped.
- **Easier maintenance.** The codebase is consistent because deviations were caught.
- **Less rework.** Catching problems at PR time is much cheaper than catching them post-release.
- **A stronger negotiating position with leadership.** "We can't skip the security review; it's the standard."
- **A track record of shipping things that don't break.**

When the enforcer is doing the job badly, the team gets:

- **Resentment.** The enforcer is seen as obstructive.
- **Workarounds.** Engineers route around the enforcer.
- **Inconsistency.** Some PRs get scrutinized, others don't.
- **Theater.** Reviews happen; nothing changes; everyone wastes time.

The difference is in the mindset: **the enforcer's success metric is the team's quality and velocity over the long arc**, not the number of PRs they personally reviewed.

## Enforcement vs Gatekeeping

These look similar from the outside; they're very different in practice.

| Enforcement | Gatekeeping |
|---|---|
| Engages at clear, agreed gates | Engages whenever, on whatever feels worth checking |
| Cites specific standards from source-of-truth skills | Cites personal preference or vague "best practices" |
| Brings options when blocking ("here's the path to yes") | Just blocks ("this isn't good enough") |
| Applies the same bar to everyone | Applies different bars based on personal feelings |
| Has a clear exception process | Exceptions happen ad-hoc, opaquely |
| Decisions are documented and reusable as precedent | Decisions are in the gatekeeper's head |
| Protects the team from pressure | Imposes additional pressure on the team |
| Engages early to catch problems cheaply | Engages late to catch problems expensively |
| Welcomes pushback and improves the process | Treats pushback as insubordination |
| Trusts the team to do the work; verifies at gates | Doesn't trust the team; checks everything |

The same person can be an enforcer or a gatekeeper depending on how they operate. The role doesn't determine the behavior; the *philosophy* does.

## The Standards Are the Contract

The standards aren't the enforcer's preferences. They're the team's *agreed* contract with itself. Each standard was put in place for a reason; each one is documented in a source-of-truth skill or in a DAD/ADR; each one is the team's collective decision.

The enforcer doesn't get to invent new standards. The enforcer enforces the standards *the team has agreed to*. If a standard is wrong, the path is to *change the standard* (via the strategist or the source-of-truth skill), not to selectively ignore it.

This is why the enforcer cites. Every block or approval points at the source. "Per security-engineering's API security reference, we require parameterized queries; this PR has string concatenation; please fix." The block is grounded in the team's agreement, not in the enforcer's opinion.

When an engineer disagrees with the standard, the conversation isn't with the enforcer; it's with whoever owns that standard. The enforcer routes the disagreement appropriately.

## The Strategy Layer

Beyond the per-domain standards (security, quality, accessibility, operational readiness), the enforcer also checks **strategic alignment**. The team's technical strategy says certain things are in-scope and others are out-of-scope; the load-bearing DADs encode the team's defaults; ADRs document the decisions that have been made.

The enforcer's job, before any other check, is to ask: **does this work fit the strategy and the existing decisions?** If yes, proceed with the per-domain checks. If no, route it through the exception process.

This is the most important enforcement loop the team has. Without it, the strategy and the DADs are decorative — they exist but no one checks whether work matches them. With it, the strategy stays alive because the enforcer surfaces deviations as they happen.

For the workflow of strategic alignment, see [strategic-alignment-check.md](strategic-alignment-check.md).

## When the Standards Are Wrong

Sometimes the standard turns out to be wrong for a specific case. The enforcer's instinct should *not* be "the standard is the standard, no exceptions." That's gatekeeping. The right instinct is:

1. **Acknowledge the case.** "I see why this is a problem for what you're trying to do."
2. **Route to the exception process.** "File an exception ADR. Here's the template. Here's who reviews it."
3. **If the exception is approved, the standard might need to change.** Surface that to the strategist or the source-of-truth skill owner.
4. **Don't grant the exception personally.** The enforcer applies the process; doesn't override it.

The exception process is the safety valve. Without it, the enforcer becomes a tyrant; with it, the standards stay firm but flexible.

For the exception workflow, see [exceptions-and-waivers.md](exceptions-and-waivers.md).

## When the Team Is Wrong

Sometimes the team genuinely isn't meeting the standard, and they want to ship anyway. Pressure from leadership; deadline panic; "this is good enough."

The enforcer's job in these moments is to **hold the line, with empathy**.

The line:

1. **Acknowledge the pressure.** "I understand this needs to ship Friday."
2. **State the standard clearly.** "The standard requires X. Here's why it exists."
3. **Bring options.** "We can comply by doing Y. Or we can file an exception ADR if leadership signs off on the trade-off. Or we can push the deadline."
4. **Don't capitulate to pressure alone.** "We're under deadline" is not a reason to skip the standard. It's a reason to file an exception or change the deadline.
5. **Document the disagreement** if forced to ship under protest. "I flagged this; the team chose to proceed; here's the documented record."

The enforcer who folds under pressure becomes useless. The enforcer who holds the line becomes the team's most valuable defense.

## The Enforcer's Authority

A practical question: where does the enforcer's authority come from?

It's not personal authority. It's not seniority. It's not popularity. It's the *team's prior agreement* to the standards. The enforcer is enforcing what the team already said it wanted.

When an engineer challenges the enforcer, the right response isn't "I'm the enforcer, I get to decide." The right response is "the standard the team agreed to says X. If you disagree with the standard, here's how to change it. If you want an exception, here's the process. But I'm not going to override the standard on my own authority."

This depersonalizes enforcement. It's not about the enforcer being right; it's about the team's collective agreement being honored. The enforcer is the agent of that agreement, not its source.

## Trust and Time

Effective enforcement is built on trust, and trust takes time:

- **The team learns** that the enforcer applies the bar fairly, brings options instead of just blocks, defends them from leadership pressure, and stays out of the way when work is going well.
- **The enforcer learns** that the team is generally trying to do the right thing and that catching problems early is much cheaper than catching them late.
- **Both learn** that the standards are real and that the team's quality has improved because of them.

This trust is fragile. A single unfair enforcement (favoring one team over another, capitulating to a powerful stakeholder, applying the standard inconsistently) can damage it for months.

The discipline is to be **boringly consistent**. Same bar, every time, with options. Boring is the goal.

## Anti-Patterns (Brief)

(The full catalog is in [enforcer-anti-patterns.md](enforcer-anti-patterns.md). A preview:)

- **Gatekeeping for its own sake.** Blocking things to feel important.
- **Restating rules.** Re-implementing what the source-of-truth skills already say.
- **Becoming a bottleneck.** Engaging continuously instead of at gates.
- **Unfair application.** Different bars for different people or projects.
- **Pure no.** Blocking without offering options.
- **Capitulating to pressure.** Folding when leadership pushes.
- **Skipping the source-of-truth.** Citing personal preference instead of the team's agreed standards.
- **Hidden reasoning.** Decisions without documentation.

## Related

- [the-gates.md](the-gates.md) — when the enforcer engages
- [strategic-alignment-check.md](strategic-alignment-check.md) — verifying work fits the strategy
- [exceptions-and-waivers.md](exceptions-and-waivers.md) — the safety valve
- [escalation.md](escalation.md) — what to do when teams won't comply
- [enforcer-anti-patterns.md](enforcer-anti-patterns.md) — the full catalog of failure modes
- [technical-strategist](../../technical-strategist/SKILL.md) — the source of the strategy and load-bearing DADs
- [team-lead](../../team-lead/SKILL.md) — the ADR/DAD machinery

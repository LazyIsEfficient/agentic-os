# The Gates

The most important architectural decision in standards enforcement: **at what moments does the enforcer engage?**

The wrong answer is "always." Continuous enforcement becomes a bottleneck; teams work around it; the enforcer becomes the team's adversary. The right answer is **at clear, agreed-upon gates** within the development lifecycle, where the enforcer is thorough, and between which the team works without interference.

This file defines the gates, what gets checked at each, and how the enforcer engages.

## The Four Gates

Every non-trivial piece of work passes through four enforcement gates:

| Gate | When | What gets checked | Cost of failure |
|---|---|---|---|
| **1. Kickoff** | Before any code is written | Strategic alignment; relevant DADs/ADRs; security threat model; design soundness | Smallest — just stop or rescope |
| **2. Pre-merge** | Before code merges to main | Code quality; security baseline; test coverage; accessibility; design conformance | Small-medium — fix the PR |
| **3. Pre-release** | Before code goes to production | Operational readiness; runbooks; alerts; rollback plan; release plan | Medium — delay release |
| **4. Post-release** | After code is in production | Telemetry; success metrics; postmortems; lessons | Largest — already in prod, harder to fix |

The principle: **catch problems as early as possible**. Fixing a strategic misalignment at kickoff is hours of work; fixing it post-release is months. The enforcer is most valuable at the early gates.

## Gate 1: Kickoff

**When**: at the start of a non-trivial feature, before significant code is written. Often pairs with the design review or PRD review.

**What's being checked**:

### Strategic alignment

- **What's the relevant strategy section?** Cite the technical strategy (or product strategy) that this work serves.
- **Are there relevant DADs/ADRs?** Pull up the existing decisions. Does the proposed work conform to them?
- **If it doesn't conform**, is this a deliberate deviation that needs an exception ADR? Or is it an unconscious deviation that should be brought into compliance?
- **Is this work scoped within the current strategy's bets?** Or is it off-strategy?

### Design soundness

- **Does the design make sense?** Review with the architect / software-design skill.
- **Does it cross known boundaries?** Multi-team work needs explicit coordination.
- **Is there an existing pattern this should follow?** Don't reinvent.

### Security threat model

- **What's the threat model?** What user input is involved? What's the trust boundary?
- **Are there known risks?** Auth, data handling, third-party integrations all have their own considerations.
- **Does this need a security review** before proceeding? (For high-risk features, yes.)

### Capacity and timing

- **Is this work realistic in the time given?** A feature that's already squeezed at kickoff will fail at later gates.
- **Are there dependencies?** What needs to happen before this work can start?

### Operational expectations

- **What's the SLO target?** If the feature has its own reliability requirements, name them.
- **Who will be on-call for this?** The team that builds it should be the team that supports it.

### Output of this gate

A go/no-go decision with one of these outcomes:

- **Approved**: proceed to build.
- **Approved with conditions**: proceed, but the conditions must be met before pre-merge.
- **Needs revision**: scope down, change approach, address the gap, then re-review.
- **Needs exception ADR**: deliberate deviation; file an ADR; route to the strategist.
- **Blocked**: stop. The work doesn't fit the strategy or violates a critical standard. Discuss with leadership.

The kickoff gate is the highest-leverage moment for the enforcer. Catching a problem here is dramatically cheaper than catching it later.

## Gate 2: Pre-merge

**When**: when a PR is ready to merge but before it lands on the main branch. Pairs with code review.

**What's being checked**:

### Code quality

- **Does the code meet the team's design standards?** Routes to [software-design](../../software-design/SKILL.md). The enforcer doesn't restate SOLID; the enforcer checks that the code review surfaced these concerns.
- **Are there code review comments outstanding?** Don't merge with unresolved blocking concerns.
- **Are there obvious smells?** God classes, tight coupling, etc.

### Test coverage

- **Are there tests?** Routes to the relevant testing skill (typescript-testing-backend, typescript-testing-frontend, typescript-quality-engineering).
- **Are the tests good?** Not just present — actually testing observable behavior, not just internal calls.
- **Do the tests pass in CI?**
- **Is the coverage on the changed code reasonable?** Not 100%; just not zero.

### Security baseline

- **Does the change introduce any of the security baseline concerns?** Routes to [security-engineering](../../security-engineering/SKILL.md). User input handled? Auth checks present? Secrets not committed? SQL parameterized?
- **For higher-risk changes**, is there a documented security review?

### Accessibility (for UI changes)

- **Does the UI meet the accessibility baseline?** Routes to [ux-design](../../ux-design/SKILL.md). Color contrast? Keyboard navigation? Screen reader support? ARIA roles where needed?

### Strategic conformance

- **Does the change conform to the load-bearing DADs?** Quick re-check.
- **Has anything in the implementation drifted from what was approved at kickoff?** Sometimes implementation reveals problems that change the design; surface them.

### Documentation

- **Is the change documented** appropriately? Code comments where needed; user-facing docs updated; ADR filed if a new significant decision was made.

### Output of this gate

- **Approved**: merge.
- **Approved with conditions**: merge after specific changes.
- **Needs revision**: don't merge yet; address the concerns.
- **Needs exception ADR**: deliberate deviation; file an exception; route through the process.
- **Blocked**: don't merge. Significant problem; discuss.

The pre-merge gate is the most frequently engaged. Most of the enforcer's work happens here. The discipline is to be *thorough but not nitpicky*: focus on the high-impact concerns, not the bikeshed details.

## Gate 3: Pre-release

**When**: before a release goes to production. For continuous deployment, this might be before any deploy; for batched releases, it's before the release window.

**What's being checked**:

### Operational readiness

- **Are runbooks updated?** Routes to [site-reliability-engineering](../../site-reliability-engineering/SKILL.md). New alerts have runbooks; existing runbooks reflect changes.
- **Are alerts configured?** New error conditions have alerts; the alerts route to the right on-call.
- **Is the dashboard ready?** Metrics are visible; the team can see what's happening post-release.

### Rollback plan

- **What's the rollback if this goes wrong?** Specific, tested, documented.
- **What's the kill switch?** Feature flags? Config changes? Rapid rollback?
- **Has the rollback been tested?** Not just designed — actually verified to work.

### Phased rollout plan

- **Is the rollout phased?** Internal first, then small percentage, then expand.
- **What are the kill criteria for each phase?** When do we stop expanding?
- **Who's watching?** The on-call rotation knows about the release and will catch problems.

### Communication

- **Have stakeholders been notified?** Sales, support, leadership know what's coming.
- **Is customer communication ready** if applicable?
- **Is the release timing right?** Not Friday afternoon; not during a major event.

### Final security check

- **Has anything new been introduced** since the pre-merge gate that changes the security profile?
- **Are secrets in the right place?** Not in code; not in environment files.

### Output of this gate

- **Approved**: release.
- **Delayed**: missing operational readiness; fix and re-review.
- **Phased**: release in stages with gates between phases.
- **Blocked**: significant gap; cannot release until addressed.

The pre-release gate is where the operational discipline lives. The team that ships frequently also engages this gate frequently; it shouldn't be onerous, but it's non-negotiable.

## Gate 4: Post-release

**When**: after the release is in production, typically 1-2 weeks after.

**What's being checked**:

### Was the bet right?

- **Did the metric move?** What was the success criterion at kickoff?
- **Is the metric being watched?** Or did instrumentation get skipped?
- **What did we learn?** Anything surprising?

### Are operations healthy?

- **Any incidents?** Postmortem if so.
- **Any new alerts firing?** Are they actionable?
- **Is the support volume what was expected?**

### Is the strategy still right?

- **Did this work confirm the strategy** or invalidate part of it?
- **Should the strategy be updated** based on what was learned?
- **Should any DADs be added or modified?**

### Lessons fed back

- **Are the lessons captured** somewhere that future work can learn from?
- **Is the postmortem (if any) blameless and actionable?**
- **Are the action items filed and assigned?**

### Output of this gate

- **Closed clean**: the work succeeded; no further action needed.
- **Closed with lessons**: the work succeeded; document the lessons.
- **Closed with follow-ups**: the work succeeded but produced new work that needs to be tracked.
- **Failed; remediate**: the work didn't succeed; figure out what to do.
- **Failed; postmortem**: the work failed in a way that needs a formal postmortem.

The post-release gate is the most often skipped. The team has shipped; they want to move on. The enforcer's discipline is to *not let the team move on without closing the loop*. Otherwise, the same problems recur in the next feature.

## How the Enforcer Engages at Each Gate

### Engagement model 1: Synchronous review meeting

For high-stakes work or for teams that want explicit gating, the enforcer engages in a meeting:

- **Kickoff meeting**: 30-60 minutes. Walk through the design, the strategy fit, the risks.
- **Pre-merge review**: 15-30 minutes per major PR. Walk through the change.
- **Pre-release readiness review**: 15-30 minutes. Walk through the operational checklist.
- **Post-release review**: 30 minutes. Walk through what happened.

This is the heaviest model. Use it for high-stakes work (major launches, security-sensitive features, cross-team changes).

### Engagement model 2: Async checklist

For routine work, the enforcer engages async:

- **Kickoff**: a checklist filled out by the engineer; reviewed by the enforcer; comments via PR or chat.
- **Pre-merge**: a checklist included in the PR template; reviewed as part of code review.
- **Pre-release**: a checklist filled out before deploy; reviewed by on-call.
- **Post-release**: a brief check-in 1-2 weeks after deploy.

This is the lightest model. Use it for most work most of the time. The synchronous meetings are reserved for high-stakes cases.

### Engagement model 3: CI / automation

Some checks can be automated:

- **Lint rules** for code style.
- **Security scanners** for known vulnerabilities (e.g., OWASP ZAP, Snyk, GitHub Dependabot).
- **Test coverage gates** in CI.
- **Accessibility checks** (axe-core, jest-axe).
- **Build / deploy automation** that requires certain artifacts (runbooks, alerts) before release.

Automated checks are the cheapest enforcement. The enforcer's job is to *configure* the automation correctly and to *engage manually* on the things automation can't catch (strategic alignment, design soundness, judgment calls).

The right mix is usually: heavy automation for routine checks, async checklists for most reviews, sync meetings for high-stakes work.

## Calibration: How Strict to Be at Each Gate

The enforcer's instinct should be **stricter at the earlier gates, more pragmatic at the later gates**.

- **Kickoff**: very strict on strategic alignment. Catching a strategic misalignment here costs hours; catching it later costs months. Be willing to block.
- **Pre-merge**: strict on critical things (security, accessibility, load-bearing DADs); pragmatic on debatable things. The PR is already written; the cost of major rewrites is real. Block on the things that matter; flag the things that don't but let the PR through.
- **Pre-release**: strict on operational readiness. A release without runbooks or rollback is not ready, regardless of how complete the feature is.
- **Post-release**: more about *learning* than blocking. The work is in production; the question is whether to keep it, fix it, or roll it back. Bring data and judgment.

The discipline is to be *consistent*. Same standard at the same gate, every time.

## Gates That Don't Apply

Not every piece of work needs all four gates. The enforcer adjusts based on the size and risk of the work:

| Work shape | Gates |
|---|---|
| Bug fix (no behavior change) | Pre-merge only (minimal) |
| Small refactor (no behavior change) | Pre-merge only |
| Small feature (single screen, isolated) | Pre-merge + pre-release (lightweight) |
| Medium feature (multi-component) | All four gates (lightweight) |
| Large feature / multi-team | All four gates (full review) |
| Major refactor / migration | All four gates (synchronous reviews) |
| Security-critical change | All four gates plus dedicated security review |
| New service / new platform | All four gates plus design review |

For trivial work, the enforcer should be invisible. For high-stakes work, the enforcer should be embedded throughout.

## Common Failure Modes

### Gates that don't actually gate

The "review" happens but it's a rubber stamp. Nothing is ever blocked. The enforcer's job is to actually block when blocking is warranted.

### Gates skipped for "speed"

The team is under deadline; the enforcer is bypassed. This is exactly the moment the enforcer is most valuable. The enforcer's job is to *hold the line under pressure*, not to fold.

### Gates only at pre-merge

All enforcement happens at PR review. Strategic and design problems are caught after the work is already built; rework is expensive. Move enforcement earlier.

### Gates only at the easy moments

The enforcer engages on small features but waves through large ones because they're "too big to block." The opposite is correct: large work needs more enforcement, not less.

### Gates with no consequences

The enforcer flags problems but the team ships anyway. The flags become decoration. The enforcer must have actual authority to block, or the gates are theater.

### Gates that rotate by mood

Sometimes strict, sometimes loose. Engineers can't predict what the bar is. Be boringly consistent.

## Anti-Patterns

- **No gates.** Standards exist on paper; nobody checks them at decision points.
- **Continuous enforcement.** No clear gates; the enforcer is always in the way.
- **Gates with no teeth.** Rubber-stamping; nothing ever gets blocked.
- **Gates only for some teams.** Unfair application.
- **Gates only at pre-merge.** Catching problems too late; rework is expensive.
- **Gates that the enforcer skips under pressure.** The moment standards matter most.
- **Gates without a process for exceptions.** Forces silent deviations.
- **Gates without documented criteria.** Engineers can't predict the bar.
- **Gates that nitpick.** Bikeshed details instead of high-impact concerns.
- **Gates as performance.** Synchronous reviews that never produce decisions.
- **Pre-release skipped for hotfixes.** Hotfixes are exactly when ops readiness matters most.
- **Post-release skipped because "we shipped already."** Lessons get lost.
- **Manual gates for things that should be automated.** Wastes the enforcer's time and the team's.
- **Automated gates that block on trivial things** without an override path.

## Related

- [enforcement-philosophy.md](enforcement-philosophy.md) — the why
- [strategic-alignment-check.md](strategic-alignment-check.md) — what gets checked at kickoff
- [security-baseline-check.md](security-baseline-check.md) — what gets checked for security
- [quality-baseline-check.md](quality-baseline-check.md) — what gets checked for code quality
- [operational-readiness-check.md](operational-readiness-check.md) — what gets checked at pre-release
- [exceptions-and-waivers.md](exceptions-and-waivers.md) — when work doesn't fit
- [assets/pre-merge-review-checklist.md](../assets/pre-merge-review-checklist.md) — fillable checklist

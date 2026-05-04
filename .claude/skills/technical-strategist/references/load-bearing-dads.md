# Load-Bearing DADs

[team-lead](../../team-lead/SKILL.md) owns the DAD/ADR machinery — the format, the lifecycle, the index, the review process. This file is about a more specific question that lives in the strategist's domain: **which DADs are *load-bearing*** — the ones that, if violated, threaten the strategy itself — and which DADs are merely conventions that can drift without consequence?

The distinction matters because DADs accumulate. Over years, a project ends up with dozens of them: "we use Postgres," "we use OIDC for CI/CD," "we test with Jest," "we use Tailwind for styling," "we name our services with the `svc-` prefix." Some of those are critical; some are merely cosmetic. Treating them all the same loses both the critical ones (because they get drowned out) and the cosmetic ones (because the team treats them as bureaucracy).

The strategist's job is to **declare which DADs are load-bearing**, and to make sure those specific DADs are honored. Everything else can drift with no harm done.

## What "Load-Bearing" Means

A load-bearing DAD is one where **violating it materially threatens the strategy or the system's correctness**. Examples:

- **"Postgres for OLTP"** — load-bearing if your strategy depends on a single database technology for operational simplicity, schema migration tooling, backup/restore procedures, etc.
- **"All inter-service communication uses our event bus"** — load-bearing if the strategy is a distributed event-driven system; introducing direct HTTP calls undermines the architecture.
- **"All endpoints behind OIDC-authenticated gateway"** — load-bearing for security; deviating creates a real vulnerability.
- **"No new microservices without an ADR"** — load-bearing if you're trying to *consolidate* services; without this DAD, the team adds a new service every quarter and the consolidation fails.
- **"All migrations run before deploy"** — load-bearing for data integrity; violating it can corrupt production.

A non-load-bearing DAD is one where violating it is annoying but not strategically threatening:

- **"Service names start with `svc-`"** — purely cosmetic; one service named differently is a small inconsistency, not a strategic failure.
- **"Use 2-space indentation in YAML"** — cosmetic; auto-formatting handles it; no strategic impact.
- **"Slack reactions for PR approval"** — process convention; doesn't affect the system.
- **"Open PRs by EOD Thursday"** — workflow convention; small impact at most.

The test: **if this DAD were violated, would I, as the strategist, want to know about it and treat it as a problem?** If yes, it's load-bearing. If no, it isn't.

## Why the Distinction Matters

Two failure modes if you don't make the distinction:

### 1. All DADs treated as critical → bureaucracy

If every DAD violation is a problem, the team learns that everything is a problem, which means nothing is. They start ignoring the DAD index because too many entries are there. The critical DADs get lost in the noise.

The result: a project with 80 DADs, none of which the team can recite, none of which feel binding, all of which are technically violated by some part of the system. The DADs become decoration.

### 2. No DADs treated as critical → drift

The opposite failure: the team treats DADs as suggestions. The "Postgres for OLTP" DAD gets violated because someone really wanted to try MongoDB; nobody pushes back because the DAD wasn't explicitly load-bearing; six months later there are three databases in production and the strategy of "operational simplicity through one database" has quietly died.

The strategy collapsed not because anyone disagreed with it, but because no one defended its critical DADs.

The cure for both is **explicit labeling**. The DAD index marks which DADs are load-bearing. The team knows which ones to defend and which ones to let slide.

## Declaring a DAD as Load-Bearing

The strategist works with team-lead to mark DADs as load-bearing. The mechanism can be:

- **A field in the DAD frontmatter**: `load_bearing: true`
- **A separate index** maintained by the strategist: "load-bearing DADs as of 2026-Q2"
- **A naming convention**: `DAD-LOADBEARING-0042` vs. `DAD-CONVENTION-0043`
- **A category in the DAD index page**

The specific format doesn't matter; what matters is that *the team can tell which DADs are load-bearing without having to ask*.

When the strategist declares a DAD as load-bearing, they're committing to:

1. **Defending it** when it's challenged (and, if the challenge has merit, updating the strategy rather than letting the DAD silently die).
2. **Surfacing violations** as strategic problems, not just as ticket noise.
3. **Reviewing it periodically** to confirm it's still relevant.
4. **Routing exceptions** through the formal ADR process.

If the strategist isn't willing to do those things, the DAD probably shouldn't be marked as load-bearing.

## Selecting Which DADs Are Load-Bearing

The strategist's decision criteria:

### 1. Does the DAD encode a strategic choice?

A strategic choice is one that has long-term consequences and was made deliberately. "We use Postgres for OLTP" is strategic. "We indent YAML with 2 spaces" is not.

If the DAD reflects a *choice the team would make differently in different circumstances*, it's potentially strategic. If it reflects a *convention the team adopted because someone had to pick one*, it's probably not.

### 2. Would violating the DAD cost real money or risk?

A violation that produces an incident, a security exposure, a data loss, or a major refactor cost is a real strategic concern. A violation that produces "the codebase looks slightly inconsistent" is not.

A useful test: estimate the cost of remediation if the DAD is violated and not caught. If it's tens or hundreds of engineering hours, the DAD is load-bearing. If it's an hour with a linter, it isn't.

### 3. Does the DAD enable other DADs?

Some DADs are foundational: violating them invalidates a chain of other decisions. "All services use the same authentication library" might enable "single sign-on" which enables "session management" which enables "audit logging." Violating the foundation breaks the chain.

Foundational DADs are usually load-bearing.

### 4. Would the strategist want to be paged for a violation?

Most direct test. If a DAD is violated, would the strategist want to be told about it? If yes, load-bearing. If no, not.

(In practice, the strategist isn't *literally* paged — that's the standards-enforcer's job — but the question still works as a thought experiment.)

## How Many Load-Bearing DADs?

Ideally, **5-15** for a typical project or org. Fewer than 5 and the strategy isn't constraining enough; more than 15 and the team can't keep them all in mind.

If you find yourself with 30+ load-bearing DADs, something is wrong:

- **Maybe some of them aren't really load-bearing.** Re-evaluate which ones would actually threaten the strategy if violated.
- **Maybe the strategy is too broad.** A narrower strategy needs fewer load-bearing DADs.
- **Maybe several DADs should be merged.** A "we use Postgres for OLTP, ClickHouse for analytics, and Redis for caching" could be one DAD instead of three.

If you find yourself with fewer than 5, something is also wrong:

- **Maybe the team hasn't documented the load-bearing decisions yet.** They exist implicitly; document them.
- **Maybe the strategy is too vague.** A vague strategy doesn't produce specific commitments.

## A Worked Example

For a 30-engineer SaaS company, the load-bearing DADs might be:

1. **Postgres for all OLTP data.** Enables our backup, migration, replication, and operational runbooks.
2. **All public APIs go through our gateway with OIDC.** Enables our auth, audit, rate-limiting, and monitoring.
3. **All services run on ECS with our standard task template.** Enables our deployment, logging, and rollback machinery.
4. **All non-trivial async work goes through SQS, not in-process queues.** Enables visibility, retry, and dead-letter handling.
5. **All schema migrations run before deploy.** Required for zero-downtime deploys to work.
6. **All cross-service communication is async (events) by default, sync only when justified.** Enables our resilience strategy.
7. **All secrets in Secrets Manager, never in env vars or config files.** Enables rotation, audit, and compliance.
8. **All teams own a single bounded context end-to-end (code, ops, incidents).** Enables clear responsibility.
9. **No new programming languages without an ADR.** Limits the matrix of "languages × services" we have to operationally support.
10. **All payment-processing code is PCI-scoped and isolated.** Required by compliance.

Ten DADs. Each one corresponds to a real strategic choice. Each one would cost real engineering time to remediate if violated. Each one is something the strategist would want to know about.

The other 50 DADs in the project (testing conventions, naming conventions, code formatting, PR templates, etc.) are *real* DADs but not load-bearing. They're worth having, but the team can let them drift without strategic consequence.

## Reviewing Load-Bearing DADs

The list isn't static. Quarterly (or at strategy revision time):

- **Are any of these no longer relevant?** Maybe the team finished the migration that required the DAD; maybe the underlying technology has changed; maybe the situation that produced the DAD is gone.
- **Should any new DADs be promoted to load-bearing?** Sometimes a convention turns out to be more strategic than it looked when it was written.
- **Are any being violated silently?** Find out before the standards-enforcer surfaces it.
- **Are the descriptions still accurate?** The world changes; documentation drifts.

If a load-bearing DAD is no longer load-bearing, **demote it explicitly**. Don't quietly remove it; mark it as "previously load-bearing, now superseded by ADR-XX." History matters.

If a non-load-bearing DAD becomes load-bearing, **promote it explicitly** with rationale.

## Routing Through Standards-Enforcer

The strategist names the load-bearing DADs; the [standards-enforcer](../../standards-enforcer/SKILL.md) is the one that *checks* whether work conforms to them at gates. The relationship:

1. The strategist marks the load-bearing DADs.
2. The team-lead skill maintains them in the project's ADR/DAD index.
3. When a feature is reviewed (kickoff, PR, pre-release), the standards-enforcer pulls up the load-bearing DADs and checks the work against them.
4. If a violation is detected, the enforcer routes it back to either:
   - **Compliance**: bring the work into line with the DAD.
   - **Exception**: file an ADR justifying the deviation; the strategist reviews and approves or denies.

This is the loop. The strategist owns the *what*; the enforcer owns the *check*; team-lead owns the *machinery*.

## Anti-Patterns

- **All DADs treated equally.** Bureaucracy; the team can't remember which ones matter.
- **No load-bearing DADs.** No strategic constraint at the convention level; everything drifts.
- **Load-bearing DADs that are vague.** "We care about quality." Means nothing; can't be enforced.
- **Load-bearing DADs nobody reviews.** They go stale and get ignored.
- **Load-bearing DADs without rationale.** "We use Postgres" with no explanation. The team can't reason about whether to deviate.
- **Promoting/demoting without explanation.** History is lost; trust erodes.
- **Load-bearing DADs that don't get enforced.** The strategist marked them as critical but the standards-enforcer doesn't actually check them.
- **Load-bearing DADs that no one can violate** because the system enforces them automatically. (Then they don't need to be DADs; they're just code.)
- **Marking too many DADs as load-bearing.** Loss of focus; the team can't hold them all in mind.
- **Marking too few.** Loss of constraint; strategy drifts.
- **Strategist marks DADs as load-bearing without coordinating with team-lead.** The DAD index isn't updated; nobody else can find which DADs matter.

## Related

- [what-technical-strategy-is.md](what-technical-strategy-is.md) — the strategy that the load-bearing DADs encode
- [strategy-as-constraint.md](strategy-as-constraint.md) — why constraint matters
- [strategy-evolution.md](strategy-evolution.md) — promoting and demoting DADs over time
- [team-lead](../../team-lead/SKILL.md) — the DAD/ADR machinery
- [standards-enforcer](../../standards-enforcer/SKILL.md) — the skill that enforces load-bearing DADs at review gates
- [system-architect](../../system-architect/SKILL.md) — designs that operate within the load-bearing DADs

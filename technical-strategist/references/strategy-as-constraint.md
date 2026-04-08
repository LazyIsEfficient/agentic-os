# Strategy as Constraint

The most counterintuitive thing about strategy is that **good strategy makes the team's life easier, not harder**. The instinct is the opposite: strategy sounds like more work, more meetings, more documents, more rules. The reality is that good strategy *removes* work — by closing off arguments the team would otherwise have over and over.

This file is about the most important property of a real strategy: **it constrains**. A strategy that doesn't constrain anything isn't strategy. A strategy that does constrain things is doing the most valuable work a strategy can do.

## What Constraint Means

When a team has a clear strategy, certain conversations stop happening. The strategy answers the question before it gets asked.

Examples:

- **Without strategy:** "Should we use MongoDB for this new feature?" → meeting → debate → research → meeting → eventually a decision (sometimes wrong) → six months later, someone proposes MongoDB again because the original decision wasn't documented.
- **With strategy:** "Should we use MongoDB for this new feature?" → "Our strategy is committed to Postgres for OLTP and we have a DAD on it. The answer is no, unless you want to file an exception." → 30 seconds → conversation closed.

The team didn't have to think. The strategy thought for them. Multiplied across hundreds of decisions per year, this is enormous time savings.

This is what strategy is *for*. Not to look impressive in a deck. Not to satisfy auditors. To **pre-load the answers to recurring questions**, so the team can focus on the questions that don't have pre-loaded answers.

## The Cost of No Constraint

A team without a strategy isn't a team without rules — it's a team where every decision is made fresh, by whoever's in the room, with the loudest voice winning. The cost is invisible because it's spread across hundreds of small moments:

- An engineer debates whether to add a new dependency to the project. Spends 30 minutes. Decides yes.
- A second engineer debates the same question for a different feature. Spends 30 minutes. Decides no.
- A third engineer notices the inconsistency. Files a ticket asking for a "policy on dependencies." The ticket sits.
- Six months later, the project has 14 conflicting dependency choices. Refactoring is expensive.

The visible cost is the refactor. The invisible cost is the dozens of 30-minute debates. With strategy, none of those debates happen, because the answer is pre-loaded.

This is the dynamic that produces "design by committee" results: nobody has the authority to close the question, so the question stays open, and the answer is whatever was easiest to merge.

The strategy is the *authority* that closes recurring questions. Without it, every question is open, every time.

## What Constraint Looks Like in Practice

A strategy constrains by being explicit about *what is in* and *what is out*. Both halves are necessary.

### What is in (the affirmative)

> "Over the next 18 months, we will refactor the monolith into 3-5 services along bounded contexts that match team boundaries."

This commits the team to a direction. It's specific enough to inform daily decisions. It's general enough to leave room for the specific design work the architect will do.

### What is out (the non-goals)

> "We are *not* extracting analytics, billing, or admin in this period."
> "We are *not* introducing a new language."
> "We are *not* migrating to Kubernetes as part of this work."

This is where the strategy does its real work. Each of these prevents a class of conversations:

- **Not extracting analytics** → when someone proposes extracting analytics, the answer is "not in this round; that's next year." No debate; no research; no meeting.
- **Not introducing a new language** → when someone proposes Rust for the payments service, the answer is "no language changes this round." Saves the language-debate that would otherwise eat a week.
- **Not migrating to Kubernetes** → when someone proposes Kubernetes "while we're refactoring anyway," the answer is "no; that's a separate decision and not in this round."

Each "not" is more valuable than the corresponding "is." Anyone can list things to do; the discipline is listing things *not* to do.

A useful test: **read your strategy and circle the non-goals**. If the non-goals section is empty or vague, the strategy isn't constraining anything.

## The Discipline of Saying No

The reason strategy is hard isn't writing the document. It's making the choices. Every "not" closes off something a stakeholder wants. The strategist has to defend the no.

The defense is the strategy itself. "This isn't what we're doing this period because it doesn't fit the diagnosis: the constraint we're solving is X, and Y doesn't address X." The argument is grounded in the diagnosis. The diagnosis is the foundation.

Without a diagnosis, the no is just preference. With a diagnosis, the no is reasoned. The diagnosis is what gives the strategist the authority to close conversations.

This is why the diagnosis matters more than the actions. The actions are what people read; the diagnosis is what justifies the actions when challenged.

## Constraint vs. Restriction

There's a difference between **constraint** (a strategy that says "we are doing X and not Y, in service of being great at X") and **restriction** (a strategy that says "we are not doing Y, because rules"). Both close off Y, but they feel very different to the team:

- **Constraint** says "here's what we're investing in instead." It's positive; it explains the trade-off; the team can see the win.
- **Restriction** says "no, because rules." It's negative; it has no rationale; the team feels controlled.

A good strategy is full of constraints, not restrictions. The format:

> "We are *doing* X (with these specific actions). In service of being great at X, we are *not doing* Y, Z, or W."

The "not doing" is in service of the "doing." Each non-goal has a positive reason: we're not doing this *because we are doing that*. The team understands the trade-off; they can see what they're getting in exchange for what they're giving up.

A strategy of bare restrictions ("don't use MongoDB; don't add new languages; don't refactor without permission") is not strategy — it's bureaucracy. The team will ignore it.

## Constraint and the Team's Trust

Constraints work only if the team trusts the strategist's judgment. If the team thinks the constraints are arbitrary, they'll work around them. If they think the constraints are well-reasoned, they'll respect them.

Trust comes from:

- **Explaining the diagnosis.** Why these constraints? What's the situation that requires them?
- **Welcoming pushback.** When an engineer challenges the strategy, the strategist engages with the challenge. Sometimes the engineer is right; sometimes they're not; either way, the conversation strengthens trust.
- **Updating the strategy** when new evidence shows it's wrong. A strategist who never updates becomes a strategist who's right by fiat.
- **Applying constraints consistently.** Constraints that bind some teams and not others (or some projects and not others) destroy trust. Apply the same bar everywhere.
- **Making exceptions visible.** When a constraint gets waived, the waiver is documented and explained. Silent exceptions corrode trust faster than anything else.

Trust takes years to build and a quarter to lose. The strategist who burns trust on a single arbitrary decision spends the rest of the year recovering.

## Constraint at Different Levels

The strategy at each organizational level constrains the next:

- **Company-level strategy** ("we are a Postgres-and-Kubernetes shop") constrains org-level strategy ("our org will migrate off Mongo by Q3").
- **Org-level strategy** ("we will refactor the monolith into services") constrains team-level strategy ("our team will own the payments service extraction in Q2").
- **Team-level strategy** ("we will own payments and not introduce new tech debt") constrains daily decisions ("no, we're not adding GraphQL to the payments service").

When the levels are aligned, the team's life is easy: every decision has a chain of reasoning that traces up to the company strategy. When they're misaligned, the team is whipsawed between contradictory directives.

The strategist's job is to make sure the level they own is *consistent* with the level above and *constrains* the level below. Misalignment between levels is the most common organizational failure mode in large engineering orgs.

## When Constraints Don't Apply: Exceptions

Some decisions that violate the strategy turn out to be right. New information, a unique situation, an unexpected opportunity — the constraint that made sense in general doesn't make sense in this case.

**Exceptions are fine; silent deviations are not.** The discipline:

1. The team identifies that a piece of work violates the strategy.
2. They make the case for the exception in writing — what's the situation, why does the constraint not apply, what's the cost of the exception, what's the benefit.
3. The strategist (or the appropriate decision-maker) approves or denies.
4. If approved, the exception is documented as an ADR. The strategy itself may need to be updated.

This is the [team-lead](../../team-lead/SKILL.md) ADR machinery in service of the strategy. ADRs are for choices that *deviate* from the team's defaults; the strategy *is* the team's defaults.

The exception process is the safety valve. Without it, the strategy becomes either rigid (and gets bypassed silently) or weak (and gets ignored). With it, the strategy stays firm but flexible.

For the enforcer's view of this, see [standards-enforcer](../../standards-enforcer/SKILL.md).

## When the Constraint is Wrong

Sometimes the strategy is wrong. The diagnosis was off; the situation has changed; the actions aren't producing the expected results. What then?

**Update the strategy.** Don't defend a stale strategy out of stubbornness or sunk cost. The strategist's job is to be right *now*, not to be consistent with what they said six months ago.

But: **don't update too quickly**. A strategy that changes every month has no force. The team can't plan around it. Every revision is a small loss of trust.

The discipline: **revise on real evidence, not on opinion**. The strategy stays put when someone disagrees; it changes when the situation has measurably shifted. The strategist's judgment is what tells the difference.

For the workflow of revising a strategy, see [strategy-evolution.md](strategy-evolution.md).

## Anti-Patterns

- **Strategy with no non-goals.** Looks comprehensive; constrains nothing; everyone can find their pet project in there.
- **Strategy as restriction without rationale.** "Don't use MongoDB" with no explanation. The team works around it.
- **Strategy that nobody can challenge.** The strategist is right by fiat; the team stops engaging.
- **Strategy that nobody enforces.** The constraints exist on paper but the team violates them silently.
- **Strategy with no exception process.** The constraints become brittle; deviations happen invisibly.
- **Strategy with too many exceptions.** Every project gets an exception; the constraints are meaningless.
- **Strategy that's revised every week.** No force; team can't plan.
- **Strategy that's never revised.** Stale; ignored; corrosive.
- **Strategy that bind some teams and not others.** Unfair; corrodes trust.
- **Strategy that contradicts the level above.** Org strategy says X; team strategy says Y; team is whipsawed.
- **Strategy in someone's head.** Not written; impossible to apply.
- **Strategy as bureaucracy.** Long compliance forms; no one reads them; the team works around them.
- **Strategy that the strategist enforces with personal authority** rather than with the strategy itself. When the strategist leaves, the strategy collapses.

## Related

- [what-technical-strategy-is.md](what-technical-strategy-is.md) — the basic shape
- [load-bearing-dads.md](load-bearing-dads.md) — DADs as the constraint in daily clothing
- [strategy-evolution.md](strategy-evolution.md) — when and how to update
- [strategy-anti-patterns.md](strategy-anti-patterns.md) — the full catalog
- [standards-enforcer](../../standards-enforcer/SKILL.md) — the skill that *applies* the constraints to specific work
- [team-lead](../../team-lead/SKILL.md) — the ADR/DAD machinery that captures the constraints and exceptions

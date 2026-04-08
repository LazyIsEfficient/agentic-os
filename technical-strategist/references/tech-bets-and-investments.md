# Tech Bets and Investments

A technical strategy is built around **bets** — the things the team is investing in, with the expectation that they'll pay back over time. Picking the right bets is the core work of a technical strategist; picking the wrong ones (or picking too many) is how strategies fail.

This file is about the discipline of identifying, sizing, and committing to technical bets — and about the bets you should *decline* even when they're tempting.

## What a Technical Bet Is

A technical bet is a **deliberate, sized investment in a piece of technical work whose payoff comes over months or years**. Examples:

- Migrating from one database to another
- Refactoring a monolith into services
- Building an internal platform team
- Adopting a new language for a specific use case
- Investing in a CI/CD overhaul
- Replacing a third-party vendor with an in-house solution
- Building a feature flag system
- Standardizing on a single observability stack
- Migrating to a new cloud provider
- Building a design system

Each of these is a bet because:

1. **It costs significant engineering time up front** (often months).
2. **The payoff is uncertain** (it might not work; it might take longer than expected; it might not produce the expected benefit).
3. **It's hard to reverse** once started.
4. **It commits the team** to a direction for the foreseeable future.

A bet is *not* a feature ("ship the new login flow" — short, contained, reversible). A bet is *not* a bug fix. A bet is the kind of work that, when you take it, you're saying "this is what we're doing for the next quarter (or year)."

The strategist's job is to choose which bets to take and in what order. The architect, the engineers, and the various subsystem skills then *execute* the bets.

## Why Sizing Bets Matters

A team's engineering capacity is fixed. Every bet you take crowds out other bets and crowds out feature work. If you take too many bets, you ship none of them. If you take too few, you stagnate.

The discipline:

- **Bets are first-class roadmap items**, not background work.
- **Each bet has an explicit budget** in engineer-months or percentage of capacity.
- **Bets are committed to, not "if we have time."**
- **Bets are tracked separately** from the feature roadmap; otherwise they get squeezed.
- **A team usually has one big bet at a time**, plus possibly one or two smaller ones in parallel.

Teams that constantly start bets and never finish them are *anti*-strategic — they look busy but accomplish nothing lasting. The strategist's discipline is to **finish bets** before starting new ones.

## How to Size a Bet

Before committing to a bet, answer these questions in writing:

### 1. What's the problem?

Not the solution. The *problem*. What's the current pain that this bet would address? What evidence do we have that the pain is real and worth fixing?

If the answer is vague ("we want to be more modern"), the bet isn't ready. Real pain is specific:

> "Our deployment pipeline takes 90 minutes per release. Engineers are working around it by batching releases, which means production hits get bigger and rollbacks more painful. The team has flagged this as their top frustration in the last two surveys."

### 2. What's the desired outcome?

Not the deliverable. The *outcome*. What's different in the world after this bet pays off?

> "Engineers can ship a small fix to production in under 15 minutes. Release size shrinks to one logical change per deploy. Rollbacks become a one-click action."

The outcome is observable. You can tell whether the bet paid off by checking it.

### 3. What are the alternatives?

Almost every bet has alternatives. List them:

> "1. Rebuild our pipeline on GitHub Actions (the proposed bet).
> 2. Buy CircleCI Enterprise and migrate to it.
> 3. Invest in incremental improvements to the current Jenkins setup.
> 4. Do nothing; live with 90-minute deploys.
> 5. Adopt Buildkite as a hybrid (custom + managed)."

For each alternative, name *why it isn't the bet*. The non-chosen alternatives are as important as the chosen one — they show the strategist made a real choice.

### 4. What's the cost?

In engineer-months, dollar cost (vendors, infrastructure), opportunity cost (what else won't get done).

> "Estimated 4 engineer-months over 2 calendar months. Two engineers full-time, plus one part-time on training. Vendor cost: $0 (GitHub Actions is bundled with our existing GitHub plan). Opportunity cost: deprioritizes the analytics dashboard for Q3."

Cost estimates are usually wrong; the discipline is to *estimate honestly* and add buffer. A 4-month estimate often becomes 6 months in reality. Plan for that.

### 5. What's the success criteria?

How will we know the bet paid off? Specific, measurable, with a deadline.

> "Within 90 days of the new pipeline going live: median deploy time under 15 minutes. Rollback time under 60 seconds. Engineer survey shows pipeline is no longer in the top-5 frustrations. We will revisit at 90 days; if these criteria aren't met, we will reconsider the bet."

### 6. What's the kill criteria?

When would we stop the bet? Be explicit. Without kill criteria, bets become sunk-cost fallacies — you keep investing because you've already invested.

> "If after the first 30 days, the team has not been able to migrate even one service to the new pipeline, we stop and revisit. If GitHub Actions limitations make any of our existing workflows infeasible to migrate, we evaluate whether to live with the limitation or pivot to a different bet."

### 7. What's the risk?

What could go wrong? What's the cost if it does? What's the mitigation?

> "Risk: GitHub Actions doesn't support some of our matrix builds. Mitigation: validated in a 1-week spike before committing.
> Risk: team morale dips during the migration. Mitigation: assign a clear champion; communicate progress weekly.
> Risk: production deploys break during the switch. Mitigation: dual-pipeline period; keep Jenkins available as fallback."

These seven questions are the bet proposal. They go in writing. They're reviewed by the team and any relevant stakeholders. If the questions can't be answered well, the bet isn't ready to take.

For a fillable template, see [assets/tech-bet-proposal-template.md](../assets/tech-bet-proposal-template.md).

## Cost of Delay

A subtle but important question: **what's the cost of not doing this bet right now?**

Some bets get more expensive over time:

- **Migrations**: every new feature built on the old system is debt you'll have to migrate later. The longer you wait, the more there is to migrate.
- **Architecture changes**: every new service that follows the old pattern reinforces the old pattern. The longer you wait, the harder the refactor.
- **Security upgrades**: every day on the vulnerable version is a day at risk.
- **Tech-debt paydown**: the debt compounds.

Some bets *don't* get more expensive over time:

- **New features**: the cost is the same now or in three months.
- **Optional improvements**: tooling that's nice to have but not on a critical path.
- **Vendor switches**: the cost is roughly the same whenever you do it.

For bets with high cost-of-delay, the strategist's bias should be **start sooner**. For bets with low cost-of-delay, **wait until they fit naturally** alongside other work.

A useful heuristic: **if the bet's cost goes up by 10% per month of delay, you should be starting it now**. If it stays roughly flat, you can wait for the right moment.

## How Many Bets at Once

The single most common strategy failure: **too many bets at once**. The team is "working on" a database migration, a service refactor, a new CI system, a design system, and a multi-region deploy. None of them ship. None of them produce the expected benefit. The team burns out.

A useful default: **one big bet per team at a time**. A team of ~6 engineers can take on one major investment plus normal feature work. Two big bets in parallel usually means both get shorted; three guarantees failure.

For larger orgs:

- **Each team has its own one-big-bet at most.** Different teams can pursue different bets in parallel.
- **Org-level bets cross teams** and need explicit coordination. Don't mix org-level and team-level bets without acknowledging the conflict.

When the strategist is tempted to add a second concurrent bet, ask: **can we finish the first one first?** Almost always, the answer is "yes, if we don't add this." Add the second one to the queue, not to the active list.

## Sequencing Bets

Bets aren't independent. Often one bet enables (or requires) another. The strategist sequences them deliberately.

Common patterns:

- **Foundational first**: a CI/CD overhaul before a microservices extraction (because the extraction needs better deploys).
- **Risky first**: the bet you're least sure about goes first, so you find out early whether it'll work.
- **Highest cost-of-delay first**: the bet that's getting more expensive every month goes ahead of stable bets.
- **Easy wins first**: a quick win to build momentum and team trust before tackling a hard bet.

Each of these is a valid sequencing strategy depending on context. The strategist picks based on which constraint matters most: technical dependencies, risk tolerance, team morale, or stakeholder pressure.

## When a Bet Fails

Bets fail. The estimate was wrong; the technology didn't work; the team couldn't commit; the situation changed. Sunk cost is real but it's not a reason to keep going.

When a bet is failing:

1. **Acknowledge it** in writing. "We bet on X. Here's what happened. Here's what we learned."
2. **Make the call**: continue with adjustments, pivot to a different approach, or stop.
3. **Communicate the call** to the team and stakeholders.
4. **Update the strategy** if the failure invalidates it.
5. **Do a postmortem** — not blameful, but honest about what went wrong and what you'd do differently.

Failed bets are how teams learn. A team that never has a failed bet is either not taking enough risks or hiding the failures.

The discipline is to **be honest about failure** rather than spin it. Spinning a failed bet as a success destroys trust and prevents learning.

## Distinguishing Bets from Tactics

Sometimes a piece of work *looks* like a bet but isn't. Examples:

- **"We need to upgrade our Postgres version."** Bet or maintenance? It depends on scope. Routine upgrade = maintenance. Multi-quarter migration with breaking changes = bet.
- **"We need to fix the slow query."** Bet or bug? Bug, almost always. Don't dignify routine work as a strategic bet.
- **"We need to refactor module X."** Bet or technical debt cleanup? It depends on scope. A week of cleanup = tactical. A multi-month rework = bet.

A useful test: **does this work warrant a writeup in the strategy?** If yes, it's a bet. If no, it's normal engineering work and doesn't need the strategy treatment.

The reverse failure: **calling everything a "bet."** Then bets stop meaning anything; the team doesn't know which work to prioritize.

## When *Not* to Bet

Some situations call for *not* betting:

- **The team is in crisis.** Stabilize first; bet later.
- **The strategy isn't clear yet.** Don't take a bet that the strategy might invalidate next quarter.
- **The team is fragile** (heavy attrition, low morale, recent incidents). Bets require focus; the team can't focus on a bet right now.
- **The cost of being wrong is too high.** Some bets are existential; if they fail, the company fails. Don't take those without extreme deliberation.
- **A simpler tactical fix would work for now.** Don't make a strategic bet when a tactical fix is enough.

The opposite failure: **never betting**. A team that only does tactical work and never invests in itself becomes outdated, slow, and frustrated. The strategist's job is to push for bets when it's time, not just to evaluate bets that others propose.

## Tracking Bets

Bets in progress need their own tracking, separate from the feature roadmap:

- **Status**: not started / in progress / paused / completed / abandoned
- **Owner**: the person responsible for the bet
- **Capacity allocation**: how much engineering time
- **Milestones**: not features, but progress markers
- **Risks**: current concerns
- **Next decision**: when the next go/no-go check is

Quarterly, the strategist reviews the active bets:

- **What's progressing?**
- **What's stalled?**
- **What's failed?**
- **What should we stop?**

Bets that haven't moved in 90 days are usually dead; declare them so explicitly.

## Anti-Patterns

- **Too many bets at once.** None of them ship.
- **No explicit bets at all.** "We just do feature work." Stagnation.
- **Bets with no kill criteria.** Sunk cost fallacy; bets continue past the point of usefulness.
- **Bets without writeups.** Nobody can remember why the bet was taken or what success looked like.
- **Bets that masquerade as features.** Buried in the roadmap; never get the attention they need.
- **Bets without a champion.** Owned by "the team" or by "leadership"; nobody actually drives them.
- **Bets that nobody finishes.** Started, paused, started again, pivoted, eventually forgotten.
- **Bets sized by gut instead of by writeup.** "It'll take a few weeks." It always takes longer.
- **Bets on the latest technology** without an honest assessment of whether the team can adopt it.
- **Bets on what other companies are doing.** Cargo cult; usually wrong for your context.
- **Bets nobody ever revisits.** "We made the call last year." Yes, but is it still right?
- **Bets that don't tie back to the strategy.** Random investments; produce no compound benefit.
- **Bets without a postmortem when they fail.** No learning; same mistakes next time.

## Related

- [what-technical-strategy-is.md](what-technical-strategy-is.md) — bets are the action half of a strategy
- [build-vs-buy-vs-adopt.md](build-vs-buy-vs-adopt.md) — common bet shape
- [platform-vs-product.md](platform-vs-product.md) — platform investments are bets
- [strategy-evolution.md](strategy-evolution.md) — when bets change the strategy
- [technical-product-management/references/prioritization.md](../../technical-product-management/references/prioritization.md) — TPM-side prioritization
- [system-architect](../../system-architect/SKILL.md) — designs that implement the bets
- [team-lead](../../team-lead/SKILL.md) — bets often produce ADRs
- [assets/tech-bet-proposal-template.md](../assets/tech-bet-proposal-template.md) — fillable template

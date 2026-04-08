# What Technical Strategy Is

The phrase "technical strategy" gets used to mean many different things. Engineers use it to mean architecture; managers use it to mean roadmap; consultants use it to mean a slide deck. None of those is wrong exactly, but none of them is what a technical strategy *should* be either.

This file is about getting the definition right, so the rest of the skill has solid ground.

## The Definition

A technical strategy is **a written document that names the team's diagnosis of its current technical situation, the chosen technical direction in response, the actions that follow from the direction, and the things the team is explicitly not doing**.

It is *not* an architecture diagram. It is *not* a list of technologies. It is *not* a roadmap. It is *not* a set of values. It is *not* a forecast. Each of those is a useful thing in its own right, but none of them is a strategy.

The structure (borrowed directly from Richard Rumelt's *Good Strategy / Bad Strategy*, applied to the technical side):

1. **Diagnosis** — a clear-eyed description of the current technical situation. What's happening, what's the constraint, what's the *one* thing that matters most right now.
2. **Guiding policy** — the chosen approach in response to the diagnosis. Not a goal, not a metric — a *direction*.
3. **Coherent actions** — the specific things the team is doing (and not doing) that follow from the policy. They reinforce each other; they don't contradict.

A document that has these three things, in order, is a technical strategy. A document that has goals, OKRs, and a roadmap but not these three things is *not* a strategy — it's a plan, which is a different (and lesser) thing.

## A Worked Example

The diagnosis:

> Our backend is a Rails monolith built in 2018. It serves about 4,000 requests/second at peak. Engineering velocity has dropped sharply over the past year: PRs that touched cross-cutting code took an average of 14 days to merge in Q1, up from 4 days a year ago. Three of our most experienced engineers have flagged the monolith as the reason. The product team is asking for features that require schema changes that touch tables shared by multiple unrelated systems, and every such change requires coordination across 4 teams. Cause: the monolith has accumulated implicit coupling that makes any change risky. The constraint is not technology choice or team size; it is the lack of bounded contexts inside the codebase.

The guiding policy:

> Over the next 18 months, we will refactor the monolith into 3-5 services along the bounded contexts that match our team boundaries. We will not rewrite the monolith from scratch; we will use the strangler fig pattern to extract services one at a time. Each extracted service must be independently deployable, owned by exactly one team, and free of database-level coupling to the monolith.

The coherent actions:

> 1. Q2: extract the **payments** service. Owner: Payments team. Success criteria: payments runs in its own deploy pipeline; no shared database access; the monolith calls payments via HTTP.
> 2. Q3: extract the **notifications** service. Owner: Platform team. Same criteria.
> 3. Q4: extract the **search** service. Owner: Discovery team. Same criteria.
> 4. We will *not* extract analytics, billing, or admin in this period — those are next-year decisions.
> 5. We will *not* introduce a new language; all extracted services are Rails to keep team continuity.
> 6. We will *not* migrate to Kubernetes as part of this; the existing ECS deployment continues to work.
> 7. We will pause new shared-database schema changes; any new schema goes into one service's owned database only.
> 8. We will allocate 25% of engineering capacity to this work for the duration; the rest is product features.

Notice what's in this strategy:

- **A diagnosis grounded in evidence** (PR turnaround times, engineer feedback, the specific cross-cutting pain).
- **A guiding policy that names the approach** (refactor into services along bounded contexts) and rejects the alternatives (no rewrite, no language change, no Kubernetes migration).
- **A small number of specific actions** with clear owners and success criteria.
- **Explicit non-goals** (analytics, billing, admin not in this round; no Kubernetes; no new language).
- **A budget** (25% of engineering capacity).

A strategy of this shape is *useful*. The team can use it to make day-to-day decisions: "Should we add a feature to admin?" — the strategy says admin isn't in this round, so the answer is "yes, but not as part of the extraction work, and don't introduce new shared-database coupling." That's the value of strategy: pre-loaded answers to recurring questions.

## What a Strategy Is *Not*

### Not architecture

An architecture diagram shows *what the system looks like*. A strategy says *what direction the system is moving in, why, and what the team is investing*. They're related — the strategy informs the architecture, and the architecture might change in service of the strategy — but they're different artifacts.

You can have a beautiful architecture diagram and no strategy (the architecture exists but nobody knows where it's going). You can have a strong strategy and no architecture diagram (the direction is clear; the specific designs come later). The strategy is the higher-level artifact.

### Not a roadmap

A roadmap lists *the work the team plans to do*, in rough sequence. A strategy is the *reasoning* behind the roadmap. The strategy explains why this work and not other work; the roadmap lists the work itself.

A team with a roadmap and no strategy can ship things, but it can't explain why these things instead of others. A team with a strategy and no roadmap knows where it's going but hasn't translated that into specific work yet. Both are needed; they're different.

### Not a vision

A vision is the long-term aspiration: "we will be the most reliable database in the world." Strategy is *how* you get there: what you're doing this year and next, in service of the vision.

Vision is a few sentences and changes every few years. Strategy is a few pages and changes every few quarters. Don't confuse them.

### Not a set of values

"Move fast." "Ship quality." "Customer first." These are values. They're slogans, not constraints. They don't tell anyone what to do tomorrow.

A strategy contains *constraints* and *trade-offs*. "We will optimize for time-to-first-value over feature breadth this year" is a real trade-off. "We are customer-first" is a slogan.

### Not a forecast

"We will reach $50M ARR by 2027" is a goal, not a strategy. The strategy is *how* you get to $50M — what you'll do, what you'll invest in, what you'll cut.

Goals and strategies are different things; you can have a goal without a strategy and you can have a strategy without a goal. They serve different purposes.

### Not a quote

"Strategy is what Steve Jobs would do." Quoting famous founders isn't strategy work. The famous founder had a different situation; their strategy was for their problem; copying it doesn't address yours.

### Not a tool list

"We use React, Postgres, AWS, Kubernetes, and Datadog." That's a tool list. It might *follow* from the strategy, but it isn't the strategy itself. The strategy is *why* these tools and not others.

## The Three Levels of Technical Strategy

In a real organization, technical strategy exists at multiple levels:

| Level | Owner | Time horizon | Example |
|---|---|---|---|
| **Company-wide** | CTO / VP Eng | 2-5 years | "We are a Postgres-and-Kubernetes shop. We invest in our own platform tooling. We don't run more than two languages in production." |
| **Org-wide** (an entire eng org) | VP / Director | 1-2 years | "Over the next 18 months, we will refactor the monolith into services along team boundaries." |
| **Team-level** | Team lead / staff engineer | 6-12 months | "Our team will own the payments service. We will migrate off the legacy gateway by Q3. We won't introduce new feature flags this quarter." |

Each level should *narrow* the level above. The team-level strategy operates within the org-level strategy, which operates within the company-level strategy. When they conflict, the team is whipsawed.

For most engineering teams, the team-level strategy is the most actionable. The company-level strategy is too abstract to inform Tuesday's PR; the team-level strategy *is* what the team uses to decide whether to take on a piece of work.

## Where the Strategy Comes From

A strategy isn't invented from nothing. It synthesizes several inputs:

1. **The current state of the technical system.** What does the architecture look like? Where are the bottlenecks? What's the tech debt?
2. **The product strategy.** What is the team trying to enable for users? Where is the company going?
3. **The team's capacity.** How many engineers? What are their skills? What's their morale?
4. **The constraints.** Budget, time, regulatory environment, prior commitments.
5. **The market and competition.** What's the technical landscape? What's worth investing in?
6. **The history.** What has the team tried? What worked? What didn't?

The strategist's job is to **synthesize these inputs into one coherent direction**. This is hard work; it requires conversations with engineers, product, leadership, and a real understanding of the codebase. It's not something you do at a whiteboard in an hour.

## How Long a Strategy Should Be

**One to five pages.** That's it.

A 30-page technical strategy is hiding from the discipline of choosing. The point of strategy is to *narrow*, and a long strategy hasn't narrowed yet. If you can't say it in five pages, you don't yet have it.

The five-page version contains:

- **Diagnosis** (one paragraph; maybe two)
- **Guiding policy** (one paragraph)
- **Coherent actions** (a list of 5-10 items, each with owner and success criteria)
- **Non-goals** (a list of 3-7 items, each with one-line rationale)
- **Kill criteria** (what would make us change course)
- **Capacity allocation** (how much engineering time is committed to this)
- **Communication plan** (who hears about this, when)

The one-page version is even tighter. It's a stretch goal: if you can fit the strategy on one page and it still feels real, the strategy is sharp.

## Strategy as Conversation, Not Document

The document is the artifact, but the *real* strategy is the shared understanding the team has about where they're going. The document is necessary because shared understanding evaporates without it. But the document alone is not enough.

A useful test: **can every senior engineer on the team articulate the strategy in one sentence, in their own words?** If yes, the strategy is real. If no, the document is decorative.

Practices that build shared understanding:

- **Walk through the strategy in a meeting** when it's drafted. Take questions. Iterate.
- **Cite the strategy in design reviews.** "This work serves part 2 of the strategy."
- **Update the strategy visibly** when it changes. Don't quietly edit.
- **Refer to it when saying no.** "This doesn't fit our current strategy because X."
- **Debrief on it quarterly.** Did the actions move us in the direction the strategy named?

A strategy that's never referenced after it's written isn't real. A strategy that's referenced in every other meeting is real and is doing its job.

## Common Failures Worth Naming Up Front

(The full anti-patterns list is in [strategy-anti-patterns.md](strategy-anti-patterns.md). A preview here for things that come up immediately.)

- **Strategy as wishlist.** "We will improve performance, ship faster, retain users, expand markets, and reduce costs." Constrains nothing.
- **Strategy as forecast.** "We will be at 99.99% uptime in 2027." That's a target, not a strategy.
- **Strategy as architecture.** A diagram with no explanation of *why*.
- **Strategy as values.** "Move fast and don't break things." Slogans.
- **Strategy that's never revised.** Two years later, the team still cites a doc that no longer matches reality.
- **Secret strategy.** Leadership has it in their heads; the team makes contradictory bets.
- **Strategy for the deck, not the team.** Optimized for what looks good in the executive review.

The discipline is to name the trap and avoid it. Each requires its own correction; they're covered in [strategy-anti-patterns.md](strategy-anti-patterns.md).

## Anti-Patterns

- **Calling everything "strategy."** Architecture, roadmap, vision, goals — all distinct.
- **Strategy without diagnosis.** A list of actions with no rationale; the team can't reason about whether the actions still apply when the situation changes.
- **Strategy without non-goals.** Looks comprehensive; constrains nothing; teams reading it can each find their own pet feature in there.
- **Strategy that's longer than it is sharp.** A 30-page document is hiding from the discipline of choosing.
- **Strategy that nobody wrote down.** Lives in leadership's heads; team can't act on it.
- **Strategy that never references the product strategy.** Technical work without a product reason is engineering for engineering's sake.
- **Strategy that ignores team capacity.** "We will rewrite the monolith *and* ship every quarter's roadmap *and* migrate to Kubernetes *and* adopt a new language." Fantasy.
- **Strategy that gets a review meeting and is never referenced again.** Decoration.
- **Strategy that's secretly aspiration.** The "strategy" document describes a world that doesn't exist; the team operates in the real world; the gap goes unmentioned.
- **Strategy by analogy.** "We're the X of Y." Sometimes useful as a rallying cry; usually a substitute for thinking about your actual situation.

## Related

- [strategy-as-constraint.md](strategy-as-constraint.md) — the value of saying no
- [strategy-anti-patterns.md](strategy-anti-patterns.md) — the full catalog of failure modes
- [strategy-evolution.md](strategy-evolution.md) — how to change a strategy when reality changes
- [strategy-communication.md](strategy-communication.md) — making the strategy land with the team
- [technical-product-management/references/product-strategy.md](../../technical-product-management/references/product-strategy.md) — product strategy uses the same shape; the technical strategy serves it
- [system-architect](../../system-architect/SKILL.md) — the architecture that implements the strategy at the system level
- [team-lead](../../team-lead/SKILL.md) — DADs and ADRs as the strategy in everyday clothing

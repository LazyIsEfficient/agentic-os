# Strategy Anti-Patterns

A catalogue of the most common ways technical strategy goes wrong. Each pattern is real, observable, and recoverable. The point of naming them is to recognize them in your own work and your team's so they can be addressed.

The other reference files in this skill have anti-pattern sections specific to their topic. This file collects the *cross-cutting* patterns — the failure modes that can corrupt any strategy regardless of its specific content.

## Strategy as Wishlist

**The pattern:** the "strategy" lists everything the team wants to do. Improve performance, ship faster, retain users, expand markets, modernize the stack, reduce costs, increase reliability. Each item is reasonable; the combination commits to nothing.

**Why it happens:**

- The strategist wants to please every stakeholder.
- Saying no is hard; saying yes to everything feels safer.
- Leadership wants comprehensive coverage and rejects "narrow" strategies.

**Why it's bad:**

- The team can't choose between two competing initiatives because both serve the "strategy."
- Engineering capacity is fixed; the wishlist describes 3x the work the team can actually do.
- Six months later, the team has dabbled in everything and finished nothing.

**The fix:**

- **Force a top-3.** The strategy commits to no more than three concurrent themes.
- **Explicit non-goals.** Name what's *not* in the strategy, not just what is.
- **Push back on stakeholders** when they want their pet item added. Bring them to the trade-off conversation.

## Strategy as Forecast

**The pattern:** the "strategy" is a goal or target. "We will reach 99.99% uptime by Q4." "We will be on Postgres 17 by year end." These are *targets*, not strategies. They tell you nothing about *how*.

**Why it happens:**

- The strategist confuses goals with strategy.
- OKRs and goals are easier to write than strategy; teams substitute the easier work.
- Leadership asks "what's the strategy?" and gets "here's our goal" in response.

**Why it's bad:**

- The team can't act on a goal. They can act on a strategy.
- When the goal isn't met, there's no diagnosis to learn from.
- The work has no through-line; it's just whatever the team thinks might move the metric.

**The fix:**

- **Strategy answers "how," not "what."** Once you have a goal, the strategy says how you'll get there.
- **Goals and strategy are different artifacts.** Both are valid; don't confuse them.
- **Diagnose before prescribing.** A strategy starts with a description of the situation, not with a target.

## Strategy as Architecture

**The pattern:** the "strategy" is an architecture diagram. Boxes and arrows showing the system the team wants to build. Looks impressive; constrains nothing about what the team does today.

**Why it happens:**

- Engineers think visually; diagrams are appealing.
- Architecture is concrete; strategy is abstract; concrete feels more useful.
- The strategist (or the architect) spent the work on the diagram and forgot the strategy.

**Why it's bad:**

- An architecture diagram doesn't say *why* the boxes are arranged that way.
- It doesn't say what the team is *not* doing.
- It doesn't say *when* the boxes happen.
- It doesn't say what trade-offs were made.
- It can't be evaluated for whether it's working.

**The fix:**

- **Architecture is a result of strategy, not a substitute for it.** The strategy explains why the architecture is what it is.
- **Pair with the architect.** Strategy and architecture serve each other; the strategist doesn't draw the architecture, but the strategy informs it.
- **Always include the diagnosis and the rejected alternatives.** The strategy is *more than* the architecture.

## Strategy as Values

**The pattern:** the "strategy" is a list of principles. "Move fast." "Ship quality." "Customer first." "Engineering excellence." Each is a slogan; none constrains anything.

**Why it happens:**

- Values are easier to write than strategy.
- Companies confuse their cultural values with their strategic direction.
- The strategist can't bring themselves to make hard choices, so they fall back to principles everyone agrees with.

**Why it's bad:**

- Every company in the world claims these values; they don't differentiate.
- Two engineers with the same values can disagree completely on a specific decision; the values don't resolve the disagreement.
- The team can't tell what to do tomorrow based on "move fast."

**The fix:**

- **Strategy names the trade-off**, not the value. "We will optimize for time-to-first-value over feature breadth this year" is a real trade-off. "Customer first" is a slogan.
- **Values belong in a separate document** (the team's culture deck or onboarding doc). Don't mix them with strategy.
- **Test each strategy statement** with "what does this rule out?" If the answer is "nothing," it's a slogan.

## Strategy by Quote

**The pattern:** the "strategy" cites famous CEOs and engineering leaders. "Steve Jobs would have said..." "DHH believes..." "Werner Vogels argues..." Quotes substitute for thinking.

**Why it happens:**

- The strategist is unsure of their own judgment and seeks authority by association.
- Reading other people's strategies is easier than writing your own.
- Quotes feel substantive without requiring commitment.

**Why it's bad:**

- The famous person was solving a different problem in a different context.
- Different gurus give different advice; quoting selectively is just confirmation bias.
- The team can't act on a quote; they need a decision.
- The strategist's actual judgment doesn't develop.

**The fix:**

- **Read widely, but make your own arguments.** "I think we should X because Y, in our specific situation."
- **Cite the principle, not the person.** A principle stands or falls on its own merits.
- **Be willing to disagree with the gurus.** They're often wrong about your specific context.

## Strategy Without Diagnosis

**The pattern:** the "strategy" is a list of actions with no explanation of why. "We will ship a mobile app, expand to enterprise, and build an API." No context, no rationale.

**Why it happens:**

- The strategist skipped the hard work of diagnosing the situation.
- The actions came from leadership demands or stakeholder requests, not from analysis.
- The strategist confuses "actions" with "strategy."

**Why it's bad:**

- The team can't reason about whether the actions still apply when the situation changes.
- New team members can't tell why the strategy is what it is.
- The strategy can't be evaluated; you can't tell if the diagnosis was right because there isn't one.

**The fix:**

- **Lead with the diagnosis.** Spend real time on what's happening and what the constraint is.
- **The actions should follow obviously from the diagnosis.** If they don't, either the diagnosis is wrong or the actions don't fit.
- **The diagnosis grounds the strategy.** Without it, the strategy is preference.

## Strategy That Ignores Constraints

**The pattern:** the "strategy" describes an ambitious plan that ignores team capacity, budget, time, or technical reality. "We will rewrite the monolith *and* ship every quarter's features *and* migrate to Kubernetes *and* adopt a new language."

**Why it happens:**

- Wishful thinking.
- The strategist isn't close enough to the team to know what they can sustain.
- Leadership pressure to be ambitious.
- The strategist is afraid to be the bearer of "we can't do that."

**Why it's bad:**

- The strategy is fantasy. The team can't execute it.
- The team's morale collapses as they fall behind on the impossible plan.
- The trust in the strategist (and in strategy in general) is destroyed.

**The fix:**

- **Honest constraint accounting.** What's the actual engineering capacity? What's already committed? What's the realistic free capacity?
- **Three things, not ten.** A strategy that picks three big bets is achievable. A strategy that picks ten is fantasy.
- **The strategist talks to the team** before drafting. The team knows what they can sustain.
- **Prefer cuts to additions.** When the strategy is too big, cut something.

## Strategy Never Revised

**The pattern:** the "strategy" was written 18 months ago. The team still references it. The world has changed; the strategy hasn't.

**Why it happens:**

- The strategist moved on, was promoted, or got busy.
- The team is conservative about updates; "we said we would do this."
- Updating the strategy feels like admitting failure.

**Why it's bad:**

- The strategy stops describing reality.
- The team makes decisions by individual judgment because they no longer trust the strategy.
- New evidence doesn't make it into the strategy.
- The strategy quietly dies.

**The fix:**

- **Quarterly review.** A standing meeting where the strategy is revisited.
- **Explicit revision** when something material changes (a major launch, a new constraint, a postmortem).
- **Mark what changed.** Don't quietly edit; surface the change so the team sees it.
- **Be willing to say "the strategy was wrong."** It's a sign of a healthy strategist, not a weak one.

## Secret Strategy

**The pattern:** leadership has a strategy in their heads. They can't or won't write it down. The team makes contradictory decisions because they're guessing at the strategy.

**Why it happens:**

- Leadership feels the strategy is "obvious."
- Leadership is too busy to write it.
- Leadership wants flexibility and resists committing in writing.
- Sometimes: leadership has no strategy and is hiding the fact.

**Why it's bad:**

- The team can't act on what they can't read.
- Different team members guess differently and produce contradictory work.
- Leadership later complains that the team isn't aligned, while never having articulated what to align on.

**The fix:**

- **Force the writeup.** The strategist's job is to extract the strategy from leadership's head and put it in writing.
- **Iterate.** First drafts are wrong; that's fine. The act of writing reveals where leadership doesn't actually have a clear position.
- **If leadership genuinely has no strategy, surface that.** Better to know the team is operating without one than to pretend there's one in someone's head.

## Strategy as Performance Art

**The pattern:** a 40-slide deck with consultant-grade visuals, presented at the all-hands, shared with the board, and never referenced in any actual decision. The strategy exists for the audience, not for the team.

**Why it happens:**

- Strategy presentations get applause; strategy implementation doesn't.
- The strategist is rewarded for the deck, not for the outcomes.
- Leadership loves visual decks.
- The strategist is more comfortable presenting than implementing.

**Why it's bad:**

- The team's daily decisions don't reflect the deck.
- The deck and the reality drift apart.
- Strategy work gets a bad name; the team learns to ignore it.

**The fix:**

- **Optimize for the team's daily decisions, not for the deck.** A one-pager that the team uses beats a 40-slide deck nobody references.
- **Track whether the strategy is being applied.** If decisions aren't citing it, the strategy isn't real.
- **Stop optimizing for the audience.** Write for the team.

## Strategy by Analogy

**The pattern:** the "strategy" is "we're the X of Y." "We're the Stripe of healthcare." "We're the Notion of databases."

**Why it happens:**

- Analogies are catchy and memorable.
- They give a sense of direction without requiring detail.
- They're easier than thinking about the specific situation.

**Why it's bad:**

- The analogy almost always breaks down. Your situation is *not* the same as Stripe's or Notion's.
- The team uses the analogy as a substitute for thinking. "Would Stripe do this?" instead of "should we do this?"
- Important differences get hand-waved away.

**The fix:**

- **Use analogies to start the conversation, not to end it.** "We have something in common with Stripe in that we're both API-first; here's where we differ."
- **Always ground the strategy in your actual situation.** What's your diagnosis? What's your team's capacity? What's your competitive context?
- **Be skeptical of "we're the X of Y" framings.** They sound substantive and usually aren't.

## Strategy That's Longer Than It Is Sharp

**The pattern:** the "strategy" is a 30-page document with detailed analyses, market overviews, technology surveys, references, and appendices. Looks comprehensive; doesn't constrain anything.

**Why it happens:**

- Length feels like rigor. It isn't.
- The strategist hides from the discipline of choosing by writing more.
- Stakeholders demand "thoroughness."

**Why it's bad:**

- Nobody reads the document.
- The actual strategic content is buried in 30 pages of supporting material.
- The team can't recite the strategy because it's too long.
- The strategist confuses writing with thinking.

**The fix:**

- **Force a one-page version.** If you can't fit it on one page, you don't yet know what you're saying.
- **Move supporting material to appendices** or to separate documents. The strategy itself is short.
- **Test by reading aloud.** A strategy you can read in 5 minutes is the right size; a strategy that takes an hour is too long.

## Strategy That the Strategist Enforces Personally

**The pattern:** the strategy is real and the team follows it — but only because the strategist personally challenges every PR that violates it. The strategy isn't sustained by the team's understanding; it's sustained by the strategist's authority.

**Why it happens:**

- The strategist is a strong personality.
- The team is small enough that the strategist can review everything.
- Nobody else has internalized the strategy.

**Why it's bad:**

- When the strategist leaves (or gets busy, or burns out), the strategy collapses immediately.
- The team learns to avoid the strategist rather than to align with the strategy.
- The strategy becomes "what makes the strategist happy" rather than a real shared direction.

**The fix:**

- **The strategy must work without the strategist in the room.** Write it down so others can apply it.
- **Empower other engineers to enforce it.** The standards-enforcer skill is exactly this layer.
- **Test by leaving the office.** If the strategy holds when you're on vacation, it's real. If it falls apart, it isn't.

## Strategy That Contradicts the Level Above

**The pattern:** the team-level strategy says X; the org-level strategy says Y; the company strategy says Z. The team is whipsawed.

**Why it happens:**

- Strategy at different levels is set independently.
- The strategist doesn't read the upper-level strategies before drafting.
- Levels were set at different times; reality has shifted.

**Why it's bad:**

- The team gets contradictory directives.
- Decisions become political (whose direction wins?) instead of strategic.
- Trust in strategy in general collapses.

**The fix:**

- **Read the upper-level strategies first.** Your strategy operates within them.
- **Surface contradictions explicitly.** "Our team's strategy needs to deviate from the org strategy because X. Here's why."
- **Negotiate alignment** when contradictions are real. Don't ship a contradictory strategy and hope no one notices.

## Strategy That Has No Connection to the Product Strategy

**The pattern:** the technical strategy describes what the team will build technically, but doesn't connect to *why* — what business outcome or product direction it serves. Engineering for engineering's sake.

**Why it happens:**

- The technical strategist isn't talking to product.
- The strategist values technical aesthetics over business impact.
- The product strategy is unclear and the technical strategist filled the gap with their own preferences.

**Why it's bad:**

- The work doesn't move the product forward.
- Leadership eventually notices and cuts the engineering investment.
- Engineers feel they're building things nobody asked for.
- The product team feels engineering is going its own way.

**The fix:**

- **Every technical strategy should have a "what this enables for product" section.** Specific outcomes, not vague "we'll be faster."
- **Pair with the TPM constantly.** The two strategies should serve each other.
- **If the product strategy is unclear**, surface that as a problem to solve before drafting the technical strategy.

## Related

- [what-technical-strategy-is.md](what-technical-strategy-is.md) — the basic shape
- [strategy-as-constraint.md](strategy-as-constraint.md) — what real strategy does
- [strategy-evolution.md](strategy-evolution.md) — when and how to update
- [strategy-communication.md](strategy-communication.md) — making strategy land
- [technical-product-management/references/pm-anti-patterns.md](../../technical-product-management/references/pm-anti-patterns.md) — many parallels
- [standards-enforcer](../../standards-enforcer/SKILL.md) — applies the strategy at gates

# Product Strategy

Strategy is the most-talked-about and least-understood word in product management. Most "strategy" documents are wishlists with bullet points; most "strategy meetings" are status updates with extra slides. Real strategy is rarer and more uncomfortable.

The reason it's uncomfortable: strategy is *what you say no to*. A document that lists everything the team wants to do and calls it "strategy" is a wishlist; a document that lists what the team is *not* doing, and *why*, is strategy.

This file is the playbook for thinking about, writing, and defending real product strategy.

## What Strategy Actually Is

Richard Rumelt's *Good Strategy / Bad Strategy* is the cleanest treatment of this topic. His three-part definition is unusually useful:

A strategy has three parts:

1. **A diagnosis.** A clear-eyed description of the situation — what's actually happening, what's the real problem, what's the *one critical thing* that matters most. Most strategy fails at this step because the team confuses many problems with one core problem.
2. **A guiding policy.** The approach you've chosen to address the diagnosis. Not a goal, not a metric — a *direction*. "We will compete on the depth of our integrations, not on the breadth of our feature set." That's a policy.
3. **Coherent actions.** The specific things you're doing (and not doing) that follow from the policy. They reinforce each other; they don't contradict.

A document that has these three things, in order, is a strategy. A document that has goals, OKRs, and a roadmap but not these three things is *not* a strategy — it's a plan, which is a different (and lesser) thing.

## Vision vs Strategy vs Roadmap

A common confusion. The three words mean different things and live at different time horizons.

| Term | What it is | Time horizon | Changes how often |
|---|---|---|---|
| **Vision** | The aspirational long-term state — what the world looks like if you succeed. Inspirational, durable. | 5–10 years | Rarely (every few years) |
| **Strategy** | How you intend to get to the vision — the diagnosis + guiding policy + actions. Constraining, opinionated. | 1–3 years | Quarterly to yearly |
| **Roadmap** | The specific things you plan to ship in service of the strategy, in rough sequence. Tactical, time-bound. | Quarter to a year | Continuously |

The mistakes:

- **Vision as strategy.** "We will be the leader in X." Doesn't tell the team what to do tomorrow.
- **Roadmap as strategy.** "Here's a list of features we're building." Doesn't tell the team why these features and not others.
- **Strategy as vision.** "Our strategy is to delight customers." Vague enough to be unfalsifiable; constrains nothing.

A useful test: if you removed your strategy and put in a competitor's strategy, would your team's day-to-day work change? If no, you don't have a strategy.

## Strategy as Constraint

The most counterintuitive thing about strategy: **good strategy makes the team's life easier, not harder**, because it tells them what they don't have to think about.

A team with no strategy has to evaluate every opportunity from scratch. "Should we build X?" requires re-arguing the same questions every time: who is this for? Is it on-mission? How does it compare to other ideas? Without a strategy, every decision is a fresh fight.

A team with a clear strategy has most of those answers pre-loaded:

- "Should we build X?"
- "Does it serve our diagnosis? Does it follow from our guiding policy? Does it reinforce our other actions?"
- "...not really."
- "Then no. Next."

Real strategy short-circuits the meeting. Bad strategy *adds* a meeting.

This is why "strategy as constraint" is the right frame. The strategy says "we are *not* doing this whole class of things, in service of being great at this *narrower* class of things." A team that can articulate what's outside the strategy has a strategy. A team that can't doesn't.

## Where Strategy Comes From

Strategy is downstream of several inputs. A useful sequence:

1. **The mission and vision** — the long-term aspiration. Why this company exists, what world it's trying to create.
2. **The market and the competition** — what's actually true about the space. Where are the open lanes? Who else is in them? What advantages do you have?
3. **The customer** — what do real users actually need? Where is the pain? What's the underserved job?
4. **The team and the organization** — what can you actually do? What's your engineering capacity? What's your design strength? What's your distribution?
5. **The constraints** — money, time, regulatory environment, technical debt, prior commitments.

A strategy synthesizes all five into one direction. A strategy that ignores the team's actual capacity ("we will outbuild every competitor") is fantasy. A strategy that ignores the customer ("we will optimize internally") is hubris. A strategy that ignores the market ("we will be the best, regardless of what others do") is naive.

The PM's job is not to invent strategy from nothing — it's to surface the relevant inputs, connect them, articulate the constraint, and pressure-test the result.

## Levels of Strategy

A real org has nested strategy at multiple levels. From outermost to innermost:

| Level | Owns | Time horizon |
|---|---|---|
| **Company strategy** | Markets, products, M&A, fundraising | Multi-year |
| **Product strategy** | Which products, which customers, what differentiation | 1–3 years |
| **Product line / area strategy** | Which problems within a product, in what order | 6–18 months |
| **Quarterly themes** | The 2–4 outcomes the team is going after this quarter | 3 months |
| **Initiative strategy** | How a specific initiative will achieve its outcome | Weeks to months |

Each level should *narrow* the level above. The product strategy should be a coherent subset of the company strategy. The quarterly themes should be a coherent subset of the product strategy. When they don't line up, the team is working against itself.

A common failure: the company strategy says one thing, the product strategy says something else, and the quarterly plan says a third. The team is whipsawed; nothing aligns; nothing ships well.

## Writing a Strategy Document

A real strategy document is short — almost always a one- to three-pager. The length is the point: if you can't say it in three pages, you don't yet have it.

A useful structure:

### The Diagnosis (one paragraph)

> What's the situation we're in? What's the *one* most important thing happening? What's the critical challenge or opportunity? Be specific. Avoid bromides.

Example:

> "Our users — small B2B teams of 5–20 — adopt the product easily but churn within 90 days because the value compounds slowly and the first three weeks feel like setup work. Our competitors have shipped onboarding flows that get users to value in days, not weeks. The fight is no longer about features; it's about time-to-value."

### The Guiding Policy (one paragraph)

> What's our chosen approach? Not a goal, not a metric — a *direction*. What are we *doing differently* in response to the diagnosis?

Example:

> "We will reorient the product around getting new teams to a meaningful first outcome within seven days. Every roadmap decision this year will be evaluated against this lens. Features that help with month 3+ are deprioritized; features that compress time-to-value are accelerated."

### The Coherent Actions (one paragraph or a short list)

> What specific things follow from the guiding policy? What are we doing? What are we *not* doing? How do these actions reinforce each other?

Example:

> "We will (1) ship a new onboarding flow with a guided first project in Q2, (2) build a templates library so users can start from working examples, (3) instrument time-to-first-value as our north star metric, (4) pause work on the advanced reporting features until time-to-value targets are hit, and (5) say no to enterprise feature requests for the year."

Notice the *not doing* in #4 and #5. That's where strategy lives.

### What This Means for the Team (a few bullets)

> What changes for product, design, engineering, and adjacent teams as a result?

### What Would Make Us Wrong

> What would we observe that should make us reconsider this strategy? What's the kill criterion?

This last section is the most overlooked and the most important. A strategy with no kill criterion is not falsifiable and therefore not a strategy. Naming the conditions under which you'd abandon the strategy *now* prevents you from defending a stale strategy *later*.

### Total length

3–5 paragraphs of substance. Maybe a one-page diagram. That's it. Long strategies are hiding from the discipline of choosing.

## Common Strategy Failures

### Strategy as wishlist

> "Our strategy is to grow revenue, delight users, expand into new markets, ship faster, and improve retention."

This says nothing. None of it constrains anything. The team can't choose between two competing initiatives because both serve the "strategy."

The fix: a strategy that names *one* dominant lens. The other things still matter, but the strategy makes them subordinate to the chosen one.

### Strategy as forecast

> "Our strategy is to reach $50M ARR by 2027."

This is a *goal*, not a strategy. It tells you nothing about *how*. You can have a goal without a strategy, and you can have a strategy without a goal — they're different.

The fix: separate the goal (the target) from the strategy (the approach to reaching the target).

### Strategy as values

> "Our strategy is to be customer-obsessed, move fast, and ship quality."

These are values (or principles, or platitudes). They don't say what you'll do that competitors won't. Every company in the world claims these values; they don't differentiate or constrain.

The fix: name the *trade-off* you're making. "We will optimize for customer trust over feature velocity" is a real trade-off. "We will be customer-obsessed" is a slogan.

### Strategy as competitive copy

> "Our strategy is to do what Competitor X does, but better."

This abdicates the diagnosis. You haven't said what *your* situation is or what *you* should do. You've outsourced your strategy to a competitor whose situation is different from yours.

The fix: do the diagnosis from your own situation. The right move for a fast-follower can be very different from the right move for a market leader.

### Strategy without diagnosis

> "Our strategy is to ship a mobile app, expand to enterprise, and build an API."

Three actions, no rationale. Why these and not other things? What problem do they solve? Without the diagnosis, the actions are just a list.

The fix: lead with the diagnosis. The actions should follow obviously from it.

### Strategy that ignores constraints

> "Our strategy is to outbuild every competitor across every dimension."

You don't have the team for this. You don't have the budget for this. The strategy ignores reality.

The fix: a strategy that respects what you can actually do. Hard choices follow from honest constraint.

### Strategy that's never revised

A strategy from 18 months ago that the team still references but no longer believes. Decisions get made by individual judgment because nobody trusts the strategy anymore. It dies slowly.

The fix: revisit the strategy quarterly. Confirm it still reflects the situation. Revise when the diagnosis changes.

### Strategy as performance art

A 40-slide deck with consultant-grade visuals, presented at the all-hands, shared with the board, and never referenced in any actual decision. The strategy was for the audience, not for the team.

The fix: a one-page strategy that the team can recite and that informs daily choices. If nobody can repeat it, it doesn't exist.

### "We have a strategy; we just don't share it"

The leadership team has a strategy in their heads. They can't or won't write it down. The team makes contradictory decisions because they're guessing at the strategy. Velocity drops; trust erodes.

The fix: write it down. The act of writing forces the team to confront whether the strategy is real or just a vibe.

## When Strategy Is Worth the Effort

Strategy is hard work. It's also overkill for some situations.

| Situation | Strategy effort |
|---|---|
| 0→1 startup, single product, founder-led | Vision + short product strategy. Don't over-formalize. |
| Early growth, finding product-market fit | Strategy that's revisited *constantly* as the team learns. The strategy is a hypothesis. |
| Scaling, multiple teams, multiple products | Real strategy at multiple levels. Necessary to align teams. |
| Mature, slow-growing | Strategy as discipline against drift. The hard part is not building; it's choosing what *not* to build. |
| Turnaround / pivot | Aggressive strategy work. The team is making big bets; the bets need rationale. |

A startup with one team and three engineers doesn't need a 12-page strategy doc. A 200-person org with three product lines does.

## How a TPM Uses Strategy

Even if you didn't write the strategy, you live inside it. Practical uses:

- **Filter incoming requests.** "Does this serve the strategy?" If no, deflect. If yes, prioritize against other yes-items.
- **Defend your roadmap.** "We chose these things because they serve the strategy." Citing strategy is more durable than citing opinion.
- **Push back on stakeholders.** "I hear the request, but it doesn't fit our strategy. Here's the strategy. If we should change the strategy, that's a different conversation." Routes the discussion productively.
- **Justify saying no.** Saying no to a powerful stakeholder is much easier when you can point at the strategy as the reason.
- **Inform sequencing.** When two features are both "yes," the strategy often tells you which is more central.
- **Surface contradictions.** When you find that the strategy doesn't actually answer a question, that's information — escalate to whoever owns the strategy and get clarity.

A PM who can't articulate the strategy in one sentence isn't ready to make prioritization decisions inside it. A PM who can articulate it makes those decisions much faster.

## Anti-Patterns

- **Strategy as wishlist.** No constraint; no choice.
- **Strategy as forecast.** Goal masquerading as strategy.
- **Strategy as values.** Slogans, not direction.
- **Strategy without diagnosis.** Actions without rationale.
- **Strategy that ignores constraints.** Wishful thinking.
- **Strategy never revised.** Stale, ignored, eventually corrosive.
- **Strategy as performance art.** Decks for stakeholders, not direction for the team.
- **"Secret" strategy.** Leaders know it; team doesn't; team makes contradictory bets.
- **Strategy by quote.** Citing famous CEOs as if quoting them counted as strategy work.
- **Strategy by analogy.** "We're the X of Y." Sometimes useful; often a substitute for thinking about your actual situation.
- **Strategy that's longer than it is sharp.** A 30-page strategy is hiding from the discipline of choosing.

## Related

- [prioritization.md](prioritization.md) — strategy informs prioritization; without one, prioritization is preference
- [roadmapping.md](roadmapping.md) — the roadmap is the strategy in calendar form
- [saying-no.md](saying-no.md) — strategy is the source of authority for the no
- [stakeholder-management.md](stakeholder-management.md) — communicating strategy across audiences
- [system-architect](../../system-architect/SKILL.md) — technical strategy and product strategy must reinforce each other

# Prioritization

Prioritization is the daily work of product management. Strategy says what direction to point in; prioritization says what to do *next*. The two are different decisions and require different tools.

The thing most teams misunderstand: **prioritization is not about evaluating ideas in isolation**. It's about *comparing them against each other and against the cost of doing nothing*. An idea that scores 85/100 in isolation is uninformative; the right question is "how does it compare to the other idea that scored 80, and how does it compare to leaving the time unspent on either?"

This file is the playbook for prioritizing well — including the parts where prioritization frameworks fail and what to do instead.

## What Prioritization Is For

Prioritization answers three different questions, often confused:

1. **Sequencing** — given that we're doing both A and B, which should we do first?
2. **Selection** — given that we have capacity for one of A or B but not both, which should we choose?
3. **Inclusion** — should A even be on the list?

Most prioritization frameworks address #1 and #2 well and #3 badly. The single most important PM call is usually #3 — "no, that doesn't belong on the list at all" — and frameworks that try to score every idea on a uniform scale obscure rather than clarify it.

A useful sequence: **filter aggressively first** (saying no to half the ideas), *then* prioritize what survives.

## The Filter Step

Before applying any framework, run incoming ideas through these gates:

1. **Does it serve the strategy?** If no, deflect. (See [product-strategy.md](product-strategy.md) and [saying-no.md](saying-no.md).)
2. **Is the problem real?** Has anyone validated that users actually have this problem, or is it a guess? Guesses go to discovery, not to the roadmap.
3. **Does the team have any way to know if it worked?** If the success criterion is "we'll know when we see it," it doesn't go on the roadmap. Define success first.
4. **Is the cost knowable?** Engineering can give a rough estimate. If the work is so vague that no estimate is possible, it's not ready.
5. **What does it displace?** If you say yes to this, what falls off the list? If the answer is "nothing," you're not making a prioritization decision — you're growing scope.

Anything that fails any of these gates goes back. The remaining items are the ones worth prioritizing against each other.

This filter step is more impactful than any framework you apply afterward. **Most teams don't filter; they try to score everything**. The result is a backlog of 200 items, none of which are well-understood, all of which are "important," none of which can be confidently chosen against the others.

## Frameworks (and Their Limits)

Prioritization frameworks are useful as *thinking aids*, not as scoring rubrics. The numbers they produce are not real; they reflect the inputs the team chose. The value is in the conversation the framework forces, not in the score.

### RICE (Reach × Impact × Confidence ÷ Effort)

Probably the most-used framework. Score each item on:

- **Reach:** how many users will this affect in a defined period? (e.g. "users per quarter")
- **Impact:** how much will it move the metric for each affected user? (often a 0.25–3 scale: minimal / low / medium / high / massive)
- **Confidence:** how sure are you of the above numbers? (50% / 80% / 100%)
- **Effort:** how many person-months will this take?

Then `RICE = (Reach × Impact × Confidence) / Effort`.

**What it's good for:** comparing relatively similar items where the inputs are reasonably knowable, in a context where the team has shared definitions of "impact" and "effort."

**What it's bad for:** comparing items of very different shapes (a quick fix vs. a multi-quarter platform investment), or items where reach and impact are deeply uncertain (most strategic bets). The "confidence" multiplier doesn't actually fix this — it just makes the false precision feel more honest.

**The trap:** RICE produces a number, and humans treat numbers as authoritative. The team starts arguing about whether something is impact 2 or impact 3, and the conversation drifts away from the underlying question. The number is not the answer; the conversation is the answer.

### MoSCoW (Must / Should / Could / Won't)

Sort items into four buckets:

- **Must have** — required for the release; can't ship without it
- **Should have** — important but not vital; would hurt to leave out
- **Could have** — nice to have; included if there's room
- **Won't have** — explicitly excluded from this release

**What it's good for:** scoping a defined release with a fixed deadline; aligning a team on what's in and what's out; communicating with stakeholders about what to expect.

**What it's bad for:** the steady-state work of an ongoing team. There's no "release" to scope against, so everything migrates to "must" over time and the framework loses meaning.

**The trap:** "must have" is the only meaningful bucket; the others are aspirational. After a few cycles, the team learns that "should" and "could" never get built, and they start labeling everything "must" to ensure inclusion.

The "won't have" bucket is the most important and the most underused. Naming what's *out* is harder than naming what's in.

### ICE (Impact × Confidence × Ease)

A simpler cousin of RICE. Score each item 1–10 on impact, confidence, and ease; multiply.

**What it's good for:** lightweight prioritization in a small team; quick triage of a long list.

**What it's bad for:** the same problems as RICE, with even less rigor. The 1–10 scale is arbitrary; teams disagree systematically on what a 7 means.

### Cost of Delay / Weighted Shortest Job First (WSJF)

Common in SAFe and Lean Product Development. Score each item by the *cost of delaying it* (urgency, time-sensitivity, opportunity cost) divided by the *job size*. Items with high cost-of-delay and small size go first.

**What it's good for:** time-sensitive items where the value of doing it now is clearly different from doing it later. Particularly useful when the team is debating "should we do the small urgent thing or the big strategic thing?"

**What it's bad for:** strategic work where "delay" is hard to quantify. The cost of delaying a foundational platform investment is real but uncomputable.

### Opportunity scoring (Outcome-Driven Innovation)

Survey users about *desired outcomes* (e.g. "minimize the time it takes to handle a returned item") and ask them to rate each on **importance** and **current satisfaction**. Score each opportunity as `importance + max(0, importance − satisfaction)`. High scores are high-importance, low-satisfaction outcomes — the team's biggest opportunities.

**What it's good for:** B2B and enterprise contexts where you can survey a clear segment and where outcomes are stable. Generates a *prioritization input* grounded in real customer evidence rather than internal opinion.

**What it's bad for:** consumer products where outcomes are harder to articulate, or contexts where the survey effort is disproportionate to the prioritization decision.

### The Eisenhower Matrix (Important / Urgent)

Four quadrants:

- **Important and urgent** — do now
- **Important and not urgent** — schedule
- **Not important and urgent** — minimize / delegate
- **Not important and not urgent** — drop

**What it's good for:** triaging incoming requests as a team lead or PM; cleaning out a noisy backlog.

**What it's bad for:** comparing two important-and-not-urgent items against each other. Most strategic product work lives in that quadrant; the matrix doesn't help you choose within it.

**The most useful insight from the matrix:** "important and urgent" is usually a sign of a planning failure upstream. Things become urgent because they were ignored when they were merely important. A team that's constantly in firefighting mode has a prioritization problem, not a velocity problem.

## Why Most Frameworks Fail

A list of the failure modes shared by most prioritization frameworks:

### False precision

The framework produces a number; the team treats the number as objective. But the inputs (impact = 3, effort = 5) are subjective estimates. Multiplying subjective estimates produces false confidence: the score *looks* rigorous but encodes the same biases the team had before they started scoring.

### Confirmation bias in scoring

The team enters scores that support the conclusion they already favored. The PM wants to ship feature X; X conveniently scores 87; the framework "validates" the choice. The framework didn't surface anything; it laundered preference.

### The score-first habit

Teams reach for the framework before they've defined what they're trying to achieve. They score 50 items, then realize the scores don't help because nobody agrees on the goal. The conversation should start with "what are we trying to do this quarter?" — not "let's score everything."

### Apples vs oranges

The framework compares items of fundamentally different shapes. A two-day bug fix scored alongside a six-month platform migration produces a meaningless ranking. The right move is to *separate* the two streams of work, not combine them into one ranking.

### Strategic blindness

The framework scores items in isolation. An item that scores 50 might be the one that unlocks the next three items, each of which would score 80. The framework can't see this. Only strategy can.

### The democracy trap

Everyone on the team scores everything. The result is a kind of average that nobody actually believes. Real prioritization is opinionated; averaging opinions strips out the strongest signals.

## What to Do Instead (or Alongside)

Several practices that work better than scoring frameworks:

### Compare against the best alternative

Instead of asking "is this idea good?", ask **"is this idea better than the best other thing we could do this week?"** This forces honest comparison rather than abstract scoring.

If the answer is "yes, much better," the choice is clear. If the answer is "kinda better, I think," the answer is *not yet* — keep both alive and decide later when you know more.

### "What would we stop doing?"

Whenever someone proposes adding something to the roadmap, ask: **"if we say yes to this, what comes off?"**

The team always has a fixed amount of capacity. Adding without subtracting is not prioritization — it's growing the backlog. Forcing the displacement question makes the trade-off real.

If the answer is "nothing, we'll just do more," the roadmap is already too big and the team is going to burn out.

### Bets, not commitments

Frame prioritized work as *bets*: "We are betting that doing X this quarter will produce outcome Y. We will know within Z weeks." Bets are inherently uncertain and explicitly revisable.

This changes the conversation from "this is what we will do" to "this is what we're trying," which is more honest and more durable. When the bet doesn't pay off, you don't have to defend a stale plan — you have a result to learn from.

### Outcomes, not features

Prioritize *outcomes*, not *features*. "Increase activation rate from X% to Y%" is an outcome; "build a new onboarding flow" is a feature. The outcome is durable; the feature is one possible way to achieve it.

When the team prioritizes outcomes, they're free to discover that the right way to hit the outcome isn't the feature they originally imagined. When they prioritize features, they ship the feature whether or not it produces the outcome.

### One thing at a time

A team that's working on six "top priorities" is working on zero priorities. Real prioritization narrows. The strongest move you can make is sometimes "this is the *one thing* we're focused on this month; everything else waits."

### Working backward from the outcome

Start from the outcome you want at the end of the quarter, then work backward to identify the smallest set of work that gets you there. This is the opposite of "list everything we might do, then prioritize." It produces shorter lists with sharper rationale.

### The 70/20/10 split

Default split for a team's capacity:

- **70% on the core work** — the strategic bets the quarter is built around
- **20% on adjacent improvements** — the things that aren't strategic but are clearly valuable
- **10% on the unknown** — bug fixes, support escalations, things that come up

This is a *guideline*, not a law. Adjust based on context. The point is to acknowledge that the team isn't 100% predictable and to plan for it explicitly, rather than over-committing and then constantly slipping.

## Prioritization Conversations With Stakeholders

Prioritization isn't a calculation; it's a negotiation. The PM's job is to lead the negotiation honestly.

### When a stakeholder insists their thing is critical

Don't argue about whether it's critical. Ask:

- "What outcome are you trying to achieve?"
- "What does success look like?"
- "What's the cost of delay — what happens if we don't do this for another month?"
- "What would you have us stop doing to make room?"

The last question is where the conversation becomes real. Most "critical" things stop feeling critical when the stakeholder has to choose what gets dropped.

### When leadership pushes a feature

Treat it as data, not a directive. Leadership has context the team doesn't (customer conversations, board pressure, competitive intel). Take the input seriously. But push back if it doesn't fit the strategy:

- "I hear it. Help me understand the customer or business context behind it."
- "How does this fit with our current strategy of `<X>`?"
- "If we're changing the strategy, that's a separate conversation worth having."

Sometimes leadership is right and the team should pivot. Sometimes leadership is reacting to the loudest customer of the week. Your job is to distinguish.

### When sales / customer success bring requests

Sales teams hear customer pain in real-time and bring it back. Their requests deserve serious attention but rarely deserve to override strategy.

Process:

- **Aggregate** the requests. One angry customer is anecdote; ten angry customers about the same thing is a signal.
- **Connect** to the strategy. "These five requests are all about `<X>`; that's exactly what our strategy says we're not doing this year. Here's why."
- **Push back** when sales tries to make a one-customer commitment into a roadmap item. "This is a deal-specific request; let's not generalize it into the product yet."
- **Respect** the input by closing the loop. Tell sales what happened. They'll bring better-quality input if they trust you to listen.

### When engineering raises technical debt

Engineering knows about code health in a way the PM never will. When they say "this needs to be addressed," default to listening. Ask:

- "What happens if we don't?"
- "What's the cost of delay?"
- "What does the fix look like? How big?"

Then make the trade-off explicit: "We can do feature X or pay down debt Y. Here's the cost of either side."

A PM who reflexively deprioritizes tech debt will eventually have a team that can't ship anything because the debt has compounded. A PM who reflexively prioritizes it will never ship features. The right answer is "some of both, on a deliberate cadence" — a fraction of every cycle reserved for engineering health, not negotiated case by case.

## Anti-Patterns

- **Scoring everything.** Long lists, false precision, no actual choices.
- **Frameworks as decision-makers.** Treating the score as the answer instead of a thinking aid.
- **Adding without subtracting.** Saying yes to new work without naming what comes off.
- **The "high priority" everything.** When everything is critical, nothing is.
- **Roadmap as wishlist.** Listing what the team would ideally do, not what it will do.
- **Sequencing without filtering.** Spending an hour debating order on items that shouldn't be on the list.
- **HiPPO** (Highest Paid Person's Opinion). Whoever's in the room with the most authority gets their way regardless of evidence.
- **Squeaky wheel.** The loudest stakeholder gets prioritized; the rest get ignored.
- **Prioritization theater.** Workshop, sticky notes, dot-voting — all as performance, not as decision.
- **Confirmation-bias scoring.** Inputs chosen to support the answer the PM already wanted.
- **One-time prioritization.** Done once at the start of the quarter, never revisited as new info arrives.
- **No way to say no.** The PM who can't refuse anything turns into a router; the team becomes a feature factory.
- **"Important and urgent" everywhere.** The team is always firefighting because they never make time for "important and not urgent."
- **No reservation for engineering health.** Every cycle, debt is "next quarter." It is never next quarter.

## Related

- [product-strategy.md](product-strategy.md) — prioritization is downstream of strategy; without strategy, prioritization is preference
- [roadmapping.md](roadmapping.md) — prioritization produces the roadmap
- [saying-no.md](saying-no.md) — prioritization decisions are usually "no" decisions
- [working-with-engineering.md](working-with-engineering.md) — eng input is essential to prioritization
- [stakeholder-management.md](stakeholder-management.md) — prioritization is a multi-stakeholder negotiation
- [team-lead](../../team-lead/SKILL.md) — prioritization decisions become tickets and DADs

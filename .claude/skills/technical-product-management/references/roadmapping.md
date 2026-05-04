# Roadmapping

A roadmap is the visible artifact of the team's strategy and prioritization, expressed in time. It tells the team what they're doing next; it tells stakeholders what to expect; it tells leadership where the bets are. Done well, it aligns everyone on direction without overcommitting on details. Done badly, it becomes a hostage to its own promises.

The most important property of a good roadmap is something most teams get wrong: **a roadmap is a hypothesis, not a commitment**. The roadmap reflects what the team currently believes is the right next set of work *given what they know now*. As they learn more, the roadmap should change. A team that defends a stale roadmap because "we said we would" is doing PM theater.

This file is the playbook for building, communicating, and revising roadmaps that actually work.

## What a Roadmap Is For

A roadmap serves three audiences, with three different needs:

1. **The team** — what are we doing next, and how does today's work fit?
2. **Stakeholders inside the company** — sales, support, marketing, leadership, adjacent teams. They need to know what to expect so they can do their jobs.
3. **Customers and the outside world** (sometimes) — what's coming. Often a watered-down version with explicit "subject to change" framing.

These three audiences want different things, which is why one roadmap document rarely serves all three well. The team wants detail; leadership wants confidence; customers want commitment. **A useful default: build the team's roadmap first, then derive the others from it.**

## Horizons: Now / Next / Later

The single most useful roadmap format for an iterative product team is **now / next / later**. Three columns, no specific dates:

| Now | Next | Later |
|---|---|---|
| What we're actively building this quarter / month | What we expect to start when we finish "now" | Things on the strategic radar but not committed to a time |

What's good about this format:

- **No false precision.** Stakeholders don't see "Q4 2026" and treat it as a contract.
- **Flexible.** Items can move between columns as the team learns. This is *expected*, not a slip.
- **Outcome-friendly.** Each column can hold outcomes, not features.
- **Honest about uncertainty.** "Later" explicitly means "we don't know yet." Most "Q4 2026" plans don't actually know either; they just pretend.

What it doesn't do well:

- **Date-dependent commitments.** If marketing needs a hard launch date for a campaign, "later" doesn't help.
- **Cross-team coordination.** When two teams need to ship in sync, vague horizons don't align them.

For these cases, you supplement now/next/later with specific, narrow date commitments — and you treat *those* with the rigor of real commitments.

## Themes vs Features

A theme is an *outcome* the team is going after; a feature is one possible *means* of achieving it.

A roadmap of themes is more durable than a roadmap of features:

| Theme-based roadmap | Feature-based roadmap |
|---|---|
| "Reduce time-to-first-value for new teams" | "Ship new onboarding flow" |
| "Increase retention of free-tier users" | "Build the engagement digest email" |
| "Enable enterprise admin controls" | "Build SSO + audit log + role permissions" |

When the team prioritizes themes, they're free to discover during build that the feature they imagined isn't the right one. They ship something else that hits the same outcome. The theme survives; the feature is just one bet on how to achieve it.

When the team prioritizes features, they ship the feature whether or not it produces the outcome. Six months later they discover the feature didn't move the metric and they ship another feature, and another. Feature factory.

**Default: roadmap themes; track features as the current bet inside each theme.** When the team decides to swap features, the roadmap updates without needing a stakeholder battle.

The exception: when you're shipping a *known thing* with predictable scope (a migration, a regulatory requirement, an integration with a specific partner), feature-based items are fine. The discovery is done; the build is the work.

## Confidence Levels

Not all items on a roadmap deserve the same confidence. Make the confidence visible:

| Confidence | Meaning |
|---|---|
| **High** | We've validated the problem, sized the work, and committed to shipping. ~90% likely to ship in the time horizon. |
| **Medium** | We're confident in the direction but the specifics are still emerging. May change shape during build. ~70%. |
| **Low** | We think this is the right area to invest, but we haven't yet validated. Could shift entirely. ~50%. |
| **Exploring** | We're investigating whether this is even the right thing to do. Not committed at all. |

A roadmap that mixes these confidences without labeling them sets stakeholders up for disappointment. Marking them honestly *increases* trust in the long run, even though it feels like undercommitting in the moment.

## Sequencing and Dependencies

A roadmap with no sequencing logic is a wishlist. Real sequencing thinks about:

### Dependencies

- **A blocks B** — A must ship before B can start.
- **A unlocks B** — A doesn't strictly block B, but doing A makes B much cheaper.
- **A and B compete** — A and B both need the same scarce resource (a person, an environment, a key engineer).
- **A and B reinforce** — shipping them close together produces more value than shipping them apart.

The PM's job is to map these out *before* committing to sequence, not during build when surprises hurt.

### Risk loading

The riskiest items go first. If something has a real chance of failing or surprising the team, you want to find out early. Putting risky items at the end of the quarter means you discover the failure when there's no time left to recover.

A useful heuristic: **the first item on the roadmap should be the one whose failure would most change the rest of the roadmap.** If item 1 doesn't work, the team needs to know early enough to re-plan everything else.

### Energy management

Long, grinding work is exhausting. Quick wins are energizing. A roadmap that's nothing but six-month epics burns the team out; a roadmap that's nothing but two-day fixes never moves the needle.

Mix. The team needs both — visible progress on big bets *and* small wins that ship and feel good.

### Compound effects

Some items unlock the next several items. A platform investment that lets the team ship features 2x faster is worth more than its individual score. Conversely, a feature that creates ongoing maintenance load is worth less than its individual score.

The framework can't see this. The PM has to.

## Roadmap Format Choices

Different formats fit different contexts. A few common ones:

### Now / Next / Later

(Described above.) The default for iterative teams. Best for internal use.

### Quarterly themes

A list of 2–4 themes per quarter, each with the bets being made and the success criteria. No dates within the quarter.

- **Best for:** organizations that plan in quarters; communicating to leadership.
- **Risk:** rigidity. The team locks in for three months and resists revising.

### Outcome roadmaps

Organized around the business outcomes the team is trying to influence (activation, retention, expansion, etc.) instead of around features or themes.

- **Best for:** teams with clear business outcomes; growth-stage products.
- **Risk:** outcomes can be too abstract to inform daily work.

### Gantt charts

Time on the X axis, items on the Y axis, bars showing duration.

- **Best for:** projects with hard dependencies and fixed deadlines (regulatory work, hardware launches, marketing campaigns).
- **Risk:** the format implies precision that almost never exists for product work; treated as commitment.

### Story maps

Vertical: user journey steps. Horizontal: depth (MVP / nice-to-have / future). Items are sticky notes in the matrix.

- **Best for:** scoping a single product or major feature; aligning around a user journey.
- **Risk:** doesn't scale to multi-product teams; not great for cross-team coordination.

### Bet-based roadmaps (Shape Up-influenced)

Each item is a *bet* with a fixed time budget (e.g. 6 weeks) and a clear shaping doc. The team commits to the bet, not to a specific deliverable; if the time runs out, the work either ships or stops.

- **Best for:** teams that want to avoid scope creep and indefinite project drift.
- **Risk:** the format requires discipline to enforce the time budget; many teams break it under pressure.

There's no single "right" format. Pick one that fits your team's cadence, audience, and tolerance for change. And **be willing to change formats** when one stops serving you.

## What NOT to Put on a Roadmap

A roadmap is signal-to-noise sensitive. Each item dilutes the rest. Things that don't belong:

- **Wishful thinking** — items the team would *like* to do but won't actually have time for. They never ship; they crowd out real items.
- **Sales commitments** — one-customer requests promised in a deal. These are sales contracts, not roadmap items. Track them separately.
- **Bug fixes** — except for major ones with strategic implications. Routine bugs go to the regular maintenance budget, not the roadmap.
- **Vague aspirations** — "improve performance," "make it faster." Either it's a specific outcome with a target, or it's not roadmap-shaped.
- **Marketing announcements** — what the marketing team will *say* about a thing. The roadmap is what the team will *build*; marketing can derive their plan from it.
- **Things you've already shipped** — no, the roadmap is forward-looking. The shipped log is a different artifact.

## Communicating the Roadmap

The roadmap document is necessary but not sufficient. The communication around it matters more than the artifact itself.

### To the team

- **Walk through it in a meeting**, with rationale. The team should be able to explain *why* each item is on the list, not just what it is.
- **Update it visibly when it changes.** A roadmap that updates silently is one that nobody trusts.
- **Tie weekly work back to it.** "This sprint we're working on `<X>`, which is part of the `<Y>` theme." Keeps the connection alive.
- **Welcome challenges from the team.** The team often spots problems with the plan before the PM does. A team that can challenge the roadmap improves it.

### To stakeholders inside the company

- **Use a shorter, less detailed version.** The full team roadmap is too detailed for sales / support / leadership.
- **Lead with the *why*, not the what.** "We're focused on `<theme>` this quarter because `<reason>`. Here are the things we're betting on."
- **Explicitly mark confidence levels.** Stakeholders deserve to know the difference between "shipping in 4 weeks" and "exploring whether this is even the right thing."
- **Be honest about what's *not* on the list.** "We are not shipping `<X>` this quarter, in service of `<Y>`." This is the most important part for stakeholders.

### To customers and the outside

- **Default to less, not more.** Promise less than you'll deliver; let the upside be a delight.
- **Avoid specific dates** unless you're absolutely sure. A missed public date erodes trust faster than a missed private one.
- **Use directional language**: "We're working on", "Coming soon", "On our radar." Avoid "Will ship by".
- **Update or delete promises that no longer hold.** A roadmap page that hasn't been touched in 9 months and still says "coming Q3" is reputational damage.

### To leadership

- **Lead with confidence and bets, not features.** Leadership wants to know "are you on track for the strategy" and "what are you betting on." The feature list is secondary.
- **Show what's *not* on the list and why.** This is more reassuring than the "what's on" list.
- **Surface risks proactively.** "Item X is at risk because Y. Here are our options." Leadership pays attention to risks; they ignore status reports.
- **Don't hide misses.** A miss reported early is salvageable; a miss revealed at the deadline is a crisis.

## Revising the Roadmap

Roadmaps go stale fast. The team learns things; the market shifts; estimates turn out to be wrong; a new opportunity surfaces. A team that revises its roadmap regularly stays aligned with reality; a team that doesn't drifts.

### When to revise

- **Quarterly, at minimum.** A planned roadmap review at the end of each quarter (or the start of the next).
- **When the team learns something material.** Discovery surfaces a major insight; usability testing invalidates a core assumption; a competitor ships something that changes the calculus.
- **When estimates are wrong.** If item X is taking 3x longer than expected, the rest of the roadmap is now wrong. Fix it.
- **When something fails.** A bet didn't pay off. The team needs to decide what to do next.
- **When leadership's strategy shifts.** If the company strategy moves, the roadmap should move with it.

### What to do when revising

- **Update the artifact visibly.** Don't quietly delete things; mark what changed and why. Stakeholders should be able to see "this used to be on the roadmap; here's why it isn't now."
- **Communicate the change.** A team that finds out from the artifact that their work has been deprioritized is a demoralized team. Tell them first, in person, with rationale.
- **Avoid the "revise and never finish" trap.** Roadmaps that change every week have no force. Aim for stability between quarters with explicit revision moments, not constant churn.

### When *not* to revise

- **When the work is just hard.** "It's taking longer" is not a reason to drop something; it might be a reason to scope it down or to find a smaller win, but not to abandon it on the first sign of friction.
- **When a stakeholder is loud.** Loud requests are not new information. They're old requests with more volume.
- **When you're tired.** Roadmap revision under fatigue produces bad decisions. Sleep on it.

## Roadmap as Hypothesis (the Stance)

The most important shift in modern PM practice: treating the roadmap as a *hypothesis* about what the team should do, not as a *commitment* to do those exact things.

A hypothesis-style roadmap:

- States what the team currently believes is the right work
- Names the *bets* implicit in the plan
- Names the *kill criteria* — what would make the team change course
- Updates when the bets pay off, fail, or get superseded
- Doesn't punish the PM for changing it when the evidence changes
- Doesn't punish the team for ending up somewhere different from where they started, *if* they got somewhere better

A commitment-style roadmap:

- Treats deviations as failures
- Demands explanations for any change
- Encourages the PM to defend stale plans rather than update them
- Produces feature-factory behavior (ship the planned thing whether or not it works)
- Erodes trust in the team's judgment over time

The transition from commitment-style to hypothesis-style is partly cultural and partly contractual. Leadership has to be willing to evaluate the team on *outcomes* rather than on *did they deliver what they said they would*. PMs have to be willing to *defend the changes* with rationale rather than hide them.

It's worth the discomfort. Hypothesis-style roadmaps produce more learning, more alignment, and (ironically) fewer surprises than commitment-style roadmaps.

## Anti-Patterns

- **Roadmap as commitment.** Defended past the point of usefulness; team can't change course.
- **Roadmap as wishlist.** Lists everything the team would like to do; prioritizes nothing.
- **Roadmap as marketing.** Optimized for what looks good in the deck, not what's actually shipping.
- **Vague aspirations on the roadmap.** "Improve performance." Not actionable; not measurable.
- **Date-locked roadmaps for uncertain work.** Three-month-out dates treated as hard commitments; the team is set up to slip.
- **Quiet revisions.** Items disappear from the roadmap with no explanation; stakeholders find out by accident.
- **Roadmap reviewed quarterly, ignored in between.** Goes stale fast; doesn't reflect current reality.
- **Sales commitments on the product roadmap.** Conflates promised work with planned work.
- **Feature-only roadmap.** Ships features whether or not they hit the outcome.
- **No "later" column.** Pretends everything is committed; fights with reality.
- **No "won't do" section.** Stakeholders don't know what to expect *not* to happen.
- **Confidence levels not shown.** Stakeholders treat "exploring" with the same weight as "shipping in 2 weeks."
- **Roadmap written for the executive review, not for the team.** Polished, decorative, doesn't inform daily work.
- **Roadmap never killed.** Items live on the roadmap for a year, never shipping, never explicitly removed. Backlog rot.

## Related

- [product-strategy.md](product-strategy.md) — strategy is the source of the roadmap; without strategy, roadmap is preference
- [prioritization.md](prioritization.md) — prioritization fills the roadmap
- [saying-no.md](saying-no.md) — the most important roadmap decisions are "no"
- [stakeholder-management.md](stakeholder-management.md) — different audiences need different versions
- [discovery-to-delivery.md](discovery-to-delivery.md) — discovery feeds the roadmap
- [team-lead](../../team-lead/SKILL.md) — roadmap items become tickets in the team's backlog
- [system-architect](../../system-architect/SKILL.md) — technical roadmap and product roadmap should reinforce each other
- [assets/roadmap-template.md](../assets/roadmap-template.md) — fillable now/next/later template

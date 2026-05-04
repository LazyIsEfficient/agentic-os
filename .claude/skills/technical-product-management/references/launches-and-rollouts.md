# Launches and Rollouts

A launch is the moment a feature meets real users at scale. It's also the moment most product teams discover they've under-prepared. Launches go wrong in predictable ways: nobody set up the metrics; the rollout was too aggressive; the support team had no warning; the rollback plan didn't exist; the announcement said one thing while the product did another.

The good news: most launch failures are avoidable. The bad news: avoiding them takes deliberate planning that many teams skip in the rush to ship.

This file is about doing launches that don't blow up.

## What "Launch" Actually Means

The word is fuzzy. Different teams use it to mean different things:

| Type | What it means |
|---|---|
| **Internal launch** | The feature is on for the team building it. Eat your own dog food. |
| **Internal beta** | The feature is on for the company. Wider internal use, still no external users. |
| **Closed beta** | A small group of external users (often hand-picked or invited) use the feature. |
| **Open beta** | Anyone can opt in. No marketing push; users find it themselves. |
| **Soft launch** | Released to all users without fanfare. Some marketing. Watching closely. |
| **Hard launch** | Marketing campaign, press, sales enablement, big announcement. The Big Day. |

Most things should ship through several of these phases, in order. Skipping phases is how bad launches happen.

## The Phased Rollout

The single best practice in launching: **don't launch to everyone at once**. Launch to a small fraction, watch, expand, watch, expand. Each phase is a chance to catch problems before they're at scale.

### The phases

1. **Internal first** — the team using the feature.
2. **Company-wide** — the broader org using the feature.
3. **A small percentage of real users** — 1%, 5%, 10%. Often via feature flags.
4. **Larger percentage** — 25%, 50%.
5. **All users** — 100%.

Each phase has *bake time*. You don't move from 5% to 100% in an afternoon; you wait long enough to see if the metrics are healthy. For a major feature, bake time is days to weeks at each phase.

### What you watch at each phase

- **Error rates.** Are users hitting errors that didn't show up in testing?
- **Performance.** Is the feature slow under real load?
- **The success metric.** Is it actually moving in the right direction?
- **Counter-metrics.** Are other things getting worse?
- **Support volume.** Are users confused enough to ask for help?
- **Qualitative signal.** What are users saying? In tweets, in support tickets, in NPS comments?

If any of these look bad at the current phase, **stop expanding**. Investigate. Fix. Then continue.

### The kill criteria

Before launch, define what would make you roll back. Be specific:

- "If error rate exceeds 1%, roll back."
- "If conversion drops by more than 5 percentage points, roll back."
- "If support volume on this feature exceeds 50 tickets in 24 hours, pause expansion."
- "If `<core metric>` doesn't improve by `<X>` after 30 days at 100%, consider it a failure and consider rollback or major redesign."

These criteria should be agreed *before* the launch, when nobody is invested in defending the feature. After launch, with effort sunk and stakeholders watching, the temptation is to rationalize away the bad signal. Pre-committed criteria prevent this.

## Beta Programs

A beta is a controlled exposure of the feature to a small group of real users *before* the public launch. Done well, betas catch problems and produce testimonials. Done badly, they're confused, frustrated users with no clear feedback channel.

### Recruiting the beta

Pick beta users deliberately:

- **Not just power users.** Power users will figure anything out; they don't represent the typical user. Include some less-experienced users.
- **Across segments.** If you have multiple user types, include all of them.
- **Across use cases.** Different people use the product for different things; sample broadly.
- **Some friendlies, some skeptics.** Friendlies will give you forgiving feedback; skeptics will tell you the truth.
- **Not too many.** A beta of 10 you can talk to is better than a beta of 200 you can't.

### Setting beta expectations

Tell beta users explicitly:

- **What's beta.** "This feature is in beta. It might break. Here's what to expect."
- **What you want from them.** "We'd love to hear what works, what doesn't, and what surprises you."
- **How to give feedback.** A clear channel — email, in-product feedback widget, dedicated Slack channel.
- **What you'll do with the feedback.** "We read every message. We can't promise to act on every request, but we'll consider it."
- **When they can opt out.** "You can leave the beta at any time, no questions asked."

A beta without expectation-setting becomes "users who got an unfinished feature without warning and now feel cheated." The same product, framed honestly, becomes "early adopters who feel like insiders helping shape the product." Same content, different relationship.

### Closing the loop with beta users

Beta users gave you their time. Acknowledge it:

- **Thank them** when the feature ships generally.
- **Tell them what changed** because of their feedback. ("Several of you mentioned X; here's what we did.")
- **Give them something small** if you can — early access to the next thing, a credit, a t-shirt, a personal note.

This isn't about gifts; it's about *respect*. Beta users who feel respected become advocates. Beta users who feel used become churners.

## Feature Flags

A feature flag (also called a toggle) is a switch in the code that enables or disables a feature. Modern launches almost always use them.

### What feature flags enable

- **Phased rollouts.** Turn the feature on for 1%, then 5%, then 25%, etc.
- **Targeted rollouts.** Turn it on for specific segments (US users only, paying users only, the beta cohort).
- **Instant rollback.** If something goes wrong, flip the flag back. No deploy needed.
- **A/B testing.** Compare the feature on vs off across two cohorts.
- **Decoupled launches.** Engineering ships the code; the PM decides when to flip it on. The two events are separate.

### Flag hygiene

Feature flags are also a source of long-term technical debt if not managed:

- **Flags should be temporary.** A "temporary" flag from 2021 still in the codebase in 2026 is a bug.
- **Each flag should have an owner** and an *expected removal date*.
- **Stale flags should be removed** as part of regular maintenance.
- **Avoid deeply nested flag logic.** When code branches on three flags, it's untestable.

The PM and engineering co-own the flag strategy. The PM owns the *rollout* decisions; engineering owns the *implementation* and the cleanup.

## Launch Communication

A launch isn't just shipping code. It's also communicating that you've shipped, to the people who need to know.

### Internal communication (before launch)

Several teams need to know what's coming:

- **Sales** — they need to know what to talk about with customers.
- **Customer success / support** — they need to know how to help users with the feature.
- **Marketing** — they need to know what's coming so they can prepare announcements.
- **Leadership** — they need to know to expect questions.
- **Other engineering teams** — adjacent teams need to know if anything affects them.

A useful artifact: a **launch brief** that goes out 1–2 weeks before launch, summarizing:
- What's launching
- Who it's for
- What the key user-facing changes are
- What support might see (likely questions, likely confusions)
- Where to learn more
- Who to ping with questions

This is short — half a page to a page. The point is to *avoid surprises*, not to brief in detail.

### Customer communication (at launch)

When the feature is launching publicly, customers need to know — but the message depends on the size of the launch.

For small launches: in-product announcement, changelog entry, maybe an email to active users.

For medium launches: blog post, in-product banner, email, social media.

For big launches: press release, public webinar, partner announcement, conference talk, the works.

Match the noise level to the size of the change. A small change announced as a Big Deal looks like padding; a big change announced as a small thing looks like timidity.

### What goes in the launch announcement

Whatever the format, the announcement should answer:

- **What is this?** In plain language. Not jargon.
- **Who is it for?** The user can tell whether they're the target.
- **Why does it matter?** The user can tell whether they should care.
- **How do I use it?** Concrete, actionable.
- **What's the catch?** If there are limitations, name them. (Not in the marketing voice; in the honest one.)
- **Where to learn more?** Documentation link, video, contact for questions.

Avoid:

- **"Excited to announce"** — every product launch starts with this; it's noise.
- **Marketing-speak.** "Synergy," "leverage," "next-generation," "industry-leading." Means nothing.
- **Overpromising.** Better to deliver more than expected than less.
- **Burying the news.** The first sentence should tell the reader what changed.

## Setting Up Metrics Before Launch

The single most-skipped step. Teams ship features and *then* try to figure out whether they worked. By that point, the relevant metrics weren't being tracked, the comparison baseline doesn't exist, and the team is left arguing about anecdotes.

### Set up the metrics first

Before the launch:

1. **Decide what success looks like.** Specific, measurable. (See [metrics-and-evidence.md](metrics-and-evidence.md).)
2. **Decide on the counter-metric.** What could get worse if you're not careful?
3. **Make sure the metrics are instrumented.** The events fire; the dashboards exist.
4. **Capture the baseline.** What was the metric *before* the feature shipped? Without this, you can't say it changed.
5. **Decide the time horizon.** "We'll evaluate this 30 days after 100% rollout."
6. **Decide who watches.** Who's responsible for looking at the metric and reporting back?

If any of these are missing on launch day, the launch is incomplete. Delay the launch (or accept that you won't know if it worked) until they're in place.

### Ongoing monitoring

For the first week or two of a launch, watch the metrics *daily*. Catch problems fast. After that, weekly is usually enough.

Don't watch only the success metric. Also watch:

- **Error rates** — broken stuff
- **Performance** — slow stuff
- **Support volume** — confused stuff
- **Conversion / retention / engagement** — knock-on effects

A useful default: a single "launch dashboard" with all the relevant numbers in one place, accessible to the team.

## The Rollback Plan

Rollback is the most important word in launch planning that nobody wants to talk about.

A rollback plan answers:

1. **What's the trigger to roll back?** (See kill criteria above.)
2. **How do we actually roll back?** Feature flag flip? Revert deploy? Database migration?
3. **How long does it take?** Seconds (flag), minutes (deploy), hours (database)?
4. **What's the data implication?** If users created data with the new feature, what happens to it on rollback?
5. **Who decides to roll back?** Named individual or on-call rotation. Don't rely on consensus in a panic.
6. **How do we communicate the rollback?** Internal, external. What do we say?

The plan should be **written down** and **rehearsed**. A rollback plan that exists on paper but has never been tested is not a rollback plan; it's a vague hope.

For high-risk launches, do a *rollback drill* — execute the rollback in a non-production environment to make sure it actually works.

## Post-Launch Reviews

A launch isn't done when the feature is live. It's done when the team has *learned from it*.

### Cadence

- **Day 1–7:** daily check-ins on metrics. The team is on alert.
- **Week 1–2:** weekly check-ins. Settling into the new normal.
- **Week 4–6:** the post-launch review. Real data is in; time to evaluate.
- **Quarter:** revisit in the next strategy review. Did this matter? What did we learn?

### The post-launch review meeting

A 30–60 minute meeting, 4–6 weeks after launch, with the team that built it.

Agenda:

1. **What did we ship?** Brief recap, in case some people in the room need context.
2. **What were the success criteria?** (From the PRD / launch plan.)
3. **What actually happened?** The data. Honestly. Including the bad parts.
4. **Did we hit the goal?** Yes / no / partial. Be honest.
5. **What do we know now that we didn't before?** The learning.
6. **What would we do differently?** Next time, what changes?
7. **What's next for this feature?** Iterate? Kill? Move on?

This is *not* a postmortem (nothing went wrong, necessarily). It's a *learning review*. The point is to extract lessons that improve future launches.

### What to do if the launch failed

Sometimes the launch was wrong. The metric didn't move, or worse, it moved in the wrong direction. The team is disappointed; stakeholders are asking questions.

The right response:

- **Be honest about it.** Don't spin. Don't reframe. The launch didn't hit the goal.
- **Don't blame.** Frame it as the team's collective bet that didn't pay off.
- **Extract the lesson.** What did we learn that we couldn't have known before? That's the value.
- **Decide what to do.** Iterate? Roll back? Kill? Move on?
- **Communicate the decision** to stakeholders, with rationale.

A team that handles a failed launch well becomes more trusted, not less. Stakeholders learn that the team will tell them the truth and decide based on evidence. A team that hides failed launches loses trust.

### The danger of "small wins"

Watch out for the post-launch syndrome of finding small positive numbers and declaring victory. "Engagement is up 0.3%!" — is that real? Statistically significant? Worth the cost of building?

If the feature didn't move the primary metric meaningfully, it didn't work. Don't backfill success by cherry-picking a metric that ticked up.

## Anti-Patterns

- **Launch as event.** Treats launch as a single moment instead of a process. Concentrates risk; nothing to fall back on.
- **No phased rollout.** 100% from day 1; broken thing affects everyone.
- **No kill criteria.** Nobody knows when to roll back; defends the broken feature instead.
- **No baseline.** Ships and can't tell if metrics moved.
- **Metrics set up after launch.** "We'll figure out how to measure it later." Later never comes.
- **No rollback plan.** "We'll figure it out if we need to." Then a real incident happens; figuring it out under pressure goes badly.
- **Untested rollback.** The plan exists; nobody verified it works.
- **No internal communication.** Sales / support find out from customers.
- **No customer communication.** Users discover the change by surprise; some don't notice; some are confused; some are angry.
- **Marketing-speak announcements.** "Excited to announce a synergistic next-generation experience." Nobody knows what it means.
- **Overpromising.** Marketing says the feature does things it doesn't do.
- **Underselling.** Big change announced like a footnote; users miss it.
- **Beta with no expectation-setting.** Users feel cheated.
- **Beta with no feedback loop.** Beta users never hear back; treat the next beta with skepticism.
- **No post-launch review.** Ships and forgets; doesn't learn.
- **Post-launch theater.** Cherry-picks positive numbers; declares victory regardless of the truth.
- **Refusing to roll back.** The feature is broken; the PM defends it instead of pulling it. Damage compounds.
- **Launching before metrics are set up.** Forced to declare victory based on anecdotes.
- **No counter-metric.** Optimizes the primary number; wrecks the system around it.
- **Skipping internal beta.** Real users are the first to find the obvious bugs.
- **Big-bang launch with no soft launch.** All risk concentrated in one moment; no chance to learn before the big push.
- **Stale feature flags.** Old flags accumulate; the codebase becomes a maze of toggles; nobody dares remove them.
- **Launch sprint that consumes the team for weeks.** Everyone is exhausted; bugs from the rush land in production.

## Related

- [discovery-to-delivery.md](discovery-to-delivery.md) — launch is the end of delivery and the start of post-launch learning
- [metrics-and-evidence.md](metrics-and-evidence.md) — what to measure and how
- [stakeholder-management.md](stakeholder-management.md) — launch comms are stakeholder work
- [working-with-engineering.md](working-with-engineering.md) — launch is a co-owned event
- [site-reliability-engineering](../../site-reliability-engineering/SKILL.md) — runtime safety nets, error budgets, on-call response
- [deployment-pipelines](../../deployment-pipelines/SKILL.md) — release mechanics, canaries, rollback automation
- [team-lead](../../team-lead/SKILL.md) — coordinating the team rhythm during launch
- [assets/launch-plan-template.md](../assets/launch-plan-template.md) — fillable launch plan template

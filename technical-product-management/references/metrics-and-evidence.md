# Metrics and Evidence

A PM lives and dies by metrics. The right ones, used well, focus the team and make decisions easier. The wrong ones, or the right ones used badly, produce optimization theater — numbers tick up while the product gets worse.

The most important thing to internalize: **a metric is a tool, not an answer**. Numbers describe reality but don't interpret it. The PM's judgment is what turns a number into a decision. PMs who outsource decisions to numbers ("the data says so") have abdicated the job; PMs who ignore numbers ("I trust my gut") have abandoned it.

The right stance: **data informs; judgment decides; both are necessary**.

## Picking the Right Metric

Most metrics failures are *picking the wrong metric* before any analysis is done. Once the team is optimizing for the wrong number, all the rigor in the world won't save them.

### A good metric

- **Reflects what the team actually cares about.** If you optimize this number and it goes up, are you happy? If yes, it's a candidate. If "well, it depends," it's not.
- **Is measurable without inventing new instrumentation.** Or, if it requires new instrumentation, the cost is justified.
- **Moves on the timescale of your decisions.** A metric that takes a year to move can't inform weekly decisions.
- **Can be moved by the team's actions.** If the metric depends entirely on external factors, the team can't influence it.
- **Has a baseline.** You know what it was before; you can detect change.
- **Has a counter-metric.** You know what could go wrong if you optimize the primary one too hard.
- **Survives the "what would we do differently?" test.** Knowing this number changes a decision the team would otherwise make.

### A bad metric

- **Vanity metric.** Big number, no decision implication. Pageviews, registered users, total downloads. Looks impressive; means nothing.
- **Lagging beyond the decision horizon.** "Annual revenue" is real but doesn't help you ship next week's feature.
- **Out of the team's control.** "Stock price" — interesting, not actionable.
- **No baseline.** "Engagement is up" — compared to what?
- **Easy to game.** Anything where the team can hit the number without producing the value.
- **Mistakes proxy for the thing.** Tracking "session length" because you think it means engagement, when actually shorter sessions might mean users are more efficient.

A useful test before adopting any metric: **what would we do differently if we knew this number went up by 20% next week?** If the answer is "celebrate," it's vanity. If the answer is "ship more of X" or "stop doing Y" or "investigate Z," it's actionable.

## Leading vs Lagging Indicators

A foundational distinction.

- **Leading indicators** predict future outcomes. They move *before* the thing you ultimately care about. Example: "number of users who completed onboarding in week 1" leads "30-day retention."
- **Lagging indicators** are the outcomes themselves. They move *after* the changes that caused them. Example: "30-day retention," "annual recurring revenue."

You need both, but they serve different purposes:

- **Lagging indicators** are what you ultimately care about. Revenue, retention, NPS. They tell you whether the business is working.
- **Leading indicators** are what you can act on. They move on a timescale that lets you adjust before the lagging indicator arrives.

The trap: optimizing only lagging indicators is too slow ("we shipped a feature; we'll know if it worked in a year"). Optimizing only leading indicators is dangerous ("the leading indicator is up, but it turned out not to actually predict the lagging one"). Real practice tracks both, treats them as a system, and *validates* that the leading indicators actually predict the lagging ones over time.

### How to find good leading indicators

The honest answer: by experiment. You have a hypothesis ("users who do X within their first week become long-term users"), you measure both X and long-term retention, you check whether the correlation holds, and you keep the indicator if it does.

Common patterns that often work as leading indicators:

- **Activation events.** A user who took action X is much more likely to retain.
- **Habit signals.** A user who came back N times in their first week is much more likely to stay.
- **Engagement depth.** A user who used N features is much more likely to convert.
- **Network effects.** A user who invited others is much more likely to retain.

The exact ones depend on your product. The discipline is to *test* whether your candidate leading indicator actually predicts the lagging outcome.

## North Star Metrics

The "north star metric" is the single most-discussed metric concept in modern PM, and it's both useful and over-hyped.

A north star metric is **one number that captures the value the product delivers to users**. It's a single rallying point for the team — the thing everyone agrees they're optimizing for.

Examples:

- **Spotify:** time spent listening
- **Airbnb:** nights booked
- **Slack:** weekly active users sending messages
- **Stripe:** transactions processed
- **Notion:** weekly active users with X actions

Notice the common thread: each is a *user value* metric, not a *business* metric. Revenue is a *result* of delivering user value; the north star is the *cause*. Optimize the cause; the result follows.

### What a north star is for

- **Aligning the team.** Everyone knows what we're trying to move.
- **Filtering ideas.** Does this feature plausibly move the north star? If not, why are we doing it?
- **Communicating up.** Leadership can see one number that proves whether the product is working.
- **Resisting feature factory.** Features that don't move the north star are visible as such.

### What a north star isn't for

- **The only metric.** You still need counter-metrics, leading indicators, business metrics. The north star is one tool, not a replacement for the others.
- **A short-term tool.** North stars move slowly. Don't use them for sprint-level decisions.
- **A justification for ignoring user pain.** "It doesn't move the north star, so we won't fix it." Some things matter even if they don't show up in a metric.
- **Set in stone.** The right north star changes as the product matures. Revisit yearly.

### Picking a north star

Hard. The wrong north star drags the team in the wrong direction for years. Some heuristics:

- **It should reflect the value the user gets**, not the value the company extracts. (Time listening, not ad revenue.)
- **It should be something only your product can move.** Not a market-wide metric.
- **It should compose well with your business model.** If your business depends on retention, the north star should be retention-correlated.
- **It should be one number** — not a "north star scorecard." If you can't pick one, you don't have a north star yet.
- **It should pass the gut check.** If it went up 50% next quarter, would you be happy? Honestly?

If you can't find one north star, that's a signal that your product or strategy isn't focused enough. It's a problem to solve, not a problem to paper over with a multi-metric dashboard.

## Counter-Metrics

The single most-skipped practice in metrics. Every primary metric should be paired with a counter-metric — the thing that could get worse if you optimize the primary one too aggressively.

Examples:

| Primary | Counter |
|---|---|
| Engagement (time in app) | User-reported satisfaction; addiction signals; well-being |
| Conversion rate | Refund rate; cancellation rate; complaint volume |
| Onboarding completion | Day-30 retention (people who completed but didn't return) |
| Email open rate | Unsubscribe rate; spam complaint rate |
| Search result clicks | Search abandonment; time to find result |
| Active users | Active *paying* users; active users who do X meaningful action |
| Revenue per user | Churn rate; brand sentiment |
| Page load speed | Functionality completeness (faster but broken is not faster) |

The pattern: pair the metric you want to *move* with the metric you don't want to *break*. Optimize within the constraint.

Without a counter-metric, optimization eventually destroys what you actually care about. Engagement up, trust down. Conversion up, refunds up. Speed up, features missing.

## Metric Hierarchies

In a real product, you don't have *one* metric — you have a *hierarchy*.

A useful mental model:

```
                    NORTH STAR
                  (1 metric)
                       │
              ┌────────┼────────┐
              │        │        │
          INPUT 1   INPUT 2   INPUT 3
       (3-5 sub-metrics that compose into the north star)
              │        │        │
          ┌───┼───┐    │     ┌──┼──┐
        team-level metrics for each input
```

The north star is at the top. Below it are the inputs that compose into it. Below those are the team-level metrics that each team is moving.

This composition is what lets the org pursue one direction while different teams work on different things. Each team has metrics they can move; those metrics compose into the larger picture; the larger picture is the north star.

The skill is in the *decomposition*. A good decomposition tells you what to do; a bad one is just a collection of numbers nobody acts on.

## OKRs (Briefly)

Objectives and Key Results — the most-used goal-setting framework in modern PM.

An **objective** is a qualitative aspiration: "Make new users feel confident in the first week."

**Key results** are quantitative indicators that the objective is being met: "Median time-to-first-project drops from 14 days to 7 days. Day-7 retention rises from 45% to 55%."

What OKRs are good for:

- **Forcing the team to commit to outcomes**, not activities.
- **Making goals visible** across the org.
- **Aligning teams** on the same north star at quarter-level.

What OKRs are bad for:

- **Day-to-day work.** OKRs are quarterly; daily work is much smaller.
- **Things that don't fit the format.** Some valuable work (paying down debt, infrastructure, exploration) doesn't have a clean key result.
- **Anything where the team can't actually move the metric.** "Increase MRR by 30%" is not under one team's control.

The most common OKR failure: treating them as commitments to be hit at any cost. Real OKRs are *aspirations* with a threshold of "if we hit 70% of the key results, we're doing well." OKRs that have to be hit at 100% are just deadlines wearing OKR badges.

## Instrumentation

A metric that isn't instrumented is a wish. Before you commit to tracking something, make sure the events fire, the dashboards exist, and the data is clean.

### Before launching anything you want to measure

- **Instrument the events** that compose the metric.
- **Verify the data is correct** by spot-checking — log a few events, look at the dashboard, confirm they appear correctly.
- **Build the dashboard** so the metric is visible.
- **Capture the baseline** by waiting long enough (a week, often) to see what "normal" looks like before the change.
- **Document what the metric means** so the team interprets it consistently. ("Active user" — defined how? Sessions in the last 7 days? Logged in once?)

A common failure: launching something, then trying to figure out *retroactively* whether it worked. The data isn't there. The baseline doesn't exist. The team is reduced to anecdotes. **Set up the instrumentation before, not after.**

### Common instrumentation mistakes

- **Inconsistent definitions.** "Active user" means one thing in the dashboard and another thing in the report. Same word, different meanings, decisions made on the wrong number.
- **Sampling bias.** The metric tracks 10% of users; the 10% is not representative; conclusions are wrong.
- **Lagging data.** The dashboard updates daily; you make a real-time decision; the data is yesterday's.
- **Survivor bias.** The metric counts only users who came back, not users who churned. Looks like everything is great.
- **Cohort confusion.** Mixing up new users and existing users; mixing up users from different segments.
- **Bot traffic.** Automated traffic skewing the numbers; not filtered out.
- **Holiday effects.** Numbers spike or drop on holidays; teams misread them as feature-related.
- **A/B test peeking.** Looking at results early and stopping the test when it looks favorable. Statistical malpractice.

A skeptical eye on the *quality* of the data is as important as a sharp interpretation of it.

## Vanity Metrics

A vanity metric is one that looks impressive but doesn't inform decisions. The classic examples:

- **Total registered users.** Doesn't tell you how many actually use the product.
- **Total downloads.** Doesn't tell you usage or value.
- **Social media followers.** Doesn't tell you whether followers do anything.
- **Pageviews.** Without context, says nothing about whether users got value.
- **Total revenue.** A single number; doesn't tell you growth, retention, churn, segments.

Vanity metrics aren't *wrong* — they're just not *useful for decisions*. A team that reports them in updates is hiding from the real work.

The fix: pair every vanity metric with an actionable one. Total registered users + monthly active users + activation rate. Total downloads + day-30 retention. Total revenue + ARR growth + churn.

The skeptical question for any reported metric: **what would we do differently if this changed?** If the answer is nothing, drop it from the report.

## A/B Tests (Briefly)

A/B testing is the most rigorous way to know whether a change actually caused an outcome. Show version A to one group, version B to another, compare.

What A/B tests are good for:

- **Specific changes** with clear outcomes.
- **High-traffic products** where you can reach statistical significance.
- **Features that are reversible** if they fail.

What A/B tests are bad for:

- **Strategic decisions.** "Should we build this product line?" — you can't A/B test this.
- **Long-term effects.** Most A/B tests measure 2-4 weeks; some effects only show up over months.
- **Low-traffic products.** Statistical power requires volume.
- **Anything where the test itself biases the result.** Testing "should onboarding be 3 steps or 7 steps" requires hundreds of users in each arm; if you only have 50 new users a week, the test takes months and the conclusion is weak.

Common A/B test failures:

- **Peeking.** Looking at the data early; stopping when the result is favorable. Inflated false positives.
- **Multiple tests at once.** Interactions between tests confound each one.
- **Too short.** Weekend-only data is biased; week-only data misses weekend effects.
- **Wrong metric.** Optimizing the click-through rate while user retention drops.
- **No counter-metric.** Same problem at the test level.
- **Significance theater.** P-value of 0.049 is not "the result is real" — it's "the result might be real, with significant uncertainty." Treat marginal significance as marginal.
- **Ignoring the magnitude.** The result is significant but the effect is 0.3%; not worth the cost.

A/B tests are powerful but easy to misuse. If you're going to use them, learn the statistical pitfalls or pair with someone who has.

## Common Metric Failures

### Optimizing for the wrong thing

The team chose a metric that doesn't reflect what they actually care about. Years of work go into moving it; the business doesn't improve.

Fix: spend more time at the start picking the metric. Test with the "what would we do differently" question. Validate against the business outcome before committing.

### Goodhart's Law

> "When a measure becomes a target, it ceases to be a good measure."

Once the team is *optimizing* for a metric, they will find ways to move the metric that don't move the underlying value. Engagement up, depth down. Active users up, paying users flat. Conversion up, refunds up.

The fix is *not* to abandon metrics; it's to *constrain* them with counter-metrics and qualitative checks.

### Metric theater

The team has a beautiful dashboard. The numbers move. Nobody can articulate what to do about them. The metrics exist to *report*, not to *decide*.

Fix: tie every metric explicitly to a decision. If a metric doesn't inform a decision, drop it from the dashboard.

### Data without context

"Conversion is down 5%." So what? Compared to what? Over what period? In what segment? With what changes happening at the same time?

A number without context is unintepretable. A change without an explanation is noise.

Fix: report metrics with the context that makes them meaningful. Trend, baseline, segment, what else changed.

### Correlation as causation

"We launched the new dashboard last week and engagement is up 12%!" Maybe. Or maybe Tuesday is just always higher than Monday. Or maybe a marketing campaign happened the same week. Or maybe a competitor was down.

Fix: be skeptical of correlation. The only ways to establish causation are A/B tests, natural experiments, or before-and-after comparisons with appropriate controls.

### Anecdote-driven decisions

"One customer told me they hate the new design." Real signal? Or one loud customer in a sea of happy ones?

Fix: separate "this is one anecdote" from "this is a pattern." Look at the data. The anecdote points to something to investigate; the data confirms or denies.

### Data-driven malpractice

"The data says we should kill this feature." But the data was wrong, or interpreted wrong, or measured the wrong thing, or didn't capture the long-term value.

Fix: data informs; judgment decides. Numbers without interpretation are noise; interpretation without humility is theater.

## Anti-Patterns

- **Vanity metrics.** Big numbers; no decision implication.
- **No counter-metric.** Optimize the primary; break the system.
- **No baseline.** Ship and have nothing to compare against.
- **Metrics set up after launch.** Reduced to anecdotes.
- **No instrumentation verification.** Numbers are wrong; nobody notices.
- **Inconsistent definitions.** Same word, different meanings, conflicting reports.
- **Goodhart's Law in action.** Metric moved; underlying value didn't.
- **Cherry-picking.** Pick the metric that supports the conclusion you wanted.
- **Peeking at A/B tests.** Inflated false positives.
- **Stopping A/B tests early.** Same problem.
- **Single metric obsession.** Ignoring the system around the chosen metric.
- **Dashboard as decoration.** Updates daily; nobody acts on it.
- **"The data says so."** Outsourcing the decision to a number; abdicating judgment.
- **"My gut says so."** Ignoring the data; abdicating evidence.
- **Lagging-only.** Measure what already happened; can't act in time.
- **Leading-only.** Measure things that haven't been validated against the lagging outcome.
- **One quarter is enough.** Treats short-term data as permanent.
- **Too many metrics.** A 30-metric dashboard hides the signal in noise.
- **No definition for the metric.** Different team members interpret it differently.
- **Survivorship bias.** Track only the users who stuck around; conclude things are great.
- **Confounding ignored.** "It worked!" — but five other things changed at the same time.

## Related

- [product-strategy.md](product-strategy.md) — the strategy informs which metrics matter
- [prioritization.md](prioritization.md) — metrics inform prioritization decisions
- [launches-and-rollouts.md](launches-and-rollouts.md) — set metrics up before launch
- [discovery-to-delivery.md](discovery-to-delivery.md) — closing the loop with post-launch metrics
- [pm-anti-patterns.md](pm-anti-patterns.md) — many PM failures are metrics failures
- [ux-research](../../ux-research/SKILL.md) — qualitative complement to quantitative
- [site-reliability-engineering](../../site-reliability-engineering/SKILL.md) — operational metrics (SLIs/SLOs) overlap with product metrics

# Design Process

A design process is not a recipe. It's a set of habits and stages that, applied with judgment, makes the work more likely to ship something useful. Following it slavishly produces stiff, overweight design work; ignoring it entirely produces designs that solve the wrong problem at the wrong fidelity for the wrong audience.

This file is the operating model for "how design unfolds over time" — what happens when, what each stage is for, and how to know when you've stayed too long in any one of them.

## The Double Diamond

The most useful single mental model for design work. Two diamonds, side by side:

```
   problem space          solution space
   ┌──────────┐           ┌──────────┐
   │ diverge  │  converge │ diverge  │  converge
   │   →      │     →     │    →     │     →
   │ explore  │  define   │ explore  │  refine
   │ problem  │  problem  │ solutions│  solution
   └──────────┘           └──────────┘
        Discover  Define     Develop   Deliver
```

The first diamond is **problem space**: open up to understand the problem widely (discover), then narrow to a clear problem statement (define).

The second diamond is **solution space**: open up to many possible solutions (develop), then narrow to one that gets shipped (deliver).

The crucial insight: **the two diamonds are different work**. The instinct of most teams is to skip straight to the second diamond ("let's design something") without spending real time in the first ("what are we even solving?"). This produces beautiful solutions to the wrong problem.

The other crucial insight: **divergence and convergence alternate**. You must open before closing, in both diamonds. A team that starts converging immediately misses the insight that comes from exploring — the second-best idea is often more interesting than the first idea you thought of.

## The Four Stages, Concretely

### Discover — open the problem space

What it is: research, observation, conversation, listening. Building a wide, evidence-based understanding of the people you're designing for and the situation they're in.

The output is *not* a design. It's a deeper, more nuanced, less assumption-laden picture of the problem. It's the raw material that everything else rests on.

Designers participating in discover:

- Attend user research sessions ([ux-research](../../ux-research/SKILL.md)).
- Read past research and synthesis.
- Talk to support, sales, and customer success.
- Use the product themselves, in real situations.
- Look at competitors and adjacent products without rushing to copy.
- Spend time with the data — analytics, telemetry, feedback channels.

Common failures here:

- **Skipping discover entirely.** "We know what users need." You don't, and the next month proves it.
- **Mistaking opinion for data.** "I think users will love this." Maybe — but maybe not.
- **Treating discover as marketing input.** Marketing segments are not user segments.
- **Treating discover as something only researchers do.** Designers participate. Watching a user struggle in real time is irreplaceable.

### Define — close on a problem statement

What it is: synthesis. Turning the raw material from discover into a *clear, specific, agreed-upon* statement of the problem you'll solve.

The output is a problem statement — see [ux-research/references/discovery-and-problem-framing.md](../../ux-research/references/discovery-and-problem-framing.md).

You know you're done with define when:

- The team can describe the problem in one paragraph that everyone agrees with.
- You can name the user segment, the situation, the consequence, and the desired outcome.
- You can name what you are *not* solving — the related problems explicitly out of scope.

You know you haven't finished define when:

- The team is arguing about solutions while seemingly agreeing on the problem.
- Different people would describe the problem differently.
- The "user" is described as everyone (then it's nobody).
- Success looks like "users will love it" (vague).

Common failures here:

- **Skipping define and starting to design.** The most common failure. The team converges on a solution without converging on a problem; everyone designs for a different problem; nothing aligns.
- **Define that's actually a feature spec.** "The user needs a dashboard with filters" — that's a solution, not a problem.
- **Define that's too broad.** "Improve the onboarding experience." Too vague to design against.

### Develop — open the solution space

What it is: exploration. Wide, fast, low-cost generation of many possible solutions. Sketches, wireframes, divergent ideas, deliberately bad ideas, deliberately weird ideas, the obvious idea, the boring idea.

The point is *quantity and diversity*, not quality. The first idea is rarely the best; the eighth idea often pulls something useful out of the second; the sixteenth idea is often the one that gets shipped (in a refined form).

Tools and techniques:

- **Crazy 8s** — 8 sketches in 8 minutes, on paper. Force divergent thinking by quantity pressure.
- **How might we** — reframe the problem statement as multiple "how might we..." questions. Each one is a distinct angle.
- **Sketch sessions** — group exercises where everyone sketches in parallel, then shares.
- **References** — collect designs from other products (not to copy, but to provoke). Pinterest boards, Mobbin, screenshots from your own life.
- **Constraints exercises** — "design this with three buttons only," "design this for someone with one hand," "design this so it works in 5 seconds."
- **Worst possible idea** — deliberately bad ideas, then ask "why is it bad?" The reasons usually surface design principles.

You know you're done with develop when:

- You have at least 5–10 distinct directions to choose from.
- The team has discussed the trade-offs of several.
- Promising directions have been pulled into mid-fidelity wireframes for closer evaluation.

You know you haven't done enough develop when:

- The team converged on the first idea anyone proposed.
- The "design" is the first sketch the lead designer made.
- Nobody can name an alternative direction that was considered and rejected.

### Deliver — close on a solution

What it is: refinement, prototyping, testing, and shipping. The chosen direction gets fleshed out — visual design, microcopy, edge cases, handoff. The design is tested with real users, iterated, tested again, shipped.

This is where most team's design work *feels* like design work — the polished mockups, the Figma libraries, the prototypes. It's also where the *interesting* decisions are mostly already made. If define and develop went well, deliver is execution; if they went badly, deliver is panicked rework.

Activities in deliver:

- **High-fidelity wireframes / mockups.** Real content, real states, real edge cases.
- **Interactive prototypes** for usability testing and stakeholder review.
- **Microcopy** — every label, every button, every error message.
- **Edge cases** — empty, loading, error, success, partial data, no permissions.
- **Accessibility** — WCAG audit, contrast checks, keyboard flows, screen reader walkthrough.
- **Engineering handoff** — specs, tokens, asset export, conversation with the build team.
- **Design QA** — checking the build against the design.
- **Usability testing** — confirming the design works with real users.

Common failures here:

- **Starting with high fidelity.** Wastes time on visual polish before structure is right.
- **Designing the happy path only.** The unhappy paths get bolted on later or not at all.
- **Throwing the design over the wall.** Engineering builds something different; nobody catches it until launch.
- **Treating "deliver" as the end.** The design ships; nobody looks at how it actually performs in production. Then no learning carries forward.

## Divergent and Convergent Thinking

The single most useful skill in design is knowing which mode you're in.

| Mode | Goal | Stance | Worst thing to do |
|---|---|---|---|
| **Divergent** | Generate options, explore breadth | "Yes, and..." | Critique too early; converge prematurely |
| **Convergent** | Choose, narrow, decide | "No, because..." | Generate new options when you should be deciding |

These modes are *incompatible in the same conversation*. Mixing them produces neither good ideas nor good decisions. Two practical rules:

1. **Name the mode out loud.** "We're brainstorming now — no critique yet" or "We're deciding now — no new ideas." The mode-switch is more important than people realize.
2. **Don't let one person do both.** Critique kills generation. Generation frustrates decision-making. Let the team play one role at a time.

## Iteration

Design is iterative because the first attempt is always wrong. The question is not "did we get it right" but "did we learn something from this attempt that improves the next one?"

A useful iteration loop:

1. **Try something.** A sketch, a wireframe, a prototype.
2. **Show it.** To users, to the team, to engineers.
3. **Learn from the reaction.** What worked? What didn't? What's the gap between intention and reception?
4. **Decide what to change.** Specifically. Not "improve everything" but "the empty state is unclear; let's redesign just that."
5. **Repeat.**

The shorter the loop, the more iterations you get; the more iterations, the better the design. Optimize for *cycle time*, not for the perfection of any single iteration.

## Project-Phase Design Work

Design isn't one thing; it's different at different points in a project. A rough mapping:

| Project phase | Design activities |
|---|---|
| **0 → 1** (new product) | Heavy discover, heavy define, mostly low-fidelity sketches, frequent user research |
| **1 → 10** (early growth) | More usability testing, more handoff polish, design system seedlings, growing edge case coverage |
| **10 → 100** (scaling) | Design system infrastructure, accessibility audits, UX writing investment, content design |
| **100 → ∞** (maintenance) | Refactoring, deprecations, technical debt in the design system, accessibility remediation, post-launch research |

Design work in maintenance mode is genuinely different from design work at 0→1. A team that imports its 0→1 habits into a maintenance phase produces churn; a team that imports maintenance habits into 0→1 produces over-cautious, incremental, joyless work.

## When to Skip a Stage

You can't actually skip stages — they happen whether you do them on purpose or not. But you can compress them:

- **Tiny change** ("change this label"): discover and define are done in the head; develop is one option; deliver is a Figma edit. 30 minutes total.
- **Medium change** ("redesign the empty state"): a couple of hours of look-around (discover), a one-line problem statement (define), 4–5 sketches (develop), a polished version (deliver). A day, maybe two.
- **New feature**: real discover (a few interviews or analytics), explicit define (a problem statement), real divergent develop (multiple directions), refined deliver. Days to weeks.
- **New product or major redesign**: full process. Weeks to months.

Match the depth of the process to the size of the decision. A tiny change doesn't need a workshop; a new product needs more than a sketch.

## Anti-Patterns

- **Skipping discover.** The team designs for an imagined user.
- **Skipping define.** The team designs different things in parallel because they hadn't agreed on the problem.
- **Premature convergence.** The first sketch becomes the design; alternatives never explored.
- **Endless divergence.** Ten weeks of "exploration"; nothing ships.
- **Process for its own sake.** Workshops, sticky notes, sprints, ceremony — all for a one-day change. Wastes time.
- **No iteration.** Big bang launch; never tested with users; ships full of preventable bugs.
- **Pretending to iterate but not actually changing anything.** Two "iterations" that are visually identical to the first.
- **Treating "delivery" as the end.** Ship and forget. No post-launch research; no learning carries forward.
- **Designing in stealth.** Show the team only the polished result; no critique along the way; lose the value of fresh eyes.
- **Designing by committee in develop.** Everyone has input; nobody decides; result is a compromise nobody loves.

## Related

- [wireframing-and-prototyping.md](wireframing-and-prototyping.md) — fidelity choices throughout the process
- [design-critique.md](design-critique.md) — structured critique during develop and deliver
- [ux-research/references/discovery-and-problem-framing.md](../../ux-research/references/discovery-and-problem-framing.md) — discover and define in detail
- [ux-research/references/usability-testing.md](../../ux-research/references/usability-testing.md) — usability testing during deliver
- [handoff-and-collaboration.md](handoff-and-collaboration.md) — the deliver-stage relationship with engineering

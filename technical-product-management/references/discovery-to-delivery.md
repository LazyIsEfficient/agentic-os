# Discovery to Delivery

The PM sits at the joint between two different kinds of work: **discovery** (figuring out what to build and why) and **delivery** (building and shipping it). Both are necessary; both have different rhythms; the joint between them is where most product organizations break down.

The two failures:

- **Delivery without discovery.** The team ships things constantly, none of them validated against real users. Feature factory. Most don't move metrics; nobody learns; the team grows tired of shipping things that don't matter.
- **Discovery without delivery.** The team researches endlessly. Beautiful research artifacts, no shipped product. Paralysis dressed as rigor.

The discipline is to do both, in parallel, with a healthy rhythm between them. This file is the playbook for that rhythm.

## The Two Tracks (Dual-Track Agile)

The most useful mental model: **two tracks running in parallel**, one for discovery and one for delivery, with constant flow between them.

```
DISCOVERY TRACK (continuous)
  ↓ research, problem framing, validation, prototype testing
  ↓ outputs: validated problems and shapes
  ↓
  ↓ ────────────► HANDOFF ◄────────────
  ↓                                     ↓
  ↓                                     DELIVERY TRACK (sprint cadence)
  ↓                                     designs, builds, ships, measures
  ↓                                     ↑
  ↓ ────────────── feedback ────────────
  ↓
```

Discovery is *continuous* — running quietly all the time, never stopping. Delivery is *cadenced* — sprints, releases, milestones. Discovery feeds delivery; delivery feeds discovery (post-launch metrics, support tickets, user behavior all flow back into the discovery track).

The PM is the bridge between the two tracks. They make sure discovery is producing things ready for delivery, and that delivery is generating learning that flows back into discovery.

This model is sometimes called *dual-track agile* (Jeff Patton, Marty Cagan). The name matters less than the idea: discovery and delivery are not phases; they're parallel ongoing activities.

## What Discovery Is For

Discovery answers: **what should we build, for whom, and why?**

The work of discovery:

- **Generative research** — understanding the problem space, finding unmet needs, building user understanding. ([ux-research/discovery-and-problem-framing.md](../../ux-research/references/discovery-and-problem-framing.md))
- **Problem framing** — turning research into clear problem statements the team can rally around.
- **Concept validation** — testing whether a proposed solution actually addresses the problem, before committing to building it.
- **Risk reduction** — identifying the things that could make a planned solution fail, and addressing them early.
- **Prioritization input** — collecting the evidence the PM needs to choose what to build next.

The output of discovery is *not* a design or a spec. The output is **a validated problem with enough context that the team can confidently commit to addressing it**. The shaping of *how* to address it happens in delivery.

## What Delivery Is For

Delivery answers: **how do we build, ship, and learn from it?**

The work of delivery:

- **Design** — turning a validated problem into a specific shape ([ux-design](../../ux-design/SKILL.md)).
- **Spec writing** — capturing the what and the why ([prds-and-specs.md](prds-and-specs.md)).
- **Building** — engineering the thing.
- **Shipping** — getting it in front of users (often in phases — see [launches-and-rollouts.md](launches-and-rollouts.md)).
- **Measuring** — instrumenting and watching the metrics that tell you whether the bet paid off.
- **Iterating** — refining based on what you learn.

The output of delivery is *shipped product* and *learning about whether the bet was right*. The learning flows back into discovery.

## Continuous Discovery

The most important shift in modern PM practice: discovery is *continuous*, not a phase.

The old model: do discovery for 6 weeks, hand off to delivery, build for 6 months, launch, do more discovery. The team is starved of fresh user input for most of the cycle; the original research is stale by launch; nobody talks to users between launches.

The new model: ongoing user contact every week, all year. The team always has a fresh sense of who the users are and what they need. Decisions during build can draw on recent user input, not on stale assumptions.

The mechanics of continuous discovery (Teresa Torres' framing):

- **Weekly user contact.** The team talks to 1–3 users per week, ongoing. Not a research project; just a habit.
- **Opportunity exploration**, not "feature validation." The conversations are about understanding the user's world, not about asking "would you use this thing we're building?"
- **A shared opportunity solution tree.** A living artifact mapping the team's understanding of opportunities and the experiments they're running.
- **The team participates.** Not just the researcher. Designers, PMs, engineers all attend conversations. Everyone gets fresh user contact.

Continuous discovery sounds like more work; it's actually less, because the team stops shipping the wrong things. The cost of one wrong feature is much higher than the cost of an hour-a-week conversation habit.

## The Handoff (Discovery → Delivery)

The single most error-prone moment in the dual-track flow: when discovery hands off to delivery.

Bad handoffs look like:

- **Research dumped over the wall.** A 30-page research report; engineering doesn't read it; the build proceeds from the PM's interpretation of the report.
- **Premature handoff.** The problem hasn't been validated yet; delivery is committed; everyone discovers the problem is wrong six weeks in.
- **Late handoff.** Discovery is complete; delivery hasn't started because nobody noticed the handoff moment. The research goes stale.
- **No handoff.** Discovery and delivery are separate tracks that never meet. Delivery builds whatever the PM thinks is right, regardless of what discovery learned.

Good handoffs look like:

### A clear "ready for delivery" signal

The PM (or research lead) declares: "we've validated this problem enough that the team can commit to addressing it. Here's the evidence." This is a *moment*, named, with a clear artifact.

The artifact is usually a one-pager (sometimes a PRD) that captures:
- The problem
- The user
- The evidence
- The desired outcome
- What's still uncertain

It's not a full PRD yet — that comes during delivery — but it's enough to commit.

### The team that built it built it together

The engineers who will ship it have been part of the discovery, even if only by attending a couple of interviews. They know who the user is. They know what the pain feels like. They make better decisions during build as a result.

If engineering's first exposure to the problem is the spec, the handoff was too late.

### Designers are involved during discovery

Design starts before delivery. The designer attended the research; they have a sense of the problem; they can start sketching directions in parallel with discovery wrapping up. By the time delivery starts, the design is far enough along to inform the build.

### Open questions are explicit

The handoff names what's *still uncertain* — things the team will resolve as they go. "We're not sure whether the empty state should suggest templates or go blank; we'll usability-test both during build." This is fine; the alternative (pretending everything is figured out) is worse.

## Validation Loops

Both discovery and delivery have validation loops — opportunities to test whether the team's current bet is right.

### In discovery

- **User interviews** — does the user actually have this problem? ([interview-craft.md](../../ux-research/references/interview-craft.md))
- **Concept testing** — does this approach feel like it would solve the problem? Cheap prototypes, not real builds.
- **Demand testing** — are users willing to take a small action that would indicate real interest? (Click a "request access" link, sign up for a waitlist, etc.)
- **Prototype usability tests** — can users navigate this rough version? ([usability-testing.md](../../ux-research/references/usability-testing.md))

### In delivery

- **Internal review** — does the team think this matches the spec?
- **Internal beta** — does this work for people who know the product?
- **Customer beta** — does this work for real users in the wild?
- **Phased rollout** — does this work at scale? ([launches-and-rollouts.md](launches-and-rollouts.md))
- **Post-launch metrics** — did the bet pay off?
- **Post-launch interviews** — what does usage feel like for real users?

Each loop is a chance to learn the team is wrong before it's expensive to find out. **Skipping loops is the most damaging form of speed**: you go faster until you go off the cliff.

The skill is to *match the loop to the question*. A small change doesn't need a six-week beta; a major redesign shouldn't go straight from designer to public launch. Match the validation depth to the risk.

## When to Research vs When to Build

A common question: how do we know whether the team is in "discovery mode" or "delivery mode" for a given decision?

A useful heuristic:

| Signal | What it means |
|---|---|
| You can't articulate the problem in one sentence | Discovery |
| You can name the user and the situation but not the solution | Discovery, leaning into shape |
| You have a candidate solution but no evidence it works | Late discovery — concept test before committing |
| You have a validated solution but the implementation is unclear | Delivery (early) |
| You have a clear spec and an unclear timeline | Delivery |
| You've shipped and don't know if it worked | Back to discovery (post-launch) |

Most teams err in one direction: they jump to delivery too fast. The fix is to ask, before committing: "What's our evidence that this is the right thing? Could we test this cheaper before building it?"

If the answer is "we don't have evidence; let's just build it and see," that's sometimes okay (small bets, low risk) and sometimes a disaster (big bets, high risk). The PM's judgment is to know which.

## Reducing Discovery Friction

Discovery only works if it's *cheap and routine*, not a special project.

Things that make discovery cheap:

- **A standing recruitment pipeline.** Not having to recruit from scratch every time. A panel, a community, a list of friendly users.
- **Templates for interviews and tests.** Not reinventing the script every time.
- **A regular cadence.** A weekly slot on the team's calendar for user contact. Skipped occasionally, never abandoned.
- **Shared team knowledge.** Notes from past conversations are searchable; new team members can read into the user base quickly.
- **Light synthesis tools.** Affinity mapping in Miro, tags in a doc — not a full research-ops platform.

Things that make discovery expensive:

- **Big-bang research projects.** A 6-week study every quarter; nothing in between.
- **Heavy artifacts.** 30-page reports; nobody reads them; the team learns nothing.
- **Recruitment friction.** Each round starts from scratch; the cost discourages use.
- **Researcher-only practice.** Only the researcher does discovery; the team never gets fresh user contact directly.

The PM's job is to keep discovery cheap so it stays continuous. Whenever discovery starts feeling like a lot of work, look for the friction and remove it.

## Reducing Delivery Friction

Symmetrically, delivery only works if it's *predictable and rhythmic*, not chaotic.

Things that make delivery work:

- **Clear sprint or cycle cadence.** The team knows when work starts and ends.
- **PRDs ready before sprint start.** Not "ready" in the sense of perfect, but "ready enough to commit."
- **Engineering involvement during shaping.** Engineers aren't surprised by the work in sprint planning.
- **Design ahead of engineering.** Design is far enough along that engineering isn't blocked.
- **Clear acceptance criteria.** The team knows when something is "done."
- **A way to ship.** Deploy pipelines that work; release processes that aren't theater.
- **Time reserved for unplanned work.** Bugs, support escalations, surprises — not 100% of capacity allocated.

Things that break delivery:

- **PRDs delivered halfway through the sprint.** Engineering builds the wrong thing or stalls.
- **Designs delivered after the build started.** Engineers re-do work.
- **Too much work in the sprint.** Constant slippage; team morale drops.
- **No definition of done.** Things ship in an unfinished state; QA finds them later.
- **No pipeline.** Manual releases; deploys are an event; risk is concentrated.

The PM's job here is to *unblock the team*. When the team is stuck because they're missing input from the PM (the spec, the priority, the answer to a question), that's the PM's fault to fix.

## Closing the Loop

The most-skipped step in the dual-track flow: feeding the *learning from delivery* back into discovery.

After every shipped feature:

- **Did it move the metric?** (See [metrics-and-evidence.md](metrics-and-evidence.md).)
- **What did users actually do with it?** Watch session recordings, analytics, support tickets.
- **What did we learn that we didn't know before?**
- **What does this change about our next bets?**

The post-launch review is where the team converts a shipped feature into *organizational learning*. Without it, the team ships, ships, ships and gets no smarter. With it, each ship makes the next one better.

A useful cadence: a 30-minute post-launch retrospective, 2–4 weeks after launch, with the team that built it. Not a postmortem (no blame); a learning exercise. What worked? What didn't? What surprised us?

The output is one or two specific lessons that go into the team's permanent memory and inform future bets. Over a year, these lessons compound. A team that does post-launch reviews well gets dramatically better at the work.

## Anti-Patterns

- **Discovery as a phase.** Done once at the start; never again. The team operates from stale assumptions for the rest of the year.
- **Delivery without discovery.** Ships features; none validated; feature factory.
- **Discovery without delivery.** Research, decks, frameworks; nothing ships.
- **Research dumped over the wall.** Engineering reads a 30-page report (or doesn't); learns nothing.
- **Premature handoff.** Spec finalized before the problem is validated; team builds the wrong thing.
- **Late handoff.** Research goes stale before the team starts building.
- **Engineering excluded from discovery.** Engineers never meet a user; build from imagination.
- **Designers excluded from discovery.** Designs are based on the spec, not on user understanding.
- **No closed loop.** Ships and forgets; doesn't measure post-launch; doesn't learn.
- **Research as theater.** Lots of research artifacts; none of them inform decisions.
- **Skipping validation.** Big bets shipped with no concept testing or beta. Disasters at scale.
- **Skipping iteration.** Ship and move on; never come back to refine.
- **Validation only after build.** Usability test reveals fundamental problems; too late to change.
- **No fresh user contact.** The team's mental model of the user is from a year-old persona; reality has moved.
- **The PM as gatekeeper to users.** Only the PM talks to users; the team relies on the PM's interpretation. Loses signal.
- **No post-launch review.** Each shipped feature teaches the team nothing.
- **PM owning all the discovery.** Researchers and designers excluded; PM's biases dominate the synthesis.
- **Discovery for things that are obviously needed.** Sometimes the team just *knows*; spending two weeks "validating" is wasted effort.
- **No discovery for things that are obviously needed but actually wrong.** The team is sure; the user disagrees; nobody asked.

## Related

- [product-strategy.md](product-strategy.md) — strategy informs which problems are worth discovering
- [prioritization.md](prioritization.md) — discovery output feeds prioritization
- [roadmapping.md](roadmapping.md) — the roadmap is a hypothesis; discovery validates it
- [prds-and-specs.md](prds-and-specs.md) — PRDs are the artifact at the discovery-delivery boundary
- [launches-and-rollouts.md](launches-and-rollouts.md) — the post-build half of delivery
- [metrics-and-evidence.md](metrics-and-evidence.md) — closing the loop after launch
- [ux-research](../../ux-research/SKILL.md) — the discovery side, in depth
- [ux-design](../../ux-design/SKILL.md) — the design side of delivery
- [system-architect](../../system-architect/SKILL.md) — the engineering side of delivery

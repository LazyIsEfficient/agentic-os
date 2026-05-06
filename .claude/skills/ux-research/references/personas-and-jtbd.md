# Personas and Jobs-To-Be-Done

Personas and JTBD are the two most common artifacts produced by user research, and the two most commonly produced as theater. A persona poster on a wall that nobody references is a product of the team's anxiety, not its understanding. A JTBD statement that nobody can name a decision-by is the same.

This file is about doing them well *or* declining to do them at all. The middle ground — "we have personas because we should" — is wasted effort.

## When Each Helps (And When It Doesn't)

| Question | Tool |
|---|---|
| Who is our user? (broad strokes, for new team members) | Persona |
| What is the user trying to accomplish in a given situation? | JTBD |
| How is segment A different from segment B? | Persona |
| What pulls a user from one solution to another? | JTBD (switching event) |
| How do we explain the user to a non-product audience (sales, marketing, support)? | Persona |
| How do we decide which feature to build? | JTBD (most often) |
| What does a user's day look like? | Journey map (a related artifact) |
| Who specifically should we test with? | Persona, recruitment criteria |

The high-level distinction:

- **Personas** are about *who* the user is — a synthesized archetype with demographics, behaviors, goals, motivations.
- **JTBD** is about *what* the user is trying to do — a description of a job, deliberately ignoring who's doing it.

For most product decisions, JTBD is more actionable. For onboarding new team members and aligning a team's mental model of the user base, personas often work better. **You don't have to pick one.** Many mature teams use both.

## Personas — Done Well

A useful persona is:

- **Built from real research**, not from the team's imagination or marketing's segmentation.
- **Based on patterns of *behavior and motivation*** more than demographics.
- **Specific enough to drive decisions** ("would Maria use this feature? probably not — she's already overwhelmed and skeptical of new tools").
- **Living** — updated when research surfaces new patterns.
- **A small set** — usually 2–4. More than that and the team can't keep them straight.
- **Differentiated** — each persona is *different from the others* in meaningful, decision-relevant ways.

A useful persona is *not*:

- A photo of a stock person with their age and a cute name.
- A wishlist of demographic attributes.
- An average ("our user is 34, 50% female, has 1.7 kids").
- A marketing buyer profile dressed up as UX work.

### Anatomy of a useful persona

Sections that earn their place:

- **Name and one-line description.** Memorable. Not "Persona A."
- **A real quote** from research that captures the essence. Quotes are sticky in a way that descriptions aren't.
- **Goals and motivations.** What this person is trying to accomplish in their work or life that the product is part of.
- **Frustrations / pain points.** Where the current world fails them.
- **Behavior patterns.** How they actually do things — not aspirations.
- **Context.** Where they work, who they collaborate with, what tools they live in.
- **What this persona means for design decisions.** "When designing for Maria, prioritize speed over flexibility."

Sections that don't earn their place:

- **Stock photo.** Risks ageism, gender bias, and the team treating them as cute trivia.
- **Demographics**. Useful only if they actually predict behavior. Most don't.
- **"Bio" of personal life.** Cluttering and rarely informs design.
- **Tech literacy bar charts.** Theater. (If it matters, say it in plain English.)

### Worked example

> ## Maria — The Overwhelmed Coordinator
>
> > "I'm not opposed to new tools. I'm opposed to having to learn another one this week."
>
> Maria is a project coordinator at a 40-person marketing agency. She runs four to six projects at any given time, mostly for mid-size B2B clients. Her job is to keep things from falling through the cracks.
>
> **Goals**
> - Hand off work between team members without losing context.
> - Surface what's blocked, before it's a fire drill.
> - Make her clients feel taken care of without overpromising.
>
> **Frustrations**
> - Tools that require multiple steps to do anything routine.
> - Notifications that bury the urgent ones in the noisy ones.
> - Features she has to re-learn after each release.
>
> **How she works**
> - Lives in email and Slack. Reluctant to add more apps to the rotation.
> - Drafts in spreadsheets and docs first, then enters into the formal tool only when something is "real."
> - Escalates by Slack DM, not by ticket comment.
>
> **Context**
> - 5–10 hours a week of meetings.
> - 3 monitors, all stuffed with tabs.
> - Reports to a Head of Operations who reviews her in monthly 1:1s.
>
> **What this means for design decisions**
> - Speed matters more than flexibility. Maria will not configure something complex.
> - In-product notifications are background noise. Email digest is more reliable.
> - Onboarding for new features must be inline; she will not read documentation.
> - Bulk operations beat one-at-a-time flows for her workflows.

This persona is *useful* because every design choice can be tested against it: would Maria do this? Would she ignore it? Would she abandon it after one frustrated try?

### Validating a persona

A persona is valid only if you can:

1. **Recruit to it.** A real person must be findable who matches the persona — not exactly, but in the meaningful patterns.
2. **Disconfirm it.** What evidence would make you re-do this persona? If you can't name any, it's a static stereotype.
3. **Distinguish it from other personas.** What does "Maria" have that "James" (your other persona) doesn't? If you can't say, you have one persona, not two.
4. **Cite the research.** "This persona is based on study X (n=8) and study Y (n=12). Last validated 2026-Q1."

If a persona fails these checks, retire or rebuild it.

### Keeping personas alive

A persona that nobody references after the launch event is dead. Practices that keep them alive:

- **Cite them in design reviews.** "Would Maria do this?" "How does James experience this?"
- **Recruit by persona.** When planning a usability test, the recruitment criteria reference the persona.
- **Update annually.** Research evolves; personas shouldn't be set in stone. A yearly refresh keeps them honest.
- **Retire when they stop being useful.** A persona that no longer matches the user base is misleading. Kill it explicitly.

## Jobs-To-Be-Done — Done Well

A JTBD is a description of a *job* a user is trying to accomplish, deliberately ignoring *who* the user is. Two people in completely different demographics may share the same job; the same person has different jobs in different situations.

The classic articulation: a customer doesn't buy a quarter-inch drill. They buy a quarter-inch hole. The job is "make a hole," not "own a drill."

### The format

A job statement has three parts:

> When `<situation>`, I want to `<motivation>`, so I can `<expected outcome>`.

Three rules for writing them:

1. **The situation is specific.** Not "I'm at work" but "I'm onboarding a new contractor on day 1."
2. **The motivation is the immediate action.** Not "use the product" but "give them access to only the projects they're working on."
3. **The outcome is the *real* goal**, often emotional or relational. Not "have permissions set" but "not have to worry about them seeing client work that isn't theirs."

The outcome is what the user is *really* hiring the product to do. The motivation is the proximate action; the outcome is why it matters.

### Worked examples

> When I'm reviewing a PR on my phone in line at the coffee shop, I want to leave a comment without typing on a tiny keyboard, so I can keep the review moving without making the team wait until I'm back at my desk.

> When I'm onboarding a new contractor to my agency on their first day, I want to give them access to only the projects they're working on, so I don't have to worry about them seeing client work that isn't theirs and I don't have to spend the morning copy-pasting permissions.

> When I'm trying to estimate a sprint and I'm not sure how long similar tasks have taken in the past, I want to see history without leaving the planning view, so my estimate is grounded in evidence and the team trusts it.

What these have in common: they describe a *moment* in someone's life with enough specificity that a designer can imagine the situation, the friction, and the relief.

### Finding jobs

Discovery interviews oriented around the *situation* and the *most recent specific instance*, not around the product. See [interview-craft.md](interview-craft.md) for the technique.

Two especially powerful prompts:

- **"Walk me through the last time you `<situation>`."** Concrete, recent, real.
- **"When was the last time you switched from one way of doing this to another?"** Switching events expose what was wrong with the previous solution and what the new one had to deliver.

### Validating a JTBD

A useful JTBD is one where you can:

1. **Find people in the situation it describes.**
2. **Hear them describe the same outcome in their own words** (not necessarily the exact phrasing).
3. **Name a design decision** that would change based on whether this job is or isn't a priority.

If a JTBD can't drive a design decision, it's a wishlist item, not a job.

### Outcome-driven innovation

A more rigorous variant of JTBD asks users to rate desired outcomes by *importance* and *satisfaction*. Outcomes that are highly important and poorly satisfied are opportunities. The math is simple: opportunity score = importance + max(0, importance − satisfaction).

This is most useful for B2B and enterprise contexts where you can survey a clear segment. For consumer or early-stage work, the qualitative version is usually enough.

## Personas vs. JTBD — The Trade-Off

| Aspect | Personas | JTBD |
|---|---|---|
| Centered on | Who the user is | What the user is doing |
| Best for | Aligning a team's mental model; communicating with non-product audiences | Driving feature decisions; identifying opportunities |
| Risk | Stereotyping; static thinking; treating average as universal | Abstraction without humanization; team can't picture the user |
| When to build | Once per major segment; refresh annually | Continuously, as discovery surfaces new jobs |
| When NOT to build | Early-stage, when segments aren't yet clear | Late-stage, when the question is about who, not what |

**You can have both.** Many mature teams use personas to align the *who* and JTBD to drive the *what*.

A common pattern: a persona has *several JTBD* attached to it — the things this kind of user is trying to accomplish. The JTBD tells you which feature to build; the persona tells you who you're building it for.

## Journey Maps (Briefly)

A *journey map* is a visualization of a user's experience over time, often showing emotional state, touchpoints, and pain points across stages of an interaction.

When journey maps help:

- **Multi-step workflows** where each step is part of a larger arc (onboarding, customer support escalation, signup-to-activation).
- **Cross-team alignment** — a journey map shows where the experience crosses team boundaries and where handoffs go wrong.
- **Surfacing the "between" steps** the team forgets about (e.g. the email that arrives after a form submission, the day the user has to wait, the moment of frustration before they call support).

When journey maps are theater:

- **Single-screen interactions** that don't unfold over time.
- **Brand-new domains** where you're imagining the journey rather than mapping a real one.
- **Maps so generic** they could describe any product ("user discovers, evaluates, purchases, uses, advocates"). If a map says nothing specific, delete it.

A useful journey map is research-driven, specific, and emotionally honest. Mark the bad moments more prominently than the good ones — those are where the design work is.

## Anti-Patterns

- **Marketing personas dressed up as UX personas.** The marketing team's segmentation cards make poor design tools — they're built for buying, not using.
- **Personas without research.** "Let's whiteboard our personas this afternoon." Imagined; static; useless.
- **Too many personas.** 7 personas means the team can't remember which is which. Cut to 2–4.
- **Static personas.** Set in stone in 2022, still on the wall in 2026, no longer match the user base. Kill or refresh.
- **Demographic-only personas.** "33-year-old female product manager" tells you nothing useful.
- **JTBD as a feature wishlist.** "I want a button that does X." That's a feature request, not a job. Re-frame as situation + outcome.
- **JTBD without situation.** "I want to manage my projects." Too abstract; describes everyone.
- **JTBD without outcome.** "I want to click the export button." Means nothing about the *why*.
- **Persona-poster syndrome.** Beautiful artifacts on the wall; nobody references them in any decision. Theater.
- **Cherry-picking participants to fit a persona.** Recruiting only people who match the existing persona; missing that the user base has shifted.
- **Confusing persona with target user.** A persona is a research artifact; a target user is a marketing decision. Same underlying data, different uses.
- **Building a journey map for a thing that doesn't have a journey.** A single-screen interaction is not a journey. Don't force it.

## Related

- [research-methods.md](research-methods.md) — generative research that produces both personas and JTBD
- [discovery-and-problem-framing.md](discovery-and-problem-framing.md) — JTBD as the framing for discovery
- [interview-craft.md](interview-craft.md) — JTBD interviews and probing for situations
- [synthesis-and-insights.md](synthesis-and-insights.md) — turning interview data into personas or jobs
- [communicating-findings.md](communicating-findings.md) — making personas and JTBD actually used by the team
- [ux-design](../../ux-design/SKILL.md) — the consumer of personas and JTBD

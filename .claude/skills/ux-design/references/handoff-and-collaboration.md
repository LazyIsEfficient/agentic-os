# Handoff and Collaboration

The handoff is the moment the design moves from designer to engineer to be built. The premise of this file is that **handoff is not a moment** — it's a relationship that begins early in the design process and continues through ship and beyond. Treating it as a single moment ("here's the Figma, build it") produces drift, missed details, and friction.

The pattern that fails:

1. Designer designs in isolation.
2. Designer hands off the Figma file at the end.
3. Engineer builds something different from the design.
4. Designer notices at QA, but it's too late to change much.
5. Both sides blame each other.

The pattern that works:

1. Designer and engineer talk about the problem early.
2. They sketch trade-offs together.
3. The designer iterates with engineering input.
4. The engineer builds with the designer available for questions.
5. The designer reviews the build before launch and pairs on fixes.
6. Both sides feel they shipped together.

This file is about the second pattern.

## Engineering as a Design Constraint

Engineering capacity, technical feasibility, and existing patterns all constrain what can be designed. A designer who treats these as inconveniences fights with engineering throughout the project. A designer who treats them as part of the design problem produces better, more buildable work.

Some things that should constrain design:

- **What the design system already supports.** A new component is an order of magnitude more expensive than reusing an existing one. If the existing one is "almost right," prefer it unless the difference is genuinely user-impacting.
- **What the platform supports.** Web, iOS, Android, desktop — each has its own conventions, capabilities, and gotchas. Ignoring them creates a custom UI that fights the platform.
- **Performance.** A design that requires loading 5MB of data on first paint is not a good design even if it tests well in usability.
- **Backend reality.** A design that assumes data is real-time when the backend can only provide it daily is a bug.
- **Existing user behavior.** A design that requires users to re-learn navigation they've used for years has to be *really* worth the disruption.

A useful design principle: **the buildable design is usually better than the unbuildable design**. Constraints sharpen thinking. A designer who can't articulate engineering trade-offs is designing in a vacuum.

## Talk to Engineers Early

The single most valuable thing a designer can do for handoff is **talk to engineers during design**, not after. Specifically:

- **Before committing to a direction**, sketch with an engineer. What's hard? What's easy? Where would you push back?
- **Before high-fidelity work**, walk through the wireframe with the engineer who will likely build it. Anything they'd flag?
- **Throughout build**, be available for questions — Slack, async, or scheduled.
- **After ship**, debrief together. What went well? What was unclear? What should we do differently next time?

Engineers who feel like collaborators ship designs more faithfully than engineers who feel like recipients of a deliverable. The quality of the relationship is reflected in the product.

## What Belongs in a Handoff

When the design is ready to build, the engineer needs:

- **The design itself** — Figma file, prototype, mockups for all states.
- **The states**: default, hover, focus, active, disabled, loading, error, empty, partial, success. All of them, not just the happy path.
- **The responsive behavior** — what happens at different breakpoints. Not just "responsive"; specifically what.
- **Spacing and layout values** — from the design system tokens, not arbitrary numbers.
- **Color and type** — referenced as tokens, not as hex codes.
- **Microcopy** — final words, not lorem ipsum. Including button labels, errors, empty states, loading messages.
- **Accessibility behavior** — keyboard order, focus management, ARIA roles, screen reader narration, color contrast verified.
- **Edge cases and validation** — what's the maximum string length? What if a field is empty? What if there are 1,000 items? What about 0?
- **Animation timing** if any — duration, easing, what triggers it.
- **External dependencies** — icons, fonts, images, data sources.
- **The intent** — what is this design trying to do for the user? Why this and not that?

The engineer should be able to build the design without having to guess at any of the above. If they have to guess, the handoff is incomplete.

### What's intentional vs. what's draft

The single biggest source of handoff confusion: the engineer can't tell what's intentional and what's placeholder. Lorem ipsum that was supposed to be replaced gets shipped. A misaligned grid that was "we'll fix later" gets built exactly as drawn.

Mark explicitly:

- **Lorem ipsum** with a note: "TODO: real copy from PM by Friday."
- **Placeholder images** with a note: "Stock image; final asset coming."
- **Approximate spacing**: "8px (token: spacing.2)" or just use the token in Figma so the spec is unambiguous.
- **Trade-offs being discussed**: "I'm not sure about this; let's sync before you build it."

When in doubt, leave a note in the Figma file at the relevant frame.

## Design Tokens as Contract

The strongest version of design-engineering collaboration uses **design tokens** as the shared contract. The same token values exist in:

- The Figma library (so designers see real values).
- The design system code (so engineers reference them by name).
- The compiled CSS / theme (so the production build uses them).

When a designer picks `color.action.default` in Figma, the engineer doesn't need to look up the hex value — they import the same token. When the brand color changes, both the design and the code update from the same source.

This eliminates entire categories of handoff bugs:

- **No more "the blue in the design is slightly different from the blue in the build."**
- **No more "what padding goes here?"** — the spacing token answers it.
- **No more drift** between the design system and what's actually shipping.

For a deeper discussion, see [design-systems.md](design-systems.md).

## Specs and Documentation

The Figma file is necessary but not sufficient. For non-trivial features, you also need:

- **A short design document** explaining the user problem, the chosen solution, the rejected alternatives, and the trade-offs. Engineers reference this when they're not sure why something is the way it is.
- **A flow diagram** for multi-step processes. Helps engineers understand the system, not just the screens.
- **Acceptance criteria** in the ticket. What does "done" look like? What states must work? What can be deferred to a follow-up?
- **A list of edge cases** to handle.

The design document doesn't need to be long — a one-pager is often enough. But it should exist for anything more complex than a single-screen change. Without it, the engineer makes decisions without context, and the decisions are sometimes wrong.

## Engineering Estimates and Trade-offs

When an engineer says "this would take a week, the alternative would take a day" — listen. The right design isn't always the most ambitious one. Sometimes the simpler version is *better* because it ships sooner, has fewer bugs, and frees the team to test the idea before committing more.

A designer who insists on the more expensive version every time is spending engineering capital they didn't earn. A designer who always defers is letting engineering shape the product. The right balance: take engineering trade-offs as serious input, push back when the difference matters to users, accept when it doesn't.

A useful framing for trade-off conversations:

> "The full version is X, which would be a week. A scaled-back version that hits the main user need would be Y, which would be a day. Here's what we'd lose with Y: `<list>`. I think Y is enough for v1; we can revisit if usage shows we need more. What do you think?"

Bring options. Bring the trade-off. Decide together.

## Being Available During Build

The designer's job doesn't end at handoff. During the build:

- **Be reachable.** When the engineer has a question, fast answers prevent guessing.
- **Resist the urge to redesign during build.** "Actually, let me change this" mid-sprint is expensive. Note the change for the next iteration.
- **Pair on the tough parts.** Some interactions only become clear in code. Sit with the engineer when they're building something subtle.
- **Look at the build, not just the Figma.** As soon as something is buildable, see it in the browser. What looks right in Figma sometimes looks wrong in code.

## Design QA

Before launch, the designer (or another designer) reviews the build against the design. This is not nitpicking — it's catching the things that drift between design intent and built reality.

What to check:

- **Spacing.** Are paddings and margins correct? Are gaps between elements right?
- **Type.** Right size, right weight, right line height, right color?
- **Color.** Does everything use the right token?
- **States.** Hover, focus, active, disabled — all behave as designed?
- **Empty / loading / error states.** Built and look right?
- **Responsive.** All breakpoints working?
- **Accessibility.** Keyboard works? Screen reader sounds right? Contrast passes?
- **Microcopy.** Final words, no placeholders?
- **Edge cases.** Long names, long URLs, empty values, partial data?

A useful tool: a side-by-side comparison of the Figma frame and the built screen. Differences are usually small but add up. File them as bugs; pair on the fixes.

### Pixel-perfect vs. intent-perfect

Don't insist on pixel-perfect. Insist on intent-perfect. A 2-pixel difference in spacing isn't worth a fight; a missing focus state is.

Reserve QA capital for the things that matter. Most engineers will fix five small issues if you also let them ship without the sixth. They'll fight you on every issue if you insist on every issue.

## Post-Launch

Handoff doesn't end at launch. The most valuable design work often happens *after*:

- **Look at how the design is performing.** Analytics, usage, support tickets, user feedback.
- **Notice the gap between what you designed and what users do.** That gap is the next iteration.
- **Listen for engineering pain.** "This part was a nightmare to build" is feedback for the next design.
- **Update the design system** if the work surfaced patterns worth codifying.
- **Update the Figma** if the build diverged from the design and the build is correct. Don't let the design and the code drift apart.
- **Postmortem** if the launch went badly. What was the gap between design and reality?

A team that ships and forgets repeats its mistakes. A team that ships and learns gets better.

## Tooling

Some tools that help:

- **Figma's Inspect mode** — engineers can pull spacing, colors, type from the design.
- **Figma Code Connect** — links Figma components to their code counterparts.
- **Storybook** — engineers see the canonical built component; designers can verify against it.
- **Tokens Studio** — manages tokens between design and code.
- **Linear / Jira** — tickets where design and engineering collaborate.
- **Loom** — short async videos for explaining design intent without a meeting.

The tools matter less than the relationship. A team with great tools and bad collaboration ships worse than a team with no tools and great collaboration.

## Anti-Patterns

- **"Throw it over the wall."** Designer hands off Figma; never speaks to engineer; engineer guesses; ships wrong.
- **"It's in the Figma."** Yes, but the Figma doesn't capture intent, edge cases, or accessibility. Talk.
- **Designing without engineering input.** First time engineering sees it is at handoff. Then "this is impossible" or "this would take a month."
- **Designing in stealth, presenting at the end.** Same problem. No iteration, no buy-in.
- **Pixel-perfect QA.** Designer files 47 bugs about 2-pixel differences. Engineer learns to dread design QA.
- **No QA.** Designer never looks at the build. Production drifts from design unchecked.
- **Lorem ipsum at handoff.** Engineer ships lorem ipsum.
- **Edge cases not specified.** Engineer guesses at what to do when the field is empty; sometimes guesses wrong.
- **No notes about intent.** Engineer doesn't understand *why* the design is shaped a certain way; can't make sound decisions when the design doesn't cover a case.
- **Designer rewrites in the middle of build.** "Actually, let me change this." Expensive; eats sprint capacity.
- **Design changes that aren't communicated.** Designer updates Figma; engineer doesn't notice; build is now stale.
- **Engineer makes design changes that aren't communicated.** Engineer "fixes" something; design now doesn't match build.
- **Engineering estimates ignored.** Designer insists on expensive version; project slips.
- **Engineering treated as a service desk.** "Just build what I designed." Loses the collaboration value.
- **Friction blamed on the other side.** "Engineering just doesn't get it" / "Design is impractical." Both sides are responsible for the relationship.

## Related

- [design-process.md](design-process.md) — handoff happens in deliver, but the relationship starts earlier
- [design-systems.md](design-systems.md) — tokens as the shared contract
- [accessibility.md](accessibility.md) — accessibility specifications in handoff
- [content-and-ux-writing.md](content-and-ux-writing.md) — final words at handoff time
- [design-critique.md](design-critique.md) — engineers in critique help with handoff later
- [team-lead](../../team-lead/SKILL.md) — managing the design ↔ engineering relationship at the team level
- [software-design](../../software-design/SKILL.md) — engineers' view of the same handoff
- [assets/handoff-checklist.md](../assets/handoff-checklist.md) — pre-handoff checklist

# Wireframing and Prototyping

A wireframe is a low-fidelity representation of a layout. A prototype is something the user (or stakeholder) can interact with — click through, navigate, sometimes input data. Both are tools, used at different stages, for different questions.

The most common and most damaging mistake in this area: **using too much fidelity, too early**. A polished mockup before the structure is right wastes time, biases feedback toward visual things, and produces designs that feel finished before they actually work.

The discipline: **fidelity matches the question**.

## The Fidelity Spectrum

| Fidelity | What it tests | What it doesn't test | When to use |
|---|---|---|---|
| **Pen-and-paper sketch** | Concept, basic structure, "is this idea worth pursuing?" | Anything visual, polish, brand | First exploration of a problem space |
| **Whiteboard / Miro sketch** | Concept, group discussion of structure | Same | Early collaborative sessions |
| **Low-fi wireframe** (Balsamiq, Figma low-fi) | Layout, IA, content priority, basic flow | Visual hierarchy, brand, motion, micro-interactions | Once the concept is chosen, working out structure |
| **Mid-fi wireframe** | Real layout, real spacing, content priority, basic interactions | Brand specifics, polished interactions, edge cases | Iterating on a chosen direction |
| **High-fi mockup** (Figma) | Visual hierarchy, brand, microcopy, color, exact layout | Real performance, real data, animation timing | Final visual decisions; usability testing on look-and-feel |
| **Interactive prototype** (Figma prototype, Framer, code) | Click flow, interactions, perceived behavior, usability | Real backend, real latency, edge cases | Usability testing, stakeholder review, dev handoff |
| **Coded prototype** | Real interactions, real performance, real responsiveness, dev feasibility | Production-ready details, full edge cases | Late-stage validation, complex interactions |
| **Live in production** | Everything | Things you can't change anymore | Post-launch refinement |

The single most useful question when picking a fidelity: **what am I trying to learn?** If the answer is "is this concept worth pursuing," a sketch is enough. If the answer is "does the click flow work for first-time users," a clickable prototype. If the answer is "do the brand colors land," a high-fidelity mockup. Match the tool to the question.

## When Higher Fidelity Hurts

This is the part most teams underestimate. Higher fidelity doesn't just take longer to make — it actively *biases the conversation* toward the wrong things.

Show a polished mockup to a stakeholder, and they comment on the colors, the icon style, the brand alignment. Show the same idea as a sketch, and they comment on the structure, the priority, the missing concepts. Same content, different feedback, all because of fidelity.

Specific failure modes of premature high fidelity:

- **Stakeholders treat the design as "done"** because it looks done. Hard to change later.
- **Feedback is about polish, not structure**. The structural problems go undiscussed and ship.
- **Sunk cost takes over**. After 8 hours of polishing, you don't want to throw it away. So the bad direction survives.
- **Engineers start estimating** from the polished mockup, locking in implementation choices that the rough version would have left open.
- **Users in usability tests focus on visual reactions** ("the colors are nice") instead of behavioral signals ("I can't find the button").

The cure: **start lower fidelity than feels comfortable**. The first few iterations should look so rough that nobody could mistake them for finished work.

## When Lower Fidelity Hurts

The opposite failure also exists. There are situations where higher fidelity is necessary:

- **Visual hierarchy is the question.** Sketches don't have hierarchy.
- **The microcopy is the design.** Real words, not lorem ipsum.
- **The interaction *is* the design.** Animation timing, transitions, perceived performance — these need a real prototype.
- **The brand is the question.** Sketches can't test brand.
- **Stakeholders need to feel it's real** (be careful: this is sometimes a real need, sometimes a request for theater).

Knowing when to climb the fidelity ladder is the second skill.

## Wireframing — Operating Guide

### Sketching first

Even if you'll move to Figma in an hour, **start on paper or whiteboard**. The constraint of the sketch (no Figma plugins, no component library, no copy-pasting) forces you to think about structure rather than tools.

Crazy 8s — 8 sketches in 8 minutes — is a useful warmup. The volume forces you past the obvious first idea.

### Use real content where you can

Lorem ipsum hides design problems. Real content (or reasonable approximations of real content) reveals them. A column that fits "Lorem ipsum dolor sit amet" might not fit "Q3 Sales Performance Report — North American Region — Updated 6 minutes ago."

Especially:

- **Real labels** for real fields ("Customer email address" not "Field 1").
- **Real data lengths** — long names, edge case prices, very-long URLs, empty values.
- **Real numbers** — your dashboard with "47" looks different from your dashboard with "1,247,832."

### Wireframe the unhappy paths

The single biggest wireframe failure: only the happy path. Then loading, empty, error, partial, and edge-case states get bolted on under deadline pressure.

A wireframe that doesn't show:

- Empty state
- Loading state
- Error state
- Maximum data state (long lists, long names, overflowing values)
- Permission-denied state
- Disabled state

… is half a wireframe. Designing the unhappy paths *is* designing.

### Don't dwell

Each wireframe is a draft, not a deliverable. Spend less time than feels right. A wireframe that took 30 minutes is worth iterating on; a wireframe that took 4 hours is hard to throw away.

The exception: wireframes used for usability testing or stakeholder alignment need slightly more polish — enough that the test participants and stakeholders can engage with them without confusion.

## Prototyping — Operating Guide

A prototype is a wireframe (or mockup) made interactive. The user can click, type, navigate. The point is to test the *experience*, not the implementation.

### Match the prototype to the test

The prototype only needs to support the specific tasks you're testing. Don't build every possible screen — build the path through the screens the test exercises.

Example: if you're testing "can users sign up and create their first project," your prototype needs:
- The signup screen
- The empty state after signup
- The "create project" flow
- The project just created

It doesn't need: settings, billing, account management, search, integrations, anything else. Don't build them.

### Two ways to fail at prototype scope

- **Too much.** Building every screen, then testing only 4 of them. Wasted effort.
- **Too little.** Building only the happy path, then having the test break when the user clicks anywhere unexpected. Frustrating for the participant; degraded data quality.

The right scope: **build the screens the user might naturally click**. Anticipate one or two reasonable detours from the happy path so the user doesn't hit a dead end during the test.

### Tools

| Tool | Best for |
|---|---|
| **Figma prototype** | Most cases. Click-through prototypes with simple interactions. Industry standard. |
| **Framer** | More sophisticated interactions, animations, real components. |
| **ProtoPie** | Complex multi-touch, sensor input, conditional logic. |
| **Maze, UserTesting** | Wraps a Figma prototype with task tracking and unmoderated test infrastructure. |
| **HTML / React prototype** | When you need real responsiveness, real input handling, or want the prototype to evolve into the production code. |

For most product designers, Figma is the default and is enough for ~80% of testing.

### Prototype state and data

A prototype with one user, one project, one item, and one set of values feels artificial. Build a small set of representative data:

- **A few users** with different names, avatars, roles.
- **A few projects** in different states.
- **Realistic values** including some edge cases.
- **Some items already there** so the user isn't always starting empty.

The prototype data shapes what the user notices. Realistic data produces realistic feedback.

### Prototype scope — be honest

If a participant says "I'd want to do X here," and X isn't in the prototype, *acknowledge it explicitly*: "Yeah, that's not built in this version — assume it would do something reasonable. What would you have expected to happen?"

Pretending the prototype is more complete than it is teaches the participant to be wrong about the product. Honesty produces better data.

## Design Tokens (Briefly)

If your wireframes / prototypes use a design system, the visual properties (colors, spacing, type sizes) come from **design tokens**. The same tokens used in code.

For early wireframes: don't bother. The structural decisions are the point.

For later mockups: use the actual tokens from your design system, so the design hands off cleanly.

For more on tokens, see [design-systems.md](design-systems.md).

## Common Wireframe / Prototype Mistakes

### Lorem ipsum syndrome

Filler text everywhere. Hides:

- Real label lengths.
- Real readability of the chosen typography.
- Real comprehension when content is what matters.
- Real edge cases where content overflows or runs short.

### One-state syndrome

The wireframe shows one user, one item, one project, one moment in time. Misses:

- Empty state
- Loading state
- Error state
- Multi-item / list states
- Long-name / long-value states
- Permission states

### Polished too early

The first sketch is in Figma. The first Figma version uses the brand colors. The first usability test gets feedback about the buttons, not the structure. The structural problem ships.

### Interactive prototype used for visual decisions

A clickable prototype tests the click flow. It's a poor tool for testing whether the colors are right (use a static high-fidelity image) or whether the IA is right (use a tree test).

### Brand-locked from the start

Wireframes that already include the brand colors and typography. Now changing the underlying structure is "harder" because it'd mean redoing all the visual work.

### Not pairing with engineering

The designer prototypes; the engineer estimates from the prototype; nobody discusses *whether the prototype is buildable*. Then the prototype contains things that take 10x longer to build than reasonable alternatives.

### Ignoring responsive

Wireframes only at desktop width. The mobile version is invented later by guessing. Different visual hierarchy, different priorities, no chance to test mobile-first decisions.

### Wireframes as deliverables

The wireframe becomes the spec. Engineering builds exactly the wireframe, including the things that were "placeholder," the lorem ipsum, the misaligned grid that "we'll fix later." Discuss what's intentional and what's draft.

### Version sprawl

Twelve versions of the wireframe, none labeled, none current, nobody knows which is the right one. Use clean naming or a single "current" version that gets updated.

## A Useful Workflow

A pragmatic flow from problem to handoff:

1. **Sketch** on paper or whiteboard. 30 minutes. Multiple ideas.
2. **Pick a direction** with the team. Discuss trade-offs.
3. **Low-fi wireframe** of the chosen direction. Real content where possible. All states.
4. **Critique.** Show the team. Take feedback. Iterate.
5. **Mid-fi wireframe.** Real layout, more polish. Still low color, low brand.
6. **Usability test** if the question is "does this work."
7. **Iterate.** Fix what the test broke.
8. **High-fi mockup.** Real visuals, real microcopy, all states.
9. **Critique** again. Final visual decisions.
10. **Prototype** for any complex flows that need stakeholder review or another usability test.
11. **Handoff** to engineering. Specs, tokens, asset export, design QA plan.

The total time depends on the scope. A small feature is a day; a major flow is a few weeks. The proportions matter more than the absolute numbers — sketching and low-fi should consume more time than polishing.

## Anti-Patterns

- **Polished too early.** Real fidelity before real structure.
- **Lorem ipsum everywhere.** Content blindness.
- **Happy path only.** Empty, loading, error, edge — all skipped.
- **Brand-locked from sketch one.** Hard to change structure without redoing visuals.
- **Prototype as production-ready.** Building every screen; takes weeks; not a prototype anymore.
- **Static mockup instead of click prototype** when the question is about the click flow.
- **Click prototype instead of static mockup** when the question is about visual hierarchy.
- **Wireframes nobody iterates on.** First draft becomes final design.
- **Wireframes nobody hands off.** Engineering rebuilds from a screenshot in chat.
- **Pixel-perfect at every step.** Slow; biases feedback toward the wrong things.
- **No real data in the prototype.** "Project 1" "Item 1" "User 1." Tells you nothing about real usage.
- **Tools chosen by familiarity, not by question.** Always Figma for everything; sometimes a better tool exists for the specific problem.

## Related

- [design-process.md](design-process.md) — when to wireframe vs prototype within the process
- [interaction-design.md](interaction-design.md) — what the interactive parts of a prototype are doing
- [design-systems.md](design-systems.md) — using tokens and components in higher-fidelity work
- [accessibility.md](accessibility.md) — even wireframes can be checked for layout / hierarchy accessibility
- [ux-research/references/usability-testing.md](../../ux-research/references/usability-testing.md) — using a prototype in a usability test
- [handoff-and-collaboration.md](handoff-and-collaboration.md) — the wireframe → built code journey

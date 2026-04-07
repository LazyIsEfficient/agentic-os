# Research Methods

A research method is a tool. Different tools answer different questions, at different costs, with different kinds of confidence. The most common UX research mistake is reaching for the most familiar method (usually "let's interview some users") regardless of the question.

This file is a decision guide for picking the right method for the question, plus a brief operating guide for each.

## The Decision

Start with the **question you actually have**, not the method you'd like to run. The question determines the method.

| The question is about… | Method |
|---|---|
| What people *do* | Observation, analytics, diary studies, usability tests |
| Why people do what they do | Interviews, contextual inquiry, follow-up probes after observation |
| How many people experience X | Surveys, analytics, log mining |
| Whether design A is better than design B | A/B test, competitive usability test |
| Whether the design is usable at all | Moderated or unmoderated usability test |
| Whether the problem is real | Discovery interviews, customer support log mining |
| What the right vocabulary or mental model is | Card sort, open interviews, tree test |
| Whether a fix worked | Pre/post comparison, post-launch analytics, follow-up usability test |
| What an unfamiliar user segment is like | Generative interviews, ethnography, diary studies |

The framing matters: "let's run a usability test" is a *method* answer to a question that hasn't been asked. The right opener is "what are we trying to learn?"

## The Two Big Buckets

### Generative research — *what is the problem space*

Used early, when the team is still figuring out what to build. Open, broad, qualitative. The goal is to find unknowns.

Methods: discovery interviews, contextual inquiry, ethnography, diary studies, open card sorts.

Output: a problem space, opportunities, mental models, pain points, jobs to be done.

Decisions it informs: what to build, who to build it for, why it matters.

### Evaluative research — *is this thing any good*

Used later, when there's something to evaluate (a sketch, a wireframe, a prototype, a shipped feature). Targeted, narrow, often comparative. The goal is to validate or invalidate.

Methods: usability tests, A/B tests, surveys with specific hypotheses, post-launch analytics review.

Output: works/doesn't work, where it breaks, what to fix.

Decisions it informs: what to change, what to ship, what to roll back.

**The single most common mistake is using evaluative methods to answer generative questions.** Running a usability test on a prototype to "see what users want" is the wrong tool — usability tests evaluate; they don't generate. If you don't yet know what to build, interview people about their lives, not about your prototype.

## Method-by-Method Operating Guide

### Discovery interviews

**One-on-one conversations to understand a person's context, behavior, and motivations.** The single most generative tool in the kit.

- **When to use:** early in a problem space, when entering a new market or segment, when the team's understanding of users is implicit and you want to make it explicit.
- **Sample size:** 6–12 per segment is usually enough to start seeing patterns. More if you have multiple segments to compare. See [study-planning.md](study-planning.md) for sample-size logic.
- **Time per session:** 45–60 minutes is the sweet spot. Longer is fatiguing for both sides.
- **Output:** notes, recordings, quotes. Synthesis happens after.
- **Common failures:** asking about features instead of about lives; leading questions that confirm what the team already believes; talking too much.

For the craft of running an interview see [interview-craft.md](interview-craft.md).

### Usability tests

**Watching a participant try to complete tasks with a design.** The most common evaluative method, and one of the most misused.

- **When to use:** you have something to test (a sketch, wireframe, prototype, or live product) and want to know whether users can use it.
- **Sample size:** 5 users will surface ~80% of usability issues for a single user type ([Nielsen 2000](https://www.nngroup.com/articles/why-you-only-need-to-test-with-5-users/)). For multiple user types, 5 *per type*. The five-user rule has limits — see [usability-testing.md](usability-testing.md) for the nuance.
- **Format:** moderated (a researcher guides) or unmoderated (a tool like Maze or UserTesting captures clicks and think-aloud). Moderated finds *why* a user struggles; unmoderated finds *what* they struggle with at scale.
- **Output:** task success rates, time-on-task (sometimes), and most importantly *observed behavior with explanations*.
- **Common failures:** designing tasks that are leading ("complete checkout" tells the user the design works); the moderator helping; testing the wrong fidelity; asking opinions instead of observing.

For protocol design see [usability-testing.md](usability-testing.md).

### Surveys

**Structured questions answered by a large number of people.** Useful for *quantifying* things you already qualitatively understand. Bad at exploring.

- **When to use:** you have a hypothesis and want to know how many people agree, how often something happens, or how strong an effect is. You want statistical confidence.
- **Sample size:** depends on the population and the precision you need. For a 5% margin of error on a binary question, ~400 responses. For comparing segments, more.
- **Output:** numbers, trends, segments, sometimes free-text comments (which are often more useful than the numbers).
- **Common failures:** asking biased questions ("how much do you love this?"); asking questions people can't accurately answer ("how often do you do X?"); collecting data with no plan for analysis; using surveys to "discover" things — surveys can't discover, only confirm.

A useful test for survey questions: would a random respondent interpret each question the same way? If you're not sure, the question is bad.

### Diary studies

**Participants self-report behavior, thoughts, or feelings over time.** Captures things that don't fit in a one-hour interview.

- **When to use:** behavior unfolds over days or weeks (onboarding, recurring tasks, emotional arcs), or behavior is private and you can't observe it directly.
- **Sample size:** 8–15 participants over 1–4 weeks. Higher dropout than other methods; recruit a buffer.
- **Format:** prompted (you ask each day) or unprompted (they log when something happens). Prompted is more reliable; unprompted is less intrusive.
- **Output:** rich longitudinal data — a much fuller picture of context than a single interview.
- **Common failures:** burdensome prompts that participants stop completing; no follow-up interview to interpret what was logged; underestimating the time cost.

### Contextual inquiry

**Visiting a participant in their actual environment and watching them work.** The hidden-cost method: most expensive, most accurate.

- **When to use:** when context matters (workplaces, physical spaces, multi-device flows) and you can't reproduce it in a lab. Especially valuable for B2B and enterprise software.
- **Sample size:** 4–8 site visits is usually enough.
- **Output:** observed behavior in context, environmental factors you didn't expect, the workarounds users have built.
- **Common failures:** going in with too many assumptions; talking too much instead of watching; underestimating how much you'll learn from the things in the room (sticky notes on monitors, second monitors with private apps, the printout taped to the wall).

### Card sorts

**Participants group items the way they think they belong together.** Generates information architecture from real users' mental models.

- **When to use:** designing or redesigning navigation, taxonomies, menu structures.
- **Format:** open (participants make their own categories) or closed (participants sort into predefined categories). Open generates; closed validates.
- **Sample size:** 15–30 for online card sorts.
- **Tools:** Optimal Workshop, Maze, Miro for in-person.
- **Output:** how users group concepts, what labels they use, where the team's mental model diverges from users'.
- **Common failures:** including too many cards (limit to ~30–50); not testing the labels themselves separately; treating the result as a literal navigation design rather than as input to design.

### Tree testing

**The complement to card sorting**: given a navigation tree, can users find things in it?

- **When to use:** validating a proposed information architecture before building it.
- **Sample size:** 30–50 for statistical confidence.
- **Tools:** Optimal Workshop, UsabilityHub.
- **Output:** task success rates by path, where users get lost, which labels are misleading.
- **Pairs with:** card sorting (generate the IA → tree test it before committing).

### Analytics review

**Mining your existing telemetry for patterns, anomalies, and questions to ask in qualitative research.**

- **When to use:** you have a live product and you want to see how it's actually being used, find drop-off points, identify segments that behave differently. Always before any new qualitative study — analytics tells you *where* to look.
- **Output:** funnel breakdowns, behavioral cohorts, drop-off points, time spent, repeat usage.
- **Common failures:** confusing correlation with causation; trusting averages when distributions are bimodal; forgetting that analytics tells you *what* but not *why*; obsessing over vanity metrics.

Analytics is a *complement* to qualitative work, never a substitute. "30% of users drop off at step 3" tells you where the problem is; only an interview tells you why.

### A/B tests

**Showing two versions of something to two groups and comparing outcomes.** Quantitative and rigorous when done well.

- **When to use:** you have a clear hypothesis, a clear metric, enough traffic to reach statistical power, and the change is small enough to isolate.
- **Sample size:** depends on baseline conversion and the effect size you want to detect. Use a power calculator before designing the test.
- **Output:** "version B beat version A by X%, with Y confidence."
- **Common failures:** running the test for too short (weekend-only data is biased); peeking at the data and stopping early; running too many tests at once and getting interaction effects; testing the wrong metric (clicks vs. completion vs. retention); ignoring negative results.

A/B tests answer "is B better than A," not "what's the best version." For exploration, use other methods.

## Combining Methods

The most powerful research is rarely a single method. A few useful combinations:

- **Analytics → interviews.** Analytics tells you *where* the drop-off is; interviews tell you *why*. This is the bread-and-butter of mature research practice.
- **Interviews → survey.** Interviews surface a hypothesis ("users seem to be confused by step 2"); survey quantifies it ("47% of users agree they're confused").
- **Card sort → tree test → usability test.** Generate the IA, validate the IA, test the IA in a real interface.
- **Usability test → diary study.** Usability test catches first-use problems; diary study catches the problems that emerge after the user has been living with the product for a while.
- **Generative research → A/B test.** Generative research surfaces what to *try*; A/B test confirms which version of the trial wins.

A research plan that combines two or three methods is usually much stronger than a plan with one big study.

## Method Selection by Project Phase

| Project phase | Question | Methods |
|---|---|---|
| **Discovery / 0→1** | Is there a problem worth solving, and for whom? | Discovery interviews, JTBD interviews, contextual inquiry, market research |
| **Definition** | What is the problem precisely? Who exactly? What does success look like? | Interviews, surveys, analytics review, persona/JTBD synthesis |
| **Ideation** | What concepts could solve it? Which concepts resonate? | Concept testing, sketches, low-fidelity prototypes, comparative reactions |
| **Design** | Does this design work? Where does it break? | Moderated usability tests, tree tests, card sorts, design critique with research input |
| **Pre-launch** | Are we ready to ship? Are there blockers? | Usability tests, accessibility audit, beta diary studies |
| **Post-launch** | Did it work? What did we miss? | Analytics, surveys, follow-up usability tests, NPS / CSAT, support log mining |

The biggest gain is usually moving research *earlier* in the project. Most teams over-invest in evaluative work (after the design is done) and under-invest in generative work (before the team commits to a direction).

## When NOT to Do Research

Research has a real cost — researcher time, participant time, money, and (most importantly) calendar time. Skip it when:

- **The question is trivial** and the cost of being wrong is small. Use judgment.
- **The decision is already made** and research would be theater. Don't run a study to "validate" a foregone conclusion; you'll find what you came to find. Either commit, or actually open the question.
- **You don't have the resources to act on the findings.** A study whose recommendations will sit in a drawer is wasted effort. (The exception: research as a *forcing function* — sometimes you need findings to convince stakeholders to invest. Be honest about that with yourself.)
- **The system is changing too fast** to ship findings before the design changes. Wait, or scope the question tighter.
- **The right method is "ship it and look at the data."** Some questions are cheaper to answer in production than in a study.

## Anti-Patterns

- **Method-first thinking.** "We need to do some interviews." Why? About what? With whom? With what hypothesis?
- **Treating all research as discovery.** Every study is an interview, regardless of the question. Misses faster, cheaper methods.
- **Treating all research as validation.** Every study is a usability test on the latest mockup. Misses generative insight; creates a culture where research only confirms the team's existing direction.
- **Sample size superstition.** "We need 100 participants." For what? For a discovery interview, 5 might be enough. For a survey, 100 might not be.
- **The five-user rule applied to everything.** Five users finds 80% of usability issues *for one user type on one task*. Five users will *not* tell you whether one design is better than another (that's an A/B test) or what the right segments are (that's qualitative depth + quantitative breadth).
- **Recruiting friends and family.** Convenient and useless. They will be polite, biased toward the team, and unrepresentative.
- **Skipping the analytics review.** Then "discovering" in interviews things that the analytics would have shown in 10 minutes.
- **Asking users to design the product.** "What features would you like?" produces a useless wishlist. Ask about problems, not solutions.
- **One-and-done research.** Big study, big report, no follow-up. Research is a continuous practice, not an event.
- **Research as gatekeeping.** "We can't ship until we run a study." Turns research into a bottleneck that the team learns to bypass. Better: small, fast research that keeps up with the team.

## Related

- [discovery-and-problem-framing.md](discovery-and-problem-framing.md) — what to research in the generative phase
- [study-planning.md](study-planning.md) — turning a method choice into a study you can actually run
- [interview-craft.md](interview-craft.md) — running interviews well
- [usability-testing.md](usability-testing.md) — running usability tests well
- [synthesis-and-insights.md](synthesis-and-insights.md) — turning raw data into something the team will act on

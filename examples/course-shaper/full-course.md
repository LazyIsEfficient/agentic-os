# course-shaper — full course

Example of `/course-shape` producing a `full-course-template.md` brief — multi-module, outcome-bearing.

---

## User's initial request

> I want to build a course on system design fundamentals for engineers who keep getting tripped up in interviews and on real architecture decisions at work. Probably 6–8 weeks of content.

## Shaper's batched questions

Multi-week, outcome-bearing, "fundamentals" — routes to `full-course-template.md`. Course-shaper always pushes for outcomes (verbs the learner can do), not topics.

1. **Audience precision** — "engineers who get tripped up" is broad. Junior engineers (0–3 years), mid-level (3–6), or staff/senior trying to fill gaps? Prior systems-design exposure expected?
2. **Outcomes — what should the learner be *able to do* after?** Not a topic list. E.g. "design a rate limiter given target QPS and failure mode", "size a cache from access patterns", "lead an architecture review". Push for 3–5 observable outcomes.
3. **Format and duration** — written-only, video, notebooks, live cohort, blended? "6–8 weeks" of how many learner-hours per week?
4. **Assessment bar** — formative checks per lesson, end-of-course capstone, portfolio piece, cohort presentations, none?
5. **Voice / opinion to embed** — neutral coverage of a textbook topic list, or opinionated takes (e.g. "design for failure before scale", "cache-first thinking")?
6. **Source material available** — existing blog posts, talks, repos, prior workshop slides we can pull from?

## User's answers

1. Mid-level engineers (3–6 years) who can build features but freeze when asked to design a system from scratch. Some have read the usual books but can't apply.
2. After: (a) decompose a real system-design prompt into bounded sub-decisions; (b) size load and storage from first principles; (c) pick the right consistency / availability tradeoffs for the scenario; (d) communicate the design clearly with a written doc + diagram; (e) defend the design under pushback in a review.
3. Blended: written lessons + worked examples + 6 design-doc exercises with feedback. 6 weeks × ~5 hours/week. Self-paced with weekly office hours.
4. Per-lesson micro-checks (3–5 quick questions). Final: each learner produces a design doc for a chosen real system, peer-reviewed + reviewed by me.
5. Opinionated. Big bets: "design for failure before scale", "size before you architect", "the goal of system design is to make tradeoffs explicit, not eliminate them".
6. ~20 blog posts on related topics, three conference talks (with slides + transcripts), one prior 1-day workshop's slide deck.

## Output brief

```markdown
## Course title
System Design for Working Engineers

## One-line pitch
Stop freezing on system design. Decompose any prompt, size from first principles, pick the right tradeoffs, and defend the design — in writing and in review.

## Audience
- Primary: mid-level software engineers (3–6 years) who ship features confidently but stall when asked to design a system from a blank page.
- Secondary: senior engineers preparing for staff-level interviews; tech leads taking on first-time architecture reviews.
- Not for: complete beginners (no production engineering experience), or engineers who already lead architecture reviews routinely.

## Prerequisites
- 2+ years writing production code in any backend language.
- Comfort with HTTP, databases, queues — at the "I have used these" level, not "I have designed them".
- A drawing tool (Excalidraw, Mermaid, FigJam) and willingness to write 1–2 page design docs.

## Learning outcomes
By the end of this course, the learner can:
- Decompose a real system-design prompt into bounded sub-decisions with named tradeoffs.
- Size load (QPS, peak/avg) and storage (rows, bytes, growth) from first principles given a scenario sketch.
- Pick the right consistency / availability / partition-tolerance tradeoff for a scenario and justify the call.
- Produce a clear written design doc with a diagram, decisions, alternatives considered, and risks.
- Defend the design under realistic pushback in a written review.

## Topics in scope
- Decomposition heuristics (functional decomposition, sub-decision framing)
- Back-of-envelope sizing (QPS, latency budgets, storage growth, working-set sizing)
- Consistency models, replication tradeoffs, partition strategies
- Caching layers and invalidation discipline
- Queues, async patterns, idempotency
- Observability and failure-mode reasoning
- Writing design docs and surviving reviews

## Out of scope
- Specific cloud-vendor configuration (AWS service walk-throughs).
- Frontend system design.
- ML system design.
- Coding-heavy implementation; this is design, not implementation.

## Format
- Medium: written lessons + worked examples + design-doc exercises with feedback (blended).
- Duration: 6 weeks × ~5 hours/week = ~30 learner-hours total.
- Synchronous vs self-paced: self-paced lessons + weekly live office hours.
- Tooling / environment: Excalidraw or Mermaid for diagrams; a markdown doc tool of choice.
- Code-along vs read-only: read-only on lessons; *do-along* on the design-doc exercises (6 of them, one per week).

## Assessment bar
- Formative checks per lesson: 3–5 quick questions per lesson, mostly applied (decompose this prompt; size this scenario).
- Summative: each learner produces a design doc for a real system of their choice, peer-reviewed + reviewed by the instructor.
- Expert panel review before publishing: yes — content scored before launch.

## Voice and tone
Worked-example-heavy. Each lesson centers on a real-world prompt (e.g. "design a rate limiter for our public API", "size a session store for 200k DAU"), shows the reasoning out loud, names the tradeoffs as decisions, and forces the learner to make their own version.

## Domain focus
- Subject: system-design fundamentals applied at the working-engineer level.
- Opinions to embed:
  - Design for failure before scale.
  - Size before you architect.
  - The goal of system design is to make tradeoffs explicit, not eliminate them.
  - A written design doc beats a whiteboard for everything except the first 20 minutes.

## Constraints
- Deadline: open — quality over speed; expect ~3 months to produce.
- Author(s) / SMEs: <unknown — to investigate>
- Reference stack or canonical examples: backend-language-agnostic; examples will use HTTP, Postgres-or-similar, Redis-or-similar at the conceptual level.
- Platform (where the course will live): <unknown — to investigate>

## Source material available
- ~20 prior blog posts on adjacent topics (rate limiting, caching, queues, idempotency).
- Three conference talks with slides and transcripts.
- One prior 1-day workshop slide deck on the same topic at workshop scope.

## Open questions
- Platform — self-hosted, Maven, Teachable, something else?
- Pricing model — one-time, cohort-based, evergreen self-paced?
- Capstone review at scale — one-on-one feedback doesn't scale past ~30 learners; rubric-driven peer review needed?
```

---

**Next step:** paste this into a fresh session with `course-design` available, or say `go` and the brief is handed to course-design to produce the module/lesson outline.

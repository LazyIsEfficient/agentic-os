# Lesson structure

Every lesson follows the same arc. The arc is not decoration — each segment does a job, and dropping one leaves the lesson feeling either preachy (no hook), overwhelming (no chunked worked example), or untested (no check).

## The arc

1. **Hook** — one concrete scene. 1–3 sentences. A real problem, a real failure, a real system, real numbers. Never "in this lesson we'll explore…" — that's a preface, not a hook.
2. **Core idea** — the single concept, stated plainly. Two short paragraphs max. If you can't compress it, the lesson is too big; flag the spec.
3. **Worked example** — the author does the thing, step by step, with reasoning on every step. This is the center of gravity.
4. **Common misconception(s)** — named as a thing the learner might plausibly believe, corrected with a concrete failure mode and a better frame.
5. **Try it** — exercises in a progression (faded → independent). The first exercise is a small variation; the last is a new instance of the same class of problem.
6. **Check yourself** — the single formative check from the spec. Directly exercises the primary objective.
7. **Going deeper (optional)** — authoritative references and forward-looking pointers. Not a dumping ground for "things I wanted to say but didn't".

## Why this order

- **Hook before concept.** A concept without a reason to care is an abstraction. The hook supplies the reason.
- **Concept before example.** The example demonstrates the concept. Without the concept stated first, the learner watches the example without a frame, and the example degrades to a demo.
- **Example before exercise.** Worked-example effect: novices learn more from watching a full solution than from attempting cold. See `course-design/references/worked-examples.md`.
- **Misconception before exercise.** If the trap isn't named before the learner tries the work, they walk into it during the exercise and come out confused rather than corrected.
- **Exercise before check.** The exercises are practice. The check is the assessment. Mixing them costs the learner their only unguarded signal of whether they got it.
- **Going deeper last.** Optional material at the end protects the arc. Buried near the top, it becomes a tangent the learner has to wade through.

## Anti-patterns

- **The prologue.** Starting with course philosophy, historical context, or a vendor positioning paragraph. Cut. The hook is paragraph 1.
- **The tour.** A lesson that tries to visit every variation of the concept instead of teaching one mechanism well. Pick one; mention the others in "going deeper".
- **The forward reference.** "We'll cover this in lesson 7." Acceptable exactly once per lesson if truly necessary; more than once is a scoping problem.
- **The orphaned example.** A worked example whose mechanism isn't stated in the core-idea section. The learner can't generalize because they don't know what the example is an instance *of*.
- **The unchecked claim.** Technical claims about APIs, versions, or behaviors shipped without citation. Defer to `source-driven-development` and cite.
- **The check that's easier than the exercises.** A lesson whose formative check the learner can answer without doing the exercises has an inflated difficulty curve. Usually the spec needs revising.

## Pacing signals

Rough budget for a written lesson of ~20–30 min learner time:
- Hook: ~1% (a few sentences).
- Core idea: ~10% (two paragraphs + one diagram if warranted).
- Worked example: ~40–50% (the center of gravity).
- Misconceptions: ~10%.
- Try it: ~20–25% (not counting learner time on the exercises themselves).
- Check yourself: ~2–5%.
- Going deeper: ~2–5%.

These are rough. What matters is that the worked example is the largest block and the hook is the smallest.

## Voice

Voice is inherited from the course brief. Common combinations:
- **Worked-example-heavy**: terse prose, dense code, minimal philosophy. Appropriate for senior audiences.
- **Socratic**: the lesson asks the question and lets the learner attempt before revealing. Appropriate for topics where the wrong intuition is common and load-bearing.
- **Narrative**: a running case study threads through the module. Appropriate when the concept is cumulative and benefits from one scenario instead of N small ones.

Pick one per course (with small variations lesson to lesson) and stay consistent. Voice drift across a course is a sign the authoring cadence is broken.

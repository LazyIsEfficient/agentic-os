# Sequencing and cognitive load

How you order lessons — and how much you pack into each — determines whether learners retain anything. This reference is the small set of evidence-backed ideas that should guide both decisions.

## Cognitive load, briefly

Working memory is small (roughly 4 ± 1 novel elements). Each lesson has a budget:

- **Intrinsic load** — the complexity of the concept itself. You can't reduce this without changing the concept, but you *can* chunk it (see below).
- **Extraneous load** — everything the learner must hold in memory that isn't the concept. Bad notation, unexplained jargon, messy worked examples, tool setup mid-lesson. Eliminate this.
- **Germane load** — the effort of building mental structure. This is the *good* load. Exercises, retrieval, comparing cases. Maximize this.

The designer's job: minimize extraneous load, respect intrinsic load, spend the budget on germane load.

## One new concept per lesson

Strong prior. Two is sometimes fine when they're tightly paired (e.g., cache-aside + invalidation). Three is never fine — split. The test: could the learner explain the lesson back to a peer in one minute? If no, it has too much in it.

## Chunking

A lesson can cover a *large* idea if you chunk it. Chunking means introducing sub-ideas one at a time, letting each settle before stacking the next. The worked example is where chunking plays out: the author does step 1, explains step 1, then step 2, etc. Don't drop a 50-line code snippet and annotate after the fact — the learner has already lost the thread.

## Worked-example effect

Novices learn more from watching a complete worked example than from attempting the problem cold. Attempting cold spends working memory on wayfinding (what do I even try?) rather than on the concept. Once the learner has seen one or two worked examples, their capacity to learn from problem-solving climbs sharply.

Progression inside a lesson:
1. Worked example (author solves).
2. Faded example (author solves most of it; learner fills in 1–2 steps).
3. Independent practice (learner solves from scratch; author reveals a reference solution after).

The faded step is the one most often skipped — and the one that matters most, because it's where the learner transitions from recognition to production.

## Spacing and interleaving

- **Spacing**: learners retain more when practice is distributed across sessions than massed in one. If a concept is load-bearing across the course, revisit it in a later lesson's exercise, not only in its home lesson.
- **Interleaving**: when two related concepts are in play (e.g., caching and rate limiting), exercises that mix them produce better discrimination than exercises that drill them separately. Interleave *after* each has been taught in isolation, not during.

Design implication: late in the course, exercise sets should mix concepts from earlier modules. A final capstone that only exercises the last module has wasted the earlier modules.

## Prerequisite chains

Draw the prereq graph before you order lessons. An arrow from A → B means "B can't land if A hasn't". Topologically sort. When you have a choice of order (two lessons with no dependency between them), prefer the one that unlocks the most downstream lessons first. If the graph has a cycle, one of the lessons is badly scoped — break the cycle by splitting.

## Heavy lessons

Some lessons are irreducibly heavy: new tooling, stacked prereqs, or a concept that only clicks after a long worked example. Mark these in the outline. Either:
- precede them with a lightweight recap lesson,
- follow them with a practice-only lesson (no new concepts, exercises on recent material), or
- shorten adjacent lessons so the schedule absorbs the weight.

Learners don't quit because of one hard lesson; they quit when three hard lessons stack.

## The curse of knowledge

You know this material; the learner doesn't. The single highest-value sequencing exercise: read each lesson's prereq list and ask, "if a learner has *only* these, can they follow the first worked example?" If the answer depends on something you haven't listed, either add the prereq or move content around. This is the single highest-yield hour of course design.

## Revisiting the outline

After `course-author` has drafted the first two or three lessons, come back and revise the outline. Authoring surfaces sequencing problems that pure outlining can't. Treat the outline as a living document through the first module.

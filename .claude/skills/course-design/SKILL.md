---
name: course-design
description: Use to turn a course brief into a concrete outline — modules, lessons, learning objectives, sequencing, and assessment map — before any lesson content is written. Triggers on "design the course", "build the curriculum", "outline the course", "course outline", "module breakdown", "lesson plan", "learning objectives", or when handed a filled course brief from course-shaper. Produces a course outline + per-lesson specs that course-author consumes. For intake shaping see course-shaper; for writing the lessons themselves see course-author.
when_to_use: |
  Use when you have a course brief (from `course-shaper` or equivalent) and need to produce the module map, per-lesson specs, learning objectives, sequencing rationale, and assessment plan that `course-author` will implement. Triggers on "design the course", "build the curriculum", "outline the course", "lesson plan", or "learning objectives".

  Not when: the course idea is still vague or missing audience and outcomes — use `course-shaper` first. Not when lesson specs already exist and you only need to write the prose — use `course-author`.
---

# Course Design

Your job is to turn a course brief into a concrete, teachable **outline**: a module map, a lesson spec for each lesson, a sequencing rationale, and an assessment map. You are the curriculum designer, not the author. You do not write lesson prose or code snippets — you produce specs that `course-author` fills in.

## When this skill applies

You have a course brief (from `course-shaper` or equivalent) with stated audience, prerequisites, outcomes, format, and assessment bar. Your job is to map the brief onto a structure that is learnable in order, from the stated prerequisites to the stated outcomes, within the stated duration.

If the brief is missing audience or outcomes, stop and route to `course-shaper` first. Outlining without outcomes produces a table of contents, not a course.

## Procedure

1. **Read the brief end-to-end.** Identify: outcomes, prereqs, duration, assessment bar, voice, and any embedded opinion.
2. **Apply backwards design** ([references/backwards-design.md](references/backwards-design.md)). Start from the outcomes. For each outcome ask: *what evidence proves the learner can do this?* That evidence becomes the assessment. Only then design activities that produce that evidence.
3. **Draft the module map.** Group outcomes into modules. Each module has one or two outcomes and a clear unlock — what it enables the learner to do that the next module depends on.
4. **Order modules and lessons** using [references/sequencing-and-load.md](references/sequencing-and-load.md). Respect prerequisite chains, interleave related ideas, cap new concepts per lesson.
5. **Write learning objectives** for each lesson using [references/learning-objectives.md](references/learning-objectives.md). Observable verbs only. One primary objective per lesson.
6. **Fill `assets/course-outline-template.md`** with the module map and sequencing rationale.
7. **Fill `assets/lesson-spec-template.md`** once per lesson. Each spec is the contract that `course-author` will implement.
8. **Validate** against the assessment map: every outcome has at least one formative check and, where the brief requires it, summative evidence.

## Universal rules

- **Outcomes are observable.** "Understand X" is not an outcome. "Build X given Y" is. If you can't name the verb, you can't write the lesson.
- **One new concept per lesson.** Two is sometimes fine; three guarantees at least one won't stick. Split.
- **Prerequisites explicit, top of every lesson.** If a lesson depends on a prior lesson, name it.
- **Every outcome has a check.** No orphan outcomes. No orphan checks (checks that don't map to a stated outcome).
- **Worked examples before exercises.** The lesson spec must reserve room for a worked example before any "try it" block. See [references/worked-examples.md](references/worked-examples.md).
- **Assessment proportional to bar.** Don't design a capstone if the brief says "no summative". Don't design only quizzes if the brief says "portfolio".
- **Sequencing is part of the design, not a filing decision.** If you move a lesson, update the sequencing rationale and any prereq chains that depend on it.
- **Domain pitfalls are part of the spec.** Each lesson spec names the top 1–3 misconceptions `course-author` must address. See [references/domain-pitfalls.md](references/domain-pitfalls.md) for common traps in AI-usage and system-design topics.
- **Stop at specs.** Do not draft lesson prose or code. Hand off to `course-author`.

## References

- [references/backwards-design.md](references/backwards-design.md) — Understanding by Design (outcomes → evidence → activities)
- [references/learning-objectives.md](references/learning-objectives.md) — Bloom's verbs, observable-outcome anti-patterns
- [references/sequencing-and-load.md](references/sequencing-and-load.md) — cognitive load, worked-example effect, spacing, interleaving, chunking
- [references/worked-examples.md](references/worked-examples.md) — faded-guidance progression from worked to independent
- [references/domain-pitfalls.md](references/domain-pitfalls.md) — common misconceptions for AI-usage and system-design topics

## Related skills

- [course-shaper](../course-shaper/SKILL.md) — produces the brief this skill consumes
- [course-author](../course-author/SKILL.md) — consumes the outline and lesson specs this skill produces
- [documentation-writer](../documentation-writer/SKILL.md) — shares discipline around `docs/` layout and Mermaid diagrams for course structure
- [deck-generator](../deck-generator/SKILL.md) — when a module is delivered as slides, pair the lesson specs with slide generation
- [content-ops](../content-ops/SKILL.md) — expert panel scoring of the outline before it goes to course-author
- [source-driven-development](../source-driven-development/SKILL.md) — cite authoritative sources for technical claims in AI-usage and system-design content
- [spec-driven-development](../spec-driven-development/SKILL.md) — lesson specs are the teaching analog of acceptance criteria

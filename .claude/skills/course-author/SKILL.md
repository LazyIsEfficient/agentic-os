---
name: course-author
description: Use to write lesson content from a filled lesson spec — hook, explanation, worked example with code snippets, exercises, misconception callouts, and formative check. Triggers on "write the lesson", "draft lesson", "author lesson", "expand the spec", "write course content", "add the code snippets", or when handed a filled lesson-spec-template from course-design. Writes one lesson at a time against the spec; does not reopen curriculum decisions. For course outlining see course-design; for intake shaping see course-shaper.
when_to_use: |
  Use when you have a filled lesson spec from `course-design` and need to expand it into a complete, teachable lesson — hook, core idea, worked example, misconception callouts, exercise progression, and formative check. Triggers on "write the lesson", "draft lesson", "expand the spec", or "write course content".

  Not when: the lesson spec doesn't exist yet — use `course-design` first to create the curriculum outline and specs. Not when the overall course brief is still vague — use `course-shaper` first. Not when the deliverable is a blog post — use `blog-post-author`.
---

# Course Author

Your job is to turn a single lesson spec into a complete, teachable lesson — prose, code, exercises, and checks — that honors the spec. You are the writer, not the curriculum designer. You do not move lessons, add objectives, or rescope the module; if the spec is wrong, flag it and stop.

## When this skill applies

You have a filled `lesson-spec-template.md` from `course-design`. Your job is to expand it into a lesson that a learner can actually follow, working from the stated prerequisites to the stated objective, through a worked example and an exercise progression, ending at the stated formative check.

If you were handed a raw topic without a spec, stop. Route back to `course-design`. Writing without a spec produces content that feels fine and fails to teach.

## Procedure

1. **Read the lesson spec end-to-end.** Note the primary objective, worked-example plan, exercise progression, and named misconceptions. These are the contract.
2. **Read sibling lesson specs** for the module so you don't repeat setup the learner has already done or forward-reference something not yet taught.
3. **Draft the lesson** by filling `assets/lesson-template.md` in order: hook → core idea → worked example → misconception → exercises → formative check → (optional) going deeper.
4. **Write the worked example** using [references/code-snippet-discipline.md](references/code-snippet-discipline.md). Minimal, runnable, one mechanism per snippet, labeled with what it shows.
5. **Write the exercise progression** using [references/exercise-progression.md](references/exercise-progression.md). The spec names the types; you design the specific tasks and reference solutions.
6. **Name and correct each misconception** from the spec using [references/misconceptions.md](references/misconceptions.md). Frame as "here's a thing the learner might believe, here's why it fails, here's the better frame."
7. **Validate against the spec's done criteria.** If any line item fails, either fix the lesson or stop and flag the spec as too thin.
8. **Hand back** the finished lesson file, plus any notes about spec edits you recommend for adjacent lessons (often discovered during authoring).

## Universal rules

- **One concept per section.** If a section teaches two things, split it.
- **Code snippets must be runnable as shown** unless explicitly labeled as `// pseudocode` or `// excerpt`. No mystery imports, no undefined helpers.
- **Every snippet has an intent label.** A one-line "what this shows" sits adjacent to the code. The code carries the *what*; the prose carries the *why*.
- **Show, then do.** Worked example precedes the first exercise. Faded guidance precedes independent practice. No exceptions.
- **Name the misconception before correcting it.** "You might assume X" → "Here's why X breaks" → "Do Y instead." Don't ship a correction without the misconception attached; the learner won't recognize it as theirs.
- **Formative check exercises the stated objective directly.** If the check is easier than the exercises, it isn't measuring the objective — fix it.
- **Cite external claims.** Technical claims about APIs, behaviors, specs, papers, or vendor systems need sources. Defer to `source-driven-development`; don't invent URLs or version numbers.
- **Stay inside the spec.** New objectives, new scope, new topics — those are curriculum decisions. Raise them; don't absorb them.
- **No filler.** "In today's lesson, we will explore…" is filler. Open on the hook.

## References

- [references/lesson-structure.md](references/lesson-structure.md) — the hook → core idea → worked → faded → independent → check arc
- [references/code-snippet-discipline.md](references/code-snippet-discipline.md) — minimal, runnable, labeled; handling of omitted code; output display
- [references/exercise-progression.md](references/exercise-progression.md) — Parsons → fill-in → modify → from-scratch ladder and when to use each
- [references/misconceptions.md](references/misconceptions.md) — how to phrase, place, and land a misconception callout

## Related skills

- [course-design](../course-design/SKILL.md) — produces the lesson specs this skill consumes
- [course-shaper](../course-shaper/SKILL.md) — produces the brief upstream of course-design
- [documentation-writer](../documentation-writer/SKILL.md) — shares voice, Mermaid discipline, and incremental-update etiquette
- [source-driven-development](../source-driven-development/SKILL.md) — mandatory for citing APIs, specs, and vendor behavior
- [content-ops](../content-ops/SKILL.md) — expert panel scoring of the drafted lesson before publishing
- [code-simplification](../code-simplification/SKILL.md) — worked-example code should pass the simplification bar
- [deck-generator](../deck-generator/SKILL.md) — when a lesson is delivered as slides, author the lesson once and split it

# course-shaper — single module

Example of `/course-shape` producing a `single-module-template.md` brief — one focused unit, 3–8 lessons.

---

## User's initial request

> I want to write a module on prompt caching for the Anthropic API. Engineers using the SDK who haven't turned it on yet. Maybe 5 lessons.

## Shaper's batched questions

Single module, narrow topic, audience clear-ish — routes to `single-module-template.md`.

1. **Outcomes — what should the learner be *able to do* after?** Push past "understand prompt caching": what artifact or decision changes for them?
2. **Prior knowledge** — comfortable with the Anthropic SDK already, or starting from "I have an API key"?
3. **Module-level evidence** — end-of-module mini-project, a code change to their own app, or just per-lesson checks?
4. **Lessons rough cut** — what 5 lessons are you imagining? Helps confirm 5 is the right count.
5. **Voice and opinion** — neutral docs-style, or opinionated ("always cache the system prompt", "cache hit rate is your real metric")?
6. **Source material** — Anthropic prompt-caching docs, your own existing code samples, anything else?

## User's answers

1. After: (a) decide which prompts in their own code should be cached; (b) implement caching with the right `cache_control` placement; (c) measure cache hit rate; (d) avoid the three common mistakes that silently disable caching.
2. They've used the SDK for at least basic completions. Comfortable with TypeScript or Python.
3. End-of-module: each learner adds caching to a sample app (provided) and shows a measured hit-rate improvement. Per-lesson micro-checks too.
4. Roughly: (1) what caching is and when it pays off, (2) `cache_control` mechanics, (3) caching the system prompt, (4) caching tool definitions and large context, (5) measuring hit rate + the three traps.
5. Opinionated. Big takes: "cache hit rate is the metric, not whether caching is on", "cache the system prompt first, always", "if your hit rate is below 70% something's wrong".
6. Anthropic prompt-caching docs, two of my prior posts, sample app repo I'll provide.

## Output brief

```markdown
## Module title
Prompt Caching with the Anthropic API

## Parent course (if any)
standalone (could fit later inside a "Production-Ready Anthropic API" course)

## Audience
- Primary: engineers using the Anthropic SDK in TypeScript or Python who haven't turned on prompt caching yet, costing them money or latency.
- Not for: engineers brand-new to the API (no SDK exposure), or those already running production caching with a measured hit rate.

## Prerequisites
- Basic comfort with the Anthropic SDK (`messages.create` round-trip in TS or Python).
- An API key with access to a current Claude model.
- A local environment that can run the provided sample app.

## Learning outcomes
By the end of this module, the learner can:
- Decide which prompts in their own application should be cached, based on stable-prefix and call-frequency criteria.
- Implement caching with `cache_control` placed on the right content blocks (system prompt, tool definitions, large context) and verify it via the API response.
- Measure cache hit rate and reason about whether it's high enough.

## Lessons (rough cut)
- Lesson 1 — What prompt caching does and when it pays off (decision criteria, not mechanics yet)
- Lesson 2 — `cache_control` mechanics: where it goes, what it caches, what it doesn't
- Lesson 3 — Caching the system prompt (the highest-leverage move)
- Lesson 4 — Caching tool definitions and large context
- Lesson 5 — Measuring hit rate + the three traps that silently disable caching

## Out of scope
- Other API features (thinking, batches, files) — covered separately.
- Provider-neutral caching strategies (Vercel AI Gateway, etc.).
- Cost modeling beyond the simple cache-hit savings calculation.

## Format
- Medium: written lessons + runnable code snippets + sample-app exercise.
- Duration: ~3 hours total (5 lessons × ~30 min each, plus sample-app work).
- Tooling / environment: Anthropic API key, Node 20+ or Python 3.11+, the provided sample-app repo.

## Assessment bar
- Per-lesson checks: 2–3 micro-questions, mostly applied (where would `cache_control` go in this snippet? what's wrong with this attempt?).
- Module-level evidence: each learner adds caching to the provided sample app and submits before/after measurements showing a hit-rate improvement.

## Voice and tone
Worked-example-heavy, opinionated, terse. Show the snippet, name the decision, point at the trap. Each lesson ends with "now do this in the sample app".

## Domain focus
- Subject: effective Anthropic API usage.
- Opinions to embed:
  - Cache hit rate is the metric, not whether caching is on.
  - Cache the system prompt first, always.
  - If your hit rate is below 70% in a stable workload, something is misplaced.

## Source material available
- Anthropic prompt-caching documentation (current).
- Two prior posts by the author on the same topic.
- Sample app repo (to be provided) — stable system prompt, tools defined, demonstrates measurable hit rate after the module is applied.

## Open questions
- Sample-app repo: TS-first, Python-first, or one of each? Probably TS given audience overlap with `anthropic` SDK use.
- Should the module include a section on cache-aware testing (snapshot stability when prompts are cached)?
```

---

**Next step:** paste this into a fresh session with `course-design` available, or say `go` and the brief is handed to course-design to flesh out per-lesson outlines.

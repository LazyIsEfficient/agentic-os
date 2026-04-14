# Learning objectives

A learning objective is a one-sentence claim about what the learner can *do* after the lesson. It must be observable — you must be able to watch the learner perform it and decide whether they succeeded. Objectives that can't be observed can't be assessed, and unassessable objectives are decorative.

## The shape

> By the end of this lesson, the learner can **[verb]** **[artifact or scenario]** **[under what conditions]**.

Examples:
- "…can **rewrite** a vague prompt into a task brief that includes context, constraints, and success criteria, given a one-line user request."
- "…can **diagnose** the root cause of a cascading failure from a set of logs and service dependencies, and name the first mitigation to ship."
- "…can **design** a rate limiter for a public API given a target QPS, fairness requirement, and failure mode."

## Observable verbs (by Bloom level, loosely)

| Level | Verbs | What the learner shows |
|---|---|---|
| Remember | list, name, define, recall | They can produce the name or term. |
| Understand | explain, summarize, paraphrase, classify, compare | They can restate in their own words or place something in a category. |
| Apply | use, compute, execute, implement, write, draft | They can perform the skill on a known-pattern problem. |
| Analyze | diagnose, decompose, differentiate, trace, infer | They can pull apart a system or find a cause. |
| Evaluate | critique, choose, justify, defend, compare | They can pick among options and say why. |
| Create | design, compose, build, invent, refactor | They can produce a novel artifact. |

Most technical courses live in **Apply**, **Analyze**, **Evaluate**, and **Create**. If every objective in your course is Remember/Understand, you're writing a glossary, not teaching a skill.

## Anti-patterns

- **"Understand X."** Unobservable. What does a learner *do* if they understand X? Write that instead.
- **"Be familiar with X."** Same — unmeasurable.
- **"Know about X."** Same.
- **"Learn X."** This describes the activity, not the outcome.
- **"Appreciate X."** Reads as filler. If there's a real outcome, name the action ("choose X over Y when appropriate, with reasoning").
- **Stacked objectives.** "…can understand, use, evaluate, and extend X." Pick one. If the lesson really does teach four things, it's four lessons.
- **Topic-as-objective.** "Kubernetes networking." A topic is not an objective.

## Translating vague aims to observable outcomes

| Vague aim | Observable outcome |
|---|---|
| "Understand prompt engineering." | "Given a failing prompt and a target behavior, diagnose which of (context, constraints, examples, format) is missing and rewrite to fix it." |
| "Know how caching works." | "Given a read-heavy endpoint and latency target, design a cache layer including invalidation strategy, and defend the choice of cache-aside vs read-through." |
| "Be familiar with LLM agents." | "Given a task and a tool set, decompose the task into agent steps, and identify where non-determinism will bite." |
| "Understand distributed consensus." | "Given a multi-writer scenario, compare single-leader, multi-leader, and consensus-based approaches, and pick one with failure-mode reasoning." |

## One primary objective per lesson

A lesson can have up to one secondary objective if it's genuinely load-bearing (e.g., the primary depends on a small terminology build-up). More than that and the lesson is doing too much. The signal is simple: if you can't hold all objectives in your head while reading the lesson, the learner can't either.

## How objectives feed the assessment map

In the outline's assessment map, each outcome (course-level) is traced to the lessons that teach it and the checks that verify it. Lesson-level primary objectives are the atomic unit; course-level outcomes are aggregates of them. A course outcome with no lesson objective behind it is an unfulfilled promise; a lesson objective with no course outcome above it is a tangent.

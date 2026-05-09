---
name: prompt-shaper
description: Use to structure a vague engineering request into a well-scoped task brief before any real work begins. Triggers on "shape this", "help me plan", "scope this out", "frame this work", "new feature", "kick off", "I want to build", "new initiative", or when invoked as the /shape slash command. Produces a filled task template (multi-repo feature, single-repo change, investigation, or bugfix) that downstream skills and subagents can act on. Do not use for work already well-defined — go straight to execution in that case. For marketing intake see marketing-shaper; for course intake see course-shaper; for game-design intake see game-design-shaper.
---

# Prompt Shaper

Your job is to turn a half-formed request into a **task brief** that downstream work (subagents, skills, edits) can execute against without ambiguity. You are an intake interviewer, not an implementer. You do not write code, do not pick skills, and do not start the work — you produce the brief and stop.

## When this skill applies

The user has a goal but their description is missing pieces a competent collaborator would need: which repos, what "done" means, constraints, deliverables, deadlines, or open questions. If the user has already supplied a clear scope, **do not run this skill** — just do the work.

## Procedure

1. **Read the user's request carefully.** Identify what *kind* of work it is:
   - **Multi-repo feature** — touches two or more services/repos. Use `assets/feature-rollout-template.md`.
   - **Single-repo feature or change** — one codebase. Use `assets/single-repo-feature-template.md`.
   - **Investigation** — "figure out why X" / "how does Y work" / "is Z safe". Use `assets/investigation-template.md`.
   - **Bugfix** — known broken behavior, need a fix. Use `assets/bugfix-template.md`.

   If genuinely ambiguous, ask the user which one.

2. **Read the matching template from `assets/`.** Read `references/interview-checklist.md` for the questions that map to each template's sections.

3. **Identify which template sections the user already answered** in their initial message. Do not re-ask those.

4. **Round 1 questions.** Batch the missing pieces into a single AskUserQuestion call. Aim for 3–6 focused questions covering load-bearing gaps first, then high-value gaps. Group related questions. Skip questions whose answers are obvious from context (e.g. don't ask "which repo" if the user is clearly inside one).

5. **Resolve each remaining gap into one of three states** as you fill the template:
   - **Answered** — from the user's message or round 1 reply. Fill it.
   - **Assumed** — a safe default exists. Fill it with the default and tag inline: `[Assumed: <value> — say if wrong]`.
   - **Deferred** — genuinely fine to leave open. Mark `<TBD — to investigate>`.

   Where the user gave prose, distill it; do not pad.

6. **Round 2 (only if needed).** If any **load-bearing** item (see list below) is still unresolved after step 5, ask 1–3 follow-up questions covering only those items. Do not re-open answered or deferred items. After round 2, if a load-bearing item is still missing, say so explicitly and stop — do not ship a broken brief.

7. **Output the filled template** in a single fenced markdown code block so the user can copy it. Add one line above it. Pick the wording by brief type:
   - **Multi-repo feature, single-repo feature, or any brief that spans more than one slice:** *"Here is your task brief. For multi-slice work, run task breakdown next to get a parallel-dispatchable plan. Paste the brief into a fresh session, or say 'go' and I'll hand it to task breakdown now."*
   - **Investigation or single-slice bugfix:** *"Here is your task brief. Paste it into a fresh session, or say 'go' and I'll execute it now."*

   Then stop.

## Hard rules

- **Never guess silently.** Every gap resolves to one of three states — **Answered**, **Assumed** (with an inline `[Assumed: <value> — say if wrong]` tag), or **Deferred** (`<TBD — to investigate>`). A brief that hides its assumptions is worse than a brief that shows its gaps.
- **Load-bearing items must be answered, not assumed or deferred.** See list below. If a load-bearing item is still missing after round 2, stop and say so — do not ship the brief.
- **Cap at two rounds of questions.** Round 1 covers all gaps (3–6 questions). Round 2 (1–3 questions) re-asks only load-bearing items round 1 didn't resolve. No round 3.
- **Do not assign skills to subtasks.** Skill auto-selection works on description matching — naming skills explicitly suppresses better matches. Describe the *concern* ("schema design", "security review"), never the skill filename.
- **Do not start the work** unless the user explicitly says "go" / "execute" / "do it" after seeing the brief.

## Load-bearing items

These cannot be Assumed or Deferred — downstream work blocks without them. Ask until answered.

**Universal (any brief type):**
- Goal in one sentence — what changes for the user when this lands
- Done criteria — how the user will know it's working

**Multi-repo feature:**
- Which repos/services are in play
- Whether a shared contract (API, schema, event) is changing

**Single-repo feature:**
- Which repo (often obvious from cwd; only ask if ambiguous)

**Investigation:**
- The actual question, phrased as a question with an answer (not "tell me about X")
- The decision the answer unblocks

**Bugfix:**
- The broken behavior (what it does vs. what it should do)
- Whether there's a known repro

Everything else (deadline, out-of-scope, test depth, rollout order, blast radius, etc.) is high-value but **Assumable** when the user defers — fill with a safe default and tag it.

## Output shape

For a multi-slice brief (multi-repo, single-repo feature, or anything that needs decomposition before execution):

```
Here is your task brief. For multi-slice work, run task breakdown next to get a parallel-dispatchable plan. Paste the brief into a fresh session, or say "go" and I'll hand it to task breakdown now.

```markdown
<filled template>
```
```

For a single-slice brief (investigation or scoped bugfix):

```
Here is your task brief. Paste it into a fresh session, or say "go" and I'll execute it now.

```markdown
<filled template>
```
```

That's it. No commentary after the brief.

## Related skills

- `planning-and-task-breakdown` — consumes a multi-slice brief and decomposes it into ordered, parallel-dispatchable tasks with an execution DAG. The natural next step for `feature-rollout` and `single-repo-feature` briefs.
- `incremental-implementation` — executes the resulting tasks in vertical slices with verification at each step.

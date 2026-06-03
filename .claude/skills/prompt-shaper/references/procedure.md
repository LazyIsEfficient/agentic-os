# Prompt Shaper Procedure

## Brief Types

Identify what *kind* of work the request is:

- **Multi-repo feature** — touches two or more services/repos. Use `assets/feature-rollout-template.md`.
- **Single-repo feature or change** — one codebase. Use `assets/single-repo-feature-template.md`.
- **Investigation** — "figure out why X" / "how does Y work" / "is Z safe". Use `assets/investigation-template.md`.
- **Bugfix** — known broken behavior, need a fix. Use `assets/bugfix-template.md`.

## Steps

1. Read the request; identify the brief type (ask if ambiguous).
2. Read the matching template from `assets/`. Read `references/interview-checklist.md` for questions.
3. Identify which sections the user already answered. Do not re-ask those.
4. **Round 1 questions.** Batch missing pieces into a single AskUserQuestion call — 3–6 questions, load-bearing gaps first. Skip questions obvious from context (e.g. don't ask "which repo" if clearly inside one).
5. Resolve each remaining gap into one of three states:
   - **Answered** — fill it.
   - **Assumed** — fill with default, tag inline: `[Assumed: <value> — say if wrong]`.
   - **Deferred** — mark `<TBD — to investigate>`.
6. **Round 2 (only if needed).** 1–3 questions covering only unresolved load-bearing items. No round 3.
7. Output the filled template in a single fenced markdown block, then stop.

## Hard Rules

- Never guess silently — every gap must be Answered, Assumed (tagged), or Deferred.
- Load-bearing items must be answered — never assumed or deferred.
- Cap at two rounds of questions.
- Do not assign skills to subtasks — describe the concern ("schema design", "security review"), not the skill filename.
- Do not start the work unless the user says "go" / "execute" / "do it" after seeing the brief.

## Load-Bearing Items

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

Everything else (deadline, out-of-scope, test depth, rollout order, blast radius) is Assumable — fill with a safe default and tag it.

## Output Shape

**Multi-slice brief (multi-repo, single-repo feature, or anything needing decomposition):**
> *"Here is your task brief. For multi-slice work, run task breakdown next to get a parallel-dispatchable plan. Paste the brief into a fresh session, or say 'go' and I'll hand it to task breakdown now."*

**Single-slice brief (investigation or scoped bugfix):**
> *"Here is your task brief. Paste it into a fresh session, or say 'go' and I'll execute it now."*

Then stop. No commentary after the brief.

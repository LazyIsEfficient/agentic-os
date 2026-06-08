---
description: Launch the sharded, adversarially-verified skill-library audit (all skills, or one named skill)
argument-hint: "[skill-name]"
allowed-tools: Workflow
---

You are launching this library's skill/agent quality audit. It runs as a deterministic multi-agent workflow — one generation agent per skill (clean context, reads the skill's actual files + the `skill-library-review` rubric), then an independent default-reject verify gate before any finding is filed. This sharded+verified model exists because monolithic single-pass audits run ~10–15% false positives, concentrated in routing-collision findings; do not replace it with an ad-hoc single-agent review.

Not the same as the `library-reviewer` agent — that is an ad-hoc, read-only reviewer for a small set of files. This command runs the deterministic sharded+verified workflow across the whole library (or one named skill). Reach for the agent when iterating on a few files mid-edit; reach for this command for a full, low-false-positive audit.

## Step 1 — determine scope

- `$ARGUMENTS` holds an optional skill name.
- If `$1` is **non-empty**, scope the audit to that one skill: validate it is kebab-case, then pass `args` as `{ "skills": ["$1"] }`. If `.claude/skills/$1/` does not look like a real skill name, STOP and ask which skill to audit rather than guessing.
- If `$ARGUMENTS` is **empty**, audit the whole library: invoke with no `args` (the workflow self-discovers every `.claude/skills/*/SKILL.md`).

## Step 2 — run the workflow

Invoke the `Workflow` tool with `name: "audit-skill-library"` and the `args` decided in Step 1 (omit `args` entirely for a full-library run). Do not author or inline a new script — run the existing registered workflow.

## Step 3 — report

When the workflow returns, report to the user:

- The confirmed findings it returned (these already passed the verify gate — do not re-litigate them).
- The counts the workflow logs for its two backstops: Backstop 1 (re-attribution — warn if the finding count changed) and Backstop 2 (body-level dedup — how many existing issue bodies were fetched and how many candidates were dropped as duplicates).
- Do NOT file issues automatically. Present the confirmed findings and let the user decide what to file.

---
description: Run the in-session multi-agent collaboration pod (PM + engineer + library-reviewer) on a task via the v2-collab workflow, then materialize the result
argument-hint: <task description, or a path to a task file>
allowed-tools: Workflow, Read, Write, Bash
---

You are launching the **v2-collab** in-session collaboration pod. A pod of three
real Claude Code subagents — `technical-pm` -> `engineer` -> `library-reviewer` —
collaborates over a shared artifact across orchestrator-clocked rounds until the
reviewer approves or the round cap is hit. It runs entirely in this session on the
subscription (no Redis, no Rust, no API key). This replaces driving the standalone
Rust runtime from a terminal.

This spends real subscription tokens (up to `maxRounds × 3` subagent turns). Tell
the user the rough cost before launching if the cap is high.

## Step 1 — resolve the task

`$ARGUMENTS` holds the task. If it is **empty**, STOP and ask the user what the pod
should produce. If `$ARGUMENTS` is a path to an existing file, `Read` it and use its
contents as the task; otherwise use the literal text as the task instruction.

A good task names: the deliverable, its acceptance criteria, and where the output
files should be written. If the task is a one-liner, that is fine — the PM will
frame it in round 1.

## Step 2 — run the workflow

Invoke the **Workflow** tool with `name: "v2-collab"` and `args: { task: <the task
text>, maxRounds: <N> }`. Default `maxRounds` to 6; offer a lower cap (e.g. 3) for a
cheaper first run if the user is cost-sensitive. The workflow returns
`{ approved, rounds, files, artifact, log }` where `artifact` is a map of
`filename -> content`.

## Step 3 — materialize the artifact (sanitize paths — model output is untrusted)

The `artifact` keys are filenames CHOSEN BY THE AGENTS and are untrusted. Before
writing any file, reject — fail-closed, abort the whole materialize — any key that
is absolute, contains a `..` component, or whose resolved path would escape the
output directory. Do not silently skip a bad key.

Write the files under a clearly-scoped output directory the user named in the task,
or default to `./v2-out/<short-slug>/`. **Do NOT write into `.claude/skills/`,
`.claude/agents/`, or any live library path unless the user explicitly asked for
that** — a new library artifact must go through the normal review gate, not ride in
on a pod run. Use `Write` for each file.

## Step 4 — report

Report concisely: approved or hit-the-cap, how many rounds, the files written and
where, and a one-line summary of the reviewer's final note (from `log`). If the
deliverable was a library skill and the user wants it kept, run
`bash scripts/validate.sh <staged-root>` to gate it (validate.sh validates a whole
`<root>/.claude` tree — stage the skill under a temp `<root>/.claude/skills/<name>/`
first) and report PASS/FAIL. Do not merge anything into the live library yourself.

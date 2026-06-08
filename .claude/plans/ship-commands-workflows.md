# Plan 1 — Ship commands + workflows (distributable surfaces)

**Status:** proposed
**Author:** orchestration session, 2026-06-08 (split from `claude-feature-expansion.md`)
**Scope:** add `.claude/commands/` and `.claude/workflows/`, wired into both installers, with each artifact tagged ship-to-users vs. in-repo-only.

> Split rationale: the original plan bundled four categories. Output-styles (Category C) were cut — the plan itself rated them "lowest marginal value" and `CLAUDE.md` already enforces house voice. The `CLAUDE.md`→`rules/` refactor (Category D) is **not a distribution feature** (the installer never copies `CLAUDE.md`) and moved here: see [claudemd-rules-refactor.md](claudemd-rules-refactor.md).

## Context (grounded — re-verified 2026-06-08)

- Library today: 82 skills, 18 agents, 1 hook ([block-bad-bash.sh](../hooks/block-bad-bash.sh)). No `commands/` or `workflows/` dir.
- **Distribution gate:** [install.sh](../../install.sh#L91-L93) calls `install_dir "skills"` / `"agents"` / `"hooks"`; nothing else ships. [install.ps1](../../install.ps1#L79-L87) is **asymmetric** — `skills`/`agents` go through `Install-Dir`, but `hooks` is a bespoke block (it needs the exec bit). New `.md`/`.js` dirs need no `chmod`/exec handling, so they use plain `Install-Dir` / `Install-Dir`-equivalent lines in both.
- Workflows are discovered by the Workflow tool from `.claude/workflows/` (built-in or repo-local), plain-JS scripts beginning with `export const meta`.
- Commands are `.claude/commands/<name>.md`: frontmatter `description`, optional `argument-hint`, `allowed-tools`; body is the prompt using `$ARGUMENTS` / `$1`.

## Ship/no-ship tagging (decided up front)

Every command is a new routing surface installed into the consumer's **global** command namespace. Maintainer-only tooling must NOT ship — it pollutes consumers and risks colliding with their own commands.

| Artifact | Audience | Wire into installer? |
|---|---|---|
| `commands/skill-new.md` | skill **authors** (consumers may author too) | **Ship** |
| `commands/agent-new.md` | agent authors | **Ship** |
| `commands/route.md` | anyone routing a task | **Ship** (but see redundancy note) |
| `commands/audit-library.md` | **this repo's maintainers** | **In-repo only** |
| `commands/review-gate.md` | maintainers (Pattern-3 gate) | **In-repo only** |
| `commands/wave.md` | maintainers | **In-repo only** |
| `commands/mem.md` | **this repo's memory discipline** | **In-repo only** |
| `workflows/audit-skill-library.js` | maintainers | **In-repo only** |
| `workflows/routing-collision-sweep.js` | maintainers | **In-repo only** |

Mechanism for in-repo-only: keep them in `.claude/commands/` and `.claude/workflows/` for this repo's own use, but the installer's copy list enumerates **only the ship-tagged files**, not whole directories. (Decide: per-file allowlist in the installer, or a `commands/_local/` subdir excluded from copy. Per-file allowlist preferred — explicit.)

## Category A — Commands

| File | `argument-hint` | Purpose | Routes to |
|---|---|---|---|
| `skill-new.md` | `<skill-name>` | Scaffold `skills/<name>/SKILL.md` (name/description/when_to_use + starter body), hand to review | `library-reviewer` |
| `agent-new.md` | `<agent-name>` | Scaffold `agents/<name>.md` (frontmatter + tool allowlist + "Skills available" block) | `library-reviewer` |
| `route.md` | `<task description>` | Recommend owning skill/agent; no work performed | `using-agent-skills` |
| `audit-library.md` | `[skill-name]` | Launch sharded + adversarially-verified audit | workflow `audit-skill-library.js` |
| `wave.md` | `<brief>` | brief → DAG → parallel dispatch | `planning-and-task-breakdown` |
| `review-gate.md` | — | `code-reviewer` + (if library files touched) `library-reviewer` on current diff | Pattern 3 |
| `mem.md` | — | Review session, propose/write `.claude/memory/` entries | memory mechanics |

**Redundancy justification required before building each command.** `route`/`wave`/`review-gate`/`audit-library` are thin wrappers over existing skills/agents. A command earns its place only via **ergonomics a skill invocation lacks**: discoverability in `/help`, positional-arg passing, a fixed allowed-tools sandbox. If a command adds none of these over "invoke the skill," cut it. Build priority: `skill-new`, `agent-new`, `audit-library`, `review-gate` first; `route`, `wave`, `mem` second.

**Frontmatter template:**
```md
---
description: <one line, shown in /help>
argument-hint: <hint or omit>
allowed-tools: <minimal set, e.g. Read, Grep, Glob, Task>
---
<prompt body using $ARGUMENTS / $1>
```

## Category B — Workflows

| File | What it does | Pattern |
|---|---|---|
| `audit-skill-library.js` | One reviewer per skill (pipeline) → adversarial verify gate per finding | find → verify |
| `routing-collision-sweep.js` | Pairwise routing-overlap detection across all skills | fan-out + dedup barrier |

Both have **proven demand** — the last three commits were exactly routing-collision + sharded-audit work. Build these two only; defer `cross-reference-health.js` and `shape-plan-dispatch.js` from the original plan until demand is shown.

### audit-skill-library.js — MUST encode the documented harness, not a fresh design

[audit_skill_library_sharded.md](../memory/audit_skill_library_sharded.md) records the *working* recipe and two backstops a naive "verify each finding" drops. The workflow regresses to the 10–15% false-positive rate if these are omitted:

- **Harness:** `pipeline(skills, generate, verify)` — one agent per skill (clean context, reads actual files + `skill-library-review` rubric) for generation; an independent **default-reject** verify agent re-reads files and re-runs the Step-0 contention + reciprocal "not when" check before any finding is filed.
- **Backstop 1 — meta-skill mis-attribution:** an agent reviewing a meta-skill (e.g. `skill-library-review` itself) may attribute findings about *other* skills to itself. Re-attribute from each finding's title/evidence.
- **Backstop 2 — body-level dedup:** dedup candidate findings against existing issue **bodies**, not just titles (a `CRM_API_KEY` finding duplicated an open issue whose title never said "CRM").
- **Reference point:** the 2026-06-05 run over 79 skills produced 43 candidates → gate rejected 1 (severity, not falseness) → 27 issues filed (#63–#89). Use as the regression baseline.

## Cross-cutting tasks

1. **Wire installers (ship-tagged files only).** Add the ship-tagged `commands/` files to [install.sh](../../install.sh) and [install.ps1](../../install.ps1). No exec-bit handling needed (`.md`/`.js`). In-repo-only files are excluded — confirm the copy list is a per-file allowlist, not a whole-dir copy. **No workflows ship** in v1 (all maintainer-only).
2. **README** — add the new surfaces + the ship/no-ship distinction to [README.md](../../README.md).
3. **gitignore** — confirm `commands/` and `workflows/` are not ignored (only `memory`/worktrees/`settings.local` are today).
4. **Review path for new artifact types.** `library-reviewer`'s contract is skills/agents — confirm it (or an extension) validates command frontmatter (`allowed-tools`, `$ARGUMENTS` usage) and workflow `meta`. If not covered, this is a gap to close before the gate is meaningful.

## Execution DAG

- **Wave 1 (parallel, worktree-isolated):**
  - A1 commands: `skill-new`, `agent-new`, `review-gate`
  - B1 workflows: `audit-skill-library.js`, `routing-collision-sweep.js`
  - **Edge:** `audit-library.md` routes to `audit-skill-library.js` — build the workflow before (or in the same wave as) the command, or the command dangles. Defer `audit-library.md` to after B1 lands.
- **Wave 1.5:** run `routing-collision-sweep.js` **against the new command trigger vocabulary** — the new commands are new routing surfaces; sweep them before merge, same discipline as waves 2–3.
- **Wave 2 (serial — conflict on shared files):** wire `install.sh` + `install.ps1` + `README.md` for the ship-tagged artifacts only.
- **Wave 3 (gate):** `library-reviewer` (or extended reviewer) on commands/workflows; `code-reviewer` on installer/README edits. Address verdicts before merge.

Branch suffixes: `-commands`, `-workflows`, `-dist`.

## Success criteria (per artifact)

- A command is done when: frontmatter validates, `allowed-tools` is minimal-and-sufficient, `$ARGUMENTS`/`$1` resolve, it appears in `/help`, and it adds an ergonomic the bare skill invocation lacks.
- `audit-skill-library.js` is done when: it reproduces the 2026-06-05 baseline shape (sharded generate → default-reject verify) with both backstops encoded, and a dry run over the current 82 skills produces a candidate set with ≤1 false positive in the routing category.
- Installer is done when: a clean `install.sh` into a temp `~/.claude` copies exactly the ship-tagged files and zero in-repo-only files.

## Open decisions

- In-repo-only exclusion mechanism: per-file installer allowlist (preferred) vs. `_local/` subdir?
- `route`/`wave`: build at all, or is invoking `using-agent-skills` / `planning-and-task-breakdown` directly enough? Resolve via the redundancy-justification test above.

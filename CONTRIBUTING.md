# Contributing

This repo is a Claude Code skills + agents library. Contributions are mostly new or improved skills, agents, commands, and workflows under `.claude/`. This document codifies the conventions and the review gates a change must pass before it ships.

## Quick start

Scaffold with the maintainer commands rather than by hand — they emit conforming frontmatter and hand the result to `library-reviewer` automatically:

- `/skill-new <skill-name>` — creates `.claude/skills/<skill-name>/SKILL.md`
- `/agent-new <agent-name>` — creates `.claude/agents/<agent-name>.md`

Then fill in every `TODO`, add supporting files, update the README tables, and run the gates below.

## Skill conventions

- One folder per skill: `.claude/skills/<skill-name>/`, kebab-case. The frontmatter `name` MUST equal the folder name — the validator blocks a mismatch.
- `SKILL.md` frontmatter requires `name`, `description`, and `when_to_use`:
  - `description` — third person, starts with "Use when …", includes concrete trigger vocabulary (real user phrasing in quotes, file globs), and ends with at least one cross-reference ("For X see other-skill"). Keep under 1024 chars.
  - `when_to_use` — expands the situation the skill owns, then a "Not when:" paragraph deflecting to every sibling skill that could plausibly fire on the same request.
- Keep `SKILL.md` under ~100 lines. Deep content goes in `references/*.md`, fill-in templates in `assets/`, runnable helpers in `scripts/`.
- Scripts must exit nonzero on failure so they compose with CI (convention: `0` = pass, `1` = check failed, `2` = setup error). Declare Python dependencies in a skill-local `requirements.txt`.
- **Body cross-references are markdown links** to the target file — `[name](../other-skill/SKILL.md)` for a skill, `[name](../../agents/other-agent.md)` for an agent — so `validate.sh` Invariant 3 catches a dangling one (R37). The `## Skills available` / `## Related skills` lists are links, not bare names, and should be reciprocal (point at a sibling → add a back-reference in its `Related skills`). Sibling mentions in the `description`/`when_to_use` stay as plain-text routing hints (links would clutter the catalog) — they are **not** gated, so keep them accurate by hand.

## Agent conventions

- One file per agent: `.claude/agents/<agent-name>.md`, kebab-case. The frontmatter `name` MUST equal the file stem.
- Frontmatter requires `name`, `description` (trigger vocabulary + "For X see Y" cross-refs), and `tools` (comma-separated allowlist).
- Choose the minimal allowlist for the role (rule of thumb, per `.claude/skills/skill-library-review/references/tool-allowlists.md`):
  - read-only reviewer/auditor → `Read, Grep, Glob, Bash, WebFetch, WebSearch`
  - intake/shaper → reviewer set plus `AskUserQuestion` (no `Agent`, no `Edit`/`Write`)
  - authoring → reviewer set plus `Edit, Write, AskUserQuestion`
  - build/orchestrator → omit `tools:` entirely to inherit (orchestrator is the only role that gets `Agent`)
- End the body with a `## Skills available` section linking the skills the agent executes, and a `## Delegate` section stating whether it delegates.

## README tables

Add a one-line row for every new skill and agent to the `## Skills` and `## Agents` tables in `README.md`, in alphabetical position.

## Review gates

Both gates must pass before a change is done:

1. **Library review.** Run the `library-reviewer` agent on your diff for any change touching `.claude/skills/`, `.claude/agents/`, `.claude/commands/`, or `.claude/workflows/`. If the change includes runnable scripts, run `code-reviewer` on them as well. Address the verdict — the gate is the gate.
2. **Structural validation.** `bash scripts/validate.sh` must exit 0. It is deterministic and LLM-free: frontmatter completeness, kebab-case names matching file/dir, no dangling links or `@`-imports, `MEMORY.md` length, ship-manifest drift, review-tier wiring ("Tier discipline" sections must reference the tier doctrine; the findings ledger, if present, must be valid JSONL with known status values), hook-safety (Invariant 8), and **tombstones (Invariant 9)** — no prose reference (`` `slug` ``, `/slug`, `slug/path`) to a pruned skill/agent/command. CI runs it on every PR and push to `main` (`.github/workflows/validate.yml`).
   - **When you delete a skill/agent/command, add its slug to the `TOMBSTONES` list in `scripts/validate.sh`** (and remove a slug if you re-add it). Invariant 9 then fails on any surviving prose reference — the class of dangling ref that link-only checks (Invariant 3) cannot see, which is how ~30 dead refs once survived a prune with validate green.

**The tier rule.** Every check belongs to a tier sorted by reproducibility (doctrine: [.claude/rules/review-tiers.md](.claude/rules/review-tiers.md)). Only Tier 0 — deterministic checks like `validate.sh` — hard-blocks a change on its own authority. Tier 1 LLM findings may block only through their attached evidence artifact (a failing script or explicit counterexample). Everything unevidenced is Tier 2: advisory, recorded in the findings ledger (`findings-ledger` skill, `/triage-findings` command) so recurrence — not one run's mood — decides what gets investigated and promoted into a deterministic check. In gate 1 above, treat a reviewer verdict that rides only on unevidenced findings as a proposal, not a block.

Enable the pre-commit hook once per clone so the validator runs before every commit:

```sh
git config core.hooksPath .githooks
```

## What ships to consumers

`install.sh` / `install.ps1` ship the full `skills/`, `agents/`, and `hooks/` directories plus three commands (`skill-new.md`, `agent-new.md`, `state.md`). Everything else — `CLAUDE.md`, `CURSOR.md`, `rules/`, maintainer commands, `workflows/`, `pocs/` — is repo-local and never installed. The validator enforces exact equality between the install scripts and this manifest (`EXPECTED_DIRS` / `EXPECTED_CMDS` in `scripts/validate.sh`), so changing what ships means updating the install scripts **and** the validator in the same PR.

## Cursor maintainers

Claude conventions above govern shared content under `.claude/`. Cursor adds a parallel consumer install and a repo-local hook surface.

- **Install.** `install-cursor.sh` / `install-cursor.ps1` copy `skills/` and `agents/` from `.claude/` and production hook scripts from `.cursor/hooks/` (excluding `*-probe.sh` spike fixtures) into `~/.cursor/skills/`, `~/.cursor/agents/`, and `~/.cursor/hooks/` (dormant until registered). Changing what ships requires updating both Cursor install scripts and `EXPECTED_CURSOR_DIRS` in `scripts/validate.sh` in the same PR.
- **Shared vs Cursor-specific.** Skill and agent markdown live in `.claude/`. Cursor-native production hooks live in `.cursor/hooks/` (these ship globally); activation wiring lives in project `.cursor/hooks.json`; operating doctrine lives in `.cursor/rules/` (repo-local — clone this repo into a project to use). Consumer install details: [README — Cursor](README.md#cursor).
- **Hook activation (opt-in).** The global installer lands hook scripts dormant; no `hooks.json` ships. To enable the awareness harness in a project, register `.cursor/hooks/*.sh` via `.cursor/hooks.json` — this repo ships a working example at `.cursor/hooks.json`. See README [Awareness harness](README.md#awareness-harness-experimental).
- **Gates for `.cursor/hooks/` changes.** Run all four before merging:

  ```sh
  bash scripts/session-state-test-cursor.sh
  bash scripts/survey-guard-test-cursor.sh
  bash scripts/block-bad-bash-test-cursor.sh
  bash scripts/validate.sh
  ```

  CI runs the same set on every PR (`.github/workflows/validate.yml`). Add or rename a production hook → update `.cursor/hooks.json` if registering it; `validate.sh` checks command paths against the v1 schema.

## What not to commit

- `.claude/memory/` — machine-local persistent memory (gitignored)
- `.claude/settings.local.json` — local overrides (gitignored)
- `.claude/worktrees/` — ephemeral agent worktrees (gitignored)

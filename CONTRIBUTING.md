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
- Cross-references must resolve (the validator checks relative file links in `SKILL.md` and agent files) and should be reciprocal — when you point at a sibling skill, add a back-reference in that sibling's "Related skills" section.

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
2. **Structural validation.** `bash scripts/validate.sh` must exit 0. It is deterministic and LLM-free: frontmatter completeness, kebab-case names matching file/dir, no dangling links or `@`-imports, `MEMORY.md` length, and ship-manifest drift. CI runs it on every PR and push to `main` (`.github/workflows/validate.yml`).

Enable the pre-commit hook once per clone so the validator runs before every commit:

```sh
git config core.hooksPath .githooks
```

## What ships to consumers

`install.sh` / `install.ps1` ship a curated allowlist only: the `skills/`, `agents/`, and `hooks/` directories plus three commands (`skill-new.md`, `agent-new.md`, `route.md`). Everything else — `CLAUDE.md`, `rules/`, maintainer commands, `workflows/`, `pocs/` — is repo-local and never installed. The validator enforces exact equality between the install scripts and this allowlist (`EXPECTED_DIRS` / `EXPECTED_CMDS` in `scripts/validate.sh`), so changing what ships means updating the install scripts **and** the validator in the same PR.

## What not to commit

- `.claude/memory/` — machine-local persistent memory (gitignored)
- `.claude/settings.local.json` — local overrides (gitignored)
- `.claude/worktrees/` — ephemeral agent worktrees (gitignored)

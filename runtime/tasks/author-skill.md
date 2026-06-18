# Task: author ONE small, real, self-contained library skill

You are a pod (technical-pm, engineer, library-reviewer) collaborating over a
shared blackboard. Your single deliverable is **one** new Claude Code library
skill that passes the deterministic library validator
(`scripts/validate.sh`) with zero failures.

Keep it SMALL and achievable in a few rounds. One file. No scripts, no
references, no extra assets. Quality of the frontmatter and routing prose is
what matters, not size.

## What you are building

Author a skill named **`commit-message-conventions`**: a short, self-contained
skill that guides writing clear, conventional git commit messages (imperative
subject ≤ 50 chars, blank line, wrapped body explaining *why*, and a footer for
issue/breaking-change trailers). Pick crisp, non-overlapping routing language so
it does not collide with a general git-workflow skill.

If a skill with that name already exists in the library, instead author
**`pull-request-descriptions`** — a skill for writing reviewable PR
descriptions (what changed, why, how to test, risk/rollback). Same structure
rules below apply.

## Required output: exactly ONE artifact edit

Emit a single `artifact_edits` entry whose **key is exactly** `SKILL.md`
(no directory prefix, no leading slash, no `..`). Its value is the full
Markdown file contents. The orchestrator materializes this key to
`.claude/skills/<name>/SKILL.md` and runs the validator there; any other key
shape (absolute, `..`, nested escape) is rejected fail-closed and the demo
aborts. Do **not** emit any other files.

## Required structure (what `scripts/validate.sh` enforces — Tier 0)

The validator parses YAML frontmatter line-by-line. Your `SKILL.md` MUST:

1. **Open with a `---`-delimited frontmatter block** as the very first line.
2. Carry these three frontmatter keys, each **present and non-empty**:
   - `name:` — inline value, **kebab-case**, and it MUST equal the skill's
     directory name (the materialize `--out` dir basename). Use exactly the
     chosen name above (`commit-message-conventions` or
     `pull-request-descriptions`).
   - `description:` — inline value: one rich sentence-or-two describing what the
     skill does AND the trigger phrases that route to it ("Use when …").
   - `when_to_use:` — a block scalar (`when_to_use: |`) with at least one
     non-blank indented line. Include an explicit **"Not when: …"** clause that
     points at the neighbouring skill it must not be confused with, so routing
     stays disambiguated.
3. **Close the frontmatter** with a second `---` line, then the skill body.

### Frontmatter shape (copy this exact skeleton, fill the values)

```
---
name: commit-message-conventions
description: <one or two sentences: what it does + "Use when …" trigger phrases>
when_to_use: |
  <indented, non-blank>. Use when …

  Not when: <neighbouring skill> — use that instead.
---

# <Title>

<body: the actual guidance>
```

### Links must resolve (Tier 0 dangling-ref check)

If the body uses a **relative markdown file link** with a file extension
(e.g. `[git-workflow-and-versioning](../git-workflow-and-versioning/SKILL.md)`),
the target MUST exist on disk relative to your `SKILL.md`. Before linking to a
sibling skill, be sure it exists; if unsure, **describe it by name in prose
without a `.md` link** rather than risk a dangling reference that fails the
validator. URLs (`https://…`), `mailto:`, and pure `#anchor` links are exempt.

## Round protocol

- **technical-pm**: state the skill's job, its one-sentence scope boundary, and
  the single neighbouring skill it must not collide with. Do not write the file.
- **engineer**: write the complete `SKILL.md` as the one `artifact_edits["SKILL.md"]`
  entry, conforming to every rule above.
- **library-reviewer**: check the frontmatter keys, kebab `name`, the "Not when"
  disambiguation, and that any relative `.md` link resolves. Approve only when
  the file would pass `scripts/validate.sh` with zero failures.

## Done

The run is done when the reviewer approves a single-file `SKILL.md` artifact
that satisfies every rule above. Keep it tight — a correct small skill beats a
sprawling one.

---
description: Scaffold a new skill (SKILL.md with conforming frontmatter) and hand to library-reviewer
argument-hint: <skill-name>
allowed-tools: Glob, Write, Agent
---

You are scaffolding a new conforming skill named `$1`.

## 1. Resolve the name

The skill name is `$1`. If `$ARGUMENTS` is empty, STOP and ask: "What is the skill name? (kebab-case, e.g. `rust-engineer`)". Otherwise validate `$1` is kebab-case (lowercase, hyphen-separated, no spaces/underscores/capitals). If it is not, STOP and report the violation — do not auto-correct silently.

## 2. Check for collision

Before writing anything, use `Glob` to check whether `.claude/skills/$1/` already exists (e.g. glob `.claude/skills/$1/*`). If the folder exists or contains any files, STOP and report the collision — do NOT overwrite. Tell the author the skill `$1` already exists and they must pick a different name or edit the existing skill directly.

## 3. Write the SKILL.md

Create exactly one file: `.claude/skills/$1/SKILL.md`. The folder name MUST equal `$1` (the loader keys off the `name` field, and a name/folder mismatch is a blocking error).

Emit this content verbatim, substituting `$1` for the name. Leave every `TODO` in place — do NOT invent triggers, cross-references, or domain detail. The author fills those in.

```
---
name: $1
description: TODO — one line. Start with "Use when <situation>." Add concrete trigger vocabulary — file globs (e.g. `*.rs`) and real user phrasing in quotes (what users actually say, not jargon). End with at least one cross-reference: "For <adjacent concern> see <other-skill>." Keep under 1024 chars; aim under 800. Third person, no "I"/"We".
when_to_use: |
  TODO — Use when <expand the situation the skill owns>: <list the concrete tasks and the load-bearing signal that should route here>.

  Not when: <name each adjacent skill and the case it owns> — use <other-skill>. <Repeat for every sibling that could plausibly fire on the same request, so the loader can deflect.>
---

# TODO — Skill Title

TODO — one or two sentences: the role Claude adopts and the operating posture.

## TODO — Core Rules / Principles

TODO — the non-negotiable rules this skill enforces.

## TODO — Workflow

TODO — the steps Claude follows when this skill is active.

## References

TODO — link any `references/*.md` deep-dive docs, or remove this section.
```

Keep `SKILL.md` under ~100 lines; deep content belongs in `references/`. Templates the author fills out go in `assets/`; runnable helpers go in `scripts/`.

## 4. Review

After the file is written, dispatch the `library-reviewer` agent via Agent. Brief it: "Review the newly scaffolded skill at `.claude/skills/$1/SKILL.md` for frontmatter conformance (name matches folder, description has Use-when + trigger vocab + cross-ref, when_to_use has a Not-when paragraph) and file structure. It is a scaffold — flag structural problems, but treat `TODO` placeholders as expected, not findings. Report under 150 words."

## 5. Report

Report back: the path written, and the `library-reviewer` verdict. Remind the author to replace every `TODO` before the skill ships.

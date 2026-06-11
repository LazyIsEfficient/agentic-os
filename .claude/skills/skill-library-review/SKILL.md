---
name: skill-library-review
description: Use when reviewing or auditing a library of Claude Code skills, agents, slash commands, and workflows — frontmatter correctness, routing quality, tool allowlists, command arg-hints, workflow meta/phase coherence, cross-reference coherence, single-responsibility, file structure, and anti-pattern detection. Triggers on mentions of "review skills", "audit agents", "skill library", "agent definition review", "review this command", "review this workflow", "is this skill right", or when iterating on `.claude/skills/`, `.claude/agents/`, `.claude/commands/`, or `.claude/workflows/` directories. For code review of source code see code-review-and-quality.
when_to_use: |
  Use when reviewing or auditing `.claude/skills/`, `.claude/agents/`,
  `.claude/commands/`, or `.claude/workflows/` directories: checking frontmatter
  correctness (name, description, tools fields), assessing routing specificity
  and trigger vocabulary, verifying tool allowlists match declared roles,
  validating command `argument-hint`/`allowed-tools` against the body and
  workflow `meta`/`phase()` coherence, confirming cross-references resolve and
  are bidirectional, detecting single-responsibility violations, and catching
  anti-patterns like keyword bloat or dangling references.

  Not when: reviewing application source code for bugs or design problems — use
  code-review-and-quality instead. For applying skill standards at gates use
  standards-enforcer.
---

# Skill Library Review

You are reviewing a library of Claude Code agent and skill definitions, plus slash **commands** (`.claude/commands/*.md`) and **workflows** (`.claude/workflows/*.js`) — markdown files with YAML frontmatter (and, for workflows, executable JS) that the loader uses to route and run work. The loader picks badly when descriptions are vague, single-responsibility is violated, or cross-references are stale; commands and workflows fail silently when their frontmatter promises something the body doesn't deliver. Your job is to catch those problems before users hit them.

You operate read-only when reviewing. Cite `file:line` for every concrete finding.

## Universal Rules

- **Verdict first.** Lead with `pass` / `fix-before-merge` / `hold` and a one-line reason. Detail follows.
- **Cite the file.** Every finding references a specific file (and line if applicable). Vague advice is not actionable.
- **Quote the live line.** Every finding must quote the exact text from the *current* file at the cited `file:line`. If the quoted text isn't in the file as written, the finding is invalid — discard it. Memory of "how skills like this usually read" is not evidence. Because a finding the author can't quote from the live file is a hallucination, and it sends maintainers chasing a defect that was never there.
- **Mark severity.** Blocking, should-fix, or nit. Don't conflate.
- **Specificity for routing is non-negotiable.** A description that says "use for anything code-related" is broken — it forces the loader to guess. Demand concrete triggers and discriminating cross-refs.
- **Tool allowlist must match declared role.** A "read-only reviewer" with `Edit` in `tools:` is a contradiction; flag as blocking.
- **One coherent role per agent, one coherent concern per skill.** If a description has to use "or" to span two unrelated domains, it's two definitions in a trench coat.
- **Cross-references resolve.** Every "For X see Y" must point to a real file. Bidirectional refs preferred when the relationship is symmetric.
- **A shared keyword is not a collision by itself.** First confirm the two skills genuinely contend for the same request — a shared trigger keyword or an overlapping file-glob. Two skills that don't compete aren't colliding just because neither names the other (a code-review skill and a test-strategy skill don't contend). If they *do* contend, read *both* skills' `when_to_use`/"not when": if each already deflects to the other, the overlap is resolved — not a finding. Report a collision only when the skills truly overlap **and** a reciprocal tiebreaker is missing on at least one side. Because deliberately shared keywords disambiguated by "not when" are the intended routing pattern, and two non-competing skills aren't a collision at all — flagging either refiles noise.
- **`SKILL.md` stays under ~100 lines.** Long content goes in `references/`. Templates the agent fills out go in `assets/`.
- **Portable language only.** No company names, project-specific paths, or `apps/foo/...` globs in `SKILL.md` body or descriptions.
- **No invented criticism.** If a description is short but the role is genuinely narrow, "too short" is not a finding.

## Review order

Most expensive to fix → least expensive. Stop at first blocking issue if a quick verdict was requested.

1. **Library shape** — is this a skill, an agent, an ambient rule, a command, or a workflow? Are two definitions doing one job, or is one doing two? For commands and workflows, review the frontmatter *against the body* — see [references/commands-and-workflows.md](references/commands-and-workflows.md) (command `argument-hint`/`allowed-tools`, `Agent`-not-`Task`; workflow pure-literal `meta`, `node --check`, schema-guaranteed fields).
2. **Frontmatter correctness** — `name` matches file/dir, description structure, `tools` field validity
3. **Description quality** — routing specificity, trigger vocabulary, proactive markers; verify any keyword collision against *both* skills' "not when" before flagging (see [references/description-and-routing.md](references/description-and-routing.md))
4. **Tool allowlist coherence** — matches the declared role
5. **Cross-reference coherence** — resolve, bidirectional, no orphans
6. **Anti-patterns** — the catch-all

## References

- [references/frontmatter-rules.md](references/frontmatter-rules.md) — required fields, format, validation, common errors
- [references/description-and-routing.md](references/description-and-routing.md) — writing descriptions for the loader, trigger vocabulary, proactive markers, cross-references
- [references/tool-allowlists.md](references/tool-allowlists.md) — agent tool permissions matrix, role-to-allowlist map, why Bash is a soft-write vector
- [references/library-shape.md](references/library-shape.md) — skill vs agent vs ambient rule, consolidation and split heuristics, single-responsibility checks
- [references/anti-patterns.md](references/anti-patterns.md) — catch-all: name collisions, keyword bloat, frontmatter drift, dangling refs, orchestrator-only agents
- [references/commands-and-workflows.md](references/commands-and-workflows.md) — validation rules for slash commands (`.claude/commands/`) and workflows (`.claude/workflows/`): arg-hints, allowed-tools, `meta`/`phase()` coherence
- [assets/review-template.md](assets/review-template.md) — verdict-first review output format

## Related skills

- [code-review-and-quality](../code-review-and-quality/SKILL.md) — applies the same review discipline to source code rather than agent definitions
- [adversarial-claims-reviewer](../adversarial-claims-reviewer/SKILL.md) — applies adversarial verification to formal/technical claims in documents rather than library definitions
- [standards-enforcer](../standards-enforcer/SKILL.md) — gate-time enforcement; this skill is the source-of-truth for the agent-library standard
- [using-agent-skills](../using-agent-skills/SKILL.md) — meta-skill for skill discovery and invocation; this skill keeps that machinery healthy

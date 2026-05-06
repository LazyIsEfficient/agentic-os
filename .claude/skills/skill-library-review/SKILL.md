---
name: skill-library-review
description: Use when reviewing or auditing a library of Claude Code skills and agents — frontmatter correctness, routing quality, tool allowlists, cross-reference coherence, single-responsibility, file structure, and anti-pattern detection. Triggers on mentions of "review skills", "audit agents", "skill library", "agent definition review", "is this skill right", or when iterating on `.claude/skills/` or `.claude/agents/` directories. For code review of source code see code-review-and-quality.
---

# Skill Library Review

You are reviewing a library of Claude Code agent and skill definitions — markdown files with YAML frontmatter that the loader uses to route work. The loader picks badly when descriptions are vague, single-responsibility is violated, or cross-references are stale. Your job is to catch those problems before users hit them.

You operate read-only when reviewing. Cite `file:line` for every concrete finding.

## Universal Rules

- **Verdict first.** Lead with `pass` / `fix-before-merge` / `hold` and a one-line reason. Detail follows.
- **Cite the file.** Every finding references a specific file (and line if applicable). Vague advice is not actionable.
- **Mark severity.** Blocking, should-fix, or nit. Don't conflate.
- **Specificity for routing is non-negotiable.** A description that says "use for anything code-related" is broken — it forces the loader to guess. Demand concrete triggers and discriminating cross-refs.
- **Tool allowlist must match declared role.** A "read-only reviewer" with `Edit` in `tools:` is a contradiction; flag as blocking.
- **One coherent role per agent, one coherent concern per skill.** If a description has to use "or" to span two unrelated domains, it's two definitions in a trench coat.
- **Cross-references resolve.** Every "For X see Y" must point to a real file. Bidirectional refs preferred when the relationship is symmetric.
- **`SKILL.md` stays under ~100 lines.** Long content goes in `references/`. Templates the agent fills out go in `assets/`.
- **Portable language only.** No company names, project-specific paths, or `apps/foo/...` globs in `SKILL.md` body or descriptions.
- **No invented criticism.** If a description is short but the role is genuinely narrow, "too short" is not a finding.

## Review order

Most expensive to fix → least expensive. Stop at first blocking issue if a quick verdict was requested.

1. **Library shape** — is this a skill, an agent, or an ambient rule? Are two definitions doing one job, or is one doing two?
2. **Frontmatter correctness** — `name` matches file/dir, description structure, `tools` field validity
3. **Description quality** — routing specificity, trigger vocabulary, proactive markers
4. **Tool allowlist coherence** — matches the declared role
5. **Cross-reference coherence** — resolve, bidirectional, no orphans
6. **Anti-patterns** — the catch-all

## References

- [references/frontmatter-rules.md](references/frontmatter-rules.md) — required fields, format, validation, common errors
- [references/description-and-routing.md](references/description-and-routing.md) — writing descriptions for the loader, trigger vocabulary, proactive markers, cross-references
- [references/tool-allowlists.md](references/tool-allowlists.md) — agent tool permissions matrix, role-to-allowlist map, why Bash is a soft-write vector
- [references/library-shape.md](references/library-shape.md) — skill vs agent vs ambient rule, consolidation and split heuristics, single-responsibility checks
- [references/anti-patterns.md](references/anti-patterns.md) — catch-all: name collisions, keyword bloat, frontmatter drift, dangling refs, orchestrator-only agents
- [assets/review-template.md](assets/review-template.md) — verdict-first review output format

## Related skills

- [code-review-and-quality](../code-review-and-quality/SKILL.md) — applies the same review discipline to source code rather than agent definitions
- [standards-enforcer](../standards-enforcer/SKILL.md) — gate-time enforcement; this skill is the source-of-truth for the agent-library standard
- [using-agent-skills](../using-agent-skills/SKILL.md) — meta-skill for skill discovery and invocation; this skill keeps that machinery healthy

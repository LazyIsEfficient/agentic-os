---
name: documentation-and-adrs
description: Records decisions and documentation. Use when making architectural decisions, changing public APIs, shipping features, or when you need to record context that future engineers and agents will need to understand the codebase.
when_to_use: |
  Use when making a significant architectural decision, choosing between competing approaches,
  adding or changing a public API, shipping a feature that changes user-facing behaviour,
  onboarding new team members or agents, or when the same design rationale keeps being
  re-explained. Also use to write and maintain ADRs, README structure, API docs, and changelogs.

  Not when: the task is keeping docs/ in sync with an ongoing PR diff — use `documentation-writer`
  for that incremental work. Not when the task is obvious code-level comments — those belong
  inline in the code without a separate skill.
---

# Documentation and ADRs

Document decisions, not just code. The most valuable documentation captures the *why* — the context, constraints, and trade-offs that led to a decision. Code shows *what* was built; documentation explains *why it was built this way* and *what alternatives were considered*.

## Core Rules

1. Write ADRs for every significant architectural decision — framework, data model, auth strategy, API shape, or anything expensive to reverse. Store in a consistent decisions directory (e.g., `docs/decisions/`) with sequential numbering.
2. Comment the *why*, not the *what*. If the code already says it, the comment adds no value.
3. Never delete old ADRs; write a new one that supersedes the old and cross-reference it.
4. Document known gotchas inline at the point where an engineer would encounter them.
5. Keep README current: quick start, commands, and architecture overview — nothing less.
6. Maintain a changelog for shipped features using Added / Fixed / Changed sections.
7. Don't document obvious code; don't write docs for throwaway prototypes.
8. Keep rules files (CLAUDE.md, etc.) current — they are the primary context for agents.

## Verification

After documenting:

- [ ] ADRs exist for all significant architectural decisions
- [ ] README covers quick start, commands, and architecture overview
- [ ] API functions have parameter and return type documentation
- [ ] Known gotchas are documented inline where they matter
- [ ] No commented-out code remains
- [ ] Rules files (CLAUDE.md etc.) are current and accurate

## References

- [assets/adr-template.md](assets/adr-template.md) — fill-in ADR template (store completed ADRs in `docs/decisions/`)
- [assets/readme-template.md](assets/readme-template.md) — fill-in README template for new projects
- [references/adr-guide.md](references/adr-guide.md) — when to write ADRs, lifecycle, and a worked example
- [references/inline-documentation.md](references/inline-documentation.md) — comment rules, API doc patterns (JSDoc + OpenAPI)
- [references/changelog-and-agents.md](references/changelog-and-agents.md) — changelog format, agent-context docs, red flags

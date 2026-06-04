---
name: git-workflow-and-versioning
description: Structures git workflow practices. Use when making any code change. Use when committing, branching, resolving conflicts, or when you need to organize work across multiple parallel streams.
when_to_use: |
  Use when working with atomic commits, branch management, git bisect, pre-commit hooks,
  worktree setup, tagging releases, or recovering from git mistakes. Specifically use when
  committing (atomic commit discipline, descriptive messages), branching (feature branches,
  trunk-based development), resolving merge conflicts, setting up worktrees for parallel agent
  work, debugging regressions with git bisect, or establishing a .gitignore and pre-commit
  hygiene for a new project.

  Not when: the task is managing CI/CD pipelines that run after a push — use
  `deployment-pipelines` for that. Not when the task is a higher-level release process
  (changelogs, versioning strategy, hotfix coordination) — use `git-workflow-and-versioning`
  for the commit mechanics and `documentation-and-adrs` for the changelog.
---

# Git Workflow and Versioning

## Overview

Git is your safety net. Treat commits as save points, branches as sandboxes, and history as documentation. With AI agents generating code at high speed, disciplined version control is the mechanism that keeps changes manageable, reviewable, and reversible.

## Universal Rules

1. **Commit early, commit often.** Each successful increment gets its own commit — never accumulate large uncommitted changes.
2. **Atomic commits.** Each commit does one logical thing; mixed concerns are separate commits.
3. **Descriptive messages explain the why.** Use `<type>: <description>` format with an optional body; see commit conventions for types.
4. **Keep concerns separate.** Formatting changes, refactors, and features are distinct commits and ideally distinct PRs.
5. **Size your changes.** Target ~100 lines per commit/PR; anything over ~1000 lines must be split.
6. **Trunk-based development.** Keep `main` always deployable; feature branches merge back within 1–3 days.
7. **No secrets in the diff.** Check staged output before every commit; automate with lint-staged.

## References

- [references/commit-conventions.md](references/commit-conventions.md) — message format, type list, atomic commit examples, concern separation, change summary template
- [references/branching-strategy.md](references/branching-strategy.md) — trunk-based development diagram, feature branch rules, the save point pattern
- [references/worktrees.md](references/worktrees.md) — git worktree commands for parallel agent work
- [references/pre-commit-hygiene.md](references/pre-commit-hygiene.md) — pre-commit checklist, lint-staged config, gitignore rules, git bisect/blame/log commands
- [references/rationalizations-and-red-flags.md](references/rationalizations-and-red-flags.md) — rationalization table and red-flag checklist

## Verification

For every commit:

- [ ] Commit does one logical thing
- [ ] Message explains the why, follows type conventions
- [ ] Tests pass before committing
- [ ] No secrets in the diff
- [ ] No formatting-only changes mixed with behavior changes
- [ ] `.gitignore` covers standard exclusions

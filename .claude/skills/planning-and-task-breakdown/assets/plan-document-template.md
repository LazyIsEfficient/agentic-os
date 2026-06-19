# Plan document template

Full structure for a parallel-dispatchable implementation plan. The per-task block format is defined in `task-block-format.md`. The DAG syntax and dispatcher contract are defined in `execution-dag.md`.

```markdown
# Implementation Plan: [Feature/Project Name]

**Status:** proposed   <!-- lifecycle: proposed → in-progress → shipped | superseded. Prune shipped & superseded plans manually. -->

## Overview
[One paragraph summary of what we're building]

## Architecture Decisions
- [Key decision 1 and rationale]
- [Key decision 2 and rationale]

## Execution DAG

```yaml
dag:
  - T-schema → T-register, T-login
  - T-register || T-login
  - T-register, T-login → T-session
  - checkpoint: Foundation after [T-session]
  - T-session → T-history || T-search
  - checkpoint: Complete after [T-history, T-search]
```

## Task List (presentational)

### Phase 1: Foundation
- [ ] T-schema
- [ ] T-register
- [ ] T-login
- [ ] T-session

### Checkpoint: Foundation
- [ ] Tests pass, builds clean
- [ ] Core auth flow works end-to-end

### Phase 2: Core Features
- [ ] T-history
- [ ] T-search

### Checkpoint: Complete
- [ ] All acceptance criteria met
- [ ] Ready for review

## Task Details

[One block per task ID, in any order — each block is self-contained
 (YAML frontmatter + description + acceptance + verification) so a
 dispatcher can hand any single block to a fresh agent without the
 rest of the document.]

### Task: User can register
```yaml
id: T-register
depends_on: [T-schema]
parallel_safe: true
conflicts_with: [T-login]
files_write:
  - src/auth/register.ts
  - src/api/auth/register.handler.ts
files_read:
  - src/db/schema/users.ts
branch_suffix: register
scope: M
```
**Description:** ...
**Acceptance criteria:** ...
**Verification:** ...

[...remaining task blocks...]

## Risks and Mitigations
| Risk | Impact | Mitigation |
|------|--------|------------|
| [Risk] | [High/Med/Low] | [Strategy] |

## Open Questions
- [Question needing human input]
```

## Plan status lifecycle

The `**Status:**` line (directly under the title) drives plan cleanup. Maintain it as the work moves:

- `proposed` — written, not started (the value a fresh plan ships with).
- `in-progress` — execution has begun.
- `shipped` — the work landed (merged).
- `superseded` — replaced by another plan or abandoned.

Keep it current: this line marks a plan's lifecycle, so `shipped` or `superseded` plans can be pruned (manually, after confirmation), leaving only live work in `.claude/plans/`. A plan with a missing or unrecognized status won't be recognized as done — so always set one.

## Section ordering rationale

- **Overview + Architecture Decisions first** — humans read top-down; these set context.
- **Execution DAG next** — dispatchers read top-down looking for the dispatch contract; surfacing it here means they don't have to scan the whole document.
- **Presentational task list** — for humans skimming "what's in this plan."
- **Task Details** — the meat. One block per task. Order does not matter (the DAG defines order).
- **Risks and Open Questions last** — these can be load-bearing but they're not part of dispatch. Putting them at the bottom keeps the dispatch path uncluttered.

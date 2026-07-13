# Task block format

Each task is one block: a YAML frontmatter for dispatchers (parallel runners, CI) plus prose for humans. The frontmatter is the dispatch contract; the prose is what the executing agent reads.

## Structure

```markdown
## Task: [Short descriptive title]

```yaml
id: T-stable-slug                 # stable across edits — never renumber
depends_on: []                    # task IDs that must complete and verify first
parallel_safe: true               # false if it mutates shared state in a way siblings can't tolerate
conflicts_with: []                # task IDs whose files_write overlap — dispatcher serializes these
files_write:                      # authoritative — dispatcher uses this for conflict detection
  - src/path/to/file.ts
files_read:                       # informational — context the agent will consult
  - src/path/to/other.ts
branch_suffix: stable-slug        # used when each task runs on its own branch or worktree
scope: S                          # XS | S | M | L  (L should be split before dispatch)
```

**Description:** One paragraph explaining what this task accomplishes.

**Acceptance criteria:**
- [ ] [Specific, testable condition]
- [ ] [Specific, testable condition]

**Verification:**
- [ ] Tests pass: `<project test command, scoped to this task>`
- [ ] Build succeeds: `<project build command>`
- [ ] Manual check: [description of what to verify]
```

## Why each field exists

**`id` — stable across edits.** Task IDs are referenced by `depends_on`, `conflicts_with`, and the execution DAG. Renumbering tasks breaks every reference. Use a short content-based slug (`T-auth-schema`, `T-register-flow`). If a task is dropped, retire its ID rather than reusing it.

**`depends_on` — partial order.** Task IDs that must finish *and verify* before this one dispatches. Empty list = ready on day zero.

**`parallel_safe` — runtime safety.** `false` if the task mutates shared state in a way concurrent siblings can't tolerate. See `parallelization-decisions.md`.

**`conflicts_with` — file-level mutual exclusion.** When two tasks both write the same file, list each in the other's `conflicts_with`. The dispatcher serializes them even if neither is in the other's `depends_on`. List both directions — dispatchers check one side only.

**`files_write` — authoritative, not advisory.** The dispatcher uses it to detect conflicts. Under-declare → parallel runs collide. Over-declare → false serialization.

**`files_read` — informational.** What the agent will consult. Used to scope context loading; not used for conflict detection.

**`branch_suffix` — isolation hint.** When the dispatcher runs each task on its own branch or worktree, this is the suffix appended to the parent branch name.

**`scope` — sizing.** XS / S / M dispatch fine. L should be split before dispatch. XL is malformed.

## Self-contained dispatch

Each task block must be readable on its own. A dispatcher should be able to copy one block into a fresh agent context — without the rest of the document — and the agent should have everything it needs: what to build, what files to touch, what success looks like, how to verify. If the block depends on context elsewhere in the document (architecture decisions, glossary), inline a one-line reference or pull the relevant fact into the block.

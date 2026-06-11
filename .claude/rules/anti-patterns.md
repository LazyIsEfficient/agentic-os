## Anti-patterns — do not do these

- Spawning agents that all edit the same files without `isolation: "worktree"`. They will stomp on each other.
- Skipping the shaper because "I know what I want." If you knew, the brief would already exist. Write it.
- Treating subagent summaries as ground truth without reading the diff.
- Writing memory for things derivable from the repo (file paths, conventions, architecture).
- Adding memory entries faster than removing stale ones. The index must stay clean.
- Sequential dispatch of independent work. Parallel or it's wasted wall-clock.
- Letting reviewer agents become optional. The gate is the gate — running the reviewer is mandatory; what its findings may do is governed by the tier rule (`review-tiers.md`): only Tier 0/1 evidence blocks, Tier 2 goes to the ledger.
- Letting agents reason about code state without reading the current files first.
- Accepting "based on the codebase" or "typically in this pattern" claims without knowing what the agent actually read. If you don't know what it read, it probably read nothing.

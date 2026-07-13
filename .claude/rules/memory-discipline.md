## Persistent memory — non-negotiable habits

**Memory for this repo lives at `.claude/memory/` (in-repo, gitignored).** This overrides the default global memory path described in the system prompt. Always read from and write to `.claude/memory/` when working in this repo — never `~/.claude/projects/.../memory/`. The index is `.claude/memory/MEMORY.md`. Treat memory as the long-term cache that lets future sessions start hot instead of cold.

Why in-repo: memory sits next to the work, is visible in the editor, and is gitignored so personal context stays local. It is not synced across machines or checkouts — each clone starts with an empty memory.

### Read memory at the start of every session
- Open `.claude/memory/MEMORY.md` first. Scan titles, then read any entry whose description plausibly touches the user's request.
- If memory references a file path, function, or flag that the user is about to act on, **verify it still exists** (`grep`, `ls`, or `Read`) before recommending. Memory is a frozen snapshot, not ground truth.
- If a memory contradicts what the code says now, trust the code and update or remove the stale memory.

### Write memory whenever you learn something durable
Save a fact iff **(a) decision-relevance** — a cold future session would act differently without it — **AND (b) non-derivability** — it can't be reconstructed from the repo, git history, or tools. Both clauses, every time; the examples below span the space, they don't bound it:

- **A correction or fact about the user** — `"don't do X"`, a confirmed preference, their role or mental model; lead with the rule, then `**Why:**` and `**How to apply:**`.
- **A project fact** — a decision, deadline, in-flight initiative, or who owns what; convert relative dates to absolute (`"Thursday"` → `"2026-05-14"`).
- **A pointer to an external system** — a Linear project, dashboard, or channel the repo never names.
- **A data representation** — e.g. timestamps stored as Unix epoch seconds, never a Date/ISO string; an enum's canonical values — facts that change how you read or write the data.

The primary capture point is the end-of-session extraction pass (the Stop hook nudges the `memory-extraction` skill), so durable facts get swept up at session close — don't interrupt task work to write mid-conversation unless losing the fact to an abrupt end would be costly.

### Do NOT write to memory
- Code patterns, file paths, architecture — derivable from the repo.
- Git history or who-changed-what — `git log` / `git blame` are authoritative.
- Debugging recipes — the fix is in the code; the commit message has the why.
- In-progress task state — that belongs in plans / todos, not memory.

If the user explicitly asks to "save" something on this list, push back and ask what was *surprising* about it — that's the part worth keeping.

### Memory file mechanics
- One memory per file under `.claude/memory/`, with frontmatter (`name`, `description`, `type`).
- One line per entry in `.claude/memory/MEMORY.md`: `- Title — one-line hook`. Under ~150 chars. No frontmatter on `MEMORY.md`.
- Update existing memories before creating new ones. Duplicates are a smell.
- After edits, the index must still be ≤ 200 lines or it gets truncated.

## Persistent memory — non-negotiable habits

**Memory for this repo lives at `.claude/memory/` (in-repo, gitignored).** This overrides the default global memory path described in the system prompt. Always read from and write to `.claude/memory/` when working in this repo — never `~/.claude/projects/.../memory/`. The index is `.claude/memory/MEMORY.md`. Treat memory as the long-term cache that lets future sessions start hot instead of cold.

Why in-repo: memory sits next to the work, is visible in the editor, and is gitignored so personal context stays local. It is not synced across machines or checkouts — each clone starts with an empty memory.

### Read memory at the start of every session
- Open `.claude/memory/MEMORY.md` first. Scan titles, then read any entry whose description plausibly touches the user's request.
- If memory references a file path, function, or flag that the user is about to act on, **verify it still exists** (`grep`, `ls`, or `Read`) before recommending. Memory is a frozen snapshot, not ground truth.
- If a memory contradicts what the code says now, trust the code and update or remove the stale memory.

### Write memory whenever you learn something durable
A non-obvious fact about the user, the project, or how to work — that a future session would otherwise have to relearn — must be saved before the conversation ends. Specifically:

- **Feedback memories** — every correction (`"don't do X"`, `"stop Xing"`) AND every quiet confirmation (`"yes that was right"`, accepting an unusual choice without pushback). Lead with the rule, then `**Why:**` and `**How to apply:**`.
- **Project memories** — decisions, deadlines, in-flight initiatives, who owns what. Convert relative dates to absolute (`"Thursday"` → `"2026-05-14"`).
- **User memories** — role, expertise, preferences, mental models the user already has.
- **Reference memories** — pointers to external systems (Linear projects, dashboards, channels).

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

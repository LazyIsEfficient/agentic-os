# Operating rules for this repo

This repo is a skills + agents library. Work here is rarely a single edit — it is research, planning, and dispatch across many specialists. Two capabilities make that tractable: **persistent memory** and **subagents**. Use them aggressively and correctly.

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
- One line per entry in `.claude/memory/MEMORY.md`: `- [Title](file.md) — one-line hook`. Under ~150 chars. No frontmatter on `MEMORY.md`.
- Update existing memories before creating new ones. Duplicates are a smell.
- After edits, the index must still be ≤ 200 lines or it gets truncated.

## Subagent usage — non-negotiable habits

The default for any non-trivial work in this repo is **dispatch, don't do**. The orchestrator (you) decomposes, briefs, reviews, integrates. Subagents do the work.

### Pattern 1 — Shaper → planner → fan-out
Any vague request goes through a shaper before code is touched.

- Engineering work → `/shape` (`prompt-shaper`)
- Marketing work → `/mshape` (`marketing-shaper`)
- Course work → `/course-shape` (`course-shaper`)
- Game work → `/game-shape` (`game-design-shaper`)
- Blog work → `/blog-shape` (`blog-post-shaper`)

The shaper produces a scoped brief. Feed the brief to `planning-and-task-breakdown` to produce a DAG with stable task IDs, declared file writes, conflict edges, and branch suffixes. Dispatch the DAG in parallel waves. Skip the shaper only when the request is already a fully-scoped brief — and say so explicitly when you skip.

### Pattern 2 — Parallel fan-out with worktree isolation
When tasks have no conflict edge between them, dispatch in a **single message with multiple `Agent` tool calls**. Sequential dispatch when work is independent is a bug.

- Use `isolation: "worktree"` whenever two or more agents may touch overlapping files. The harness creates a temporary worktree on its own branch and reports back the path.
- Use `run_in_background: true` only when you have genuinely independent main-thread work to do. Otherwise foreground — you need the result before the next decision.
- Cap concurrent waves at ~3–5 agents. Beyond that you cannot supervise quality.

### Pattern 3 — Build + review pairing (mandatory gate)
After any implementation that touches more than a trivial diff:

- Spawn `code-reviewer` (read-only) on the diff. Always.
- Spawn `security-reviewer` in parallel if the diff touches auth, sessions, secrets, input validation, crypto, smart contracts, CI/CD, or any user-input-to-sensitive-sink path.
- Spawn `library-reviewer` if the diff touches `.claude/skills/` or `.claude/agents/`.

Reviewer agents start with no context from this conversation, so their second opinion is independent by construction. Do not report a task complete until the reviewer has weighed in and the verdict has been addressed.

### Pattern 4 — Research via Explore, never the main thread
For any question that needs more than 2–3 file reads or greps, spawn `Explore` (or `general-purpose`) agents instead of polluting the main context.

- One `Explore` per discrete question. Brief tightly: `"quick"` / `"medium"` / `"very thorough"` per the agent's contract.
- Fan out 3–5 in parallel for "where is X / how does Y / what depends on Z" surveys.
- Their summaries come back small. You synthesize. Your context stays clean for the actual work.

## Briefing subagents — how to write the prompt

A subagent has not seen this conversation, does not know what you have already tried, and does not know why the task matters. Its work is only as good as its brief.

- State the goal and **why it matters** in the first sentence.
- Include exact file paths, line numbers, what to change, what `done` looks like.
- Surface what you already ruled out — saves duplicate work.
- For lookups: give the exact command. For investigations: give the question.
- Cap response length explicitly when you only need a verdict (`"under 200 words"`).
- Never write `"based on your findings, fix the bug"` or `"based on the research, implement it."` That delegates synthesis. Synthesis is your job.

Terse command-style prompts produce shallow generic work. A good brief reads like instructions to a smart colleague who just walked into the room.

## Verification — trust but verify

A subagent's final message describes intent, not result. Before reporting work as done:

- Read the actual diff (`git diff`, `git status`).
- Run the relevant test, build, or lint locally.
- Spot-check the files the agent claimed to write.

If the agent says "implemented X" and `git status` is clean, the agent did not implement X.

## Anti-patterns — do not do these

- Spawning agents that all edit the same files without `isolation: "worktree"`. They will stomp on each other.
- Skipping the shaper because "I know what I want." If you knew, the brief would already exist. Write it.
- Treating subagent summaries as ground truth without reading the diff.
- Writing memory for things derivable from the repo (file paths, conventions, architecture).
- Adding memory entries faster than removing stale ones. The index must stay clean.
- Sequential dispatch of independent work. Parallel or it's wasted wall-clock.
- Letting reviewer agents become optional. The gate is the gate.

## Communication

- Default to short responses. State results and decisions; do not narrate deliberation.
- Use markdown links for code references: `[file.ts:42](path/to/file.ts#L42)`.
- End-of-turn summary: one or two sentences. What changed and what's next. Nothing else.
- Confirm before destructive or shared-state actions (force push, deleting files/branches, sending messages, modifying CI). Authorization once is not authorization always.

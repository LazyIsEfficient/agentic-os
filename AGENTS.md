# Operating Rules for This Repo

This repo is a skills and agents library. It is meant to be installed into real work repos so Claude, Cursor, or Codex can load the same shared workflows.

The canonical skill source is `.claude/skills/`. Each skill is a directory with a required `SKILL.md` file and optional `references/`, `assets/`, and `scripts/` folders.

Codex reads `AGENTS.md` as project guidance. Treat this file as the Codex equivalent of the durable operating guidance in `CLAUDE.md`, adjusted for Codex behavior.

## Persistent Project Memory

For Codex, durable repo guidance lives in `AGENTS.md` files:

- `~/.codex/AGENTS.md` for user-level preferences across repos.
- `AGENTS.md` at the repo root for project-wide rules.
- More specific `AGENTS.md` files in subdirectories when a subtree needs different guidance.

Do not use `.claude/memory/` as Codex memory. That path is Claude-specific.

### Read Memory at the Start of Every Session

- Read the nearest applicable `AGENTS.md` before doing work.
- For this repo, read the root `AGENTS.md` before editing skills, agents, docs, or scripts.
- If a memory rule references a file, command, or workflow, verify it still exists before relying on it.
- If memory contradicts the current repo contents, trust the repo and update the stale guidance.

### Write Memory When You Learn Something Durable

Update `AGENTS.md` only for non-obvious facts that future Codex sessions would otherwise have to relearn.

Good candidates:

- Team workflow rules.
- Cross-agent compatibility decisions.
- Skill authoring conventions.
- Review expectations.
- Durable user corrections about how this repo should be maintained.

When adding memory:

- State the rule directly.
- Include the reason if it affects future decisions.
- Keep it concise.
- Update an existing rule instead of adding a duplicate.

### Do Not Write to Memory

Do not add these to `AGENTS.md`:

- In-progress task state.
- Git history or who changed what.
- File paths or repo structure that are obvious from the tree.
- Debugging notes already reflected in code or docs.
- One-off command output.
- User-specific preferences that belong in `~/.codex/AGENTS.md`.

If the user asks to save something in these categories, clarify what durable rule or surprising lesson should be preserved.

## Skill Usage

Before applying a skill:

- Read that skill's `SKILL.md`.
- Load referenced `references/`, `assets/`, or `scripts/` only when needed.
- Follow the skill's procedure unless it conflicts with higher-priority user or system instructions.
- Interpret Claude-specific tool names by intent:
  - `AskUserQuestion` means ask the user a concise clarifying question.
  - `Agent` or subagent dispatch means use Codex subagents only when available, appropriate, and allowed.
  - Slash commands such as `/shape`, `/mshape`, `/course-shape`, `/game-shape`, and `/blog-shape` are invocation conventions; natural language can trigger the same workflow.

## Skill Authoring

- Preserve YAML frontmatter with `name` and `description`.
- Folder names must match the skill `name`.
- Keep `SKILL.md` short and procedural.
- Put long-form background in `references/`.
- Put templates in `assets/`.
- Put runnable helpers in `scripts/`.
- Prefer editing the canonical `.claude/skills/` source.
- Do not create separate Codex-specific copies of skills inside this repo unless the user explicitly asks for a forked skill.

## Shaper Workflow

Use shapers for vague requests before execution:

- Engineering work: `prompt-shaper`
- Marketing work: `marketing-shaper`
- Course work: `course-shaper`
- Game work: `game-design-shaper`
- Blog work: `blog-post-shaper`

A shaper turns a rough request into a scoped brief. It does not implement the work.

Skip the shaper when:

- The task is already scoped.
- The user explicitly asks to execute directly.
- The work is exploratory discussion, not a deliverable.

## Planning and Dispatch

For multi-step work:

- Decompose the work before editing.
- Keep tasks small, ordered, and verifiable.
- Identify which files each task may touch.
- Avoid parallel edits to the same files.
- Use subagents only when the active Codex environment supports them and the user has allowed delegation.

For simple work:

- Make the change directly.
- Keep edits scoped.
- Avoid unrelated refactors.

## Review and Verification

Before reporting work as done:

- Read the final diff.
- Run the relevant syntax check, test, build, or dry run when available.
- Verify generated or copied files actually exist.
- Explain any skipped verification.

For skill changes:

- Confirm frontmatter remains valid.
- Check referenced paths.
- Run helper scripts if they changed.

For docs changes:

- Confirm commands and paths match the current repo.
- Avoid documenting behavior that has not been implemented.

## Communication

- Be concise and factual.
- State assumptions when they matter.
- Surface inconsistencies instead of guessing silently.
- Report what changed and how it was verified.
- Do not claim Claude, Cursor, or Codex compatibility unless it is implemented or documented.

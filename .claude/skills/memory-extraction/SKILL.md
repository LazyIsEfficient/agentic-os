---
name: memory-extraction
description: End-of-session pass that persists durable facts from the CURRENT session into .claude/memory/. Runs IN-SESSION in the main agent (never via Task — a subagent starts cold with no transcript), prompted by the Stop hook's nudge. Triggers on "persist durable facts from this session", "run memory-extraction", "flush session memory", or "extract memory before close". Reads the in-context transcript plus existing memory, applies the durable-fact predicate below, and writes one file per fact plus one MEMORY.md index line — append-or-update, never clobbering a consumer's existing memory.
when_to_use: At session close, when the Stop hook emits its nudge (or the user asks to flush/persist session memory). The invoking agent MUST hold the current session transcript in context, so this runs in-session and is never dispatched as a Task/subagent. Not for reading memory at session start (that is the session-state inject hook) and not for retrieval — this skill only extracts durable facts and writes them.
compatibility: Pure prose skill — no scripts, no interpreter. Reads/writes plain Markdown under .claude/memory/. Works in Claude Code and Cursor.
---

# Memory extraction

This skill is the reliable-encoding pass: at the end of a session it reads what
just happened and writes the durable facts to `.claude/memory/` so the NEXT cold
session starts hot instead of relearning them. It replaces best-effort
in-conversation self-classification with a deterministically-triggered flush.

It is **self-contained**: the durable-fact predicate and the memory-file
mechanics are inlined below. It does NOT depend on `.claude/rules/` or
`CLAUDE.md` — those are not installed on consumer machines, so nothing in this
skill may assume they exist.

## Invocation contract

- **Run in-session, in the main agent.** The only input is the current session
  transcript, which already sits in the invoking agent's context. There is no
  argument passing.
- **NEVER dispatch this as a `Task`/subagent.** A subagent starts cold with none
  of the parent's transcript — it literally cannot see the session it is meant to
  extract. If you reach for `Task(subagent_type=…)` here, stop: run the skill
  inline instead.
- **Trigger.** The Stop hook nudges the still-live agent with text like "run the
  memory-extraction skill / persist durable facts from this session". A user may
  also invoke it directly ("flush session memory"). Either way, execute the
  procedure below as your final act of the turn.

## The durable-fact predicate — the only rule

Do not work from a category checklist (checklists silently gap on fact-types
nobody enumerated). Work from this predicate, applied to every candidate fact:

> **Save a fact iff (a) a cold future session would act differently without it,
> AND (b) it can't be reconstructed from the repo, git history, or tools.**

Both clauses must hold. (a) is decision-relevance; (b) is non-derivability. A
fact that fails either clause is noise — dropping it keeps memory lean.

The categories below are **illustrations of the predicate, not a whitelist** —
they exist only to show it firing across the axes the model tends to drop
(procedural vs representational, about-you vs about-the-data-and-project):

| Axis | SAVE — passes (a) AND (b) | `metadata.type` |
|---|---|---|
| **Procedural** (how to work here) | "CI runs `validate-test.sh` (meta-test with hardcoded fixtures), not `validate.sh` — run it locally before pushing validator changes." A cold session would run the wrong script (a); the convention is not stated in any single obvious file (b). | `project` |
| **Data-format / representation** | "`agent()` StructuredOutput schemas 400 on a top-level `allOf`/`oneOf`/`anyOf` and fail silently as empty results — nest under `properties`." A cold session would author a broken schema (a); you only learn it by hitting the failure, not by reading the repo (b). | `project` |
| **User** (about the person) | "Glenn's stack directive: never Python — Rust only, stated as an absolute." Changes what language you scaffold (a); not derivable from any repo file (b). | `user` |
| **Project** (decision / in-flight) | "North star = `NORTH_STAR.md`: token-efficiency + long-horizon awareness; re-bases pruning on token-tax." Steers design tradeoffs (a); the *decision and its rationale* live in a person's head, not reconstructable from code alone (b). | `project` |
| **Feedback** (a correction, lead with the rule) | "Never design CI to commit/push back to its own repo — the user calls it a disaster; export an artifact and let a human harvest instead." Kills an entire class of proposal (a); a preference, not a repo fact (b). | `feedback` |

**Do NOT save** (fails clause (b) — derivable, so re-deriving is cheaper than the
token tax of carrying it):

- Code patterns, file paths, function names, architecture — `grep`/`ls`/`Read`
  recover these on demand.
- Who changed what, or when — `git log` / `git blame` are authoritative.
- Debugging recipes — the fix is in the code; the *why* is in the commit message.
- In-progress task state / next steps — that belongs in `SESSION-STATE.md` or a
  todo list, not cross-session memory.

If the user explicitly asks to "save" something on the do-not-save list, push
back and ask what was *surprising* about it — the surprise is the part that
passes the predicate.

## Procedure

1. **Load current memory.** Read `${CLAUDE_PROJECT_DIR:-.}/.claude/memory/MEMORY.md`
   (the index) and the existing `${CLAUDE_PROJECT_DIR:-.}/.claude/memory/*.md`
   entry files. On Cursor the project dir is `${CURSOR_PROJECT_DIR:-.}` — resolve
   it the same way the session-state hooks do:
   `${CURSOR_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-.}}`. You need the existing set so
   you can dedup and never duplicate.
2. **Scan the transcript for candidate facts.** Walk the session for anything the
   user stated, corrected, decided, or you discovered.
3. **Apply the predicate to each candidate.** Keep only facts that pass BOTH
   clauses (a) and (b). Discard the rest silently.
4. **Dedup before writing** (see Write semantics). Match each surviving fact
   against existing entries by *subject*, not exact wording.
5. **Write / update** one entry per surviving fact, in the on-disk format below.
6. **Update the index** — one line per new entry; edit the existing line in place
   for an update. Keep it ≤ 200 lines.
7. **Refresh the completion marker** (see below) as your final step, so the Stop
   hook stops nudging this session.

If no candidate passes the predicate, write nothing to memory — but STILL refresh
the completion marker (step 7), so the hook doesn't nudge again this epoch.

## Memory-file format — match the on-disk shape exactly

Read a couple of existing entry files first and mirror them. The conventions:

- **Entry filename:** `snake_case.md` (underscores), e.g. `no_python_use_rust.md`.
  Pick a short, subject-descriptive slug.
- **Frontmatter** — three keys, and `type` is **nested under `metadata:`** (this
  is the real on-disk shape; a top-level `type:` is wrong):

  ```
  ---
  name: no-python-use-rust
  description: One line — the fact and, for a user/feedback fact, whose it is.
  metadata:
    type: feedback
  ---
  ```

  - `name:` is **kebab-case** (hyphens) — the same words as the filename with
    underscores swapped for hyphens.
  - `metadata.type` ∈ `user` | `feedback` | `project` | `reference`.
- **Body conventions:**
  - A **feedback** entry leads with the rule/directive (quote the correction
    verbatim when you have it), then a `**Why:**` line and a `**How to apply:**`
    line.
  - A **project**/**user** entry states the fact and why it matters; add
    `**How to apply:**` when there's a concrete action.
  - Convert relative dates to absolute (`"Thursday"` → `2026-07-13`).
  - Cross-reference sibling entries with wikilinks: `[[other_slug]]` (the
    snake_case filename, no extension). A wikilink must resolve to a real sibling
    `other_slug.md` — do not invent one.
- **Index line** in `MEMORY.md` — one Markdown list item, mirroring the exact
  style of the lines you already loaded in step 1. Its parts, in order:
  1. `- ` (dash + space),
  2. the **Title Case** title as Markdown link text in square brackets,
  3. immediately followed by the **snake_case filename** as the Markdown link
     target in parentheses (e.g. filename `no_python_use_rust.md`),
  4. ` — ` (space, em-dash, space),
  5. a one-line hook, ≤ ~150 chars.

  So it reads `- [<Title>](<snake_filename>) — <hook>`, identical in form to the
  existing index lines. The link text is Title Case; the link target is the
  snake_case filename (the kebab-case `name:` field is NOT used in the index).

## Write semantics — append-or-update, never clobber

The consumer's memory is precious and pre-existing. These rules are absolute:

- **Update in place, don't duplicate.** If a surviving fact matches an existing
  entry's subject, edit THAT file — revise the line, or append a dated
  reconfirmation (e.g. `Reconfirmed 2026-07-13: …`), as several existing entries
  do. Do not create a second file for the same subject.
- **Never clobber an unrelated memory.** Only touch the specific entry file(s)
  for the fact(s) you are writing, plus `MEMORY.md`. Never rewrite, reorder, or
  delete entries you did not author this run.
- **Edit `MEMORY.md` surgically.** Append exactly one index line per NEW entry;
  replace exactly the one line for an UPDATED entry. Preserve every other line
  and the header comment untouched.
- **Keep the index ≤ 200 lines.** If adding a line would exceed 200, first prune
  a genuinely stale entry or merge two overlapping ones — do not blow past the
  cap (the index is truncated from context beyond it, and `validate.sh` fails a
  `MEMORY.md` over 200 lines).
- **Non-destructive on consumer machines.** Treat any memory you did not write
  this session as read-mostly: add or update your own entries, never remove a
  user's. When in doubt, add rather than overwrite.

## Completion marker — loop-safety signal for the Stop hook

Because Stop fires every turn, the hook must know extraction already ran this
session so it stops nudging. After writing (step 7), refresh a per-session
marker that the hook reads:

- **Directory:** `${CLAUDE_PROJECT_DIR:-.}/.claude/memory/.extract/` (a dot-dir
  under memory; create it if absent). Use the same project-dir resolution as
  above on Cursor.
- **Filename:** the session identifier — `session_id` (Claude) / `conversation_id`
  (Cursor). The agent does not read the hook's stdin, so the Stop hook passes this
  id (and the exact marker path) into its nudge text; write the marker at the
  path the nudge gives you. If the nudge supplies no id, fall back to
  `.extract/last` so the mechanism still self-limits.
- **Contents:** a single line — an ISO-8601 UTC timestamp and the count of facts
  written this run, e.g. `2026-07-13T18:04:00Z facts=2`. Presence + recency is
  the signal; the count is for debugging.

The Stop hook (task P2b) owns the matching read: when `.extract/<id>` exists for
the current epoch it emits `{}`/allow and stops nudging; otherwise it nudges.
This skill's only obligation is to write/refresh the marker as its last action.

## Scope boundaries

This skill ONLY extracts durable facts from the just-ended session and writes
them. It does not read memory at session start (the session-state inject hook
does that) and it does not do retrieval or consolidation. Single responsibility:
extract-and-write, then signal done.

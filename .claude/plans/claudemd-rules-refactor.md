# Plan 2 — CLAUDE.md → modular rules/ (internal refactor, NOT a shipped feature)

**Status:** proposed — spike-gated, low priority
**Author:** orchestration session, 2026-06-08 (split from `claude-feature-expansion.md`)
**Scope:** split this repo's `CLAUDE.md` doctrine into `.claude/rules/*.md`, imported via `@`. Internal maintainability only — ships nothing to users.

> Split rationale: the original plan filed this under "surfaces wired for distribution," but [install.sh](../../install.sh#L91-L93) never copies `CLAUDE.md` or `rules/`. This change reaches no consumer. It is a refactor of *this repo's operating doctrine* and carries the highest blast radius in the original plan — it touches the single most load-bearing file. Kept separate so it can't be rushed in a parallel wave alongside low-risk command work.

## Why this is risky

- `CLAUDE.md` is the doctrine every session reads first. There are **two copies** that matter: the in-repo project [CLAUDE.md](../../CLAUDE.md) and the global `~/.claude/CLAUDE.md`. A broken `@import` silently guts the doctrine — sessions start cold with no error.
- The original plan said content is **"moved (not duplicated)."** Moving first means a failed import = lost doctrine with no fallback. **Reject move-first.** Use duplicate-then-delete: the import must be proven to resolve *before* the source paragraphs are removed.
- `@import` resolution semantics may differ between the repo-root project file and the installed global file. This is the load-bearing unknown.

## Spike (go/no-go gate — do this first, alone)

1. Create one file, `.claude/rules/communication.md`, containing only the Communication section copied (not moved) from `CLAUDE.md`.
2. Add `@.claude/rules/communication.md` to `CLAUDE.md` while **leaving the original Communication text in place** (duplicated on purpose).
3. Start a fresh session at the repo root. Confirm the imported content loads (the section should appear twice — once inline, once via import — proving the import resolved).
4. Repeat the resolution check from a simulated installed location (`~/.claude/CLAUDE.md` importing `~/.claude/rules/...`), since import paths resolve relative to the importing file.

**Go:** both locations resolve → proceed to the full split (duplicate-then-delete each section). **No-go:** keep `CLAUDE.md` monolithic; treat any `rules/` files as documentation copies only, never as the source of truth.

## Full split (only if spike passes)

| File | Sourced from CLAUDE.md section |
|---|---|
| `rules/memory-discipline.md` | Persistent memory (read/write/do-not/mechanics) |
| `rules/subagent-dispatch.md` | Subagent usage Patterns 1–4 |
| `rules/briefing.md` | Briefing subagents |
| `rules/grounding.md` | Grounding discipline — read before claiming |
| `rules/verification.md` | Verification — trust but verify |
| `rules/anti-patterns.md` | Anti-patterns |
| `rules/communication.md` | Communication |

**Mechanics:** for each section — (a) copy to its `rules/` file, (b) add the `@import`, (c) verify it resolves in a fresh session, (d) *only then* delete the inline copy. One section at a time; never batch the deletes. Keep `CLAUDE.md` as a short preamble + the import list so a cold read still surfaces the structure.

## Distribution decision (explicit)

**Do NOT wire `rules/` into the installer.** Installing this repo's orchestration doctrine into a consumer's global `~/.claude/rules/` would inject maintainer doctrine where it can collide with the consumer's own `CLAUDE.md`. This refactor is for this repo's editing ergonomics only. If a future need arises to *distribute* doctrine, that is a separate plan with its own audience analysis.

## Review gate

- `code-reviewer` on the `CLAUDE.md` + `rules/` diff (doctrine is load-bearing; treat like code).
- No `library-reviewer` (not skills/agents). No installer/README changes (nothing ships).

## Success criteria

- A fresh repo-root session loads all seven imported sections (verified by content presence, not by absence of error).
- `CLAUDE.md` line count drops to preamble + import list; total doctrine content is unchanged (diff the rendered/loaded result, not the file).
- No section exists in two places after completion (every duplicate-then-delete finished).

## Open decision

- Proceed past the spike at all? This is admitted-low-value internal tidying. If the spike is even mildly flaky, the correct call is **leave `CLAUDE.md` monolithic** and close this plan.

# Tool Allowlists

The `tools:` field is an allowlist. Omit to inherit. List explicitly to restrict.

## Role-to-allowlist map

| Role | Allowlist | Rationale |
|---|---|---|
| **Build / implement** | (omit — inherit) | Needs full toolset for the diversity of tasks |
| **Read-only reviewer** | `Read, Grep, Glob, Bash, WebFetch, WebSearch` | No `Edit` / `Write` / `NotebookEdit`; matches the built-in Explore agent |
| **Intake / shaper** | `Read, Grep, Glob, Bash, WebFetch, WebSearch, AskUserQuestion` | Adds `AskUserQuestion`; excludes `Agent` (no nested spawn), `Edit` / `Write` (intake-only) |
| **Authoring (e.g., course-author)** | reviewer set + `Edit, Write, AskUserQuestion` | Genuine writing role; still no nested `Agent` |
| **Orchestrator** | inherit, including `Agent` | Coordinates sub-agents — needs spawn permission |

## `Bash` is a soft-write vector

`Bash` can edit files, push to git, delete data — anything the shell can. Including it in a "read-only" allowlist relies on the agent's *system prompt* to enforce read-only intent, not the tool boundary itself.

This is the same trade-off the built-in Explore agent makes (it has Bash). It's defensible because:
- Most read-only review needs `git diff`, `git log`, `find`, `grep`, etc.
- Agents are well-aligned to follow system-prompt instructions
- The alternative (no Bash) cripples real review work

But: do not market a Bash-enabled agent as a hard read-only guardrail. It is a *posture*, not a *barrier*. If a hard barrier is required, drop `Bash` and accept the cost.

## `Agent` tool inclusion

Including `Agent` means the agent can spawn sub-agents. This is appropriate for orchestrators but a footgun for:
- **Reviewers** — review should be one coherent verdict, not a tree of sub-reviews. Nested delegation also fragments responsibility for the verdict.
- **Shapers / intake** — intake should converge on a brief, not branch into delegation. A shaper that delegates loses the conversation thread.
- **Single-deliverable specialists** — anything where the deliverable is one document/report. Spawning sub-agents rarely improves quality and always increases latency.

Default for non-orchestrator agents: omit `Agent` from the allowlist.

## Inheritance vs explicit allowlist

**Inherit (omit `tools:`)**:
- Simpler, fewer maintenance points
- Agent gains new tools automatically as the harness adds them
- Right for build / implementation agents

**Explicit allowlist**:
- Hard guardrail for restricted roles
- Protects against drift if a tool gets added that shouldn't apply
- Right for reviewers, intake, authoring, gated specialists

Rule of thumb: explicit allowlist when the role's identity is *what it can't do*; inherit when the role's identity is *what it does*.

## Common allowlist errors (in severity order)

**Blocking**
- Read-only reviewer with `Edit`, `Write`, or `NotebookEdit` — direct contradiction with declared role
- Frontmatter `tools:` is malformed YAML

**Should-fix**
- Intake agent with `Agent` — allows nested delegation, breaks intake convergence
- Build agent with overly restrictive allowlist — cripples it for marginal benefit
- Reviewer that needs `git diff` but `Bash` is excluded — review can't actually run

**Nit**
- Allowlist names a tool that doesn't exist — silent ignore by some loaders; also a maintenance hazard. Verify against the current Claude Code tool list.
- Allowlist orders tools randomly — convention is to list read tools first, then write tools, then specialty tools (`AskUserQuestion`, etc.)

## Quick verification

Given an agent file, check:

1. Does the role description say "read-only", "review", "audit", "verdict"? → `tools` should exclude `Edit`, `Write`, `NotebookEdit`.
2. Does the description say "intake", "shape", "scope a brief"? → `tools` should also exclude `Agent`, `Edit`, `Write`, `NotebookEdit`.
3. Does the description say "implement", "build", "ship"? → `tools` should usually be inherited (omitted).
4. Is `Bash` present? → confirm the role genuinely needs shell access; otherwise drop it.
5. Is `Agent` present? → confirm this is an orchestrator; otherwise drop it.

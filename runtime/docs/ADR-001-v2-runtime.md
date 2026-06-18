# ADR-001: v2 Runtime — Redis-mediated, orchestrator-clocked agent collaboration

**Status:** proposed (awaiting human approval — this is the `ADR-approved` checkpoint)
**Date:** 2026-06-17
**Context plan:** [.claude/plans/v2-runtime-plan.md](../../.claude/plans/v2-runtime-plan.md)

## Context
v2 is a runtime where a pod of Claude Code agents (PM + engineer + library-reviewer)
collaborates across fast iterative rounds, coordinated through a Redis blackboard,
to author a library skill that passes `scripts/validate.sh`. Hard constraints
(locked upstream): agents run inside Claude Code on the **subscription — no
external/metered API**; Redis is a **durable blackboard, not a live bus**; live
token streaming is impossible (sealed, completion-based subagents); **all implementation
is Rust — no Python, no exceptions** (hard directive). This ADR resolves the one
load-bearing question that gates all runtime code: **who talks to Redis, and how are
agent turns executed.**

### Grounded facts (verified 2026-06-17, this environment)
- The `Workflow` tool's JS sandbox has **no filesystem or network access** and
  forbids `Date.now`/`Math.random`. A Workflow script therefore **cannot read or
  write Redis** itself.
- The headless `claude` CLI is present (`v2.1.168`, `~/.local/bin/claude`) and
  supports non-interactive `-p/--print`. It runs on the **subscription** — no API
  key, no metered billing.
- `redis-cli` is on the host (`/opt/homebrew/bin/redis-cli`); `redis:7` will be
  supplied via `runtime/docker-compose.yml` (T-infra).
- Rust toolchain present: `rustc`/`cargo 1.96.0` at `~/.cargo/bin`. Dependency fetch
  (sparse index) confirmed at first `cargo build` (T-scaffold-crate).

## Decision
**Mechanism (b): an external Rust orchestrator owns Redis and the round loop, and
executes each agent turn by shelling out to the headless `claude -p` CLI.**

- The orchestrator (`runtime/src/main.rs` + `runtime/src/rounds.rs`) is a normal Rust
  process. It holds the round loop, reads/writes the Redis blackboard via the `redis`
  crate, evaluates the done signal, and enforces re-dispatch.
- Each agent turn = one `claude -p` invocation. The orchestrator builds the prompt
  (persona system text + a snapshot of the blackboard + a role-specific instruction),
  runs it headless, and parses the agent's structured contribution from stdout.
- **Agents never touch Redis.** They are pure: blackboard snapshot in (via prompt),
  structured contribution out (via stdout). The orchestrator mediates *all*
  blackboard I/O. Redis is the orchestrator's durable cross-round / cross-crash
  memory — exactly "blackboard, not bus."

### Why (b) over (a)
**(a) Workflow-tool script clocking rounds + agents reading Redis via `Bash`+`redis-cli`.**
Rejected because the Workflow sandbox can't see Redis, so the script cannot read the
done signal or enforce re-dispatch from durable state — it would have to round-trip
all coordination through `agent()` return values, duplicating the blackboard in two
places and weakening the durability guarantee. It also couples every agent to a
`redis-cli`/`docker exec` side effect, breaking the "agents are sealed/pure" property.
(b) keeps Redis ownership in one place, makes the loop fully resumable, and matches
the stated preference for maximum control and Redis-native state. The only thing (b)
gives up is the Workflow tool's built-in progress UI — acceptable for a PoC.

## Blackboard schema (Redis)
Key prefix from `.env` (`BB_PREFIX`, default `bb`), namespaced per run:

| Key | Type | Purpose / lifecycle |
|---|---|---|
| `{prefix}:{run}:state` | HASH | `task_id`, `status` (running\|done\|failed), `round`, `max_rounds`, `done` (0\|1). Orchestrator-owned. |
| `{prefix}:{run}:artifact` | HASH | The shared work product being iterated — `filename → content` (e.g. `SKILL.md → …`). Mutated each round. |
| `{prefix}:{run}:log` | STREAM | Append-only audit/replay of every contribution: fields `{round, role, kind, payload}`. Durable transcript = the demo evidence. |
| `{prefix}:{run}:votes:{round}` | HASH | `role → approve(0\|1)` for the round's done evaluation. |

Durability: `redis:7` with a named volume (AOF or RDB — set in compose). A crashed
orchestrator re-attaches to `{run}` and reads `state.round` + `artifact` to resume;
no work is lost because nothing lives only in orchestrator memory.

## Round protocol
1. **Init:** orchestrator writes `state` (round=0, status=running, max_rounds from
   `.env`), seeds `artifact` with the task scaffold, appends a `task` entry to `log`.
2. **Each round (ordered):** PM → engineer → library-reviewer. For each participant
   the orchestrator: (i) builds prompt = persona + current `artifact` snapshot +
   tail of `log` + role instruction; (ii) runs `claude -p`; (iii) parses the
   structured contribution `{artifact_edits, note, approve}`; (iv) applies edits to
   `artifact`, appends to `log`, records `approve` in `votes:{round}`.
3. **Done signal:** round ends the run when the **library-reviewer returns
   `approve=1`** AND the artifact passes a cheap shape check, **or** `round ==
   max_rounds`. Final gate is `scripts/validate.sh` in T-dogfood (the deterministic
   arbiter); reviewer approval is the in-loop heuristic.
4. **Advance:** increment `state.round`; loop.

## Fault-tolerant re-dispatch
A participant turn is a **failure** if `claude -p` exits non-zero, times out, or
returns output that doesn't parse into the contribution schema. On failure the
orchestrator retries the *same* participant on the *same* blackboard snapshot up to
`BB_MAX_RETRIES` (default 2). Because the snapshot is read fresh from Redis, retry
is correct after an orchestrator crash too. Exhausting retries marks
`state.status=failed` and halts with the partial transcript intact.

## Language & layout (confirms plan paths)
- **Rust** (Cargo lib+bin crate). Redis via the `redis` crate; `serde`/`serde_json`
  for the contribution schema; `std::process::Command` to spawn `claude -p`;
  `cargo test` for tests. No Python anywhere.
- `runtime/` is a Cargo crate: `Cargo.toml`, `src/lib.rs` (declares `pub mod
  blackboard; pub mod personas; pub mod rounds;`), `src/blackboard.rs`,
  `src/personas.rs`, `src/rounds.rs` (round loop + the `claude -p` agent-exec
  adapter), `src/main.rs` (thin CLI bin → `rounds::run`), `tests/`, plus infra
  (`docker-compose.yml`, `.env.example`, `setup.sh`, `.gitignore`). The dogfood
  task ships as `tasks/author-skill.md` + `run-dogfood.sh`.

## Consequences
- **bb_cli refinement:** the shell-callable Redis inspector is **demoted to an
  optional debug subcommand of the `runtime` binary** (`runtime inspect <run>`), NOT
  an agent interface — agents never touch Redis; the orchestrator owns it. The typed
  read/write API in `src/blackboard.rs` is what `rounds.rs`/`main.rs` consume.
- **Contribution schema is a hard interface** (`serde` struct) between `rounds.rs`
  and the agent prompts: `{ artifact_edits: Map<String,String>, note: String,
  approve: bool }`. The orchestrator instructs each `claude -p` agent to emit exactly
  this as JSON on stdout, and deserializes it.
- **No external API surface** anywhere — billing stays on the subscription via
  `claude -p`.
- **Resumability is free** because all state is in Redis; the driver's resume path
  is just "re-attach to `{run}`."
- Loses the Workflow tool's progress UI; the `log` STREAM is the substitute (and the
  demo evidence artifact).

## Open items folded shut by this ADR
- ✅ Redis-access mechanism → (b) external orchestrator.
- ✅ Driver language/mechanism → Rust orchestrator + `claude -p` headless.
- ✅ Blackboard schema, round protocol, re-dispatch policy → specified above.
- ✅ Downstream file paths → confirmed (only the `bb_cli` inspector's role changed).

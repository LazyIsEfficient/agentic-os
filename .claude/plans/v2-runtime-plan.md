# Implementation Plan: v2 Real-Time Multi-Agent Collaboration Runtime

**Status:** in-progress   <!-- lifecycle: proposed → in-progress → shipped | superseded -->

## Overview
Build "v2" on the `v2` branch (created off `main` at v1.3.0): a runtime where a pod
of Claude Code agents (PM + engineer + library-reviewer) collaborates across **fast
iterative rounds**, coordinated through a **Redis blackboard**, to author one library
skill that passes `scripts/validate.sh`. Agents run INSIDE Claude Code via the
headless `claude -p` CLI (no external/metered API). Redis is a **durable blackboard**
(shared state, replay, fault-tolerant re-dispatch) — NOT a live message bus. Live
token streaming is permanently out (sealed, completion-based subagents). **All code
is Rust — no Python.** Runtime lives under a new top-level `runtime/` Cargo crate;
existing `.claude/` content is read, never modified. Mechanism is fixed by
[ADR-001](../../runtime/docs/ADR-001-v2-runtime.md): a Rust orchestrator owns Redis +
the round loop and spawns each agent turn via `claude -p`; agents never touch Redis.

## Architecture Decisions
- Per **ADR-001**: external **Rust orchestrator** owns Redis (`redis` crate) and the
  round loop; each agent turn is one `claude -p` subprocess; agents are pure
  (blackboard snapshot in via prompt, structured `serde` contribution out via stdout).
- Orchestrator-clocked rounds, message/tool-cycle granularity — not peer streaming.
- Personas reused read-only from `.claude/agents/*.md`; library formats untouched.
- Done is deterministic: `scripts/validate.sh` on the emitted skill is the arbiter.
- **Retired ID:** `T-scaffold-infra` (from the pre-Rust draft) is split into
  `T-scaffold-crate` + `T-infra`. The ID is retired, not reused.

## Execution DAG

```yaml
dag:
  - T-adr
  - checkpoint: ADR-approved after [T-adr]          # human approval — hard gate
  - T-adr → T-scaffold-crate, T-infra
  - T-scaffold-crate || T-infra                      # different files, parallel-safe
  - T-scaffold-crate → T-personas
  - T-scaffold-crate, T-infra → T-blackboard
  - T-blackboard || T-personas                       # blackboard.rs vs personas.rs
  - T-blackboard, T-personas → T-protocol
  - T-protocol → T-driver, T-tests
  - T-driver || T-tests                               # main.rs vs tests/, parallel-safe
  - T-driver → T-dogfood
  - checkpoint: Demo-green after [T-dogfood, T-tests]
```

## Task List (presentational)

### Phase 1: Design gate
- [x] T-adr  *(approved)*

### Checkpoint: ADR-approved (human approval required — stops the line)
- [x] Mechanism, blackboard schema, round protocol, re-dispatch, Rust layout pinned
- [x] Human has approved ADR-001

### Phase 2: Foundation
- [x] T-scaffold-crate
- [x] T-infra
- [x] T-blackboard
- [x] T-personas

### Phase 3: Collaboration core
- [x] T-protocol  *(+ review fix: resume wired into run(), turn timeout)*
- [x] T-driver  *(bounded smoke: 3 real `claude -p` turns ran end-to-end)*
- [x] T-tests

### Phase 4: Dogfood proof
- [x] T-dogfood — **plumbing built + path-traversal gate (8 sanitizer tests)**
- [x] T-dogfood — **EXECUTION green** (run `dogfood-1781756986`: pod authored `commit-message-conventions` SKILL.md, reviewer-approved at round 1)
- [x] Fix: task-injection bug — `run()` dropped the task; now threaded into every prompt + persisted (regression test added)

### Checkpoint: Demo-green ✅ MET
- [x] `bash runtime/run-dogfood.sh` ran the pod; emitted skill passes `scripts/validate.sh` ("OK — all invariants pass", independently re-verified)
- [x] Blackboard transcript captured; `cargo test` green (39/39)
- [ ] Remaining: commit the `v2` branch (all runtime/ currently untracked)

## Task Details

### Task: Architecture Decision Record (design gate)
```yaml
id: T-adr
depends_on: []
parallel_safe: true
conflicts_with: []
files_write:
  - runtime/docs/ADR-001-v2-runtime.md
files_read:
  - .claude/agents/technical-pm.md
  - .claude/agents/engineer.md
  - .claude/agents/library-reviewer.md
  - scripts/validate.sh
branch_suffix: adr
scope: M
```
**Description:** Decision record unblocking all runtime code (see file). Resolves the
Redis-access mechanism, blackboard schema, round protocol, re-dispatch policy, and
Rust layout. **Status: written; pending human approval (this checkpoint).**
**Acceptance criteria:**
- [ ] Mechanism chosen with rationale + rejected option named *(done: mechanism b)*
- [ ] Blackboard schema, round protocol, re-dispatch specified *(done)*
- [ ] Rust layout pinned; downstream paths confirmed *(done)*
**Verification:**
- [ ] Human approval recorded (the ADR-approved checkpoint)

### Task: Cargo crate scaffold (barrel + stubs)
```yaml
id: T-scaffold-crate
depends_on: [T-adr]
parallel_safe: true
conflicts_with: [T-blackboard, T-personas, T-protocol]
files_write:
  - runtime/Cargo.toml
  - runtime/src/lib.rs
  - runtime/src/blackboard.rs
  - runtime/src/personas.rs
  - runtime/src/rounds.rs
files_read:
  - runtime/docs/ADR-001-v2-runtime.md
branch_suffix: scaffold-crate
scope: S
```
**Description:** Lay down the Cargo lib+bin crate skeleton. `Cargo.toml` pins deps
(`redis`, `serde`, `serde_json`, plus a test dep as needed). `src/lib.rs` declares
`pub mod blackboard; pub mod personas; pub mod rounds;`. The three module files are
created as compiling **stubs** (type signatures / `todo!()` bodies) so the barrel
builds before the fillers run. This is the barrel-file owner; downstream tasks fill
their own module file and never touch `lib.rs` (hence the conflict edges on the
stub files, which the dependency order already serializes).
**Acceptance criteria:**
- [ ] `cargo build` (lib) succeeds with empty stubs
- [ ] `lib.rs` exposes the three modules publicly
**Verification:**
- [ ] `cargo build --manifest-path runtime/Cargo.toml` exits 0

### Task: Infra (Redis compose + env + setup)
```yaml
id: T-infra
depends_on: [T-adr]
parallel_safe: true
conflicts_with: []
files_write:
  - runtime/docker-compose.yml
  - runtime/.env.example
  - runtime/setup.sh
  - runtime/.gitignore
branch_suffix: infra
scope: S
```
**Description:** `docker-compose.yml` defines a pinned `redis:7` service with a named
volume (AOF/RDB durability for replay), a healthcheck, and the port from env.
`.env.example` (committed) holds Redis host/port/db, round-limit, retry-limit, and
blackboard key-prefix. `.gitignore` ignores the real `.env`. `setup.sh` copies
`.env.example` → `.env` if absent.
**Acceptance criteria:**
- [ ] `docker compose -f runtime/docker-compose.yml up -d` → Redis healthy
- [ ] `.env.example` committed; `.env` gitignored; `setup.sh` materializes `.env`
**Verification:**
- [ ] `redis-cli -p <port> ping` → PONG; `git status` shows `.env` untracked

### Task: Redis blackboard layer
```yaml
id: T-blackboard
depends_on: [T-scaffold-crate, T-infra]
parallel_safe: true
conflicts_with: [T-scaffold-crate]
files_write:
  - runtime/src/blackboard.rs
files_read:
  - runtime/docs/ADR-001-v2-runtime.md
  - runtime/Cargo.toml
branch_suffix: blackboard
scope: M
```
**Description:** Implement the blackboard per the ADR schema (HASH `state`, HASH
`artifact`, STREAM `log`, HASH `votes:{round}`): typed read/write API for the shared
artifact, per-round contribution append to the stream, status/done, and a resume
read (re-attach to a run from current Redis state). Include an optional `inspect`
helper the bin can expose as a debug subcommand. Uses the `redis` crate against the
compose Redis.
**Acceptance criteria:**
- [ ] Write-then-read round-trips every field against live Redis
- [ ] Contributions accumulate in the `log` stream and replay in order
- [ ] Resume reads current `state.round` + `artifact` after a simulated restart
**Verification:**
- [ ] `cargo test --test blackboard` passes (added in T-tests) against compose Redis

### Task: Persona loader
```yaml
id: T-personas
depends_on: [T-scaffold-crate]
parallel_safe: true
conflicts_with: [T-scaffold-crate]
files_write:
  - runtime/src/personas.rs
files_read:
  - .claude/agents/technical-pm.md
  - .claude/agents/engineer.md
  - .claude/agents/library-reviewer.md
branch_suffix: personas
scope: S
```
**Description:** Load the three dogfood-pod `.md` files, parse YAML frontmatter
(name/tools), strip it, and produce round-participant structs (role, system prompt,
declared tools) the protocol hands to each `claude -p` turn. Read-only over
`.claude/agents/`.
**Acceptance criteria:**
- [ ] Returns a participant for PM, engineer, library-reviewer with non-empty prompt
- [ ] Frontmatter parsed without corrupting body text
- [ ] Missing/renamed file → clear error, not a silent empty prompt
**Verification:**
- [ ] `cargo test --test personas` (or inline unit test) asserts 3 named participants

### Task: Round/wave protocol + re-dispatch + agent-exec
```yaml
id: T-protocol
depends_on: [T-blackboard, T-personas]
parallel_safe: true
conflicts_with: [T-scaffold-crate]
files_write:
  - runtime/src/rounds.rs
files_read:
  - runtime/src/blackboard.rs
  - runtime/src/personas.rs
  - runtime/docs/ADR-001-v2-runtime.md
branch_suffix: protocol
scope: M
```
**Description:** Implement the orchestrator-clocked round loop per the ADR: ordered
PM→engineer→reviewer turns, build each prompt from persona + blackboard snapshot +
log tail, run the turn through an injected agent runner, parse the `serde`
contribution `{artifact_edits, note, approve}`, apply to `artifact`, append to `log`,
record the vote; evaluate done (reviewer approve or max-round cap); re-dispatch a
failed/empty turn from the durable snapshot up to the retry cap. The real agent
runner spawns `claude -p` via `std::process::Command`; tests inject a fake runner so
the loop is deterministic.
**Acceptance criteria:**
- [ ] Runs N rounds, accumulating contributions, halting on approve or cap
- [ ] A simulated failed/empty turn is re-dispatched, not dropped
- [ ] Loop is deterministic under a fake runner (no wall-clock/random deps)
**Verification:**
- [ ] `cargo test --test rounds` passes

### Task: CLI driver (runnable bin)
```yaml
id: T-driver
depends_on: [T-protocol]
parallel_safe: true
conflicts_with: []
files_write:
  - runtime/src/main.rs
files_read:
  - runtime/src/rounds.rs
  - runtime/docs/ADR-001-v2-runtime.md
branch_suffix: driver
scope: M
```
**Description:** Thin binary entry: parse args (`run --task <file>`, `inspect <run>`),
load `.env`, construct the real `claude -p` agent runner, and call `rounds::run`. New
file (`src/main.rs`) — auto-registers as the crate's bin target; no `Cargo.toml`/
`lib.rs` edit, so no concurrency conflict.
**Acceptance criteria:**
- [ ] One command boots a run against live Redis and executes ≥2 rounds with real agents
- [ ] Config (Redis conn, round cap, retries) read from `.env`
- [ ] Crash mid-run → re-invoking resumes from the blackboard (no lost state)
**Verification:**
- [ ] Manual smoke: a trivial 2-round task completes and writes a final artifact to Redis

### Task: Integration tests (blackboard + protocol)
```yaml
id: T-tests
depends_on: [T-protocol]
parallel_safe: true
conflicts_with: []
files_write:
  - runtime/tests/blackboard.rs
  - runtime/tests/rounds.rs
files_read:
  - runtime/src/blackboard.rs
  - runtime/src/rounds.rs
branch_suffix: tests
scope: M
```
**Description:** `cargo test` integration tests: blackboard (round-trip, stream
accumulation/replay, status, resume against compose Redis) and protocol (round
progression, done/cap termination, re-dispatch via a fake agent runner). The
repeatable safety net for the core.
**Acceptance criteria:**
- [ ] Blackboard tests cover read/write/append/status/resume against live Redis
- [ ] Protocol tests cover termination paths and re-dispatch with a fake runner
**Verification:**
- [ ] `cargo test --manifest-path runtime/Cargo.toml` exits 0 (Redis up)

### Task: Dogfood proof (pod authors a skill, validate.sh gates)
```yaml
id: T-dogfood
depends_on: [T-driver]
parallel_safe: true
conflicts_with: []
files_write:
  - runtime/tasks/author-skill.md
  - runtime/run-dogfood.sh
files_read:
  - runtime/src/main.rs
  - scripts/validate.sh
branch_suffix: dogfood
scope: M
```
**Description:** The end-to-end vertical slice. `tasks/author-skill.md` is the task
spec instructing PM + engineer + library-reviewer to collaborate (across rounds, via
the blackboard) to author one small, real, self-chosen library skill.
`run-dogfood.sh` builds the bin, runs `runtime run --task tasks/author-skill.md`,
writes the emitted skill to disk, captures the Redis `log` transcript as evidence,
and pipes the skill through `scripts/validate.sh`.
**Acceptance criteria:**
- [ ] One command runs the full pod and emits a candidate skill directory
- [ ] The emitted skill passes `scripts/validate.sh` (Tier-0)
- [ ] The Redis blackboard transcript is captured as an artifact
**Verification:**
- [ ] `bash scripts/validate.sh <emitted-skill-path>` exits 0
- [ ] Transcript artifact shows multi-round contributions

## Risks and Mitigations
| Risk | Impact | Mitigation |
|------|--------|------------|
| `claude -p` output not valid contribution JSON | High | Strict `serde` parse + re-dispatch on parse failure; prompt demands JSON-only stdout |
| Crate dependency fetch blocked (crates.io) | Med | Confirmed at T-scaffold-crate `cargo build`; vendor if the sparse index is unreachable |
| Sealed subagents → "real-time" expectations leak back | Med | ADR fixes the bar at fast rounds; no streaming tasks exist |
| Re-dispatch loops / non-deterministic rounds | Med | Injected agent runner; max-round + retry caps; fake-runner tests |
| Dogfood skill fails validate.sh for trivial reasons | Med | Reviewer participant + RULESET in-loop; validate.sh is the explicit done gate |

## Open Questions
- (Assumed, overridable) Pod = PM + engineer + library-reviewer; demo target = a
  skill (not an agent); skill topic self-chosen at dogfood time.
- (To confirm at T-scaffold-crate) crates.io sparse-index fetch works in this
  environment; if not, vendor dependencies.

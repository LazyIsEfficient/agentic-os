# V2 Dispatch Plan — ship Claude v2 + port Cursor harness

**Status:** cursor-v1 **shipped** on `main` (PR [#166](https://github.com/LazyIsEfficient/agentic-os/pull/166), `7426dd1`)
**Epic:** [#149](https://github.com/LazyIsEfficient/agentic-os/issues/149)
**Vision:** [NORTH_STAR.md](NORTH_STAR.md) · **Roadmap:** [V2_ROADMAP.md](V2_ROADMAP.md)
**Claude v2 landed:** PR [#143](https://github.com/LazyIsEfficient/agentic-os/pull/143) merged to `main` (`657403a`)

This document is the **single dispatch source** for async agents working the v2 milestone. Each task block is self-contained — copy one block into a fresh subagent prompt without the rest of the file.

### Branch policy

| Lane | Base branch | PR target | Scope |
|---|---|---|---|
| **Lane 1** — release | `main` | `main` | #156 README drift, #157 v2 release pin |
| **Lane 2** — Cursor port | **`main`** (was `v2-cursor`) | **`main`** | #150–#155, epic #149 ✅ |

- **`v2-cursor`** merged to `main` at **checkpoint:cursor-v1** (PR #166). Lane 2 worktrees/branches are archival only.
- Lane 1 and Lane 2 may run **in parallel** on their respective branches — **each lane MUST use its own git worktree** (see below).

### Worktree isolation (mandatory for parallel lanes)

Two lanes on two branches in one working directory will collide. **Never dispatch Lane 1 and Lane 2 agents against the same checkout.**

| Lane | Branch | Worktree path | Task branch suffix |
|---|---|---|---|
| **Lane 1** | `main` | `../skills-db-lane-main` | `lane-main/<branch_suffix>` |
| **Lane 2** | `v2-cursor` | `../skills-db` (primary) or `../skills-db-lane-cursor` | `lane-cursor/<branch_suffix>` |

**One-time setup** (from any checkout of this repo):

```bash
# Lane 1 — release work on main
git fetch origin main
git worktree add ../skills-db-lane-main main

# Lane 2 — already on v2-cursor at ../skills-db (primary checkout)
# Optional second cursor worktree if you want primary clean:
# git worktree add ../skills-db-lane-cursor v2-cursor
```

**Per-task isolation** (when two tasks in the *same* lane overlap on `files_write`, e.g. #156 then #157 both touch `README.md`):

```bash
# Example: T-156 on Lane 1
cd ../skills-db-lane-main
git checkout main && git pull
git checkout -b lane-main/readme-drift
# dispatch agent with Full Repository Path pointing HERE
```

**Within-lane parallel** (e.g. W2 `T-cursor-install` || `T-cursor-rules`): use **separate task worktrees** under `.claude/worktrees/` or sibling dirs — the `conflicts_with` matrix marks file overlap; do not rely on agents sharing one checkout.

**Agent prompt:** always set `Full Repository Path` to the **lane worktree**, not the repo root generically.

**Merge order:** finish + merge Lane 1 PRs to `main` first when both touch shared files (README, SECURITY); rebase `v2-cursor` onto `main` before W6 `T-cursor-docs` if README drift landed on main.

---

## How orchestrators use this

1. Read the **Execution DAG** and find the **ready set** (tasks whose `depends_on` are verified complete).
2. Assign each dispatch to the **lane worktree** (see Worktree isolation — mandatory).
3. Filter out tasks that **conflict** with agents already in flight (`conflicts_with` + overlapping `files_write`).
4. Dispatch **one wave** (max 3–5 parallel agents). **Different branches = different worktrees, always.** Same-lane overlapping `files_write` = task branch + separate worktree or serialize.
5. After each wave: run verification, apply **Pattern 3 review gate** (see below), mark task complete here + close/link the GitHub issue.
6. **Stop at checkpoints** until clearance criteria pass. Do not dispatch downstream tasks early.

### Review gate (Pattern 3 — mandatory after every implementation task)

| Diff touches | Spawn |
|---|---|
| Any non-trivial code | `code-reviewer` (readonly) |
| Hooks, install, validate, SECURITY, auth, exec | `security-reviewer` (readonly) — **always** for hook/install tasks |
| `.claude/skills/`, `.claude/agents/`, rules, README catalog | `library-reviewer` (readonly) |

Tier doctrine: fix Tier 0/1 findings before marking complete; log Tier 2 to findings ledger.

### Agent prompt wrapper (prepend to any task block)

```text
Full Repository Path: <lane worktree — see Worktree isolation table>
  Lane 1 (main):     /Users/glenneggleton/Documents/Clients/YGG/skills-db-lane-main
  Lane 2 (v2-cursor): /Users/glenneggleton/Documents/Clients/YGG/skills-db
GitHub repo: LazyIsEfficient/agentic-os
Base branch: <main | v2-cursor — see task block>
Task branch: <lane-main|lane-cursor>/<branch_suffix> — create before dispatch; do not commit to base branch directly
PR target: same as base branch
GitHub issue: #<issue>
Task ID: T-<slug>

Rules:
- Touch ONLY files listed in files_write unless a blocker forces a minimal adjacent fix (say so in your return).
- Run verification commands from the task block before reporting done.
- Return: summary, files changed, verification output, open questions, review verdicts addressed.
- Do NOT commit unless the orchestrator explicitly asked you to.
```

---

## Architecture decisions (locked for this dispatch)

| Decision | Choice | Rationale |
|---|---|---|
| Cursor content strategy | **Shared skills/agents markdown; platform-specific hooks + rules + install only** | Avoid duplicating 34 skills; hooks are the real divergence |
| Cursor v1 scope gate | **`sessionStart` injection spike must pass** before #150–#155 fan-out | Same de-risk pattern as S0; don't build install plumbing for a broken harness |
| Release sequencing | **Claude v2 release (#157) on `main` before Cursor consumer ship** | Stable tarball to port from |
| Cursor integration branch | **`v2-cursor`** — all Lane 2 tasks branch from and PR to here | Keeps Cursor port off `main` until checkpoint:cursor-v1 |
| Hook ship posture | **Dormant/opt-in on both platforms** | SECURITY.md review #2; no auto-registered `settings.json` / `hooks.json` |
| Evidence-gated work | **#145, #147, #158 dispatch only on triggers** (see bottom) | no-stochastic-gating doctrine |

---

## Execution DAG

```yaml
dag:
  # Lane 1 — Claude v2 ship (branch: main)
  - T-156-readme-drift → T-157-release-v2
  - checkpoint:claude-v2-shipped after [T-157-release-v2]

  # Lane 2 — Cursor port (branch: v2-cursor, gated)
  - T-cursor-spike → checkpoint:cursor-go
  - checkpoint:cursor-go after [T-cursor-spike]       # GO = sessionStart inject proven; NO-GO = narrow scope (see spike task)
  - T-cursor-spike → T-cursor-install, T-cursor-rules
  - T-cursor-install → T-cursor-security, T-cursor-hooks
  - T-cursor-install, T-cursor-rules → T-cursor-hooks
  - T-cursor-hooks → T-cursor-metrics
  - T-cursor-install, T-cursor-hooks, T-cursor-rules → T-cursor-docs
  - checkpoint:cursor-v1 after [T-cursor-docs, T-cursor-security, T-cursor-metrics]

  # Lane 3 — evidence-gated (NOT in ready set until trigger fires)
  # T-147-interactive-ab  — trigger: orchestrator opt-in + budget
  # T-145-survey-deny     — trigger: warn log near-zero FP rate
  # T-158-decision-coverage — trigger: dogfood shows decision re-derivation post-compact
```

**Ready set (now):**
- **Deferred:** `T-cursor-hooks`, `T-cursor-metrics` (NO-GO until live `sessionStart` proof)
- **Lane 3:** evidence-gated only (#145, #147, #158 — triggers required)

---

## Checkpoints

### checkpoint:pre-merge ✅ CLEARED

- [x] PR #143 merged to `main` (`657403a`, 2026-06-22)

**Unblocks:** `T-157-release-v2` once `T-156-readme-drift` completes (no longer blocked on merge).

---

### checkpoint:claude-v2-shipped ✅ CLEARED

- [x] `T-157-release-v2` verified — v2.0.0 tag + tarball (#157 closed)
- [x] Remote Claude install works (`install.sh` / `install.ps1` pin)

**Note:** v2.1.0 supersedes v2.0.0 on `main` after cursor-v1 merge (includes Cursor installer pins + updated payload).

---

### checkpoint:cursor-go — **NO-GO** (2026-06-22)

- [x] `T-cursor-spike` verified — verdict in [eval/spikes/cursor-hook-capability.md](eval/spikes/cursor-hook-capability.md)
- [x] Orchestrator recorded NO-GO in [#149](https://github.com/LazyIsEfficient/agentic-os/issues/149)

**If NO-GO:** dispatch only `T-cursor-install`, `T-cursor-rules`, `T-cursor-docs` (skills-only port); defer `T-cursor-hooks`, `T-cursor-security` hook parity, `T-cursor-metrics` hook-dependent paths. Update #149 scope.

**Blocks:** `T-cursor-hooks`, `T-cursor-metrics` (full hook-dependent scope). `T-cursor-install`, `T-cursor-rules`, `T-cursor-docs`, `T-cursor-security` proceed on narrowed scope.

---

### checkpoint:cursor-v1

**Clears when:**
- [x] #150–#155 merged on `v2-cursor`
- [x] `validate.sh` + `validate-test.sh` green (34/34)
- [x] Simulated `install-cursor.sh` smoke test passed
- [x] **`v2-cursor` merged to `main`** — PR #166 (`7426dd1`, 2026-06-22)

**Closes epic #149** ✅

---

## Task index

| Task ID | GitHub | Phase | Status |
|---|---|---|---|
| T-156-readme-drift | [#156](https://github.com/LazyIsEfficient/agentic-os/issues/156) | Lane 1 | ✅ #159 |
| T-157-release-v2 | [#157](https://github.com/LazyIsEfficient/agentic-os/issues/157) | Lane 1 | ✅ v2.0.0 |
| T-cursor-spike | [#152](https://github.com/LazyIsEfficient/agentic-os/issues/152) (subset) | Lane 2 | ✅ #160 (NO-GO) |
| T-cursor-install | [#150](https://github.com/LazyIsEfficient/agentic-os/issues/150) | Lane 2 | ✅ #162 |
| T-cursor-rules | [#151](https://github.com/LazyIsEfficient/agentic-os/issues/151) | Lane 2 | ✅ #163 |
| T-cursor-security | [#153](https://github.com/LazyIsEfficient/agentic-os/issues/153) | Lane 2 | ✅ #164 |
| T-cursor-hooks | [#152](https://github.com/LazyIsEfficient/agentic-os/issues/152) (full) | Lane 2 | ⏸ deferred (NO-GO) |
| T-cursor-metrics | [#154](https://github.com/LazyIsEfficient/agentic-os/issues/154) | Lane 2 | ⏸ deferred (NO-GO) |
| T-cursor-docs | [#155](https://github.com/LazyIsEfficient/agentic-os/issues/155) | Lane 2 | ✅ #165 |

---

## Task blocks

---

## Task: Fix README drift before v2 release

```yaml
id: T-156-readme-drift
depends_on: []
parallel_safe: true
conflicts_with: [T-157-release-v2]
files_write:
  - README.md
files_read:
  - .claude/agents/game-design-shaper.md
  - .claude/commands/state.md
  - install.sh
branch_suffix: readme-drift
base_branch: main
scope: XS
github_issue: 156
```

**Description:** Fix README inconsistencies found in PR #143 review. No code or validate rule changes expected.

**Acceptance criteria:**
- [ ] Agents table: `game-design-shaper` matches agent body (intake → design → balance → catalog; marketing → `marketer` agent)
- [ ] Commands table: includes shipped `/state` alongside `skill-new` and `agent-new`
- [ ] "What ships" prose agrees across install manifest (~L93), Commands header (~L221), and Awareness harness section

**Verification:**
- [ ] `bash scripts/validate.sh` exits 0
- [ ] Manual: scan README for "marketing end-to-end" on game-design-shaper — gone

**Suggested agent:** `engineer` (docs-only) → `library-reviewer`

---

## Task: Release v2 — bump pinned installer

```yaml
id: T-157-release-v2
depends_on: [T-156-readme-drift]
parallel_safe: false
conflicts_with: [T-156-readme-drift, T-cursor-install, T-cursor-docs]
files_write:
  - install.sh
  - install.ps1
  - README.md
  - RELEASING.md
files_read:
  - scripts/validate.sh
branch_suffix: release-v2
base_branch: main
scope: M
github_issue: 157
```

**Description:** Cut v2 release on `main` per RELEASING.md. Update pinned SHA, version strings, README install section. Confirm ship manifest matches pruned library + dormant harness.

**Acceptance criteria:**
- [ ] Tag published (semver agreed: e.g. `v2.0.0`)
- [ ] Release asset built; `EXPECTED_SHA256` in both installers matches
- [ ] README current release + verify commands updated
- [ ] Ship manifest: 34 skills / 14 agents / commands `{skill-new, agent-new, state}` / dormant hooks
- [ ] Validation + harness tests run on release tarball before publish

**Verification:**
- [ ] `bash scripts/validate.sh` && `bash scripts/validate-test.sh`
- [ ] `bash scripts/session-state-test.sh` && `bash scripts/survey-guard-test.sh`
- [ ] Simulated remote install from tag succeeds

**Suggested agent:** `engineer` → `code-reviewer` (release mechanics)

**Orchestrator note:** Requires `T-156-readme-drift` on `main`. PR #143 is already merged.

---

## Task: Cursor hook capability spike (GO/NO-GO gate)

```yaml
id: T-cursor-spike
depends_on: []
parallel_safe: true
conflicts_with: [T-cursor-hooks]
files_write:
  - eval/spikes/cursor-hook-capability.md
  - eval/spikes/cursor-hook-capability/unit-test.sh
  - .cursor/hooks/session-state-inject-probe.sh
  - .cursor/hooks/survey-before-act-probe.sh
  - .cursor/hooks.json
files_read:
  - .claude/hooks/session-state-inject.sh
  - .claude/hooks/survey-before-act.sh
  - eval/spikes/s0-hook-capability.md
  - /Users/glenneggleton/.cursor/skills-cursor/create-hook/SKILL.md
branch_suffix: cursor-spike
base_branch: v2-cursor
scope: M
github_issue: 152
```

**Description:** De-risk the Cursor port before install fan-out. Prove or disprove two capabilities using throwaway probe hooks (mirror S0 methodology).

**Spike A — context injection:** Does `sessionStart` (or documented alternative) inject `SESSION-STATE.md` content into agent context? Record exact hook output JSON / stdout format Cursor accepts.

**Spike B — shell advisory:** Does `beforeShellExecution` inject a warn-and-allow advisory on unsurveyed `docker run`? Map Claude `hookSpecificOutput` → Cursor `{ permission, agent_message }`.

**Acceptance criteria:**
- [ ] `eval/spikes/cursor-hook-capability.md` documents repro steps, Cursor version, pass/fail evidence
- [ ] `unit-test.sh` runs probe scripts deterministically (mock stdin where needed)
- [ ] Explicit **GO/NO-GO** verdict with recommended v1 scope if NO-GO
- [ ] Event mapping table filled with *verified* Cursor equivalents (not assumed)

**Verification:**
- [ ] `bash eval/spikes/cursor-hook-capability/unit-test.sh` → all pass
- [ ] Interactive or documented live-fire evidence attached in spike md

**Suggested agent:** `engineer` → `code-reviewer` + `security-reviewer` (probe hooks touch exec surface)

**Orchestrator note:** Dispatch on **`v2-cursor`**. Lane 2 day-zero task — can run in parallel with Lane 1 on `main`. Outcome drives **checkpoint:cursor-go**.

---

## Task: Cursor install script + artifact layout

```yaml
id: T-cursor-install
depends_on: [T-cursor-spike]
parallel_safe: true
conflicts_with: [T-157-release-v2, T-cursor-docs]
files_write:
  - install-cursor.sh
  - install-cursor.ps1
  - scripts/validate.sh
  - scripts/validate-test.sh
files_read:
  - install.sh
  - install.ps1
  - .claude/skills/session-state/scripts/session-state.sh
branch_suffix: cursor-install
base_branch: v2-cursor
scope: M
github_issue: 150
```

**Description:** Add Cursor install path: skills, agents, dormant hooks, session-state writer. Implement locked architecture decision (shared skill content, platform-specific hook/rules dirs). Extend ship-manifest validation if needed.

**Acceptance criteria:**
- [ ] `install-cursor.sh` (+ ps1 parity or documented gap) installs to Cursor paths
- [ ] Ship allowlist mirrors Claude: skills, agents, hooks (dormant), `/state` writer — no maintainer commands
- [ ] Simulated consumer install: `init` creates `SESSION-STATE.md` from skill-local template with zero repo-root dependency
- [ ] Writer resolves project-first + `~/.cursor/skills/` global fallback (mirror #143 global fix)

**Verification:**
- [ ] `bash scripts/validate.sh` exits 0
- [ ] Manual simulated install script in spike doc or task PR description

**Suggested agent:** `engineer` → `code-reviewer` + `security-reviewer` + `library-reviewer`

**Orchestrator note:** If **checkpoint:cursor-go** is NO-GO, still dispatch this task but scope hooks as "ship scripts only, no activation doc yet."

---

## Task: Cursor rules + /state entrypoint

```yaml
id: T-cursor-rules
depends_on: [T-cursor-spike]
parallel_safe: true
conflicts_with: [T-cursor-docs]
files_write:
  - .cursor/rules/factual-correctness.md
  - .cursor/rules/memory-discipline.md
  - .cursor/rules/subagent-dispatch.md
  - .cursor/rules/grounding.md
  - .cursor/rules/review-tiers.md
  - .cursor/rules/verification.md
  - .cursor/rules/communication.md
  - .claude/skills/session-state/SKILL.md
files_read:
  - .claude/rules/*.md
  - .claude/commands/state.md
  - CLAUDE.md
branch_suffix: cursor-rules
base_branch: v2-cursor
scope: M
github_issue: 151
```

**Description:** Port operating doctrine to Cursor rules format. Replace `/state` slash-command dependency with Cursor-native skill-triggered workflow. Ensure session-state skill documents Cursor invocation path.

**Acceptance criteria:**
- [ ] Cursor rules cover same doctrine as `.claude/rules/` (no tombstoned artifact refs — Invariant 9 clean)
- [ ] Consumer can run writer `init|show|constraint|decision|infra|thread` via documented Cursor path
- [ ] No `.claude/`-only paths in Cursor-facing skill sections without fallback

**Verification:**
- [ ] `bash scripts/validate.sh` (tombstones + dangling refs)
- [ ] Manual: follow skill-only path to append one constraint

**Suggested agent:** `engineer` → `library-reviewer`

**Parallel with:** `T-cursor-install` (no file overlap if rules stay under `.cursor/rules/`)

---

## Task: Cursor security + validate.sh parity

```yaml
id: T-cursor-security
depends_on: [T-cursor-install]
parallel_safe: true
conflicts_with: [T-cursor-install, T-cursor-hooks]
files_write:
  - scripts/validate.sh
  - scripts/validate-test.sh
  - SECURITY.md
files_read:
  - .cursor/hooks.json
  - .cursor/hooks/*.sh
branch_suffix: cursor-security
base_branch: v2-cursor
scope: M
github_issue: 153
```

**Description:** Extend Invariant 8 to `.cursor/hooks/*.sh` + `.cursor/hooks.json` strict-shape allowlist. Update SECURITY.md for dual-platform hook surface. Same gate-before-artifact doctrine as S-sec.

**Acceptance criteria:**
- [ ] Invariant 8(a) scans `.cursor/hooks/*.sh` with shared denylist
- [ ] Invariant 8(b) strict-shape allowlist defined for Cursor `hooks.json` schema
- [ ] `validate-test.sh`: ≥2 new cases (trip + clean), pinned as Tier-0 regressions
- [ ] SECURITY.md: Cursor threat model + "tripwire not sandbox" framing for both platforms

**Verification:**
- [ ] `bash scripts/validate-test.sh` — all pass including new cases
- [ ] Reproduce known bypass patterns (chain, newline) → trip on Cursor config

**Suggested agent:** `engineer` → `security-reviewer` (mandatory) + `code-reviewer`

---

## Task: Cursor awareness harness hooks (full port)

```yaml
id: T-cursor-hooks
depends_on: [T-cursor-install, T-cursor-rules, T-cursor-spike]
parallel_safe: false
conflicts_with: [T-cursor-spike, T-cursor-security, T-cursor-install]
files_write:
  - .cursor/hooks/session-state-inject.sh
  - .cursor/hooks/session-state-digest.sh
  - .cursor/hooks/session-state-checkpoint.sh
  - .cursor/hooks/survey-before-act.sh
  - .cursor/hooks.json
  - scripts/survey-guard-test-cursor.sh
  - scripts/session-state-test-cursor.sh
files_read:
  - .claude/hooks/session-state-*.sh
  - .claude/hooks/survey-before-act.sh
  - scripts/session-state-test.sh
  - scripts/survey-guard-test.sh
branch_suffix: cursor-hooks
base_branch: v2-cursor
scope: L
github_issue: 152
```

**Description:** Production port of S1/S2 awareness hooks to Cursor. Replace probe scripts from spike with production hooks. Preserve: data-not-instructions banner, fail-open posture, `[subject]` matching, warn-first survey guard, dormant ship.

**Acceptance criteria:**
- [ ] All four hooks ported; opt-in `hooks.json` snippet in `session-state/SKILL.md` (not auto-shipped active)
- [ ] Inject + digest + checkpoint behavior matches Claude semantics (modulo Cursor event names)
- [ ] Survey guard: warns unsurveyed provisioning; silent when `[subject]` matches; never denies
- [ ] Adapted test scripts ≥ Claude parity (session-state + survey-guard case counts)

**Verification:**
- [ ] `bash scripts/session-state-test-cursor.sh` — 0 failed
- [ ] `bash scripts/survey-guard-test-cursor.sh` — 0 failed
- [ ] Live-fire evidence in PR or spike follow-up doc

**Suggested agent:** `engineer` → `code-reviewer` + `security-reviewer` + `library-reviewer`

**Orchestrator note:** Skip entirely if **checkpoint:cursor-go** is NO-GO.

---

## Task: Cursor session-metrics + eval apparatus

```yaml
id: T-cursor-metrics
depends_on: [T-cursor-hooks]
parallel_safe: true
conflicts_with: []
files_write:
  - eval/metrics/session-metrics.mjs
  - eval/metrics/session-metrics-test.sh
  - eval/metrics/compare.mjs
  - eval/metrics/AB-PROTOCOL.md
  - eval/metrics/README.md
files_read:
  - eval/metrics/session-metrics.mjs
  - eval/metrics/AB-PROTOCOL.md
branch_suffix: cursor-metrics
base_branch: v2-cursor
scope: M
github_issue: 154
```

**Description:** Add Cursor transcript parsing to metrics pipeline. Document Cursor-specific interactive A/B procedure (#147). Preserve honest limit: headless never compacts.

**Acceptance criteria:**
- [ ] Cursor transcript path + schema documented
- [ ] Fixed fixture → deterministic metrics (Tier 0 test)
- [ ] `compare.mjs` accepts Cursor transcript pair when passed explicitly
- [ ] AB-PROTOCOL.md: Cursor compaction trigger + capture steps

**Verification:**
- [ ] `bash eval/metrics/session-metrics-test.sh` — all pass (Claude + Cursor fixtures)
- [ ] `bash eval/metrics/compare-test.sh` — all pass

**Suggested agent:** `engineer` → `code-reviewer`

**Orchestrator note:** Parser stub + fixture can start during `T-cursor-hooks` if transcript sample available; full close depends on hooks producing real transcripts.

---

## Task: Dual-platform README + activation docs

```yaml
id: T-cursor-docs
depends_on: [T-cursor-install, T-cursor-hooks, T-cursor-rules]
parallel_safe: false
conflicts_with: [T-156-readme-drift, T-157-release-v2, T-cursor-install, T-cursor-rules]
files_write:
  - README.md
  - .claude/skills/session-state/SKILL.md
  - SECURITY.md
  - V2_DISPATCH.md
files_read:
  - V2_ROADMAP.md
  - install-cursor.sh
branch_suffix: cursor-docs
base_branch: v2-cursor
scope: S
github_issue: 155
```

**Description:** Final consumer-facing docs: dual install, side-by-side activation snippets (Claude `settings.json` + Cursor `hooks.json`), dormant posture consistent.

**Acceptance criteria:**
- [ ] README: Claude + Cursor install sections
- [ ] Awareness harness: both activation snippets; dormant-hooks wording aligned
- [ ] Cursor-only consumer path works without reading Claude-only sections
- [ ] Update this dispatch doc task index statuses when closing

**Verification:**
- [ ] `bash scripts/validate.sh`
- [ ] `library-reviewer` pass on cross-refs

**Suggested agent:** `engineer` → `library-reviewer`

---

## Lane 3 — evidence-gated tasks (do not auto-dispatch)

Dispatch only when the **trigger** fires. Orchestrator opens a focused session; do not add to ready set by default.

### T-147-interactive-ab · [#147](https://github.com/LazyIsEfficient/agentic-os/issues/147)

**Trigger:** Orchestrator opts in to manual long-session spend; null prior acknowledged.

**Agent brief anchor:** Execute [eval/metrics/AB-PROTOCOL.md](eval/metrics/AB-PROTOCOL.md) interactive procedure. Pre-register interpretation before reading results.

---

### T-145-survey-deny · [#145](https://github.com/LazyIsEfficient/agentic-os/issues/145)

**Trigger:** `.claude/survey-guard.warns` (or Cursor equivalent) shows near-zero false-positive rate over real provisioning commands.

**Agent brief anchor:** Flip `permissionDecision` allow→deny only after structured `[subject]` match + fail-open posture verified. Update both platforms if Cursor hooks shipped.

---

### T-158-decision-coverage · [#158](https://github.com/LazyIsEfficient/agentic-os/issues/158)

**Trigger:** Dogfood shows architecture **decisions** re-derived after compaction (not covered by S2 infra guard).

**Agent brief anchor:** Measure token cost of adding Decisions to digest OR wire PostCompact re-injection. Update V2_ROADMAP S1 known-limitation.

---

## Wave planner (orchestrator cheat sheet)

| Wave | Branch | Worktree | Ready after | Dispatch together | Max agents |
|---|---|---|---|---|---|
| W0a | `main` | `../skills-db-lane-main` | PR #143 merged ✅ | `T-156-readme-drift` | 1 |
| W0b | `v2-cursor` | `../skills-db` | branch pushed ✅ | `T-cursor-spike` | 1 |
| W1 | `main` | T-156 done | `T-157-release-v2` | 1 |
| W2 | `v2-cursor` | cursor-go | `T-cursor-install` \|\| `T-cursor-rules` | 2 |
| W3 | `v2-cursor` | install done | `T-cursor-security` | 1 |
| W4 | `v2-cursor` | install + rules | `T-cursor-hooks` | 1 |
| W5 | `v2-cursor` | hooks done | `T-cursor-metrics` | 1 |
| W6 | `v2-cursor` | hooks + install + rules | `T-cursor-docs` | 1 |
| W7 | `main` | cursor-v1 + claude-v2-shipped | merge `v2-cursor` → `main` | human |

---

## Status log

| Date | Task | Result | Commit / PR |
|---|---|---|---|
| 2026-06-22 | PR #143 merge | ✅ merged to `main` | `657403a` |
| 2026-06-22 | T-156-readme-drift | ✅ merged | PR #159 |
| 2026-06-22 | T-cursor-spike | ✅ NO-GO | PR #160 |
| 2026-06-22 | T-cursor-install | ✅ merged | PR #162 |
| 2026-06-22 | T-cursor-rules | ✅ merged | PR #163 |
| 2026-06-22 | T-cursor-security | ✅ merged | PR #164 |
| 2026-06-22 | T-cursor-docs | ✅ merged | PR #165 |
| 2026-06-22 | checkpoint:cursor-v1 | ✅ shipped | PR #166 → `main` `7426dd1` |
| 2026-06-22 | v2.1.0 release pin | ✅ shipped | post-cursor housekeeping |

*Orchestrator: append a row when each task completes.*

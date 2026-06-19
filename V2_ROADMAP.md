# V2_ROADMAP.md — building the awareness harness

**Status:** proposed
**Base:** [NORTH_STAR.md](NORTH_STAR.md) · branch `v2-prune`
**Frame:** the prune did the *subtract* half (−47% always-on token tax). This roadmap is the *add* half — the awareness + token mechanisms NORTH_STAR calls for and the library does not yet have.

---

## Locked decisions (this planning pass)

1. **Lead lever: awareness mechanisms** — live session-state doc + survey-before-act, ahead of instrumentation and eval re-aim. They directly fix the failures that motivated NORTH_STAR (the unsurveyed running broker; the stale README missed until prompted).
2. **Enforcement: deterministic guards (Tier 0)** — Claude Code hooks + scripts that inject/block, *not* prompt-level rules. Rationale: a rule telling the model to maintain state is attention-dependent, and attention is precisely what fails when context is full. Only a hook is not attention-dependent.
3. **This deliverable: a strategic roadmap** — sequenced slices, dependencies, acceptance bars, measure-before-build gates. No code until a slice is approved for dispatch.

## Grounding established before planning (survey-before-act)

- **Token measurement is feasible.** The session transcript JSONL carries per-turn `usage` (input / cache_creation / cache_read / output) — 645 records in the session that produced this. Tokens-per-outcome is a transcript-parsing job, not new infrastructure.
- **Hook capability (verified via claude-code-guide):** context injection, conditional `PreToolUse` deny-with-reason, and arbitrary script file-I/O are all SUPPORTED. `.claude/settings.json` is the shippable config; hooks run with the user's shell behind a workspace-trust gate.
- **RESOLVED (S0) — `PreCompact` exists.** The disputed fact is settled: the official hooks reference documents 32 events incl. `PreCompact`+`PostCompact` (matcher `manual`/`auto`, fires on auto + manual `/compact`). The agent that said "no" was wrong. No `Stop`-hook fallback needed. See [eval/spikes/s0-hook-capability.md](eval/spikes/s0-hook-capability.md).
- **Hooks already ship.** `install.sh`/`install.ps1` already distribute `.claude/hooks/*.sh` (chmod +x) — currently the benign `block-bad-bash.sh`. The supply-chain surface is *present*, not future. So the security gate had to land **before** any new hook (gate-before-artifact), not as a Slice-5 afterthought — see S-sec below.

---

## The slice sequence

### S-sec — Hook-safety gate + SECURITY.md  ✅ LANDED (gate-before-artifact)
- **Goal:** because hooks already ship, no *new* hook should be authored before the safety gate that guards shipped hooks exists.
- **Delivered:** `SECURITY.md` (threat model + shipped-hook policy); `validate.sh` **Invariant 8 (`hook-safety`)** — Tier 0, denies network/exec/obfuscation/credential/persistence patterns in shipped hook scripts and forces hook commands to call vendored `.claude/hooks/` scripts; `validate-test.sh` cases 11–12 prove it trips, Case 0 proves no false-positive on `block-bad-bash.sh`. Runs in CI via the existing `validate.yml` (no new workflow).
- **Limit (stated, not hidden):** a static scan is a tripwire, not a sandbox. Human `security-reviewer` sign-off on every new/changed shipped hook remains the S5 gate.

### Slice 0 — Hook capability spike  ✅ LANDED (de-risked)
- **Result:** all three capabilities confirmed on Claude Code `2.1.168`. `SessionStart` injection and `PreToolUse` deny-with-reason are **proven live** (headless run: sentinel injected; Write blocked, file never created). `PreCompact` **exists** (authoritative doc + unit-tested flush script; live-fire deferred to Slice 1's first task). Full evidence + reproduction: [eval/spikes/s0-hook-capability.md](eval/spikes/s0-hook-capability.md); throwaway harness in `eval/spikes/s0-hook-capability/` (`unit-test.sh` → 6/0).
- **Gate cleared:** context-injection and conditional-deny are reliable → the deterministic-guards decision stands; Slice 1 proceeds.
- **Carry-forward:** the headless `--include-hook-events --settings <file>` recipe is the regression harness for Slice 1/2 hooks; `--bare` gives the eval harness a clean hooks-off arm (Slice 4).

### Slice 1 — `SESSION-STATE.md` mechanism  ✅ LANDED (core awareness win, dogfooded)
- **Delivered:** `SESSION-STATE.template.md` schema (Constraints / Decisions / Existing-infra / Open-threads; live `SESSION-STATE.md` gitignored). Three hooks in `.claude/hooks/`: `session-state-inject` (SessionStart → whole doc), `session-state-digest` (UserPromptSubmit → Constraints + Open-threads only, token-disciplined), `session-state-checkpoint` (PreCompact, `auto`+`manual`). Deterministic writer `scripts/session-state.sh` + `/state` command + `session-state` skill (writes go through the script, never hand-edits — capture doesn't depend on attention). **Wired live** into `.claude/settings.json` (dogfooded from next session).
- **Acceptance (Tier 0):** `scripts/session-state-test.sh` → 15/0 (writer, all three hooks, token-discipline, empty-template safety, backslash + mixed-case regressions). Invariant 8 passes the new hooks; settings commands vendored. **Live-proven:** SessionStart *and* UserPromptSubmit stdout injection both reach the model (headless `--include-hook-events` runs; the model echoed an injected sentinel verbatim).
- **Reviewed:** code-reviewer (2 Tier-1 bugs fixed: `awk -v` backslash mangling → `ENVIRON`; lowercase-only trigger regex), security-reviewer (pass; prompt-injection-at-ship advisory → SECURITY.md rule 7 + data-not-instructions banner), library-reviewer (pass; `/state` init/show arg tightened).
- **Carry-forward to S2/S5:** (1) confirm `PreCompact` *live*-fire (deferred from S0 — a one-shot can't compact); (2) S5 must register these hooks in a *shipped* settings file (the dev `settings.json` doesn't ship), newly subjecting it to Invariant 8(b) on the consumer path; (3) **conflict edge with S2** — both touch SESSION-STATE + settings.json; S2's survey-guard writes `infra` entries via the same writer.

### Slice 2 — survey-before-act guard
- **Goal:** make "what already exists?" a structural precondition of building, not a habit the model must remember.
- **Mechanism:** a `PreToolUse` hook on provisioning-class actions (new-infra `Write`/`Edit`, `docker`/package `Bash`) that blocks-with-reason unless a survey entry exists in SESSION-STATE.md. Tuned to not false-positive on ordinary edits.
- **Depends on:** S0; coordinates with S1 on the shared artifact (sequence after S1 or co-develop).
- **Acceptance (Tier 0):** hook blocks a cold "provision RabbitMQ" action until a survey entry is recorded; a fixture of ordinary edits passes untouched (false-positive rate measured, not asserted).

### Slice 3 — measurement baseline (closes the proof loop)
- **Goal:** the instrument that lets S1–S2 be *proven*, per NORTH_STAR's "measure before build" guardrail — without making measurement the lead.
- **Mechanism:** a script over the transcript JSONL emitting tokens-per-session/turn + awareness-failure signals (same-file re-reads, re-derivation of settled facts, ignored existing state).
- **Depends on:** S0 (independent of S1/S2 otherwise — can develop in parallel). **Its baseline-capture sub-step is the merge gate below.**
- **Acceptance (Tier 0):** given a fixed transcript, emits stable token totals + a re-work signal count; same input → same numbers.

### Slice 4 — re-aim the eval harness
- **Goal:** `eval/` today measures single-task ON/OFF *correctness* — the wrong axis. Re-aim it to tokens-per-outcome + long-session coherence (raw Claude Code vs harness-on).
- **Mechanism:** extend `eval/` to run a multi-step scenario under both arms and diff the Slice-3 metrics.
- **Depends on:** S3.
- **Acceptance (Tier 0):** produces a tokens-per-outcome + awareness-failure delta for one multi-step scenario; numbers reproduce.

### Slice 5 — ship + ratchet
- **Goal:** make the mechanisms installable and guarded.
- **Mechanism:** wire hooks into `install.sh`/`install.ps1` (ship `.claude/settings.json`); add a `validate.sh` rule for hook/settings integrity; cross-link NORTH_STAR ↔ RULESET ↔ README.
- **Depends on:** S1, S2 (hooks must exist), S3 (validate rule).
- **Acceptance (Tier 0):** `install.sh` ships the hooks, `validate.sh` + `validate-test.sh` green, **security-reviewer signs off on shipping executable hooks to consumers** (see Risks).

---

## Execution DAG

```
S0 → S1 → S2 → S5
S0 → S3 → S4
S3(baseline) ⊣ merge-gate for S1,S2
S1,S3 → S5   (S5 also needs S2)
```
`S1 ∥ S3` after S0. `S1`–`S2` share the SESSION-STATE artifact (conflict edge — coordinate writes).

## The measure-before-build gate (NORTH_STAR guardrail, embedded)

A built awareness hook **does not merge** until Slice-3's baseline-capture has run a fixed scripted scenario *before and after* the hook, and the after shows: (a) tokens-per-outcome not increased, and (b) the targeted awareness-failure signal reduced. A hook that doesn't move its own metric is reverted, not shipped. This is how "awareness-first" still honors "measure before adding complexity."

## Risks & open verifications

- **UNVERIFIED `PreCompact`** — resolved in S0; `Stop`-flush fallback named.
- **Shipping executable hooks is a supply-chain surface** (already live — see S-sec). Shipped hook scripts run arbitrary shell on consumer machines (no sandbox; trust-gated). Mitigated by `SECURITY.md` policy + the Tier-0 `hook-safety` gate; still gated on human `security-reviewer` at S5. A first-class risk, not a footnote.
- **`UserPromptSubmit` injection is a per-turn token cost.** The digest must stay compact or it re-creates the token tax the prune removed. Slice-3 measurement watches this directly.
- **False-positive blocking erodes trust** (the no-stochastic-gating rule). S2's guard must be deterministic and tightly scoped, or operators learn to ignore it.

## Out of scope for v2 (named, not silently dropped)

Token-aware *mediator* / budget-driven compaction (NORTH_STAR Lever 1 beyond the session-state doc); retrieval-backed long-term memory (Lever 2 beyond the findings-ledger); multi-repo awareness. Deferred until the single-repo awareness loop is proven.

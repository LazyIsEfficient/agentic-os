# V2_ROADMAP.md — building the awareness harness

**Status:** in-progress
**Base:** [NORTH_STAR.md](NORTH_STAR.md) · Claude v2 on `main` (PR #143 merged) · Cursor port on **`v2-cursor`**
**Dispatch:** [V2_DISPATCH.md](V2_DISPATCH.md) — async agent task blocks, DAG, checkpoints (epic [#149](https://github.com/LazyIsEfficient/agentic-os/issues/149))
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
- **Delivered:** `SESSION-STATE.template.md` schema (Constraints / Decisions / Existing-infra / Open-threads; live `SESSION-STATE.md` gitignored). Three hooks in `.claude/hooks/`: `session-state-inject` (SessionStart → whole doc), `session-state-digest` (UserPromptSubmit → Constraints + Open-threads only, token-disciplined), `session-state-checkpoint` (PreCompact, `auto`+`manual`). Deterministic writer (skill-local `.claude/skills/session-state/scripts/session-state.sh` after S5-C; was repo-root at S1) + `/state` command + `session-state` skill (writes go through the script, never hand-edits — capture doesn't depend on attention). **Wired live** into `.claude/settings.json` (dogfooded from next session).
- **Acceptance (Tier 0):** `scripts/session-state-test.sh` → 15/0 (writer, all three hooks, token-discipline, empty-template safety, backslash + mixed-case regressions). Invariant 8 passes the new hooks; settings commands vendored. **Live-proven:** SessionStart *and* UserPromptSubmit stdout injection both reach the model (headless `--include-hook-events` runs; the model echoed an injected sentinel verbatim).
- **Reviewed:** code-reviewer (2 Tier-1 bugs fixed: `awk -v` backslash mangling → `ENVIRON`; lowercase-only trigger regex), security-reviewer (pass; prompt-injection-at-ship advisory → SECURITY.md rule 7 + data-not-instructions banner), library-reviewer (pass; `/state` init/show arg tightened).
- **Carry-forward to S2/S5:** (1) confirm `PreCompact` *live*-fire (deferred from S0 — a one-shot can't compact); (2) S5 must register these hooks in a *shipped* settings file (the dev `settings.json` doesn't ship), newly subjecting it to Invariant 8(b) on the consumer path; (3) **conflict edge with S2** — both touch SESSION-STATE + settings.json; S2's survey-guard writes `infra` entries via the same writer.
- **Known limitation — decision coverage is asymmetric (PR #143 review; ledger `384bc04b`):** the per-turn digest re-injects **only Constraints + Open-threads**; **Decisions + Existing-infra inject at SessionStart only** — not per-turn, and not re-injected after a mid-session compaction (`PreCompact` checkpoints but doesn't re-inject; no `PostCompact` wired). Combined with S2's active guard covering **infra provisioning only**, the harness's *thinnest* coverage is **architecture-decision re-derivation** on long distributed-systems work — exactly the case where it would matter most. Workaround today: record a load-bearing architecture decision **also as a Constraint** (which re-injects every turn). Candidate fixes (unscheduled): add Decisions to the digest (token-cost tradeoff) or wire a `PostCompact` re-injection of the whole doc.

### Slice 2 — survey-before-act guard  ✅ LANDED (warn-first; ratchet pending)
- **Delivered:** `.claude/hooks/survey-before-act.sh` — a `PreToolUse(Bash)` hook (scope: container provisioning — docker/podman/nerdctl `run`, `compose up`). On an UNsurveyed provisioning command it injects a "check whether it already exists, then `/state infra`" reminder; silent when the target already appears in SESSION-STATE's Existing-infrastructure, or for non-provisioning commands. **Warn-first:** always ALLOWS and logs each interception to `.claude/survey-guard.warns` (gitignored) so the false-positive rate is *measured*, not asserted, before any ratchet to deny. Wired into `settings.json` PreToolUse; passes Invariant 8 (and proved the gate scans comments — the source can't even *name* denylisted tokens).
- **Acceptance (Tier 0):** `scripts/survey-guard-test.sh` → 12/0 (warns unsurveyed, silent surveyed, silent on `docker ps`, zero false-positives across git/ls/npm/cargo/echo, never denies, embedded-quote + log-injection regressions). Warn-and-allow proven live (headless: command ran AND reminder reached the model).
- **Reviewed:** code-reviewer + security-reviewer (both pass/ship-with-fixes, no blocking — warn-first makes every gap safe-direction). Fixed: `jq`-with-`sed`-fallback extraction (Tier-1, exact command), log-record forging via newline (Tier-1, sanitized).
- **Ratchet-to-deny requirements (before flipping `allow`→`deny`, per no-stochastic-gating):** (1) exact command parse — `jq` path already in place; (2) the "already surveyed" check must key off a **structured survey record**, not the current fuzzy ≥4-char substring match (a coincidental token like `broker`/`data` can wrongly suppress — fine for an advisory, a bypass for a block); (3) decide and document the **fail-closed vs fail-open** posture when SESSION-STATE is unreadable or `jq` is missing; (4) only flip once the `survey-guard.warns` log shows a near-zero false-positive rate in real use.
- **Depends on:** S0 + S1 (shares SESSION-STATE; reads the Existing-infrastructure section S1's `/state infra` writes).

### Slice 3 — measurement baseline  ✅ LANDED (closes the proof loop)
- **Delivered:** `eval/metrics/session-metrics.mjs` — deterministic transcript-JSONL parser emitting token accounting (output/input/cache, per-turn) + **Tier-0** awareness signals: files read >1× and repeated identical tool calls. The fuzzy signals NORTH_STAR also names ("re-derivation", "ignored existing state") need LLM judgment (**Tier 2**) and are deferred to S4's comparative eval — stated, not smuggled in.
- **Acceptance (Tier 0):** `eval/metrics/session-metrics-test.sh` → 10/0 against a fixed fixture, asserting determinism (run twice, identical) and exact counts.
- **Caught by review (and why the gate matters):** the first cut counted `turns`/tokens per assistant *record*, but one logical turn is emitted as several records with the **same usage repeated** — a 2.85× output-token inflation (919→386 turns, 2.26M→793K output). Fixed by deduping on `message.id`; the fixture now pins the dedup so it can't regress. Plus: stable-key tool-call comparison, raw "repeat" (not "redundant") naming to keep the Tier-2/0 line honest.
- **Real baseline captured:** this session = 386 turns / 793K output / 137M cache-read; 5 files read >1× (run-battery.sh 5×). This is the apparatus the **measure-before-build gate** uses: capture before/after a hook and compare tokens + signal counts.
- **Depends on:** S0 only (independent of S1/S2). Feeds S4.

### Slice 4 — re-aim the eval harness  ✅ LANDED
- **Delivered:** `eval/metrics/compare.mjs` — diffs two transcripts (ON arm = awareness hooks vs OFF arm = no-hooks baseline) into a per-metric delta `(OFF − ON)` + `saved%` over the S3 metrics; reuses `computeMetrics()` (refactored out of `session-metrics.mjs`). `run-arms.sh` runs both arms live via `--session-id` (ON `--settings .claude/settings.json`, OFF `--settings '{"hooks":{}}'` — *not* `--bare`, which confounds by also stripping LSP/plugins). `README.md` documents the scenario and the honest caveat.
- **Acceptance (Tier 0):** `compare-test.sh` → 8/0 on a fixture arm-pair with a known delta (OFF re-reads config + takes an extra turn → +110 output tokens / 41% / +1 repeat-read), reproducible. The deterministic core is the *compare*; a live `run-arms.sh` is one **stochastic** sample (smoke-tested end-to-end: both arms produce clean transcripts, compare runs).
- **Reviewed:** code-reviewer (ship) — independently recomputed the fixture deltas; fixed a latent CLI-guard bug (relative `argv[1]` via `pathToFileURL`) and dropped the `uuidgen` dependency for `node crypto.randomUUID`.
- **The honest limit (stated, not hidden):** the awareness *benefit* only appears in sessions long enough to cross a compaction boundary; a single short run measures plumbing, not awareness. Real result = a long multi-step scenario, N runs/arm, compare distributions. This apparatus makes that measurable; it does not pre-judge it (the effectiveness investigation is the cautionary tale).
- **#147 follow-up — sharpened (the limit is structural, not just "short"):** a one-shot `claude -p` **never compacts** (S0, reconfirmed #146), so the *headless* harness can never reach the boundary — it measures only the per-turn token **tax**, never the across-compaction benefit. Reporting a headless ON−OFF delta as the result would be a cost-only answer to a benefit question. The benefit needs an **interactive** multi-turn run; the by-hand procedure + pre-registered interpretation + the automation prerequisite (a multi-turn driver) are in [eval/metrics/AB-PROTOCOL.md](eval/metrics/AB-PROTOCOL.md). Executing N interactive runs is a deliberate, opt-in spend with a null prior — deferred.
- **Depends on:** S3.

### Slice 5 — ship + ratchet  (chunked by risk; A+B done, C held, D deferred)
Split because S5 bundles three *different* risk tracks. On the branch all are
reversible; the gradient is what each enables **once merged/released**.

**Branch-state finding (the reason chunking matters) — RESOLVED in C:** before
C, `install.sh` shipped via whole-dir globs (`install_dir "hooks"`, `install_dir
"skills"`), so the harness shipped **incoherently**: hooks shipped dormant, but the
`session-state` skill referenced the repo-root `scripts/session-state.sh` (NOT
shipped) and `/state` + the writer did not ship — a consumer got dormant hooks + a
skill pointing at a missing writer. C made it coherent: the writer + template are
now skill-local (ship), `/state` is in the allowlist, and the hooks remain dormant
(opt-in). Coherent + dormant = shippable; auto-registration stays gated.

- **A — docs + ship decision  ✅ DONE.** README documents the harness; NORTH_STAR
  ↔ ROADMAP ↔ SECURITY cross-linked. Ship boundary decided (below).
- **B — ship-safety + security review  ✅ DONE.** SECURITY.md ship-time plan;
  `security-reviewer` signed off on the *plan* (not shipping yet). No new
  `validate.sh` rule: most "scripts/" refs are skill-local (they ship), so a
  blanket "references scripts/" guard would false-positive — the repo-root-writer
  case is handled by the C plan instead.
- **C — wire `install.sh`/`install.ps1` to ship the harness  ✅ DONE (opt-in mode).**
  Shipped the harness as a coherent, self-contained, **dormant/opt-in** unit
  (issue #144, branch `feat/s5c-ship-harness`): writer relocated to the skill's own
  `scripts/` subdir + template to `assets/` (both ship via `install_dir "skills"`);
  writer resolves the template script-relative and the live doc at the project root;
  both call sites repointed; `/state` added to the command allowlist in `install.sh`
  AND `install.ps1` with `EXPECTED_CMDS` + `validate-test.sh` case 10 updated in
  lockstep; the opt-in `settings.json` snippet is **documented in the skill, not
  shipped active**; rule-7 untrusted-data framing carried. **Deliberately NOT
  shipped:** an active `settings.json` that auto-registers the hooks — that remains
  the still-gated supply-chain step (auto-execution on every consumer session),
  requiring an Invariant-8(b) shipped settings file + a fresh `security-reviewer`
  pass on that install diff.
- **D — S2 deny-ratchet  ⏸ PREP DONE, FLIP DATA-BLOCKED (#145).** The hardening
  prerequisites are built (warn-mode unchanged): the fuzzy ≥4-char substring scan
  is replaced by a **structured `[subject]` survey record** — the guard suppresses
  only when a command names the exact bracketed subject of a surveyed entry, fixing
  a demonstrated false-negative (a coincidental word like "broker" in a different
  service no longer aliases a survey) and shrinking the deny-time evasion surface;
  and the **fail posture is documented** (environment failure → fail-open; only a
  true guard-positive escalates). **Still deferred:** the warn→deny flip itself —
  it needs real `survey-guard.warns` false-positive evidence from actual use (we
  have none), and flipping a stochastic gate without it violates the
  no-stochastic-gating rule (`.claude/rules/review-tiers.md`).

**Ship boundary (decided in A; refined in C):** the harness ships as ONE coherent
unit — awareness hooks (dormant) + `/state` command + `session-state` skill + the
skill-local writer + template. The one piece held back from the original boundary is
the **active settings registration**: C ships the harness coherent + opt-in, and a
shipped `settings.json` that auto-registers the hooks is split out as a separate,
still-gated step. `eval/metrics/*` and `scripts/` validators are repo tooling and
never ship. The incoherent-skill-ref blocker is resolved; auto-registration remains
enforced by branch + security review.

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

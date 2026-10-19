# NORTH_STAR.md — AgenticOS

**Vision**: AgenticOS becomes the harness that makes Claude Code ship code with **measurably fewer security defects and less slop** than Claude Code without it, by enforcing quality with deterministic hooks and cold (context-free) reviewers.

We win when the same task, run by the same model, produces code with a lower security-defect rate and a lower slop rate with the library ON than with it OFF. Scripts must measure that difference, not a judge's impression of it. Token cost and long-session coherence matter, but they serve this outcome and never outrank it.

---

## The Problem

Frontier models (Opus 4.8+, etc.) are becoming extremely capable at complex coding and reasoning tasks. Adding more agents or clever communication patterns often delivers **diminishing or zero measurable uplift** on quality for single tasks.

What a capable model still does unprompted is ship **security defects** (injection, broken authz, SSRF, path traversal, committed secrets, vulnerable dependencies) and **slop**: imports that do not resolve, lint violations, duplicated and dead code. A model that wrote the code and reviews it in the same context tends to approve its own blind spots. No single prompt fixes this. It is a missing control layer: checks that run whether or not the model remembers them, and reviewers that have not seen the reasoning they are judging.

Long sessions make this worse. **Finite context and compression lead to awareness drift.** The model loses earlier facts, settled decisions and existing state, so it re-derives things, misses infrastructure that already exists, and repeats patterns that were already ruled out. Drift is one source of defects and slop. It is not the outcome we measure.

Token economics still constrain the design. Per-token pricing makes a harness that buys quality with unbounded token burn unusable. So tokens are a guardrail on how we get the outcome, not the outcome itself.

---

## Current Evidence (read this before claiming uplift)

**We have no measured security or slop uplift today.** `eval/INVESTIGATION.md` concludes the library is "a convention / conformance + process-scaffolding layer, not a correctness or reliability multiplier" for the current model on tasks within its one-shot competence. Its reproducible win is conformance to this repo's own standards. The existing harness has no SAST, secret-scan or slop checkers, and its one seeded-vulnerability fixture came out clean in every arm.

The instrument that will measure the primary outcome is the security and slop eval in **issue #273**: seeded-vulnerability tasks across stacks, scored by deterministic scanners, library ON vs OFF, with enough runs per cell to report intervals. Until #273 produces a report, no document, README or release note in this repo may claim that the library reduces security defects or slop.

---

## Our North Star Outcome

**With AgenticOS installed, Claude Code produces code with a lower security-defect rate and a lower slop rate than without it, on the same tasks and model, as measured by deterministic tools.**

Both rates are **co-primary**. A change that improves one while regressing the other is not a win. Success is not the number of agents, skills, hooks or reviewers, and it is not a judge's preference.

---

## Primary Metrics (co-primary)

Every primary metric is **Tier 0** under `.claude/rules/review-tiers.md`: a script computes it, and the same artifact gives the same number every run. LLM judgment cannot set, adjust or override these numbers. A metric with no script behind it is not primary yet.

### Shared definitions

- **Run**: one execution of one eval task in one arm, ending in a diff against the task's starting commit.
- **Arms**: **ON** has this library installed (agents, skills, hooks, cold reviewers). **OFF** has the same model, task, starting commit and tool access, without the library. The fixture, the scanner versions and the scanner configs are pinned and identical across arms.
- **Scope**: only files the run added or changed, scanned against the task's base (`--base <ref>`). Findings in pre-existing code do not count, so each arm is charged only for what it wrote.
- **Completed run**: the run produced a diff, and every scanner the metric needs reported `ran` or `findings`. A run where a required scanner reported `unavailable` or `error` is **excluded** from the denominator and counted as `invalid`. The report shows invalid counts per arm. A cell with any invalid run is flagged, never silently dropped.

### P1 — Security-defect rate (SDR)

- **Numerator**: completed runs with at least one security finding in scope.
- **Denominator**: completed runs in that arm.
- **Tools**: `scripts/security-scan.sh` (lands with PR #286). It wraps:
  - **semgrep**, with the eval's pinned ruleset
  - **gitleaks**, for secrets
  - a **dependency audit**: osv-scanner if installed, otherwise npm audit, pip-audit or cargo audit
- **What counts as a security defect**: any one of these, in scope:
  - a semgrep finding from the pinned ruleset
  - a gitleaks finding
  - a dependency advisory for a package or version the diff introduced
  - for seeded-vulnerability tasks, the seeded flaw still being present, if the fixture ships a deterministic check for it (a scanner rule or an exploit test that exits nonzero)
- **What does not count**: findings in unchanged code, advisories on dependencies the diff did not touch, and any finding raised only by an LLM reviewer. A reviewer finding counts only after it is reproduced by one of the tools above.
- **Also reported, not primary**: security findings per completed run, broken down by scanner and by rule ID. This shows whether a rate change comes from fewer defect types or from fewer repeats of one defect.

### P2 — Slop rate (SR)

- **Numerator**: completed runs with at least one slop finding in scope.
- **Denominator**: completed runs in that arm.
- **What counts as slop**, by component:

| Component | Defect | Tool | Status |
|---|---|---|---|
| Unresolved imports | relative import that doesn't resolve; bare package not declared in any ancestor manifest; Python module `find_spec` can't find; runtime dependency added in the diff that nothing imports | `scripts/check-imports.sh` (PR #286) | defined |
| Lint | an error-level finding from the task stack's pinned linter config on changed files | pinned per-stack linter, selected by the #273 fixture | defined per fixture |
| Duplication | a duplicated block in changed files above the pinned threshold | chosen by #273 | **not yet in SR** |
| Dead code | a new unreferenced export, function or file introduced by the diff | chosen by #273 | **not yet in SR** |

- **Rule for components that are not ready**: a component joins SR only once #273 pins a tool, a version and a threshold, and a script emits the count. Until then it is reported alongside SR as informational and kept out of the rate. That keeps SR Tier 0 and prevents its definition from drifting between runs.
- **Also reported, not primary**: slop findings per completed run by component, and diff size (lines added and removed). Diff size is context, not a defect: a large diff is not slop by itself.

### What counts as uplift

The library shows uplift on a metric only when the #273 report puts **OFF − ON** above zero with the whole interval above zero, for that metric, on the same corpus. Point estimates alone do not count, and neither do single runs or judge verdicts.

---

## Guardrail Metric — Tokens per Outcome

- **Numerator**: total tokens (input plus output, across the orchestrator and every subagent) summed over all runs in the arm, failed runs included, so failures are not free.
- **Denominator**: completed runs in the arm that pass the task's own deterministic check.
- **Tool**: session token accounting (`eval/metrics/`). A script computes it, so it is Tier 0. The per-run token distribution is reported next to it.
- **Role**: guardrail, not goal. We track it so the security and slop outcome stays affordable under per-token pricing. Token reduction work, including the v4 token-efficiency epic (#237), continues under this guardrail.
- **Tradeoff rule**: **a token saving never justifies a regression in SDR or SR.** Before a token-reducing change ships, it must show that neither primary rate got worse on the #273 corpus, meaning the interval for the change does not show an increase. When a change improves SDR or SR and costs tokens, we report the token cost next to the rate gain and keep the change. Token cost is a reason to look for a cheaper route to the same rate. It is not a reason to give up the rate.

---

## Invariants

These hold regardless of what any metric says.

1. **Never dispatch `general-purpose`.** Every subagent the library spawns has a typed specialist (`Explore`, `Plan`, `engineer` and the stack engineers, the reviewers). An untyped or `general-purpose` spawn is a defect in the library, not a judgment call. Enforcement is the PreToolUse hook `block-general-purpose.sh` (PR #284, merged), which fails closed, plus the `no-general-purpose` check in `scripts/validate.sh`. The eval's OFF arm is the absence of the library, not a library dispatch; how the harness runs it under the ban is described in PR #284 and decided in #273.
2. **Cold reviewers stay cold.** Gate reviewers start with no context from the session whose output they review. That independence is the mechanism the primary outcome depends on.
3. **Only Tier 0 and Tier 1 evidence gates.** Pure LLM judgment (Tier 2) never blocks work and never moves a primary metric (`.claude/rules/review-tiers.md`).

---

## Core Principles

1. **Defects and Slop Are the First-Class Design Constraint**
   - Every hook, skill, agent and reviewer is judged by its effect on SDR and SR.
   - A component that cannot show an effect on either, once #273 can measure it, is a candidate for removal.

2. **Conformity + Determinism Remain Table Stakes**
   - Structural validation, curated installation, reproducible workflows and clear invariants are non-negotiable.
   - Neither quality work nor token optimization may come at the expense of predictability or safety.

3. **The Harness Is the Product**
   - AgenticOS is not "more agents." It is the **scaffolding and control layer** around models (the harness).
   - We improve the harness so the model ships fewer defects, **and maintains better awareness over time**, with no more context than it needs.

4. **Persistent Awareness via External State (Survey Before Act)**
   - The harness must provide mechanisms for live session state, constraints, and existing infrastructure to be externalized and re-read at decision points.
   - "Survey-before-act" (explicitly checking what already exists) should be a default, enforceable habit rather than something the model has to remember to do.
   - We treat re-deriving settled facts or failing to notice existing state as a harness failure, not a model failure. It is also a common source of duplicated code and unresolved imports.

5. **External State Over Context Stuffing**
   - Prefer files, structured memory, ledgers, and retrieval over keeping everything in the active context window.
   - The mediator and skills should treat the filesystem and persistent artifacts as primary memory.

6. **Measure What Matters**
   - The headline numbers are SDR and SR, ON vs OFF, from deterministic tools. Tokens, context growth and awareness failures are instrumented as guardrails and diagnostics.
   - Qualitative "feels better" and judge preference are insufficient. We want observable reductions in defects and slop for equivalent tasks.

7. **Future-Proof for Per-Token Economics**
   - Design as if every token has a real marginal cost, because the guardrail metric will charge it.
   - Prefer deterministic checks (cheap, zero variance) over extra LLM review passes wherever a script can find the same defect.

---

## What We Optimize For

- **Security-defect rate in generated code, library ON vs OFF** (co-primary)
- **Slop rate in generated code, library ON vs OFF** (co-primary)
- Tokens per outcome, held within the guardrail (guardrail, never traded against the primaries)
- Moving recurring reviewer findings down the tier ladder into scripts (Tier 2 → Tier 1 → Tier 0), so the defect is caught for free on every run
- Long-horizon session coherence without awareness drift or re-litigation of settled facts
- Predictable and low variance in both defect rates and token consumption across similar tasks
- Reusable, auditable skills that are inherently context-efficient

## What We De-prioritize (for now)

- Adding more agents, reviewers or hooks without a hypothesis about which defect or slop component they reduce
- Token cuts that have not been checked against SDR and SR
- Complex inter-agent natural language negotiation protocols that increase token burn without a defect-rate effect
- General-purpose "agent orchestration frameworks" (and the library must never dispatch `general-purpose` subagents)
- Chasing raw model capability parity (we ride the frontier models; we do not try to out-reason them with volume)

---

## Key Levers (Where We Focus Energy)

Lever numbers are stable; other files reference them.

1. **Token-Aware + Awareness-Aware Mediator / Orchestrator**
   - The global JS scope + mediator pattern is a strategic asset.
   - Evolve it to route every dispatch to a typed specialist, track token budgets, trigger compaction, **maintain a live session state + constraints document**, and enforce survey-before-act behavior.

2. **Context Lifecycle Management**
   - Skills and hooks for intelligent compaction, summarization, and offloading.
   - Progressive disclosure of tools, skills, and context.
   - Structured memory (findings ledger → proper long-term memory with retrieval).

3. **Live Session State & Survey Discipline**
   - Explicit mechanisms for maintaining a compact, re-readable "state & constraints" document that gets consulted at key decision points.
   - Default patterns that force the model to survey existing state/infrastructure before proposing new work.

4. **External Memory & State as Default**
   - Treat the project filesystem, AGENTS.md-style files, and structured artifacts as the source of truth.
   - Minimize re-transmission of history or large artifacts.

5. **Measurement & Observability**
   - The #273 security and slop eval, library ON vs OFF, is the measurement of record for the primary outcome.
   - Token accounting per workflow, per skill and per agent interaction, for the guardrail.
   - Tracking of awareness-related failures (re-deriving, missing existing state, etc.) as diagnostics.

6. **Deterministic Guards + Cold Review**
   - Hooks and pre-commit gates that run the same scanners as the eval (`scripts/security-scan.sh`, `scripts/check-imports.sh`), so a defect the eval would count is caught before it ships.
   - Cold reviewers that must attach scanner output or a counterexample to any blocking finding (Tier 1), with recurring Tier 2 findings promoted into scripts through the ratchet.

---

## Sequence (what depends on what)

1. PR #286 (merged) lands `scripts/security-scan.sh` and `scripts/check-imports.sh`. These are the tools P1 and part of P2 need.
2. PR #284 (merged) bans `general-purpose` spawns, making Invariant 1 mechanical.
3. #273 builds the seeded-vulnerability corpus, pins the remaining slop tools, and produces the first ON vs OFF report with intervals. That report is the first measurement of the primary outcome. It depends on step 1. It also depends on step 2 only for how the OFF arm is run.
4. Token-reduction work (#237) is checked against the #273 baseline under the tradeoff rule. Cuts that predate the baseline are re-checked once it exists.
5. Components that show no effect on SDR or SR in the #273 report become candidates for removal. Their removal must also leave both rates unchanged or better.

---

## Success Looks Like

- On the #273 corpus, the library-ON arm has a lower security-defect rate and a lower slop rate than the OFF arm, with intervals that exclude zero, reproduced on re-run.
- Every blocking reviewer finding in this repo carries a scanner output or counterexample, and the set of defects caught by scripts keeps growing through the ratchet.
- Never dispatch `general-purpose`: enforced by a hook rather than by memory.
- Tokens per outcome stays within the guardrail, and no token saving has been accepted at the cost of a primary-rate regression.
- Long, multi-step sessions with a human in the loop stay coherent: settled decisions are not re-litigated, existing infrastructure is noticed and reused, and awareness drift is minimized.
- The project is referenced as an example of **serious harness engineering** that measures security and quality outcomes with deterministic tools, not agent hype.

---

## Guardrails While Exploring

- Before adding new multi-agent complexity, hooks or reviewers: name the defect or slop component it should reduce, and how #273 would show it.
- Before building new skills: ask "Does this skill lower SDR or SR for the workflows it targets, and does it stay within the token guardrail?"
- Before shipping a token cut: show no regression in SDR or SR.
- We are willing to be opinionated and say "no" to patterns that add defects, slop, token burn or awareness drift even if they feel clever.
- We keep the installable, curated, validated nature of the project. Quality, token and awareness mechanisms should enhance, not erode, conformity.

---

**This document exists to keep us honest.**

When in doubt, ask:  
*"Does this change measurably lower the security-defect rate or slop rate of the code Claude Code produces, without raising the other, while staying within the token guardrail and the invariants?"*

If the answer is not clearly yes, or cannot yet be measured, we should question whether it belongs in the harness right now.

---

*Last updated: 2026-10-19. Primary metric changed from tokens per high-quality outcome to security-defect rate and slop rate, library ON vs OFF; tokens per outcome is now a guardrail (#274).*

# v2 milestone closeout — operator checklist

Track human-run acceptance and evidence before closing the **v2** milestone. Code slices S0–S5-C and Cursor port are shipped on `main` (release **v2.1.0**). This checklist covers what only an operator can run.

**Open milestone issue:** [#145](https://github.com/LazyIsEfficient/agentic-os/issues/145) (deny ratchet — evidence-gated; may stay open or move to post-v2).

---

## 1. Activation docs ([#182](https://github.com/LazyIsEfficient/agentic-os/issues/182))

- [ ] [docs/awareness-harness-activation.md](../../docs/awareness-harness-activation.md) merged
- [ ] `session-state/SKILL.md` Claude snippet includes all four hooks (incl. survey-before-act)
- [ ] README + CURSOR.md link to activation doc

---

## 2. Preflight (automated — run from repo root)

```bash
bash scripts/validate.sh
bash scripts/session-state-test.sh
bash scripts/session-state-test-cursor.sh
bash scripts/survey-guard-test.sh
bash scripts/survey-guard-test-cursor.sh
bash eval/spikes/cursor-hook-capability/unit-test.sh
```

| Run date | Operator | All green? |
|----------|----------|------------|
| 2026-06-23 | agent automated | [x] |

One-liner: `bash eval/spikes/cursor-hook-capability/run-automated.sh`

---

## 3. Cursor hooks — automated gate ([#170](https://github.com/LazyIsEfficient/agentic-os/issues/170))

**No manual UI repro.** Run:

```bash
bash eval/spikes/cursor-hook-capability/run-automated.sh
```

| Check | Result | Gate |
|-------|--------|------|
| Session-state (Cursor) | [x] PASS | `session-state-test-cursor.sh` |
| Survey guard (Cursor) | [x] PASS | `survey-guard-test-cursor.sh` |
| Block bad bash (Cursor) | [x] PASS | `block-bad-bash-test-cursor.sh` |
| Full bundle | [x] PASS | `run-automated.sh` |

Protocol: [LIVE-FIRE-PROTOCOL.md](../spikes/cursor-hook-capability/LIVE-FIRE-PROTOCOL.md) (automated only).

---

## 4. Long-session A/B ([#147](https://github.com/LazyIsEfficient/agentic-os/issues/147) — scenario shipped)

Follow [AB-PROTOCOL.md](AB-PROTOCOL.md) and [scenarios/long-session-awareness.md](scenarios/long-session-awareness.md).

Pre-register:

```bash
bash eval/metrics/pre-register.sh long-session-awareness
```

Target: **N ≥ 3** interactive sessions per arm (ON with hooks, OFF with `'{"hooks":{}}'` — never `--bare`).

| Arm | Runs completed | Compaction observed? | Late-step anchors correct? |
|-----|----------------|----------------------|----------------------------|
| ON | 0/3 | — | — |
| OFF | 0/3 | — | — |

Pre-registered: `eval/metrics/runs/20260623T012738Z-long-session-awareness/hypothesis.md` (2026-06-23). **Interactive runs not executed** — requires ~6 multi-hour Claude sessions; cannot be automated in one agent turn.

Interpretation (pre-registered before reading results): ___

---

## 5. PreCompact live-fire ([#146](https://github.com/LazyIsEfficient/agentic-os/issues/146))

In a long **interactive** session with hooks ON, trigger compaction (auto or manual `/compact`). Confirm `.claude/session-state.checkpoints` or `.cursor/session-state.checkpoints` gains a line with `trigger=auto` or `trigger=manual`.

| Date | Platform | Trigger | Checkpoint line present? |
|------|----------|---------|--------------------------|
| | | | [ ] |

---

## 6. Dogfood warn log (#145 evidence)

Hooks ON for normal dev. Review `.claude/survey-guard.warns` / `.cursor/survey-guard.warns` after ≥2 weeks or ≥20 provisioning-adjacent sessions.

| Window start | Window end | True warns | False positives | Ready for deny flip? |
|--------------|------------|------------|-----------------|----------------------|
| | | | | [ ] no — keep warn-first |

Reset log at window start (optional): `rm -f .claude/survey-guard.warns .cursor/survey-guard.warns`

---

## 7. Close v2 milestone

When 1–5 are done (6 is ongoing / #145 stays open):

- [ ] Comment on [#145](https://github.com/LazyIsEfficient/agentic-os/issues/145) with warn-log summary
- [ ] Close v2 milestone on GitHub (leave #145 open or re-milestone to “ratchet”)
- [ ] Update V2_ROADMAP.md status to **complete** (optional doc PR)

---

## Explicitly out of scope for v2 closeout

- Survey **deny** flip (#145) — blocked on evidence
- Active shipped `settings.json` / `hooks.json` on install — security-gated, not v2
- PostCompact full re-inject — unscheduled enhancement

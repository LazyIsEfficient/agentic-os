# Operating rules for this repo

This repo is a skills + agents library. Work here is rarely a single edit — it is research, planning, and dispatch across many specialists. Two capabilities make that tractable: **persistent memory** and **subagents**. Use them aggressively and correctly.

## Awareness harness (opt-in)

This repo dogfoods the v2 awareness harness (session-state + survey-before-act). Hook scripts ship dormant on install; activation is **project-level** — see [docs/awareness-harness-activation.md](docs/awareness-harness-activation.md). v2 operator checklist: [eval/metrics/V2-CLOSEOUT.md](eval/metrics/V2-CLOSEOUT.md).

The doctrine is split into focused rule files under `.cursor/rules/`, imported below. Edit those files, not this list. (These imports are repo-local editing ergonomics; `install-cursor.sh` never ships `CURSOR.md` or `rules/` to consumers.)

@.cursor/rules/factual-correctness.md
@.cursor/rules/memory-discipline.md
@.cursor/rules/subagent-dispatch.md
@.cursor/rules/grounding.md
@.cursor/rules/review-tiers.md
@.cursor/rules/verification.md
@.cursor/rules/communication.md

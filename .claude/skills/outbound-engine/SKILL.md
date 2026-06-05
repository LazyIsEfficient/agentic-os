---
name: outbound-engine
description: Design, analyze, and optimize cold outbound email campaigns using your outbound platform. Handles end-to-end ICP definition, expert panel scoring (recursive to 90+), sequence copywriting, infrastructure audit, capacity planning, and implementation docs. Use when asked to build cold outbound sequences, optimize cold email, analyze outbound campaigns, build sales sequences, create cold outbound strategies, or design email campaigns. Supports both "start from scratch" and "optimize existing" modes.
when_to_use: |
  Use when asked to build cold outbound email sequences from scratch, optimize existing cold email campaigns, audit outbound infrastructure (sending accounts, warmup scores, domain inventory), define or refine ICP parameters, score email copy with a recursive expert panel, or generate capacity math and weekly metrics targets for an outbound motion.

  Not when: the request is about general marketing campaign planning — use `marketing-shaper` to scope it first.
---

# Outbound Engine

End-to-end cold outbound: ICP definition, expert panel copy scoring (recursive to 90+), infrastructure audit, capacity planning, and implementation docs.

## Core Rules

1. Determine mode first (existing account with API key, or starting from scratch) before any other step.
2. Run the three-phase workflow: Discovery & Audit → Expert Panel Recursive Scoring → Deliverables.
3. Expert panel scoring target is 90/100 — non-negotiable. Iterate until reached.
4. Show every scoring round in the final doc — the iteration trail is part of the value.
5. Never push anything to the outbound platform automatically — the strategy doc is for human review first.
6. Use capacity math to set realistic volume and pipeline projections.

## Reference Files

| File | Purpose |
|------|---------|
| `references/workflow.md` | Full three-phase workflow with scoring criteria |
| `references/capacity-math.md` | Capacity formula, weekly metrics targets, add-on recommendations |
| `references/instantly-rules.md` | Variable syntax, sequence structure, deliverability rules |
| `references/expert-panel.md` | Default 10-expert roster with scoring lenses |
| `references/copy-rules.md` | Email copy rules (first sentence, CTA, stats framing) |
| `references/icp-template.md` | ICP data collection template |
| `scripts/instantly-audit.py` | Pulls campaigns, accounts, warmup scores via outbound platform API |
| `scripts/lead-pipeline.py` | End-to-end lead sourcing pipeline |
| `scripts/competitive-monitor.py` | Competitor tracking and intelligence |
| `scripts/cross-signal-detector.py` | Multi-source signal detection |
| `scripts/cold-outbound-sender.py` | Send approved outbound emails |

---
name: team-ops
description: >-
  AI-powered team performance auditing: ruthless performance audits using the
  Elon Algorithm (question, delete, simplify, accelerate, automate), composite
  scoring on output velocity, quality, independence, and initiative, and A/B/C
  stack ranking with promote/coach/reassign/exit recommendations. Use when asked
  to evaluate team performance against OKRs/KPIs, stack rank team members, or
  generate individual performance scorecards. For meeting transcript and action-
  item extraction see meeting-intelligence.
when_to_use: |
  Use when evaluating team performance against OKRs/KPIs with a structured
  five-step framework (question requirements, delete redundancies, simplify
  workflows, accelerate bottlenecks, automate), stack ranking team members to
  identify A/B/C players, or generating individual scorecards with recommended
  actions (promote, retain, coach, reassign, exit).

  Not when: the task is parsing meeting transcripts or extracting action items,
  decisions, and follow-ups — use
  [meeting-intelligence](../meeting-intelligence/SKILL.md) instead. Not when the
  analysis requires financial modeling, headcount budgeting, or compensation
  planning — use [finance-ops](../finance-ops/SKILL.md).
---

# AI Team Ops

AI-powered team performance auditing: ruthless performance audits using the "Elon Algorithm" — question every requirement, delete redundancy, simplify workflows, accelerate bottlenecks, and flag automation opportunities — plus quantitative scoring and A/B/C stack ranking.

## Tool

| Script | Purpose | Key Command |
|--------|---------|-------------|
| `team_performance_audit.py` | Elon Algorithm: 5-step team audit + stack rank + scorecards | `python3 team_performance_audit.py --input team_data.json --output report.md` |

See [references/data-flow.md](references/data-flow.md) for the full data-flow diagram.

## What it does

- Ingests role descriptions, OKRs/KPIs, and output data (CSV or JSON)
- Scores each person on four dimensions: output velocity, quality, independence, initiative
- Computes a weighted composite score and assigns A/B/C tier labels
- Runs the 5-step Elon Algorithm via LLM for qualitative organizational analysis
- Generates recommended actions: promote, retain, coach, reassign, exit
- Outputs an executive summary + individual scorecards + org-level recommendations

```bash
# JSON input → markdown report
python3 team_performance_audit.py --input team_data.json --output report.md

# CSV input
python3 team_performance_audit.py --input team_data.csv --output report.md

# JSON output
python3 team_performance_audit.py --input team_data.json --format json --output report.json

# Dry run (quantitative scoring only, no LLM calls)
python3 team_performance_audit.py --input team_data.json --dry-run
```

## Configuration

Copy `.env.example` to `.env` and fill in:

- `ANTHROPIC_API_KEY` — Claude for the Elon Algorithm analysis (required unless using OpenAI)
- `OPENAI_API_KEY` — alternative LLM provider (required if `LLM_PROVIDER=openai`)
- `LLM_PROVIDER` — `anthropic` (default) or `openai`
- `LLM_MODEL` — model name override (default: `claude-sonnet-4-5` for Anthropic, `gpt-4o` for OpenAI)

Without an LLM key, quantitative scoring and stack ranking still run; only the qualitative Elon Algorithm analysis is skipped (or use `--dry-run`).

## Dependencies

- Python 3.9+
- `anthropic` or `openai` (for the LLM-powered qualitative analysis)

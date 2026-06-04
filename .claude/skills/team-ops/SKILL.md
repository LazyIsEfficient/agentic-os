---
name: team-ops
description: >-
  AI-powered team performance analysis and meeting intelligence: performance
  audits using the Elon Algorithm (question, delete, simplify, accelerate,
  automate), stack ranking, and automatic extraction of action items, decisions,
  and follow-ups from meeting transcripts. Use when asked to evaluate team
  performance, stack rank team members, extract meeting action items, or push
  meeting tasks to CRM. For financial team analysis see finance-ops.
when_to_use: |
  Use when evaluating team performance against OKRs/KPIs with a structured
  five-step framework (question requirements, delete redundancies, simplify
  workflows, accelerate bottlenecks, automate), stack ranking team members to
  identify A/B/C players, extracting action items and decisions from meeting
  transcripts, processing batch meeting notes into structured follow-up lists,
  or pushing meeting action items to a CRM as tasks.

  Not when: the analysis requires financial modeling, headcount budgeting, or
  compensation planning — use [finance-ops](../finance-ops/SKILL.md) instead.
---

# AI Team Ops

AI-powered team performance analysis and meeting intelligence: ruthless performance audits using the "Elon Algorithm" + automatic extraction of action items, decisions, and follow-ups from meeting transcripts.

## Preamble (runs on skill start)

```bash
python3 telemetry/version_check.py 2>/dev/null || true
python3 telemetry/telemetry_init.py 2>/dev/null || true
```

> **Privacy:** Logs usage locally to `~/.ai-marketing-skills/analytics/`. Remote telemetry is opt-in only. No code, file paths, or repo content ever collected.

## Tools

| Script | Purpose | Key Command |
|--------|---------|-------------|
| `team_performance_audit.py` | Elon Algorithm: 5-step team audit + stack rank + scorecards | `python3 team_performance_audit.py --input team_data.json --output report.md` |
| `meeting_action_extractor.py` | Extract decisions, actions, follow-ups from transcripts | `python3 meeting_action_extractor.py --transcript meeting.txt --format markdown` |

See [references/data-flow.md](references/data-flow.md) for the full data flow diagrams for both tools.

## Configuration

Copy `.env.example` to `.env` and fill in:

- `ANTHROPIC_API_KEY` — Claude for analysis (required)
- `OPENAI_API_KEY` — alternative LLM provider (required if using OpenAI)
- `CRM_API_KEY` — for pushing meeting action items as tasks (optional; e.g. HubSpot private app token)
- `LLM_PROVIDER` — `anthropic` (default) or `openai`
- `LLM_MODEL` — model name override (default: `claude-sonnet-4-20250514` or `gpt-4o`)

## Dependencies

- Python 3.9+
- `anthropic` or `openai` (for LLM-powered analysis)
- `requests` (for optional CRM integration)

---
name: meeting-intelligence
description: >-
  AI-powered meeting intelligence: parse meeting transcripts and extract
  structured decisions, action items (owner + deadline + priority), open
  questions, key insights, and follow-up meetings — including implicit
  commitments — with confidence scores, then optionally push action items to
  HubSpot as tasks. Use when asked to extract action items from a meeting,
  summarize decisions from a transcript, turn meeting notes into a follow-up
  list, batch-process a directory of transcripts, or sync meeting tasks to a
  CRM. For team-performance evaluation and stack ranking see team-ops.
when_to_use: |
  Use when extracting action items, decisions, open questions, and follow-ups
  from one or more meeting transcripts (file, stdin, or a batch directory),
  capturing implicit commitments as tracked action items, turning raw meeting
  notes into structured Markdown or JSON, or pushing extracted action items to
  HubSpot as CRM tasks.

  Not when: the task is team-performance evaluation, stack ranking, or A/B/C
  scorecards — use [team-ops](../team-ops/SKILL.md) instead. Not when the task
  is financial modeling or headcount budgeting — use
  [finance-ops](../finance-ops/SKILL.md).
---

# Meeting Intelligence

Turn meeting transcripts into structured, trackable output. Feed it a transcript; get back decisions (with who drove them), action items (owner + deadline + priority), open questions, key insights, and follow-up meetings — each with a confidence score. It catches implicit commitments ("I'll look into that") that humans miss, and can push action items straight to HubSpot as tasks.

## Tool

| Script | Purpose | Key Command |
|--------|---------|-------------|
| `meeting_action_extractor.py` | Extract decisions, actions, follow-ups, insights from transcripts | `python3 meeting_action_extractor.py --transcript meeting.txt --format markdown` |

See [references/data-flow.md](references/data-flow.md) for the full data-flow diagram.

## Usage

```bash
# Single transcript → markdown (default)
python3 meeting_action_extractor.py --transcript meeting.txt

# Single transcript → JSON
python3 meeting_action_extractor.py --transcript meeting.txt --format json

# Read from stdin (paste or pipe)
cat meeting.txt | python3 meeting_action_extractor.py --stdin

# Batch process a directory of transcripts (.txt/.md/.json)
python3 meeting_action_extractor.py --batch ./transcripts/ --output ./actions/

# Push extracted action items to HubSpot as tasks
python3 meeting_action_extractor.py --transcript meeting.txt --push-hubspot

# Dry run (no LLM calls; shows what would be processed)
python3 meeting_action_extractor.py --transcript meeting.txt --dry-run
```

## What it extracts

- **Decisions** — what was decided, who drove it, brief context.
- **Action items** — specific task, owner, deadline (if stated), priority (high/medium/low), and the source quote. Implicit commitments are flagged `is_implicit`.
- **Open questions** — raised but unresolved in the transcript.
- **Key insights** — notable observations or quotable moments, attributed to a speaker.
- **Follow-up meetings** — topics needing a dedicated session, with suggested attendees.
- **Confidence scores** — `1.0` = explicitly stated, `0.8` = strongly implied, `0.5–0.7` = inferred. Missing an action item is treated as worse than surfacing a low-confidence one.

## Configuration

Copy `.env.example` to `.env` and fill in:

- `ANTHROPIC_API_KEY` — Claude for extraction (required unless using OpenAI)
- `OPENAI_API_KEY` — alternative LLM provider (required if `LLM_PROVIDER=openai`)
- `HUBSPOT_API_KEY` — HubSpot private-app token, only for `--push-hubspot` (optional)
- `LLM_PROVIDER` — `anthropic` (default) or `openai`
- `LLM_MODEL` — model name override (default: `claude-sonnet-4-5` for Anthropic, `gpt-4o` for OpenAI)

Without an LLM key the extractor returns an empty structured result with an `_error` notice rather than failing.

## Dependencies

- Python 3.9+
- `anthropic` or `openai` (for LLM-powered extraction)
- `requests` (only needed for `--push-hubspot`)

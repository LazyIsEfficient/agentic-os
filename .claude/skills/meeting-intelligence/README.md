# 📋 Meeting Intelligence

> **Never lose an action item again.** Feed it meeting transcripts; get structured decisions, action items, follow-ups, and insights.

An LLM-powered meeting transcript processor that extracts decisions, action items (with owner and deadline), open questions, key insights, and follow-up meetings — including the implicit commitments people make and then forget. Optionally pushes action items to HubSpot as tasks.

For team-performance audits and stack ranking, see [team-ops](../team-ops/SKILL.md). For financial analysis, see [finance-ops](../finance-ops/SKILL.md).

---

## Architecture

```
                    ┌──────────────────────────────────────┐
                    │     MEETING ACTION EXTRACTOR          │
                    └──────────────┬───────────────────────┘
                                   │
                    Meeting Transcripts (text / stdin / batch)
                                   │
                    ┌──────────────▼───────────────────────┐
                    │  LLM Extraction Engine                │
                    │                                       │
                    │  • Decisions (who + context)          │
                    │  • Action Items (owner + deadline)    │
                    │  • Open Questions                     │
                    │  • Key Insights / Quotes              │
                    │  • Follow-up Meetings                 │
                    │  • Implicit Commitments               │
                    │  + Confidence Scores                  │
                    └──────────────┬───────────────────────┘
                                   │
                    ┌──────────────▼───────────────────────┐
                    │  Output                               │
                    │  • Structured JSON                    │
                    │  • Formatted Markdown                 │
                    │  • HubSpot Tasks (optional)           │
                    └───────────────────────────────────────┘
```

See [references/data-flow.md](references/data-flow.md) for the detailed data flow.

---

## What it does

- Extracts decisions with who made them and context
- Identifies action items with owner, deadline, and priority
- Catches implicit commitments ("I'll take care of that" → action item)
- Flags open questions and unresolved items
- Pulls out key insights and quotable moments
- Identifies follow-up meetings needed
- Assigns confidence scores (1.0 = explicit, 0.5 = inferred)
- Supports batch processing of entire transcript directories
- Optional HubSpot integration to push action items as tasks

```bash
# Single transcript → markdown
python3 meeting_action_extractor.py --transcript meeting.txt

# Single transcript → JSON
python3 meeting_action_extractor.py --transcript meeting.txt --format json

# Read from stdin (paste or pipe)
cat meeting.txt | python3 meeting_action_extractor.py --stdin

# Batch process a directory
python3 meeting_action_extractor.py --batch ./transcripts/ --output ./actions/

# Push action items to HubSpot
python3 meeting_action_extractor.py --transcript meeting.txt --push-hubspot

# Dry run
python3 meeting_action_extractor.py --transcript meeting.txt --dry-run
```

**Example Output (Markdown):**

```markdown
## Action Items

1. 🔴 **Finalize Q2 budget proposal**
   - Owner: **Sarah**
   - Deadline: Friday March 15
   - Confidence: 95%
   - Source: "Sarah, can you get the Q2 budget finalized by Friday?"

2. 🟡 **Look into the API latency issue** *(implicit)*
   - Owner: **Mike**
   - Deadline: No deadline
   - Confidence: 80%
   - Source: "Yeah, I'll look into that"
```

---

## Quick Start

### 1. Install

```bash
git clone https://github.com/your-org/skills-db.git
cd skills-db/.claude/skills/meeting-intelligence
pip install -r requirements.txt
```

### 2. Configure environment

```bash
cp .env.example .env

# Set at least one LLM provider
export ANTHROPIC_API_KEY="sk-ant-..."
# OR
export OPENAI_API_KEY="sk-..."

# Optional: HubSpot for meeting action push
export HUBSPOT_API_KEY="pat-..."

# Optional: Override LLM settings
export LLM_PROVIDER="anthropic"        # or "openai"
export LLM_MODEL="claude-sonnet-4-5"   # or "gpt-4o"
```

### 3. Test with a dry run

```bash
python3 meeting_action_extractor.py --transcript sample_meeting.txt --dry-run
```

### 4. Run for real

```bash
# Extract actions from today's meeting
python3 meeting_action_extractor.py --transcript standup.txt --format markdown

# Batch process last week's meetings
python3 meeting_action_extractor.py --batch ./weekly_transcripts/ --output ./weekly_actions/
```

---

## Integrations

| Tool | Required | Used For |
|------|----------|----------|
| [Anthropic](https://anthropic.com) | One LLM required | Extraction |
| [OpenAI](https://openai.com) | One LLM required | Extraction |
| [HubSpot](https://hubspot.com) | Optional | Task push (`--push-hubspot`) |

The HubSpot push uses the CRM v3 Tasks API (`POST /crm/v3/objects/tasks`) with a private-app token from `HUBSPOT_API_KEY`.

---

## File Structure

```
meeting-intelligence/
├── README.md                       # This file
├── SKILL.md                        # Claude Code skill definition
├── requirements.txt                # Python dependencies
├── .env.example                    # Environment variable template
├── meeting_action_extractor.py     # Meeting transcript → action items
└── references/
    └── data-flow.md                # Data flow diagram
```

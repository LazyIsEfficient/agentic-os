# 👥 AI Team Ops

> **Run your team like an engineer runs a system — measure everything, cut waste, ship faster.**

A structured team performance audit framework (the "Elon Algorithm") that scores every team member, stack ranks them into A/B/C tiers, and surfaces the redundancy, complexity, and bottlenecks holding the org back.

Built for operators who want data-driven team decisions, not vibes-based management.

For turning meeting transcripts into tracked action items and decisions, see [meeting-intelligence](../meeting-intelligence/SKILL.md). For financial analysis, see [finance-ops](../finance-ops/SKILL.md).

---

## Architecture

```
                    ┌──────────────────────────────────────┐
                    │     TEAM PERFORMANCE AUDIT            │
                    │     ("Elon Algorithm")                │
                    └──────────────┬───────────────────────┘
                                   │
          ┌────────────────────────┼────────────────────────┐
          │                        │                        │
    Role Descriptions        OKRs / KPIs            Output Data
    (who does what)      (what they should hit)   (what they actually did)
          │                        │                        │
          └────────────────────────┼────────────────────────┘
                                   │
                    ┌──────────────▼───────────────────────┐
                    │  5-Step Elon Algorithm                │
                    │                                       │
                    │  1. Question — is this necessary?     │
                    │  2. Delete — flag redundancies        │
                    │  3. Simplify — cut complexity         │
                    │  4. Accelerate — find bottlenecks     │
                    │  5. Automate — what can AI handle?    │
                    └──────────────┬───────────────────────┘
                                   │
                    ┌──────────────▼───────────────────────┐
                    │  Scoring Engine                       │
                    │  • Output Velocity (30%)              │
                    │  • Quality (30%)                      │
                    │  • Independence (20%)                 │
                    │  • Initiative (20%)                   │
                    │                                       │
                    │  → A/B/C Stack Rank                   │
                    │  → Promote / Coach / Reassign / Exit  │
                    └───────────────────────────────────────┘
                                   │
                                   ▼
                    Executive Summary + Scorecards + Org Recommendations
```

See [references/data-flow.md](references/data-flow.md) for the detailed data flow.

---

## Tool: Team Performance Audit (`team_performance_audit.py`)

The "Elon Algorithm" applied to team management. A 5-step framework that questions every role, deletes redundancy, simplifies workflows, accelerates bottlenecks, and flags automation opportunities.

**What it does:**
- Ingests role descriptions, OKRs/KPIs, and output data (CSV or JSON)
- Scores each person on 4 dimensions: output velocity, quality, independence, initiative
- Computes a weighted composite score and assigns A/B/C tier labels
- Runs the 5-step Elon Algorithm via LLM for qualitative organizational analysis
- Generates recommended actions: promote, retain, coach, reassign, exit
- Outputs executive summary + individual scorecards + org-level recommendations

```bash
# Run with JSON input
python3 team_performance_audit.py --input team_data.json --output report.md

# Run with CSV input
python3 team_performance_audit.py --input team_data.csv --output report.md

# JSON output
python3 team_performance_audit.py --input team_data.json --format json --output report.json

# Dry run (quantitative only, no LLM calls)
python3 team_performance_audit.py --input team_data.json --dry-run

# Custom scoring weights
python3 team_performance_audit.py --input team_data.json \
  --weights '{"output_velocity":0.4,"quality":0.3,"independence":0.15,"initiative":0.15}'
```

**JSON Input Format:**
```json
{
  "team_members": [
    {
      "name": "Alice Chen",
      "role": "Senior Engineer",
      "role_description": "Owns backend API development",
      "okrs": [
        {"objective": "Reduce API latency", "key_result": "P95 < 200ms", "progress": 0.85}
      ],
      "metrics": {
        "tasks_completed": 47,
        "tasks_assigned": 52,
        "avg_completion_days": 3.2,
        "quality_score": 92,
        "peer_feedback_score": 4.5,
        "initiatives_proposed": 3,
        "initiatives_shipped": 2
      },
      "deliverables": [
        {"name": "API v2 Migration", "status": "completed", "date": "2024-02-15"}
      ]
    }
  ],
  "org_context": {
    "company_goals": ["Ship v3 by Q2", "Reduce infra costs 30%"],
    "team_size": 12,
    "evaluation_period": "Q1 2024"
  }
}
```

**CSV Input Format:**
```csv
name,role,tasks_completed,tasks_assigned,avg_completion_days,quality_score,peer_feedback_score,initiatives_proposed,initiatives_shipped
Alice Chen,Senior Engineer,47,52,3.2,92,4.5,3,2
Bob Park,Junior Dev,28,40,5.1,68,3.2,0,0
```

**Scoring Dimensions:**

| Dimension | Weight | What It Measures |
|-----------|--------|-----------------|
| Output Velocity | 30% | Task completion rate + speed |
| Quality | 30% | Deliverable quality + peer feedback |
| Independence | 20% | Self-direction, low management overhead |
| Initiative | 20% | Proactive contributions beyond assigned work |

**Tier Labels:**

| Tier | Score | Meaning |
|------|-------|---------|
| 🟢 A-Player | 80+ | Top performer. Promote or retain aggressively. |
| 🟡 B-Player | 55-79 | Solid contributor. Coach to A or maintain. |
| 🔴 C-Player | <55 | Underperforming. Reassign, PIP, or exit. |

---

## Quick Start

### 1. Clone and install

```bash
git clone https://github.com/your-org/skills-db.git
cd skills-db/.claude/skills/team-ops
pip install -r requirements.txt
```

### 2. Configure environment

```bash
cp .env.example .env

# Set at least one LLM provider
export ANTHROPIC_API_KEY="sk-ant-..."
# OR
export OPENAI_API_KEY="sk-..."

# Optional: Override LLM settings
export LLM_PROVIDER="anthropic"        # or "openai"
export LLM_MODEL="claude-sonnet-4-5"   # or "gpt-4o"
```

### 3. Test with a dry run

```bash
# Quantitative scoring only — no LLM calls
python3 team_performance_audit.py --input sample_team.json --dry-run
```

### 4. Run for real

```bash
# Full team audit
python3 team_performance_audit.py --input team_data.json --output q1_audit.md
```

---

## Integrations

| Tool | Required | Used For |
|------|----------|----------|
| [Anthropic](https://anthropic.com) | One LLM required | Elon Algorithm analysis |
| [OpenAI](https://openai.com) | One LLM required | Elon Algorithm analysis |

The quantitative scoring and stack ranking run locally without any LLM key; only the qualitative 5-step analysis needs a provider.

---

## File Structure

```
team-ops/
├── README.md                       # This file
├── SKILL.md                        # Claude Code skill definition
├── requirements.txt                # Python dependencies
├── .env.example                    # Environment variable template
├── team_performance_audit.py       # Elon Algorithm team audit
└── references/
    └── data-flow.md                # Data flow diagram
```

---

## How To Use It

Run the audit quarterly. It gives you the big picture: who's performing, who isn't, and where the org is inefficient. Pair it with [meeting-intelligence](../meeting-intelligence/SKILL.md) to track the day-to-day execution of the changes the audit recommends.

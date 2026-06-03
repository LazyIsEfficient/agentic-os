---
name: finance-ops
description: "AI-powered financial analysis suite. Generates executive CFO briefings from QuickBooks exports (P&L, Balance Sheet, General Ledger, Cash Flow, etc.) with anomaly detection, burn rate, runway analysis, and scenario modeling. Also estimates codebase development costs with organizational overhead and AI ROI analysis. Triggers on: 'CFO briefing', 'financial analysis', 'cost briefing', 'expense review', 'runway analysis', 'burn rate', 'cost estimate', 'how much would this cost to build', 'development cost', 'Claude ROI'."
when_to_use: |
  Use when generating an executive CFO briefing from QuickBooks exports (P&L, Balance Sheet,
  General Ledger, Cash Flow), performing burn rate or runway analysis, modeling base/bull/bear
  financial scenarios, or estimating full development cost of a codebase including organisational
  overhead and AI ROI. Triggers on "CFO briefing", "financial analysis", "expense review",
  "runway analysis", "burn rate", "cost estimate", "how much would this cost to build",
  "development cost", or "Claude ROI".

  Not when: the task is game-studio-level revenue forecasting or LTV/ARPDAU strategy — use
  `game-monetization-strategist` for that. Not when the task is general business intelligence
  dashboards — this skill processes QuickBooks exports specifically.
---

# AI Finance Ops

Two tools: CFO Briefing Generator and Codebase Cost Estimator.

---

## Tool 1: CFO Briefing Generator

Generate executive financial summaries from QuickBooks exports.

### Workflow

1. **Ingest files** — Place QB exports (CSV, XLSX) in a working directory. Accepted: P&L Summary (most important), P&L by Customer, P&L Detail, Balance Sheet, General Ledger, Expenses by Vendor, Transaction List by Vendor, Bill Payments, Cash Flow Statement, Account List.

2. **Run analysis:**
   ```bash
   python3 scripts/cfo-analyzer.py --input ./data/uploads/ [--period YYYY-MM]
   ```
   Options: `--history DIR` for MoM comparison, `--no-history` to skip saving. See `references/quickbooks-formats.md` for file format details.

3. **Scenario modeling (optional):**
   ```bash
   python3 scripts/scenario-modeler.py --input ./data/financial-latest.json
   ```
   Generates 12-month base/bull/bear projections.

4. **Deliver** — Script outputs formatted briefing with 🟢🟡🔴 status indicators for Slack, email, or any messaging surface.

See `references/metrics-guide.md` for KPI definitions, healthy ranges, and red/yellow/green thresholds.

---

## Tool 2: Codebase Cost Estimator

Estimate full development cost of a codebase.

### Steps

1. Analyze the codebase — catalog LOC by language, architectural complexity, features, test coverage, docs quality.
2. Calculate dev hours — apply productivity rates from `references/rates.md`; add overhead multipliers for architecture, debugging, review, docs, integration.
3. Research market rates — web search for current hourly rates for the relevant tech stack; build low/median/high rate table.
4. Calculate org overhead — convert raw hours to calendar time using `references/org-overhead.md`; show across company types.
5. Calculate full team cost — apply supporting role ratios from `references/team-cost.md`; role-by-role breakdown across company stages.
6. Generate estimate — use template in `references/output-template.md`; include codebase metrics, dev hours, calendar time, market rates, engineering cost, full team cost, grand total, assumptions.
7. **AI ROI (optional)** — if built with AI assistance, calculate value per AI hour using `references/claude-roi.md`.

### Key Principles

- Always show ranges (low/avg/high), never a single number
- Include confidence level and key assumptions
- Search for CURRENT year market rates — don't use stale data
- Present professionally, suitable for stakeholders

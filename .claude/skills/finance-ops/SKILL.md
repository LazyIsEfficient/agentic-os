---
name: finance-ops
description: "Run CFO briefings from QuickBooks/CSV accounting exports: financial reporting, profitability and people-cost breakdowns, burn-rate and runway analysis, and base/bull/bear scenario modeling. Use for an executive financial briefing, expense/vendor review, or cash-runway analysis from accounting data. For estimating the development cost of a codebase (LOC-based build cost) see codebase-cost-estimator."
when_to_use: |
  Use when generating an executive CFO briefing from QuickBooks exports (P&L, Balance Sheet,
  General Ledger, Cash Flow), performing burn rate or runway analysis, reviewing expenses and
  vendor concentration, or modeling base/bull/bear financial scenarios. Triggers on
  "CFO briefing", "financial analysis", "expense review", "vendor concentration", "runway
  analysis", "burn rate", or "scenario model".

  Not when: the task is estimating the development/build cost of a codebase — LOC-based
  engineering hours, calendar time, full-team cost, or Claude/AI ROI on delivered code — use
  [codebase-cost-estimator](../codebase-cost-estimator/SKILL.md) instead. Not when the task is
  game-studio-level revenue forecasting or LTV/ARPDAU strategy — use
  `game-monetization-strategist`. Not when the task is general business intelligence
  dashboards — this skill processes QuickBooks exports specifically. Not when the task is
  team-performance evaluation or meeting action items — use `team-ops`.
---

# AI Finance Ops

Generate executive CFO briefings from QuickBooks/CSV accounting exports — profitability, people
cost, vendor and customer concentration, burn rate, runway, and forward scenarios.

## CFO Briefing Generator

Generate executive financial summaries from QuickBooks exports.

### Workflow

1. **Ingest files** — Place QB exports (CSV, XLSX) in a working directory. Accepted: P&L Summary (most important), P&L by Customer, P&L Detail, Balance Sheet, General Ledger, Expenses by Vendor, Transaction List by Vendor, Bill Payments, Cash Flow Statement, Account List.

2. **Run analysis:**
   ```bash
   # Scripts live at .claude/skills/finance-ops/scripts/ — copy to your project root or run from the skill directory
   python3 scripts/cfo-analyzer.py --input ./data/uploads/ [--period YYYY-MM]
   ```
   Options: `--history DIR` for MoM comparison, `--no-history` to skip saving. See `references/quickbooks-formats.md` for file format details.

3. **Scenario modeling (optional):**
   ```bash
   # Scripts live at .claude/skills/finance-ops/scripts/ — copy to your project root or run from the skill directory
   python3 scripts/scenario-modeler.py --input ./data/financial-latest.json
   ```
   Generates 12-month base/bull/bear projections.

4. **Deliver** — Script outputs formatted briefing with 🟢🟡🔴 status indicators for Slack, email, or any messaging surface.

See `references/metrics-guide.md` for KPI definitions, healthy ranges, and red/yellow/green thresholds.

## References

- `references/quickbooks-formats.md` — QuickBooks export format specs and parsing rules
- `references/metrics-guide.md` — KPI thresholds and benchmarks by revenue range

## Related

For estimating the development cost of a codebase (LOC-based engineering hours, calendar time,
full-team cost, AI ROI), see [`codebase-cost-estimator`](../codebase-cost-estimator/SKILL.md).

---
name: revenue-intelligence
description: >-
  AI-powered revenue intelligence: sales call insight extraction, content-to-revenue
  attribution, and multi-source client reporting. Use when asked to analyze sales
  calls, build revenue attribution models, or generate client reports. For sales
  pipeline automation see sales-pipeline; for pricing strategy see sales-playbook.
when_to_use: |
  Use when extracting structured insights from Gong sales call transcripts (objections, buying signals, competitive mentions), proving content ROI by mapping content pieces to pipeline and closed revenue, generating unified client reports from GA4 + HubSpot + Ahrefs + Gong, identifying content gaps in the buyer journey, or detecting anomalies across marketing metrics.

  Not when: the request is about automating the sales pipeline from website visitor identification — use `sales-pipeline` instead. Not when the request is about pricing strategy or deal structuring — use `sales-playbook`.
---

# Revenue Intelligence

AI-powered revenue intelligence: sales call insight extraction, content-to-revenue attribution, and multi-source client reporting.

## Preamble (runs on skill start)

```bash
# Version check (silent if up to date)
python3 telemetry/version_check.py 2>/dev/null || true

# Telemetry opt-in (first run only, then remembers your choice)
python3 telemetry/telemetry_init.py 2>/dev/null || true
```

> **Privacy:** This skill logs usage locally to `~/.ai-marketing-skills/analytics/`. Remote telemetry is opt-in only. No code, file paths, or repo content is ever collected. See `telemetry/README.md`.

## Core Tools

| Tool | Purpose |
|------|---------|
| `gong_insight_pipeline.py` | Extract objections, buying signals, and competitive mentions from call transcripts |
| `revenue_attribution.py` | Map content to closed revenue with first-touch, linear, and time-decay models |
| `client_report_generator.py` | Generate unified GA4 + HubSpot + Ahrefs + Gong client reports |

## References

- [references/tool-reference.md](references/tool-reference.md) — full CLI flags and output specifications for all three tools
- [references/configuration.md](references/configuration.md) — environment variables, data flow, recommended workflow, and dependencies

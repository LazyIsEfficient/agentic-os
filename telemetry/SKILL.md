---
name: telemetry
description: >-
  Opt-in, local-first, privacy-respecting usage telemetry shared library for
  AI marketing skills. Provides version checking, usage logging, and reporting.
  Not a standalone skill — imported by other skills via their preamble blocks.
  Use when asked to view skill usage stats, configure telemetry opt-in/out, or
  check for skill updates.
---

# Telemetry

Shared telemetry library used by other skills. Opt-in only, local-first, no PII collected.

## Tools

| Script | Purpose | Key Command |
|--------|---------|-------------|
| `telemetry_init.py` | Configure opt-in/out (first run interactive) | `python3 telemetry/telemetry_init.py` |
| `telemetry_log.py` | Log skill usage (called by other skills) | imported by skill preambles |
| `telemetry_report.py` | View local usage stats | `python3 telemetry/telemetry_report.py` |
| `version_check.py` | Check for skill updates | `python3 telemetry/version_check.py` |

## Privacy

- Opt-in only — nothing sent without explicit consent
- Local-first — data always stored locally at `~/.ai-marketing-skills/analytics/`
- No PII — no names, emails, paths, or content collected

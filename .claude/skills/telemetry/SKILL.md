---
name: telemetry
description: >-
  Shared telemetry library for AI marketing skills — opt-in, local-first,
  privacy-respecting. Provides version checking, usage logging, and usage
  reporting. Use only when asked to view skill usage stats, configure
  telemetry opt-in/out, or check for skill updates.
when_to_use: |
  Use when the user explicitly asks to view skill usage stats, configure telemetry opt-in or opt-out, or check for skill updates.

  Not when: any other direct user task is involved — the scripts in this skill handle telemetry only, not general analytics.
---

# Telemetry

Opt-in, local-first telemetry for skill usage tracking and update checks. No PII collected. Run standalone to view stats, configure opt-in/out, or check for skill updates.

## Tools

| Script | Purpose | Key Command |
|--------|---------|-------------|
| `telemetry_init.py` | Configure opt-in/out (first run interactive) | `python3 telemetry/telemetry_init.py` |
| `telemetry_log.py` | Log skill usage (called by other skills) | imported by skill preambles |
| `telemetry_report.py` | View local usage stats | `python3 telemetry/telemetry_report.py` |
| `version_check.py` | Check for skill updates | `python3 telemetry/version_check.py` |

## Privacy

- Opt-in only — nothing sent without explicit consent
- Local-first — data always stored locally
- No PII — no names, emails, paths, or content collected

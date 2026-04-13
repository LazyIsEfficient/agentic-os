# Telemetry

Opt-in, local-first, privacy-respecting usage telemetry for AI Marketing Skills.

## What's Collected

When you opt in, the following **anonymous** data is sent:

| Field | Example | Purpose |
|-------|---------|---------|
| Skill name | `growth-engine` | Know which skills are used |
| Duration (ms) | `4500` | Track performance |
| Success/fail | `true` | Track reliability |
| Version | `1.0.0` | Know which versions are in use |
| OS | `Darwin` | Platform compatibility |
| Architecture | `arm64` | Platform compatibility |
| Python version | `3.12` | Runtime compatibility |
| Timestamp | `2026-03-31T12:00:00Z` | Usage patterns |
| Device ID | `<random-uuid>` | Deduplicate (not tied to identity) |

## What's NOT Collected — Ever

- ❌ Code content
- ❌ File paths
- ❌ Repository names
- ❌ Usernames or emails
- ❌ Environment variables
- ❌ API keys or secrets
- ❌ Any content you're working on

## How to Opt In or Out

### First run (interactive)
```bash
python3 telemetry/telemetry_init.py
```
You'll be asked to choose. Your choice is saved.

### Non-interactive
```bash
python3 telemetry/telemetry_init.py --yes   # Opt in
python3 telemetry/telemetry_init.py --no    # Opt out
```

### Change your mind later
Delete the config and re-run:
```bash
rm ~/.ai-marketing-skills/telemetry-config.json
python3 telemetry/telemetry_init.py
```

## Local Data — Always Available

**Regardless of opt-in**, all skill runs are logged locally so you can see your own usage:

```
~/.ai-marketing-skills/analytics/skill-usage.jsonl
```

This data never leaves your machine unless you opt in.

## View Your Stats

```bash
python3 telemetry/telemetry_report.py
```

Shows: total runs, runs per skill, success rates, average durations, most used skill, and more.

### Options
```bash
python3 telemetry/telemetry_report.py --json          # Machine-readable JSON
python3 telemetry/telemetry_report.py --skill seo-bot  # Filter to one skill
```

## Check for Updates

```bash
python3 telemetry/version_check.py
```

- Compares your local version against the latest GitHub release
- Silent when up to date
- Caches the result for 24 hours to avoid excess API calls
- Never blocks execution if offline

## Privacy Commitment

1. **Opt-in only** — nothing is sent without your explicit consent
2. **Local-first** — your data is always stored locally for your own use
3. **Minimal data** — only what's needed to improve the skills
4. **No PII** — no names, emails, paths, or content
5. **Transparent** — all telemetry code is right here, read it yourself
6. **Revocable** — opt out any time, delete your config file

# Codebase Cost Estimator

> Point it at a codebase, get a defensible build-cost estimate — by lines of code, not guesswork.

Estimate what an existing codebase cost (or would cost) to build: development hours from measured
LOC and complexity, current-year market rates, calendar time with organizational overhead, full
team cost beyond engineering, and optional AI/Claude ROI.

## What You Get

- **Development hours estimate** — LOC by language and type, converted with per-category productivity rates
- **Market rate research** — low/median/high hourly rates for the stack, current-year data
- **Calendar time** — raw hours converted to wall-clock delivery across company types (lean startup → enterprise)
- **Full team cost** — PM, design, eng management, QA, program management, tech writing, DevOps, not just engineering
- **AI ROI analysis** — what each hour of Claude produced in value (optional)

This skill estimates by **measured lines of code and architectural complexity** — not by ticket
volume, story points, or feature counts.

## Quick Start

This is a Claude Code skill — there are no scripts to install. Drive it from `SKILL.md`:

```bash
# 1. Count the codebase (whichever counter is installed)
tokei .            # or: cloc --vcs=git .

# 2. Hand the codebase + LOC breakdown to Claude Code and follow the
#    SKILL.md process: LOC -> hours -> overhead -> rates -> calendar
#    time -> full-team cost -> assembled estimate.
```

## How It Works

1. **Measure** LOC by language; separate production code, tests, and docs; note complexity drivers.
2. **Convert** LOC to raw developer-hours using the productivity bands in `references/rates.md`.
3. **Apply** overhead multipliers (architecture, debugging, review, docs, integration) — typically 1.9x–2.25x.
4. **Research** current-year market hourly rates for the stack; build a low/median/high table.
5. **Convert** raw hours to calendar time with the efficiency factors in `references/org-overhead.md`.
6. **Layer in** full-team cost via the role ratios and multipliers in `references/team-cost.md`.
7. **Assemble** the estimate with `assets/output-template.md`.
8. **Optional:** compute AI/Claude ROI with `references/claude-roi.md`.

## File Structure

```
codebase-cost-estimator/
├── README.md                  # This file
├── SKILL.md                   # Claude Code skill definition
├── references/
│   ├── rates.md               # Lines-per-hour productivity bands + overhead multipliers
│   ├── org-overhead.md        # Efficiency factors + calendar-time formula
│   ├── team-cost.md           # Supporting-role ratios + full-team multipliers
│   └── claude-roi.md          # AI/Claude ROI calculation method
└── assets/
    └── output-template.md     # Stakeholder-ready estimate template
```

## Related

For financial reporting from accounting exports — CFO briefings, burn rate, runway, and
scenario modeling from QuickBooks/CSV data — that is a separate concern from this skill, which
estimates build cost from measured lines of code.

## License

MIT

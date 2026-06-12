# Library investigation — &lt;repo or scope&gt;

**Audited:** &lt;repo root / file set&gt; · **Investigator:** &lt;model/agent&gt; · **Date:** &lt;YYYY-MM-DD&gt;
**Cold context:** &lt;yes/no — was the investigator given only paths + RULESET, with no intent?&gt;
**Probe:** `bash .claude/skills/library-investigator/scripts/library_probe.sh &lt;REPO_ROOT&gt;` (exit &lt;n&gt;)

## Headline (counts only — no verdict)

```
CONFORMS n / VIOLATES n / UNVERIFIABLE n / N-A n   over   N files × M rules
```

| CONFORMS | VIOLATES | UNVERIFIABLE | N-A |
|---:|---:|---:|---:|
| n | n | n | n |

Tier-0 `validate.sh`: &lt;exit 0 OK / exit n — first FAIL line&gt;.
No overall verdict is emitted. Counts are the headline.

## VIOLATES — facts with evidence

| Rule | File:line | Probe command run | Quoted failing output | Tier | What would clear it |
|---|---|---|---|---|---|
| R32-body | path/SKILL.md | `wc -l < path/SKILL.md` | `132` | 1 | SKILL.md ≤ 100 lines (move detail to references/) |
| R13 | path/agent.md:3 | `fm_block \| grep -n '[<>]'` | `3:description: use &lt;tool&gt;…` | 1 | remove `<`/`>` from frontmatter |
| R12/R32-desc | path/SKILL.md | join `description:` + `wc -c` | `971` | 1 | description ≤ 800 chars |
| R9 | path/SKILL.md | `name` + `grep -iE 'claude\|anthropic'` | `claude-helper` | 1 | rename without reserved token |
| R33 | path/README.md | `test -f path/README.md` | present | 2 | fold README into SKILL.md/references (known divergence) |
| R5 | path/run.sh | `find -maxdepth 1 … run.sh` | runnable at root | 2 | move runnable under `scripts/` |

Each row is a FACT. The tier is a property of the check (per
`.claude/rules/review-tiers.md`), framed as a ratchet candidate for
`validate.sh` — not a statement that the finding blocks.

## UNVERIFIABLE — probe could not complete

| Rule | File | Why the probe was blocked |
|---|---|---|
| R13 | path/SKILL.md | no frontmatter block found |
| R12/R32-desc | path/agent.md | no description value found |

## Defer-list — out of jurisdiction

### N-A → see library-reviewer (judgment rules)

- R11 / R15–R17 / R22 / routing specificity / single-responsibility — across &lt;n&gt; files. These need a quality verdict; the investigator does not guess them. Run `skill-library-review`.

### Tier-0 → see validate.sh (deterministic structure)

- R6 / R7 / R8 / R31 / dangling-refs — reported above as the single `TIER0` row. `validate.sh` is the authority; this report does not re-find its territory.

## Self-consistency

- Files probed: &lt;n&gt;. Files appearing in probe output: &lt;n&gt;. Gap: &lt;none / list&gt;.
- Count check: CONFORMS + VIOLATES + UNVERIFIABLE + N-A = &lt;sum&gt; vs files × applicable-rules = &lt;expected&gt;.

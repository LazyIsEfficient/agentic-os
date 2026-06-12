# Probe table — the contract

One row per rule. The investigator probes ONLY the mechanically-checkable rules
(top section). It defers structural rules to `validate.sh` (Tier 0) and judgment
rules to `skill-library-review` (N-A). The probe is exact — `scripts/library_probe.sh`
implements precisely these checks; if the script and this table disagree, the
table is the spec and the script is the bug.

The tier on each row is a FACT about the check's reproducibility (per
`.claude/rules/review-tiers.md`), not a judgment and not a gate. Every VIOLATES
is a candidate to ratchet *down* into `validate.sh`.

## Surface keys

- **skills** = `.claude/skills/*/SKILL.md`
- **agents** = `.claude/agents/*.md`
- **commands** = `.claude/commands/*.md`
- **workflows** = `.claude/workflows/*.js`
- **md-fm** = the YAML frontmatter block of any `.md` surface (skills, agents, commands)

## Mechanically-probeable rules — investigator owns

| Rule ID | Applies-to | Exact probe | Conforms-iff | Verdict-when-fails | Tier | Owner |
|---|---|---|---|---|---|---|
| R9 | skills, agents | `fm_value name` then `grep -iE 'claude\|anthropic'` on the name | name contains neither `claude` nor `anthropic` (case-insensitive) | VIOLATES | 1 | investigator |
| R12 / R32-desc | md-fm (skills, agents, commands) | extract full `description:` value (inline + continuation lines joined), `wc -c` | description length ≤ 800 chars | VIOLATES | 1 | investigator |
| R13 | md-fm (skills, agents, commands) | `fm_block`, strip trailing block-scalar indicator (`key: >-`, `key: \|`, etc.) AND blank the `argument-hint:` value (exempt per RULESET R13), then `grep '[<>]'` | frontmatter content contains no `<` or `>` outside `argument-hint` | VIOLATES | 1 | investigator |
| R32-body | skills only | `wc -l < SKILL.md` | SKILL.md ≤ 100 lines | VIOLATES | 1 | investigator |
| R33 | skills only | `test -f <skill-dir>/README.md` | always conforms — in-skill README is an accepted repo convention (RULESET R33) | — (never VIOLATES) | 2 | investigator |
| R5 | skills only | `find <skill-dir> -maxdepth 1 -type f \( -name '*.sh' -o -name '*.py' -o -name '*.js' \)` | no runnable at the skill ROOT (runnables live under `scripts/`) | VIOLATES | 2 | investigator |

### Notes on the probes

- **R12/R32-desc** is checked at the **800-char local cap** (R32), which is
  stricter than the guide's 1024 (R12). The probe joins block-scalar and
  wrapped continuation lines with single spaces before counting, so a
  multi-line `description:` is measured as one string.
- **R13** scans the frontmatter block only (between the first two `---`), never
  the body — angle brackets in body prose are legal. A YAML block-scalar
  indicator on a `key:` line (`description: >-`, `when_to_use: |`, `key: >2`) is
  structural YAML, not injected content, and `validate.sh` already treats it as
  legal — so the trailing indicator is stripped before the scan. A command's
  `argument-hint` value is exempt too (RULESET R13 exception — `<placeholder>` is
  a rendered CLI hint, not injected text), so that line's value is blanked first.
  Only a `<`/`>` surviving elsewhere in a key or value (e.g. a literal `<TBD>`
  placeholder, or `LCP > 2.5s` in prose folded into the description) is a true
  R13 violation.
- **R32-body** counts physical lines of `SKILL.md` only; references/ and assets/
  are uncapped.
- **R33** is an accepted repo convention: many skills deliberately ship a
  human-facing README. The probe always emits CONFORMS for it — never VIOLATES.
- **R5** flags a runnable sitting directly in the skill folder. Files under
  `scripts/`, `references/`, or `assets/` are correctly placed and never flagged.

## Tier-0 rules — defer to validate.sh

The investigator does NOT re-implement these. The script runs
`scripts/validate.sh` and reports its exit as a single `TIER0` row. A nonzero
exit is a deterministic VIOLATES against whichever of these the validator names.

| Rule ID | Applies-to | Probe | Tier | Owner |
|---|---|---|---|---|
| R6 | skills | validate.sh (main file named exactly `SKILL.md`) | 0 | defer→validate.sh |
| R7 | skills, agents, workflows | validate.sh (folder/name kebab-case) | 0 | defer→validate.sh |
| R8 | skills, agents, workflows | validate.sh (`name` == folder / filename / `meta.name`) | 0 | defer→validate.sh |
| R31 | skills | validate.sh (`when_to_use` present) | 0 | defer→validate.sh |
| dangling-refs | skills, agents, memory | validate.sh (relative links + wikilinks + @-imports resolve) | 0 | defer→validate.sh |

## Judgment rules — N-A, defer to skill-library-review

These are not mechanically probeable. The investigator emits `N-A` with
"see library-reviewer" and never guesses.

| Rule ID | Applies-to | Why N-A | Owner |
|---|---|---|---|
| R11 | md-fm | "states what + when" is a judgment about meaning | defer→library-reviewer |
| R15–R17 | md-fm, skills body | description pattern / specificity / actionable instructions are judgment | defer→library-reviewer |
| R22 | skills | "2–3 concrete use cases" is a design judgment | defer→library-reviewer |
| routing | all surfaces | routing specificity, arg-hint/body coherence, meta/phase coherence | defer→library-reviewer |
| single-responsibility | skills, agents | "one role / one concern" is a judgment | defer→library-reviewer |

## Per-surface applicability summary

- **skills**: R9, R12/R32-desc, R13, R32-body, R33, R5 (mechanical) + Tier-0 + judgment N-A.
- **agents**: R9, R12/R32-desc, R13 (mechanical) + judgment N-A. (R32-body/R33/R5 are skills-only.)
- **commands**: R13, R12/R32-desc (mechanical) + routing N-A. (No R9: commands have no `name` key.)
- **workflows**: mostly defer — structure is Tier-0 validate.sh; meta/phase coherence is judgment N-A. The script does not parse JS.

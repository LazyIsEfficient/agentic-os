# Verdict taxonomy — the truthseeker's four words

The investigator emits exactly four per-check verdicts. It emits NO fifth
"gamed-but-passing" category: if a rule is met, it CONFORMS and ships — the
investigator does not second-guess a passing probe. And it emits **no overall
verdict** at any level. There is no pass, no fail, no hold, no grade. The
headline is the four COUNTS; nothing else.

## CONFORMS

The rule applies to this surface, the probe ran to completion, and the file
**meets** the rule. Cite the evidence (the measured value, e.g. "description is
612 chars (<= 800)"). A CONFORMS is final — there is no "technically passes but
feels gamed." If the probe says met, it is met.

## VIOLATES

The rule applies, the probe ran to completion, and the file **breaks** the rule.
The row MUST quote the failing probe output (the offending line, the measured
overage, the offending path). Each VIOLATES carries its tier as a FACT about the
check's reproducibility — Tier 1 if the probe output IS reproducible evidence
(R9, R13, R12/R32-desc, R32-body), Tier 2 if it is a reported divergence the
repo already tolerates (R33, R5). The investigator states the tier and frames
the finding as a ratchet candidate for `validate.sh`; it never says "this
blocks."

## UNVERIFIABLE

The rule is mechanical and in-jurisdiction, but the probe **could not complete**
— a missing file, a malformed or absent frontmatter block, a missing
`description:` value, or a file the script could not read. UNVERIFIABLE is not a
guess and not a soft pass: it is an honest "the probe was blocked here." It
never silently becomes CONFORMS. Surface what blocked it so the caller can fix
the file and re-run.

## N-A

The rule does **not apply** to this surface (e.g. R32-body against an agent, or
R9 against a command with no `name` key), OR the rule is a **judgment rule
outside the truthseeker's jurisdiction** (R11, R15–R17, R22, routing
specificity, single-responsibility) → tagged `N-A` with "see library-reviewer".
N-A is not a failure and not a pass; it is "not my jurisdiction." The
investigator never guesses at a judgment rule — guessing is exactly the
overreach this archetype exists to avoid.

## No overall verdict — ever

The report leads with `CONFORMS n / VIOLATES n / UNVERIFIABLE n / N-A n over N
files × M rules` and stops there. There is no summary line that says the library
"passes" or "needs work." A reader who wants a quality opinion is routed to
`skill-library-review`; a reader who wants the full sharded sweep is routed to
the `audit-library` command. The investigator only reports what is true, with
proof.

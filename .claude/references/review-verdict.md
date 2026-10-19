# Review verdict contract — `agentic-os/review-verdict@1`

One machine-parseable verdict for every gate reviewer. Tier doctrine:
[review-tiers](../rules/review-tiers.md). Parser (Tier 0):
`scripts/parse-verdict.sh`.

## Who emits it

| Agent | Verdicts it may emit |
|---|---|
| `code-reviewer`, `security-reviewer`, `library-reviewer` | `pass` \| `fix-before-merge` \| `hold` |
| `data-model-verifier` | `pass` \| `hold` (subset — REFUTED > 0 is `hold`, else `pass`) |

Exempt: `library-investigator` emits counts, never a verdict, by design.
`adversarial-claims-reviewer` is not a gate node and reviews documents that may
not live in git, so it has no `base`/`head`; it keeps its count headline.

## Brief

Gate reviewers are cold. The orchestrator passes **only** the base ref (e.g.
`origin/main`) and the changed paths (`data-model-verifier`: base ref, changed
section names, Source paths). No goal, no rationale, no pasted diff — the
reviewer runs `git diff <base>...HEAD -- <paths>` (plus `git diff HEAD` for
uncommitted work) itself.

## Shape

The reviewer's final output MUST end with exactly one fenced `json` block. The
parser reads the **last** complete ```` ```json ```` block; anything after it is
ignored, an unterminated block is invalid.

```json
{
  "schema": "agentic-os/review-verdict@1",
  "agent": "code-reviewer",
  "base": "origin/main",
  "head": "<40-hex output of git rev-parse HEAD>",
  "verdict": "pass | fix-before-merge | hold",
  "findings": [
    {
      "tier": 1,
      "severity": "high",
      "file": "src/auth.ts",
      "line": 42,
      "summary": "Session token compared with == (timing leak)",
      "evidence": "bash scripts/repro-timing.sh exits 1"
    }
  ]
}
```

| Field | Rule |
|---|---|
| `schema` | Exactly `agentic-os/review-verdict@1` |
| `agent` | Non-empty string — the reviewer's `name:` |
| `base` | Non-empty string — the base ref the reviewer diffed against |
| `head` | Full commit SHA (40 or 64 lowercase hex) from `git rev-parse HEAD` |
| `verdict` | `pass` \| `fix-before-merge` \| `hold` |
| `findings` | Array (may be empty) |
| `findings[].tier` | `0` \| `1` \| `2` (number) |
| `findings[].severity` | `critical` \| `high` \| `medium` \| `low` |
| `findings[].file` | Non-empty string; repo-relative path by convention (the parser checks non-empty only) |
| `findings[].line` | Integer ≥ 1, or `null`/omitted for a file-level finding |
| `findings[].summary` | Non-empty string, one sentence |
| `findings[].evidence` | String. **Required for tier 0/1**: the failing command, test, scanner hit, or quoted counterexample that reproduces the finding |

Severity is not tier. Reviewers whose prose uses blocking / should-fix / nit map
them to `high`-or-`critical` / `medium` / `low` in the JSON.

## Normalization (applied by the parser)

1. A tier 0 or tier 1 finding with missing or blank `evidence` is **demoted to
   tier 2**; the normalized finding carries `"demoted_from": <old tier>`.
2. Only tier 0/1 findings may justify `hold`. A `hold` with no tier 0/1
   finding left after step 1 is normalized to `fix-before-merge` and carries
   `"verdict_demoted_from": "hold"` — an unevidenced hold is a proposal to the
   operator, not a gate.
3. Output keeps only the fields above (plus the two `*demoted_from` markers),
   printed as compact JSON on stdout.

## `scripts/parse-verdict.sh`

```sh
bash scripts/parse-verdict.sh review.txt          # file
reviewer-output | bash scripts/parse-verdict.sh   # stdin
```

| Exit | Meaning |
|---|---|
| `0` | Valid; normalized verdict is `pass` or `fix-before-merge` |
| `1` | Invalid: no complete `json` block, unparseable JSON, or a schema/enum/required-field violation (reasons on stderr) |
| `2` | Valid; normalized verdict is `hold` (evidenced by tier 0/1) |

Normalized JSON is printed on stdout for exit 0 and 2 only.

## Scope of `head`

`head` names the commit the reviewer read. If the brief covered uncommitted
work, the reviewer also read `git diff HEAD`, so the verdict covers `head` plus
that working-tree delta — consumers that bind a verdict to a SHA should require
a clean tree at review time.

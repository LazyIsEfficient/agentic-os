# Review verdict contract — `agentic-os/review-verdict@1`

One machine-parseable verdict for every gate reviewer. Tier doctrine:
[review-tiers](../rules/review-tiers.md). Parser (Tier 0):
`.claude/hooks/lib/parse-verdict.sh` (wrapper: `scripts/parse-verdict.sh`).

This reference is **repo-side** — `install.sh` ships `.claude/agents/` and
`.claude/hooks/` (so the parser ships, for the capture hook) but not
`.claude/references/`. Each reviewer agent therefore restates the enum,
required fields, and demotion rule inline.

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

The reviewer's output MUST contain exactly one fenced ```` ```json ```` block,
and it MUST be the last thing in the output — only whitespace may follow its
closing fence. Zero blocks, two or more blocks (including one quoted inside a
longer fence), an unterminated block, or trailing text are all invalid: a
quoted `pass` block must never be able to override a real `hold`.

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
| `agent` | One of `code-reviewer`, `security-reviewer`, `library-reviewer`, `data-model-verifier` |
| `base` | Non-empty string — the base ref the reviewer diffed against |
| `head` | Full commit SHA (40 or 64 lowercase hex) from `git rev-parse HEAD` |
| `verdict` | `pass` \| `fix-before-merge` \| `hold`; `data-model-verifier` only `pass` \| `hold` |
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

Rejected after normalization (exit 1):

- `verdict: pass` alongside any evidenced tier 0/1 finding — a contradiction.
- `data-model-verifier` with `fix-before-merge`, or a `hold` with no evidenced
  tier 0/1 finding (REFUTED always carries evidence, so it is never downgraded).
- Duplicate JSON keys at any depth, checked with `jq --stream` (raw tokens,
  before jq's last-key-wins collapse). No python3 dependency: the parser ships
  under `.claude/hooks/lib/`, where Invariant 8 bans inline interpreters.

## `scripts/parse-verdict.sh`

The parser lives at `.claude/hooks/lib/parse-verdict.sh` so it ships to
consumers with the hooks; `scripts/parse-verdict.sh` is a wrapper that execs it.

```sh
bash scripts/parse-verdict.sh review.txt                        # file
bash scripts/parse-verdict.sh < review.txt                      # stdin
bash scripts/parse-verdict.sh --expect-head "$(git rev-parse HEAD)" review.txt
```

`--expect-head <sha>` rejects (exit 1) a block whose `head` differs.

| Exit | Meaning |
|---|---|
| `0` | Valid; normalized verdict is `pass` |
| `1` | Invalid: block count or position, unparseable JSON, duplicate keys, a schema/enum/required-field/agent violation, a rejected combination above, or `--expect-head` mismatch (reasons on stderr) |
| `2` | Valid; normalized verdict is `hold` (evidenced by tier 0/1) |
| `3` | Valid; normalized verdict is `fix-before-merge` (including a downgraded unevidenced `hold`) |

Normalized JSON is printed on stdout for exits 0, 2 and 3; nothing on exit 1.

## Captured verdict artifacts (`.claude/reviews/`)

Nobody hand-records verdicts. The `SubagentStop` hook
`.claude/hooks/review-verdict-capture.sh` runs the parser with
`--expect-head "$(git rev-parse HEAD)"` on each gate reviewer's final message
and, for exits 0/2/3 whose `agent` equals the subagent's `agent_type`, writes
the normalized JSON atomically to
`.claude/reviews/<HEAD-sha>-<agent>.json` (gitignored; the directory also gets
a `*` `.gitignore`). Invalid or stale-head blocks write nothing. The `Stop`
hook `.claude/hooks/review-gate-stop.sh` reads only these files — see
[gate-dag.md](gate-dag.md) § Stop gate.

## Scope of `head`

`head` names the commit the reviewer read. Gate reviews are **commit-first**:
the orchestrator commits the changes (including `DATA_MODEL.md`) before
dispatching reviewers, and the Stop gate blocks while qualifying changes are
uncommitted ([gate-dag.md](gate-dag.md) § Stop gate). A verdict therefore
covers exactly `head`; any later commit needs a fresh review.

---
name: findings-ledger
description: Use when recording, tallying, or triaging stochastic review findings — the append-only JSONL ledger where Tier 2 (advisory, unevidenced) reviewer output goes instead of blocking language. Triggers on "log this finding", "ledger add", "tally the findings", "triage findings", "is this finding recurring", "retire this noise", or whenever a reviewer produces an unevidenced concern that should be measured for recurrence rather than chased. For the review itself see code-review-and-quality or skill-library-review; for verifying formal claims with deterministic evidence see adversarial-claims-reviewer.
when_to_use: |
  Use when a reviewer (human or agent) produced a Tier 2 finding — pure LLM
  judgment with no deterministic evidence artifact — and it needs to be recorded
  so recurrence across independent runs can be measured; when tallying which
  findings keep coming back; or when triaging the ledger for promotion (encode
  as a Tier 0/1 check) and retirement (age out as noise) candidates.

  Not when: the finding has a failing script or counterexample — that is Tier 1
  evidence; attach the artifact and let it gate (see adversarial-claims-reviewer).
  Not when conducting the review itself — use code-review-and-quality for source
  code or skill-library-review for library definitions; this skill only stores
  their unevidenced residue.
compatibility: Requires Bash (Python 3 where scripts are invoked). Works in Claude Code and Codex via install.sh.
---

# Findings Ledger

Stochastic judgment proposes; deterministic verification disposes (tier
doctrine: review-tiers — `.claude/rules/review-tiers.md`). This skill is the *proposes* side's
inbox: a single append-only JSONL at `.claude/ledger/findings.jsonl` where
Tier 2 findings accumulate fingerprinted, so the same defect reported twice
across runs collides to one entry — deterministically when the reviewer passes
a `--category`, heuristically on claim wording when it doesn't — and recurrence across independent runs — not rhetoric — decides what gets
investigated.

## The ledger file

- **Location:** `.claude/ledger/findings.jsonl`, one JSON event per line.
- **Append-only.** Status transitions are new events for the same fingerprint;
  prior lines are never mutated. Current status = the fingerprint's most recent
  event.
- **Gitignored by default** (machine-local noise). **Team-shared mode**, two
  options: (a) commit `ledger.py export --out <path>` output — one line per
  fingerprint with category, file, count and first/last seen, **no claim
  text** — to any tracked path; no `.gitignore` change needed. (b) Commit the
  raw ledger: in `.gitignore`, replace the `.claude/ledger/` line with
  `.claude/ledger/*.lock` (the lock sidecar stays local). Append-only + stable
  ordering keeps either diff reviewable.
- **CI runners don't persist it.** Appends made during a CI job vanish with
  the runner — and CI must never push the ledger back to the repo. Upload the
  run's findings as a build artifact and harvest locally instead; patterns in
  [references/ledger-format.md](references/ledger-format.md).

Entry fields: `fingerprint`, `fingerprint_scheme` (1 = text, 2 = structured;
absent on pre-#279 entries, read as 1), `category` and `symbol` (or null),
`file`, `claim`, `tier`, `source`, `run_id`, `date`, `evidence` (path or
null), `status` (`NEW | RECURRING | INVESTIGATING | PROMOTED | RETIRED-NOISE`).
Full schema, lifecycle, and fingerprint-normalization limits:
[references/ledger-format.md](references/ledger-format.md).

## Commands

All via [scripts/ledger.py](scripts/ledger.py) (python3, stdlib only; exit 0 =
ok, 2 = setup/usage error; output ordering is deterministic). Resolve the script path first — [references/install-paths.md](references/install-paths.md):

```sh
PROJ="${CLAUDE_PROJECT_DIR:-.}"
# 1. Repo checkout
LEDGER="$PROJ/.claude/skills/findings-ledger/scripts/ledger.py"
# 2. Project Codex install
[ -f "$LEDGER" ] || LEDGER="$PROJ/.agents/skills/findings-ledger/scripts/ledger.py"
# 3. Global Claude Code install
[ -f "$LEDGER" ] || LEDGER="$HOME/.claude/skills/findings-ledger/scripts/ledger.py"
# 4. Global Codex install
[ -f "$LEDGER" ] || LEDGER="$HOME/.agents/skills/findings-ledger/scripts/ledger.py"

python3 "$LEDGER" add \
  --file <path> --claim "<one sentence>" --tier 2 \
  --source <agent-name> --run-id <id> [--evidence <path>] \
  [--category <kebab-slug> [--symbol <function|heading|key>]]

python3 "$LEDGER" tally
python3 "$LEDGER" triage [--threshold 2] [--age-days 14]
python3 "$LEDGER" promote <fingerprint> [--status INVESTIGATING] [--evidence <path>]
python3 "$LEDGER" retire <fingerprint>
python3 "$LEDGER" export --out <path>
```

- `add` computes the fingerprint (see Categories below) and labels a
  sighting `RECURRING` only when an earlier sighting came from a different
  `--run-id`; a repeat within the same run stays `NEW`. A `--tier 1` finding without
  `--evidence` is demoted to tier 2 automatically — the tier rule, enforced.
- Recurrence counts **distinct run ids**, not raw sightings — an agent
  repeating itself within one run cannot cross the threshold alone.
- `triage` lists fingerprints at/over the recurrence threshold as promotion
  candidates, and still-`NEW` single-run findings older than the age cutoff
  as retire-as-noise candidates. The `/triage-findings` command (repo-local
  maintainer tooling; not shipped by the installer) wraps this and proposes a
  ratchet target per candidate; the human disposes.
- `promote` refuses to record `PROMOTED` without `--evidence` — a promotion
  *is* its encoded check.
- `export` writes the deduplicated per-fingerprint summary (sorted,
  byte-deterministic JSONL) to `--out`, and refuses to overwrite the ledger.

## Categories (structured fingerprints)

Two reviewers rarely phrase one defect the same way, so text fingerprints
rarely recur. Pass `--category` and the fingerprint becomes
`sha256("v2" + normalized file path + category + symbol)` — claim wording no
longer matters, and paraphrases collide.

- `--category` — a short kebab-case slug naming the **defect class**
  (lowercased; anything that isn't `[a-z0-9]+(-[a-z0-9]+)*` is rejected).
  Seed vocabulary — prefer these, coin a new slug when none fits:

  | Slug | Use for |
  |------|---------|
  | `fail-open` | error/missing input path that grants or proceeds instead of denying |
  | `missing-validation` | user input reaches a sink unchecked |
  | `missing-ci-wiring` | a test/check exists but CI never runs it |
  | `missing-test` | behavior change with no test exercising it |
  | `stale-doc` | docs contradict the current code |
  | `broken-reference` | link, path or cross-reference that does not resolve |
  | `vague-routing` | skill/agent description too unspecific to route on |
  | `dead-code` | unreachable or unused code/config |
  | `secret-exposure` | credential or token logged, committed or leaked |

- `--symbol` (optional, requires `--category`) — the function, heading, or
  config key the finding is about. Backticks and a trailing `()` are stripped,
  so `` `check_token()` `` and `check_token` match. Omit it for file-level
  findings.
- Without `--category`, `add` uses the legacy text fingerprint (scheme 1),
  unchanged — existing entries keep their identity. The two schemes never
  match each other, so stick to one per defect.

Reviewers should pass both whenever the finding names a defect class and a
location, reusing the same slug for the same class across runs:

```sh
python3 "$LEDGER" add --file src/auth.py --tier 2 --source code-reviewer \
  --run-id pr-281 --category fail-open --symbol check_token \
  --claim "check_token returns True when the verifier raises"
```

## The ratchet

A recurring fingerprint is a candidate to leave the stochastic layer forever:
investigate → encode as a `scripts/validate.sh` rule (Tier 0) or an
exit-nonzero evidence script (Tier 1) → `promote` with the encoded check as
`--evidence` → no LLM ever re-litigates it. Singles nobody re-reports get
`retire`d. The ratchet only turns toward lower variance.

## Related skills

- [code-review-and-quality](../code-review-and-quality/SKILL.md) — produces the findings this ledger stores
- [skill-library-review](../skill-library-review/SKILL.md) — library-audit findings route here when unevidenced
- [adversarial-claims-reviewer](../adversarial-claims-reviewer/SKILL.md) — the Tier 1 pattern: evidence artifacts instead of ledger entries

# Ledger format — schema, lifecycle, fingerprinting

The ledger is a single append-only JSONL file at `.claude/ledger/findings.jsonl`
in the **main repository** — `ledger.py` resolves the path via
`git rev-parse --git-common-dir`, so an agent running inside a linked git
worktree appends to the main checkout's ledger, not an ephemeral worktree copy
(outside a git repo it falls back to the nearest ancestor containing
`.claude/`; `--ledger PATH` overrides either way).
One JSON object per line, one line per **event**. Events are never edited or
deleted; corrections and status changes are appended as new events carrying the
same fingerprint. Keys are serialized sorted (`json.dumps(..., sort_keys=True)`)
so identical events byte-compare equal and team-shared diffs stay stable.

## Event schema

| Field         | Type          | Meaning |
|---------------|---------------|---------|
| `fingerprint` | string (16 hex) | sha256 of `file + "\n" + normalize(claim)`, truncated to 16 chars. Groups re-sightings of the same defect. |
| `file`        | string        | Repo-relative path the finding is about. |
| `claim`       | string        | One-sentence claim summary, as the reviewer phrased it. |
| `tier`        | 1 or 2        | Per review-tiers (`.claude/rules/review-tiers.md` or `.cursor/rules/review-tiers.mdc`). Tier 0 checks live in validators and never enter the ledger. |
| `source`      | string        | Emitting agent (`library-reviewer`, `code-reviewer`, …) or `triage` for transitions. |
| `run_id`      | string or null | Identifier of the review run (branch, PR number, workflow id). Required on `add`; null only arises on transition events. Recurrence counts distinct run ids, so reuse the same id within one review run and use a fresh id per independent run. |
| `date`        | string        | `YYYY-MM-DD`. |
| `evidence`    | string or null | Path to the deterministic evidence artifact. Required for tier 1 — `add` demotes tier 1 to tier 2 when it is missing. On a `PROMOTED` event, this is the encoded check (validator rule or script) — `promote` refuses to record PROMOTED without it. |
| `status`      | enum          | `NEW`, `RECURRING`, `INVESTIGATING`, `PROMOTED`, `RETIRED-NOISE`. |

Why tier 1 entries exist in a ledger billed as the Tier 2 inbox: a tier 1
entry (evidence attached) is an audit trail, not a proposal — it records that
an evidenced finding was raised and lets a later `add` of the same fingerprint
reveal that the defect re-surfaced after its fix or promotion. Gating still
happens through the evidence artifact, never through the ledger entry.

## Status lifecycle

```
add (first sighting)          → NEW
add (fingerprint seen before) → RECURRING
promote --status INVESTIGATING → INVESTIGATING   (a human is looking)
promote --evidence <check>     → PROMOTED        (encoded as a Tier 0/1 check; leaves the stochastic layer)
retire                         → RETIRED-NOISE   (aged-out single sighting)
```

A fingerprint's **current status** is the status of its most recent event. A
fingerprint's **recurrence count** is the number of distinct `run_id` values
among its `NEW` + `RECURRING` events — independent runs, per the tier
doctrine, not raw sightings: an agent repeating itself within one run counts
once. Triage candidacy follows from both:

- **promotion candidate** — recurrence ≥ threshold AND current status is not
  `PROMOTED`/`RETIRED-NOISE`;
- **retirement candidate** — recurrence of exactly 1 AND current status is
  still `NEW` (an `INVESTIGATING` finding has an owner and is never proposed
  for retirement) AND strictly older than the age cutoff.

`PROMOTED` and `RETIRED-NOISE` are terminal for triage purposes — `triage`
stops proposing them — but nothing prevents a later `add` from sighting the
same fingerprint again; that is a signal the promotion's encoded check did not
actually cover the defect.

## Fingerprint normalization — a heuristic, not identity

Goal: the SAME defect phrased two ways across runs should usually collide to
one fingerprint. `normalize()` in `scripts/ledger.py`:

1. lowercases the claim text
2. strips backtick-, double-, and single-quoted snippets (exact code excerpts
   vary per run). Single quotes count as delimiters only when not embedded in
   a word, so apostrophes in contractions and possessives (`doesn't`,
   `user's`) are not treated as quote pairs
3. folds `n't` contractions to ` not` and drops remaining in-word
   apostrophes, so contracted and expanded phrasings of the same defect
   collide
4. strips line/column references: `line 12`, `lines 3-5`, `col 7`, `L12`,
   `:12:3`
5. collapses all whitespace runs to a single space

These rules are regression-tested by `scripts/test_ledger.py` (exit-nonzero
evidence script).

The file path is NOT normalized beyond whitespace trimming — a finding about a
different file is a different finding.

### Known limits

- **Different vocabulary, same defect, no collision.** "description is vague"
  vs "routing triggers are unspecific" fingerprint differently. Tally sorts by
  recurrence count then fingerprint (hash order — no file locality), so
  finding such near-duplicates is a manual scan of the file/claim columns at
  triage time; merging them is a human call.
- **Same wording, different defect, false collision.** Two genuinely distinct
  issues phrased identically about the same file collide. Rare, and the cost
  is a too-early promotion candidate — cheap to dismiss at triage.
- **Quoted-content stripping can over-erase.** A claim that is *mostly* quote
  ("the line `X` should be `Y`") normalizes to nearly nothing and collides
  with other quote-heavy claims about the same file. Prefer claim summaries
  that describe the defect in words.
- **Contraction folding is lossy.** `n't` → ` not` makes "doesn't"/"does not"
  collide, but irregular forms stay apart ("can't" folds to "ca not", which
  never matches "cannot"). Vocabulary-level identity is out of scope.
- **Same bug-class across different files never collides.** The file path is
  part of the fingerprint by design, so a defect pattern repeated in N files
  is N fingerprints — recurrence measures *this defect here*, not the class.
  Spotting cross-file patterns is the triage human's job (scan the claim
  column).
- **Renames break grouping.** Moving a file orphans its history; the next
  sighting starts a fresh fingerprint at `NEW`.
- **Cross-machine clones don't share a lock.** Within one machine, writers
  are serialized: `add` and status transitions hold an exclusive lock on a
  `<ledger>.lock` sidecar across their read→decide→append section, so racing
  processes (including worktree-dispatched agents) can't both record `NEW`
  for the same fingerprint. The lock is advisory and per-filesystem — it does
  nothing for two developers' separate clones, where git merge (team-shared
  mode) is the serialization.

These trade-offs are deliberate: the ledger biases toward *measuring
recurrence cheaply* over perfect identity. The triage human is the precision
layer.

## Team-shared mode

Default is machine-local: `.claude/ledger/` is gitignored, each clone
accumulates its own noise. To share across a team, delete the
`.claude/ledger/` line from `.gitignore` and commit `findings.jsonl`:

- recurrence then counts across *everyone's* review runs, so the threshold is
  crossed sooner and ratchet candidates surface faster;
- append-only + sorted keys keeps merge conflicts trivial (concurrent appends
  typically union cleanly — accept both sides);
- the file contains reviewer claims about repo files; review it like any other
  committed artifact before pushing;
- keep the lock sidecar out of the commit: add `.claude/ledger/*.lock` to
  `.gitignore` when you remove the `.claude/ledger/` line.

## CI environments — the ledger does not survive the runner

CI runners are ephemeral: any `ledger add` made during a CI job writes to the
runner's checkout and vanishes when the job ends. Two consequences:

- **Tier 2 findings emitted by CI-run reviewer agents are lost by default.**
  CI's load-bearing role in the tier architecture is Tier 0 (`validate.sh`),
  which is unaffected. But if you run stochastic reviewers in CI and want
  their residue counted toward recurrence, you must export it.
- **Never have CI commit or push the ledger back to the repo.** This fails
  predictably: concurrent jobs race on push and devolve into retry loops, bot
  commits trigger new workflow runs (so you maintain loop guards instead of a
  ledger), branch protection fights the bot, and CI merge commits pollute
  history. The write path is humans committing from their own clones — never
  the runner.

Patterns that do work:

1. **Artifact + local harvest** (recommended). The CI job uploads the run's
   `findings.jsonl` (or just the lines it appended) as a build artifact. A
   human downloads it and concatenates it into their local ledger — events
   are self-contained JSON lines, so harvest is
   `cat ci-findings.jsonl >> .claude/ledger/findings.jsonl`. Two ordering
   caveats. Recurrence counts are label-independent (derived from distinct
   run ids at read time), so stale NEW/RECURRING labels in harvested lines
   are cosmetic. But **current status is the last event in file order**, so
   harvest before making status transitions: a harvested sighting appended
   after your `promote`/`retire` flips the fingerprint back to a sighting
   status and re-lists it in triage, even though the CI sighting may predate
   the transition — a false re-sighting signal. If you must harvest late,
   re-run the affected `promote`/`retire` afterwards.
2. **Job summary for human triage.** Print the reviewer's Tier 2 findings in
   the job summary or a PR comment; a human runs `ledger add` locally for the
   ones worth tracking.
3. **Accept the loss.** If stochastic review in CI is advisory color rather
   than counted signal, let it vanish. The gates that matter in CI are
   deterministic ones.

In team-shared mode the committed ledger reaches CI read-only like any other
file (`validate.sh`'s shape check runs against it); the no-push rule still
holds.

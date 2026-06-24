---
description: Tally the findings ledger and propose ratchet targets for recurring findings (the human disposes)
argument-hint: "[recurrence-threshold] [age-days]"
allowed-tools: Bash, Read
---

You are triaging the stochastic-findings ledger per the tier doctrine in `.claude/rules/review-tiers.md`: Tier 2 findings accumulate in `.claude/ledger/findings.jsonl`; recurrence — not rhetoric — decides what gets investigated; and the RATCHET moves recurring findings out of the stochastic layer into deterministic checks. **This command only proposes. The human disposes** — never edit `validate.sh`, skills, or the ledger statuses yourself from this command.

## Step 1 — run the ledger

`$1` is an optional recurrence threshold (default 2); `$2` is an optional retire-age in days (default 14). Always run tally first (resolve ledger path per [findings-ledger references/install-paths.md](../skills/findings-ledger/references/install-paths.md)):

```sh
PROJ="${CURSOR_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-.}}"
LEDGER="$PROJ/.claude/skills/findings-ledger/scripts/ledger.py"
[ -f "$LEDGER" ] || LEDGER="$HOME/.cursor/skills/findings-ledger/scripts/ledger.py"
[ -f "$LEDGER" ] || LEDGER="$HOME/.claude/skills/findings-ledger/scripts/ledger.py"

python3 "$LEDGER" tally
python3 "$LEDGER" triage
python3 "$LEDGER" triage --threshold $1 --age-days $2
```

If the script exits 2 with "ledger not found", report that the ledger is empty and stop — there is nothing to triage.

## Step 2 — propose a ratchet target per promotion candidate

For EACH promotion candidate, read the file the finding is about (and `scripts/validate.sh` to avoid proposing a rule that already exists), then classify it into exactly one of:

1. **Tier 0 — `validate.sh` rule**, if the defect is mechanically checkable from file content alone (a grep-able pattern, a structural invariant). Give the concrete check — the invariant name and the grep/awk condition that would catch it, in the style of the existing `check_*` functions.
2. **Tier 1 — evidence script**, if the claim is verifiable by running something but not statically (behavior, exit codes, output shape). Name what the script would assert and where it would live (the owning skill's `scripts/`), exit-nonzero on failure.
3. **Stays Tier 2 advisory**, if it is irreducibly a taste/judgment call. One line of reasoning why it cannot be encoded.

Format per candidate:

```
<fingerprint>  n=<count>  <file>
  claim:    <claim summary>
  proposal: <Tier 0 rule | Tier 1 script | stays Tier 2> — <the concrete check / assertion / reasoning>
  if accepted: ledger.py promote <fingerprint> --evidence <encoded check path>
```

## Step 3 — list retirement candidates

List each retire-as-noise candidate with its age, claim, and the ready-to-run command:

```
<fingerprint>  age=<n>d  <file> — <claim>
  if accepted: ledger.py retire <fingerprint>
```

## Step 4 — stop

Present the proposals and the exact `promote` / `retire` commands. Do NOT run them, do NOT edit `validate.sh` or any skill — wait for the human's disposition.

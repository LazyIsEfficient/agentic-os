# Scanner evidence for cold reviewers

How `security-reviewer` and `code-reviewer` run the shipped deterministic
scanners and turn their output into evidence that the verdict contract
accepts. Tier doctrine: review-tiers (`.claude/rules/review-tiers.md`, in-repo
only). Only a reproducible artifact lets a finding block. A scanner hit is
that artifact.

| Scanner | Ships at | Used by |
|---|---|---|
| `security-scan.sh` | `skills/security/scripts/` (+ offline ruleset `security-scan-semgrep.yml`) | security-reviewer |
| `check-imports.sh` | `skills/code-review-and-quality/scripts/` | code-reviewer |

Both read only. They write nothing but their own `mktemp -d` dir, which they
remove on exit. Both take `--base <ref>` (files changed since
`merge-base(<ref>, HEAD)` plus untracked files) and `--json`. Both emit
`{"scanners":[{"name","status","reason"?,"findings":[{"file","line","rule","severity","message"}]}],"skipped":[…]}`.
In this repo, `scripts/security-scan.sh` and `scripts/check-imports.sh` are
wrappers around these files.

## Resolve and run

Resolve the project copy first, then the global install. Run from the project
root, because both scanners scope to the current directory:

```sh
PROJ="${CLAUDE_PROJECT_DIR:-.}"
S=skills/security/scripts/security-scan.sh   # or: skills/code-review-and-quality/scripts/check-imports.sh
SCAN="$PROJ/.claude/$S"
[ -f "$SCAN" ] || SCAN="$PROJ/.agents/$S"
[ -f "$SCAN" ] || SCAN="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/$S"
[ -f "$SCAN" ] || SCAN="$HOME/.agents/$S"
cd "$PROJ" || exit
SECURITY_SCAN_OFFLINE=1 bash "$SCAN" --base <base> --json; echo "exit=$?"   # check-imports: no env needed
```

**Tampering check.** The diff under review can change the scanner itself. Run
`git diff --name-only <base>...HEAD` and look for the resolved scanner or its
ruleset. If either is in the diff, say so in the report header. In that case a
clean result is not evidence, and it can never support `pass` on its own.
Findings still count, because a tampered scanner can only invent hits that you
then confirm by reading the code.

## Exit codes and what to report

| Exit | security-scan.sh | check-imports.sh |
|---|---|---|
| 0 | Clean, and at least one scanner ran. Still report every scanner whose `status` is `unavailable`/`error`. | Clean. |
| 1 | Findings. Cite each one (see below). | Findings. Cite each one. |
| 2 | Usage error, usually a bad `--base`. Fix the call and rerun. If it persists, treat it like 4. | Same. |
| 3 | Nothing checked: no file in scope, or no scanner installed. Tier 2 `scanner unavailable: security-scan`. | No JS/TS/Python sources or manifests in scope. Say `check-imports: nothing to check` in the report. This is not a gap, so there is no finding. |
| 4 | A scanner errored. Tier 2 `scanner unavailable: <name>` with its `reason`. | A check could not run (python3 missing, unparseable manifest). Tier 2 `scanner unavailable: check-imports`. |
| script not found | Tier 2 `scanner unavailable: security-scan`. | Tier 2 `scanner unavailable: check-imports`. |

Never skip a scanner silently. Each `scanner unavailable` finding goes into the
verdict as tier 2, severity `low`, `file` `.`, `line` `null`. Its `evidence` is
the exit code and `reason`. It is also logged to the ledger with category
`security/scanner-unavailable` (or `slop/scanner-unavailable`) and `--symbol`
the scanner name, so a gap that keeps recurring shows up in triage.

## Citing a hit

- **Tier 0:** the finding is exactly the scanner hit: same `file`, `line` and
  rule.
- **Tier 1:** the finding adds analysis (an exploit trace, a wider blast
  radius) and uses the hit as its artifact.
- `evidence` is the command, its exit code, and the JSON of that one finding:
  `SECURITY_SCAN_OFFLINE=1 bash security-scan.sh --base origin/main --json → exit 1; semgrep {"file":"src/report.py","line":5,"rule":"aos.python.subprocess-shell-true",…}`.
  gitleaks runs with `--redact`, so its JSON never holds the secret. Do not
  add the secret yourself.
- **Severity:** gitleaks → `high`. semgrep `ERROR` → `high`, `WARNING` →
  `medium`, `INFO` → `low`. Dependency advisories use the advisory's level.
  check-imports `ERROR` → `high`, `WARNING` (`unused-dependency`) → `medium`.
  Raise the severity only for a demonstrated exploit.
- **Verdict:** an evidenced hit you keep means at least `fix-before-merge`.
  `pass` next to it is rejected by the parser.
- **False positives:** you may drop a hit only by listing it under
  `Dismissed scanner hits` in the report, with the quoted line and a one-line
  reason. Examples: an alias that check-imports cannot resolve (a documented
  limitation), or a `shell=True` whose command is a constant. A dismissed hit
  is not in `findings`. It is never dropped silently.

## Network: offline by design

The reviewers have no network tools and must not open an exfiltration path.
`SECURITY_SCAN_OFFLINE=1` keeps the scanner offline:

- semgrep loads the shipped `security-scan-semgrep.yml`, not the registry
  `p/security-audit`. A registry config would also make the evidence drift,
  because the same diff could meet different rules next week, and that breaks
  Tier 0's same-input-same-verdict rule. Any non-local `SEMGREP_CONFIG` is
  reported `unavailable`. semgrep also runs with `--metrics=off
  --disable-version-check`.
- The dependency audit is reported `unavailable` whenever a lockfile is in
  scope. osv-scanner, npm audit, pip-audit and cargo audit all query online
  vulnerability databases, and npm audit uploads the lockfile. For full
  coverage, run `security-scan.sh` without the env var in CI or by hand
  outside the reviewer.
- gitleaks and check-imports never use the network.

The local ruleset covers a small set of high-signal sinks: eval/exec, shell
injection, unsafe deserialization, innerHTML, and disabled TLS verification.
It is narrower than `p/security-audit`. That is the trade for reproducible,
offline evidence.

## check-imports and Python

Python imports resolve with `$PYTHON` (default `python3`). To resolve
installed packages, set `PYTHON=.venv/bin/python`, but only when
`git ls-files .venv` is empty. A committed venv belongs to the untrusted tree,
and its interpreter start-up (`.pth` files) runs code.

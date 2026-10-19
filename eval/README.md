# eval/ — comparative library-effectiveness harness

Proves whether this library produces **better outcomes than not using it**, locally, on
demand. For each fixture the harness runs the same task through two arms — **library-ON**
(a specialist agent) and **library-OFF baseline** (a
vanilla `general-purpose` agent told to use no skills/subagents) — applies a Tier-0
deterministic check to each, then a **blind pairwise judge panel** picks a per-dimension
winner. The output is a per-dimension × output-type comparison report.

## Run it

```
/eval-harness                 # run the whole corpus
/eval-harness <fixture-id>... # run only named fixtures
```

The command reads the fixtures, runs the `eval-harness` workflow, writes results to
`eval/results/<runId>.jsonl`, and renders `eval/results/report-<runId>.md` via the
aggregator. **Cost:** each fixture = 2 produce + 2 check + 3 judge dispatches. Run a
single fixture first if cost-sensitive.

To exercise the `cargo-test` checker you must opt in (it compiles/runs model-generated
code — see Security): `EVAL_ALLOW_CODE_EXEC=1 /eval-harness code-slugify-rust`.

### The general-purpose ban and this harness

`.claude/hooks/block-general-purpose.sh` (registered in `.claude/settings.json` on
`Agent|Task`) denies `general-purpose` spawns. This harness dispatches `general-purpose`
on purpose: the baseline produce arm, every Check step, and every Judge step here, plus
both arms of `reliability/reliability-harness.js`. A run started in this repo loads the
project settings. If Workflow `agent()` spawns go through PreToolUse, those dispatches
get denied.
**UNVERIFIED:** whether Workflow `agent()` spawns go through PreToolUse has not been tested.

There is deliberately no env-var or flag-file bypass, because the model could set one
itself. The exemption is operator-side: start the session without project settings,
e.g. `claude --setting-sources user,local`. Then run `/eval-harness`. This only helps if
your user settings don't also register the hook. A global `install.sh` adds it to
`~/.claude/settings.json`; if you installed globally, run with a settings source that
omits it.

## Arm isolation

A library-OFF arm only means something if Claude Code cannot load the library. The
library is usually installed globally in `~/.claude`, and Claude Code also loads
`CLAUDE.md` files from every directory above the working directory. So an "OFF" run in
a temp dir, or one that only swaps `--settings`, still loads the library.

`metrics/run-arms.sh` isolates each arm (implementation in `metrics/lib/arm-isolation.sh`):

- **Own root per arm.** Each arm gets its own `mktemp -d` root:
  - `HOME=<root>/home`;
  - `CLAUDE_CONFIG_DIR=<root>/home/.claude`, the same directory `HOME/.claude` resolves
    to, so a code path that ignores the variable still lands in the temp dir;
  - `TMPDIR` and the `XDG_*` dirs also point under the root.
- **Committed HEAD only.** Everything comes from one export of committed `HEAD`, never
  the working tree, so the recorded `repo_sha` is exactly what ran. A dirty tree prints
  a note: uncommitted changes are not tested.
- **Working directory.** The working directory is `<root>/task`, a copy of that export
  with every `.claude`, `CLAUDE.md`, `CLAUDE.local.md`, `AGENTS.md` and `.mcp.json`
  removed. Matching is case-insensitive and covers files, dirs and symlinks.
- **What each arm gets.**
  - OFF gets nothing installed.
  - ON gets the library from the export's own `install.sh`, run as
    `env -i HOME=<root>/home CLAUDE_DIR=<root>/home/.claude TMPDIR=<root>/tmp PATH=<child path> install.sh --force`.
  - The export is deleted after preflight, before either arm runs.
  - The real `~/.claude` is never read or written.
- **Allowlisted environment.** The child keeps only `PATH LANG LC_ALL TERM USER LOGNAME
  SHELL` plus one auth variable. `CLAUDECODE`, `CLAUDE_*`, other `ANTHROPIC_*` and
  `XDG_*` are dropped. `PATH` is replaced by the system default
  (`/usr/bin:/bin:/usr/sbin:/sbin`) plus the dirs holding `claude`, `node` and `jq`.
  Values are set by `export` in a subshell, never in argv. Checking which auth variable
  is set suspends `xtrace`, so `bash -x run-arms.sh` does not print the credential.
- **Auth.** A fresh config dir has no login, and nothing is copied from `~/.claude` or
  the keychain. Export `ANTHROPIC_API_KEY` (the docs say `-p` always uses it when
  present) or `CLAUDE_CODE_OAUTH_TOKEN` (from `claude setup-token`). The run fails with
  instructions if neither is set. Only the variable's *name* is recorded. See
  <https://code.claude.com/docs/en/authentication#authentication-precedence>.
- **Preflight (Tier 0, blocking).** Before either arm sends a prompt, both are checked.
  Any mismatch aborts the run before `claude` is called. The checks:
  - temp `HOME` holds only `.claude`;
  - the task tree holds no `.claude/`, `CLAUDE.md`, `CLAUDE.local.md`, `AGENTS.md` or
    `.mcp.json`;
  - no ancestor of the task dir, up to `/`, holds any of those;
  - the managed policy dirs (`/Library/Application Support/ClaudeCode`,
    `/etc/claude-code`) carry no agentic-os marker;
  - **OFF only:** the config dir is empty;
  - **ON only:** the config dir's file set is *exactly* the install manifest plus
    `settings.json`. The manifest is every file under `.claude/{skills,agents,hooks}`
    plus the three shipped commands. Any extra file aborts the run: a plugin, a
    `.claude.json`, a rogue skill or a `CLAUDE.md`. So does any missing file. Every
    manifest file must be byte-identical to `HEAD`. `settings.json` must be exactly
    what `install.sh` writes, checked in four steps:
    - its only top-level key is `hooks`, so `enabledPlugins`, `apiKeyHelper`, `env`
      and similar keys are rejected;
    - every hook command is `bash <config>/hooks/*.sh`;
    - the set of hook commands equals the set the installer registers;
    - the whole file equals the rewritten consumer template.
- **Record.** Each preflight appends one line to `<out>/isolation.jsonl`: `run_id`,
  `repo_sha`, `harness_dirty` (true when `eval/metrics/` has uncommitted changes: the
  harness runs from the working tree, unlike the arms), `arm`, `session_id`, `recorded_utc`, `config_dir_listing_sha256` (a hash
  of every path plus file contents), `preflight` (`pass`/`fail`), `failures[]`,
  `auth_var` (name only) and `env_passthrough`. A report cites these lines to prove
  isolation.
- **Cleanup.** Arm roots are removed on exit, including on abort. `--keep` retains
  them. Kept roots hold transcripts, which contain anything the model printed.

Tested by `metrics/run-arms-isolation-test.sh`. It uses a stub `claude` and makes no
API calls.

**This is config isolation, NOT a sandbox.** The arms run with
`--dangerously-skip-permissions`. Redirecting `HOME`/`CLAUDE_CONFIG_DIR` only changes
what Claude Code *loads*; it does not limit what the arm can *do*:

- The arm can still read, and write, any of the operator's files by absolute path,
  including the real `~/.claude`, SSH keys and other repos.
- The arm holds its own credential in its environment, so it could echo it into a
  transcript or log. Kept roots (`--keep`) and `<out>/claude-*.log` may then contain it.

For anything beyond trusted prompts:

- run the arms inside a container or under `sandbox-exec` (macOS), with only the arm
  root writable and the network limited to the API;
- use a short-lived, spend-capped API key scoped to the eval, and revoke it afterwards.

Not covered: `eval-harness.js` and `reliability/reliability-harness.js` dispatch through
Workflow `agent()` inside the current session, so they inherit that session's config
and cannot be isolated this way (#273).

## How it fits together

| Piece | File | Role |
|---|---|---|
| Contract | `schema/fixture.schema.json`, `schema/result.schema.json` | input/output shapes |
| Fixtures | `fixtures/*.json` | two-arm cases across output types |
| Checkers | `checkers/run-checker.sh <kind> <artifact>` | Tier-0 deterministic gate (0 PASS / 1 FAIL / 2 skip) |
| Judge | `judge/pairwise-judge-protocol.md`, `judge/judge-output.schema.json` | blind pairwise panel protocol |
| Runner | `eval-harness.js` (workflow) + `.claude/commands/eval-harness.md` | produce → check → judge → record |
| Aggregator | `aggregate/aggregate.mjs` | de-blinds and renders the report |

## Reading the report

Three tables: **per-dimension** and **per-output-type** library/baseline/tie win-rates +
mean margin, and a **deterministic pass-rate** table with the library−baseline delta.
There is no single pass/fail verdict — it's a breakdown you read to decide adoption.
Judge verdicts are recorded blind (`A`/`B`); the aggregator de-blinds via each record's
`blinding_map`.

## Add a fixture

Copy an existing `fixtures/*.json`, set a distinct `id`/`output_type`, both `arms`
(baseline is always `general-purpose` with a no-skills prompt), a `deterministic_check.kind`
from `{validate-library-artifact, cargo-test, schema-match}`, and a typed `rubric`. Validate
against `schema/fixture.schema.json` (Node + ajv). Add a checker under `checkers/` if a new
`kind` is needed.

## Known limitations

- **Baseline fidelity** — "library OFF" is instruction-suppressed, not a hard sandbox; the
  vanilla agent still has general capability. The harness measures the value of the
  library's *specialization + collaboration structure*, not raw model access.
- **Judge stochasticity** — the panel (N=3, position-randomized, majority/median,
  default-reject) reduces but does not remove variance; trust the *trend*, not one run.
- **Code execution** — `check-code-compiles.sh` runs untrusted model code; it is opt-in
  (`EVAL_ALLOW_CODE_EXEC=1`) with best-effort containment (offline, throwaway CARGO_HOME,
  timeout). Full isolation needs an OS sandbox.

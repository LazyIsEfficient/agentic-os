# eval/metrics — measuring the awareness harness

The instruments that let the awareness harness (SESSION-STATE + survey-guard) be
**measured**, per NORTH_STAR ("tokens per high-quality outcome" + long-horizon
coherence — not vibes). Re-aims `eval/` from single-task *correctness* (the wrong
axis, per the effectiveness investigation) to **tokens-per-outcome + awareness drift**.

## The tools

| file | what | tier |
|---|---|---|
| `session-metrics.mjs` | parse one **Claude Code** transcript → tokens + awareness signals | **Tier 0** deterministic |
| `session-metrics-cursor.mjs` | parse one **Cursor** transcript → turns + awareness signals (tokens N/A in export) | **Tier 0** deterministic |
| `compare.mjs` | diff two transcripts (ON vs OFF arm) → per-metric delta `(OFF − ON)` | **Tier 0** deterministic |
| `run-arms.sh` | run a scenario live under both arms and compare | **stochastic** (one sample) |
| `run-release-arms.sh` | run scenarios under named arms built from git refs (e.g. `v3.0.1` vs `main`), N interleaved samples each → `samples.jsonl` | **stochastic** (N samples) |
| `summarize-samples.mjs` | per-arm mean / min / max of a `samples.jsonl` | **Tier 0** deterministic |

```
node session-metrics.mjs <transcript.jsonl> [--json]
node session-metrics-cursor.mjs <transcript.jsonl> [--json]
node compare.mjs <on.jsonl> <off.jsonl> [--json]   # auto-detects Claude vs Cursor per file
export ANTHROPIC_API_KEY=...   # or CLAUDE_CODE_OAUTH_TOKEN; arms have no login of their own
bash run-arms.sh [--keep] [--out DIR] "<scenario prompt>"
bash session-metrics-test.sh && bash compare-test.sh   # Claude + Cursor self-tests
bash run-arms-isolation-test.sh                        # arm isolation (stub claude, no API)
bash run-release-arms.sh [options] --scenario NAME... NAME=REF[:FLAGS]...
node summarize-samples.mjs <samples.jsonl> [--json]
bash run-release-arms-test.sh                          # release arms (stub claude, no API)
```

## The two arms (`run-arms.sh`)

Each arm runs in its own `mktemp -d` root with its own `HOME` and
`CLAUDE_CONFIG_DIR`, in a scrubbed export of the repo. See
[../README.md#arm-isolation](../README.md#arm-isolation) for the full model.

- **ON** — the library installed by `install.sh` into the arm's temp config dir:
  skills, agents, shipped commands, and every consumer hook (awareness hooks plus
  `block-bad-bash`, `survey-before-act`, `block-general-purpose`).
- **OFF** — a fresh, empty config dir. Nothing installed.

Both run the **same** scenario; the only difference is the library. `compare.mjs`
reports how much *more* the OFF arm spent (positive Δ / `saved%` = the library helped).

The interactive protocol in [AB-PROTOCOL.md](AB-PROTOCOL.md) still defines its arms
with `--settings`. That compares hook sets only and is **not** isolated from a
globally installed library.

## Release arms (`run-release-arms.sh`)

Measures one library state against another, e.g. the last release against `main`,
before a release. Each arm is `NAME=REF[:FLAG,FLAG]`:

```bash
export ANTHROPIC_API_KEY=...   # or CLAUDE_CODE_OAUTH_TOKEN
git fetch origin --tags        # every REF must resolve locally
bash eval/metrics/run-release-arms.sh --runs 3 \
  --scenario long-session-awareness --scenario seeded-path-traversal \
  v301=v3.0.1 main=main mainall=main:--with-marketing,--with-games
```

- **Per-ref install.** Each arm is a `git archive <REF>` export, installed by
  that ref's own `install.sh --force <FLAGS>` into a temp `CLAUDE_CONFIG_DIR`.
  Only `--with-<pack>` flags are accepted. The preflight's expected file set
  comes from the same export and flags: the commands come from that installer's
  `install_files "commands"` line, the installer manifest is expected only when
  that installer writes one (v3.0.1 does not), and pack items are expected only
  for the packs the flags turn on (v3.0.1 has no packs, so it ships everything).
  The isolation model is the same as `run-arms.sh`. There is no OFF arm.
- **Tasks are identical for every arm**, taken from a `git archive HEAD` export
  of the harness repo: `scenarios/<name>.md` runs in the scrubbed repo export;
  `scenarios/<name>/README.md` runs in a copy of `scenarios/<name>/app`,
  committed once as the task base. The prompts are the bare ```` ``` ```` fences
  under `## Scripted prompt sequence` (`lib/scenario-prompts.mjs`). Prompt 1
  starts the session with `--session-id`; every later prompt continues it with
  `--resume <same id>`.
- **Cost gate.** Before anything is set up, the plan and the total are printed:
  `arms x runs x (sum of prompt counts)` `claude -p` invocations. The run needs
  `--yes` or an interactive `y`; with stdin not a terminal and no `--yes`, it
  stops and sends nothing. `long-session-awareness` has 10 prompts, so it costs
  10 invocations per sample. `--max-turns N` and `--max-budget-usd X` are
  passed to every invocation (both are print-mode only; the budget is a cap per
  invocation on Claude Code's client-side estimate, and spend can pass it).
- **Interleaving.** Samples run in rounds: round *r* runs every scenario under
  every arm, with the arm order rotated by one each round, so drift in latency
  or model is spread across arms. Every sample has its own fresh root, and
  every root passes preflight before the first prompt.
- **Scoring.** After each sample: `session-metrics.mjs --json` on the
  transcript; for a scenario with `exploit-check.mjs`, the exploit check and
  `scripts/security-scan.sh --base <task base> --json` (offline mode) in the
  task dir. A missing scanner is recorded as `unavailable`; it never fails the run.

Outputs in `--out` (default `runs/<stamp>-release-arms/`): `isolation.jsonl`
(one preflight record per sample; `repo_sha` is the arm ref's full sha),
`samples.jsonl` (one row per sample: `arm`, `ref`, `flags`, `repo_sha`,
`scenario`, `sample`, `order`, `session_id`, `exit_code` / `exit_codes`,
`metrics`, `compact_boundaries`, `task_base`, `exploit`, `scan`),
`summary.json` (`summarize-samples.mjs --json`), and the per-sample install /
claude / scan logs.

The structural caveat below still applies. The resumed multi-prompt session
may cross a compaction boundary; whether it does is UNVERIFIED for headless
runs. `compact_boundaries` counts `"subtype":"compact_boundary"` transcript
records, and that record shape is also UNVERIFIED against a live transcript. A
0 there means the benefit side was not exercised in that sample.

## Cursor transcripts

Cursor agent sessions are captured as JSONL under:

`~/.cursor/projects/<workspace-slug>/agent-transcripts/<session-id>/<session-id>.jsonl`

(subagent runs: `.../agent-transcripts/<parent-id>/subagents/<subagent-id>.jsonl`)

**Orchestration signals** (`orchestration_signals` in JSON output): `task_dispatches`, `main_thread_edit_tools` (`Write`/`StrReplace`/`Delete`/`EditNotebook` on the **parent** transcript), and `orchestrator_collapse` (`true` when zero `Task` but edit tools present). Use to audit Cursor's orchestrator gap — see [cursor-orchestrator-gap.md](../../docs/cursor-orchestrator-gap.md).

Each line is a JSON object. Assistant records use `role:"assistant"` with
`message.content[]` blocks (`type:"text"`, `type:"tool_use"`). Tool calls expose
`name` and `input` on the block; **Read** uses `input.path` (Claude Code uses
`input.file_path`). As of Cursor 3.8.x these transcripts **do not include token
usage** — use `session-metrics-cursor.mjs` for turns + awareness signals.

Fixed fixtures: `fixtures/sample-cursor-transcript.jsonl`,
`fixtures/nested-input-cursor-transcript.jsonl`. Tier 0 test:
`session-metrics-cursor-test.sh` (also run from `session-metrics-test.sh`).

## What is and isn't proven

- **Deterministic (Tier 0):** given two fixed transcripts, the metrics and the delta
  reproduce exactly. `session-metrics-test.sh` and `compare-test.sh` pin this.
- **NOT deterministic:** a single live `run-arms.sh` is **one stochastic sample**.
  LLM output varies run-to-run; do not read a single delta as the effect size.

### The honest caveat about the *benefit*

The awareness benefit (settled facts surviving, existing infra reused) only shows up
when the session crosses a **compaction boundary** — the exact point where the OFF arm
loses the fact and the ON arm re-injects it.

**Stronger than "use a longer prompt":** a one-shot `claude -p` turn **never
compacts** (S0, reconfirmed in #146), so `run-arms.sh` — and any N-run *headless*
loop built on it — can **never reach that boundary**. Headless therefore measures only
the harness's per-turn token **tax**, with the benefit structurally absent: the ON arm
can only look equal-or-worse. Do **not** report a headless ON−OFF delta as the
benefit result; it answers a benefit question with a cost-only instrument.

Measuring the benefit needs a real **interactive** multi-turn session that crosses
compaction:

| Resource | Role |
|---|---|
| **[AB-PROTOCOL.md](AB-PROTOCOL.md)** | Interactive long-session procedure — N runs/arm, ON vs OFF, transcript capture, `compare.mjs`, distribution analysis |
| **[scenarios/long-session-awareness.md](scenarios/long-session-awareness.md)** | Canonical multi-step scenario (anchor facts → compaction → late probe) |
| **`pre-register.sh`** | Stamp `runs/<timestamp>/hypothesis.md` before sessions |

**Null prior:** the [effectiveness investigation](../INVESTIGATION.md) found **null**
on tractable single-task work (no measurable correctness lift where the base model
already one-shotted). The analogous prior here: compaction-boundary benefit is **not
guaranteed** — the signal, if any, is re-work avoided over long horizons. Pre-register
interpretation before runs; this apparatus makes the question measurable without
pre-judging the answer.

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
| `summarize-samples.mjs` | per-arm mean / min / max of a `samples.jsonl` (complete samples only) | **Tier 0** deterministic |

```
node session-metrics.mjs <transcript.jsonl> [--json]
node session-metrics-cursor.mjs <transcript.jsonl> [--json]
node compare.mjs <on.jsonl> <off.jsonl> [--json]   # auto-detects Claude vs Cursor per file
export ANTHROPIC_API_KEY=...   # or CLAUDE_CODE_OAUTH_TOKEN; arms have no login of their own
bash run-arms.sh [--keep] [--out DIR] "<scenario prompt>"
bash session-metrics-test.sh && bash compare-test.sh   # Claude + Cursor self-tests
bash run-arms-isolation-test.sh                        # arm isolation (stub claude, no API)
bash run-release-arms.sh --smoke --scenario long-session-awareness main=main   # plumbing (2 calls)
bash run-release-arms.sh [options] --scenario NAME... NAME=REF[:FLAGS]...
node summarize-samples.mjs <samples.jsonl> [--json]
bash run-release-arms-test.sh                          # release arms (stub claude, no API)
bash run-release-arms-docker-test.sh                   # docker sandbox vs an adversarial stub (skips without docker)
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

Measures one library state against another, e.g. the last release against
`main`, before a release. Each arm is `NAME=REF[:FLAG,FLAG]`. Live runs use the
default `--sandbox docker`.

```bash
# A dedicated Console workspace API key with a spend limit; revoke it afterwards.
export ANTHROPIC_API_KEY=...
git fetch origin --tags        # every REF must resolve locally
bash eval/metrics/run-release-arms.sh --runs 3 \
  --scenario long-session-awareness --scenario seeded-path-traversal \
  v301=v3.0.1 main=main mainall=main:--with-marketing,--with-games
```

### Sandbox (`--sandbox docker`, the default)

The model runs with `--dangerously-skip-permissions`, so it is treated as
hostile: it may try to forge its own score, read the key, or leave things for
the next sample. The harness runs on the host and does the following:

1. Builds two pinned images: a **base** (`docker/Dockerfile`: node 22.22.0 by
   digest, Claude Code 2.1.311, semgrep 1.182.1, gitleaks 8.30.1 sha256-checked,
   plus only the proxy under `/opt/harness/lib`), and a **scorer**
   (`docker/Dockerfile.scorer`, `FROM` the base, adding the full grader). The
   model and proxy containers run from the base, which does **not** contain the
   scoring code or the exploit vectors, so a sample cannot read the grader. Both
   contexts are staged from the HEAD export; the repo is never mounted into any
   container.
2. Prepares and preflights every sample root on the host, exactly as before.
3. For each sample, in interleaved order:
   - **Sample container.** The root is copied into a fresh docker volume and
     mounted at the same absolute path, so the installed hook paths stay
     valid. The container has no host mount and runs as uid 1000 with
     `--cap-drop ALL`, `no-new-privileges`, a read-only root fs, tmpfs
     `/tmp`, `--init` and a pids limit. It sits on an `--internal` network.
     Each prompt is a separate `docker exec` from the host, so the model
     cannot rewrite a later prompt. The harness re-hashes the installed
     library inside the container and aborts the sample if it differs from the
     preflighted host root.
   - **Proxy container** (`lib/api-proxy.mjs`), the sample's only route out and
     the **authoritative record** of what it spent. The sample's claude gets
     `ANTHROPIC_BASE_URL` pointing at the proxy and a placeholder key; the
     proxy holds the real `ANTHROPIC_API_KEY`, strips any client credential and
     `x-forwarded-*`, and injects the real key. It fully parses each request
     body and allows only `POST /v1/messages`,
     `POST /v1/messages/count_tokens` and `GET /v1/models`, only the arm's
     `model`, `max_tokens` ≤ 32000, and an `anthropic-beta` allowlist, and it
     rejects server-side tools (`web_search`/`web_fetch`/…) and `mcp_servers`.
     It caps requests (400) and cumulative input+output tokens per sample
     (`PROXY_MAX_TOKENS_TOTAL`, default 2,000,000), returning 429 past either.
     It parses usage from each response (including streaming SSE) and logs it,
     never headers or bodies. UNVERIFIED: the exact `anthropic-beta` values and
     endpoints Claude Code 2.1.311 needs — rejections are logged, so the smoke
     run reveals any gap; add the value to `PROXY_BETAS` and re-run.
   - **Scorer container** (`lib/score-sample.mjs`), from the scorer image, with
     network `none` and the sample volume mounted read-only. It reads only the
     task tree and the transcript, as data. The app under test runs as a
     separate uid (2000), so it cannot touch the scorer; every process of that
     uid is killed afterwards.
   - The transcript is copied out of the volume first (a read-only helper,
     size-capped), so a scorer crash can't lose the paid result. The host
     writes out only the transcript, the logs and the score, each through
     `lib/redact.mjs` (key values replaced, size-capped). Containers and the
     volume are then removed; a scorer crash leaves the volume for inspection.

**Trust model.** The model runs with `--dangerously-skip-permissions`, so its
CLI log and the transcript are treated as **model-writable**: awareness metrics
are advisory. **Tokens and cost are proxy-authoritative** (the proxy is outside
the model's reach), and the sample row flags any disagreement with the CLI's
own cost. Completeness is decided from host-observed exit codes, interrupts, and
proxy caps — a model can drop its own sample but cannot forge a complete one or
forge low spend.

`run-release-arms-docker-test.sh` runs 2 samples with an adversarial stub. It
checks that the stub cannot: rewrite the exploit check, scanner or scorer; see
or plant into another sample; see the key in its env or any `/proc/*/environ`;
reach the network except through the proxy; or get a server-tool / oversized /
disallowed-model / disallowed-beta request past the proxy. The vulnerable app
it writes still scores `fail`. The proxy's `echo` test upstream means no API
call is made. The test skips when no docker daemon is reachable.

`--smoke` runs one plumbing sample (1 arm, the long-session scenario truncated
to 2 prompts, 1 run = 2 invocations incl. one `--resume`) and prints a
checklist: proxy 4xx/beta rejections, result-record parsed, transcript holds
both prompts, CLI vs proxy cost, key hash absent from `$OUT`, a web_search
probe rejected, and a manual Ctrl-C note. Use it against the real API once
before a full run to confirm the proxy allowlist and the result-record shape.

`--sandbox none` runs the same pipeline on the host with **no containment**.
It is for tests with a stub `claude` only, and it also accepts
`CLAUDE_CODE_OAUTH_TOKEN`. The docker sandbox needs a Console API key,
because the proxy injects it.

`--sandbox none` runs the same pipeline on the host with **no containment**.
It is for tests with a stub `claude` only, and it also accepts
`CLAUDE_CODE_OAUTH_TOKEN`. The docker sandbox needs a Console API key,
because the proxy injects it.

### What the harness does

- **Per-ref install.** Each arm is a `git archive <REF>` export, installed by
  that ref's own `install.sh --force <FLAGS>` into a temp `CLAUDE_CONFIG_DIR`.
  Only `--with-<pack>` flags are accepted. The preflight's expected file set
  comes from the same export and flags:
  - the commands come from that installer's `install_files "commands"` line;
  - the installer manifest is expected only when that installer writes one
    (v3.0.1 does not);
  - pack items are expected only for the packs the flags turn on. v3.0.1 has
    no packs, so it ships everything.
- **Tasks are identical for every arm.** They come from a `git archive HEAD`
  export of the harness repo:
  - `scenarios/<name>.md` runs in the scrubbed repo export;
  - `scenarios/<name>/README.md` runs in a copy of `scenarios/<name>/app`,
    committed once as the task base.

  The prompts are the bare ```` ``` ```` fences under
  `## Scripted prompt sequence` (`lib/scenario-prompts.mjs`). Prompt 1 starts
  the session with `--session-id`, and later prompts continue it with
  `--resume <same id>`. A prompt that exits non-zero ends its sample.
- **Cost gate.** Before anything is built, set up or sent, the plan is
  printed:
  - the total: `arms x runs x (sum of prompt counts)` `claude -p`
    invocations;
  - the per-invocation budget and its worst-case ceiling;
  - the key advice.

  The run needs `--yes` or an interactive `y`. `long-session-awareness` has
  10 prompts. `--max-budget-usd 5` per invocation is the default; change it
  with `--max-budget-usd X`, or drop it with `--no-max-budget`. It is a cap on
  Claude Code's client-side estimate, and spend can pass it. `--max-turns N`
  is optional. Both flags are **client-side and model-bypassable** (a model can
  call the proxy directly); the proxy's per-sample token cap is the real
  ceiling. UNVERIFIED: whether hitting either limit exits non-zero. Every
  invocation gets `--output-format json`, so the log ends with the CLI's result
  record. A sample is marked incomplete on a non-zero exit, an interrupt, a
  proxy 429, or a structured non-success CLI result record (`subtype !==
  "success"` or `is_error`) — never by matching free text. The cost gate also
  prints the proxy token cap and a worst-case dollar ceiling at UNVERIFIED
  prices.
- **Interleaving.** Samples run in rounds. Round *r* runs every scenario under
  every arm, with the arm order rotated by one each round. Every sample has
  its own fresh root (and, in docker, its own volume and containers).
- **Scoring** (in the scorer): `session-metrics` on the transcript. For a
  scenario with `exploit-check.mjs`, two more checks run on a copy of the
  task:
  - the exploit check. A symlink or special file in the task scores `error`.
    The app runs in its own process group, as uid 2000 in docker.
  - `security-scan.sh --base <base> --json` (offline mode), via
    `lib/scan-task.sh`. It runs in a fresh repo the scorer builds: the
    pristine app as the base commit, with the task's files (minus `.git`) as
    the working tree. Git runs with no system, global, hook or fsmonitor
    config.

    `scan-task.sh` first strips every `.gitignore`/`.gitattributes`, nested
    `.git` and `.git/info/exclude`, then force-adds all files, so a model
    cannot hide a planted file from the scan.

  A missing scanner is recorded as `unavailable`.
- **Summary.** `summarize-samples.mjs` reports per arm, over **complete**
  samples only, the proxy-authoritative tokens and cost as the **primary**
  block and the transcript awareness signals as an **advisory** block. It
  strips control characters from every printed and stored string, prints a
  `WARNING` for any arm with incomplete samples, and counts those per arm with
  their reasons.

`--out` must be outside the repo. The default is
`$HOME/agentic-os-eval-runs/<stamp>-release-arms`. It contains:

- `isolation.jsonl`: one preflight record per sample;
- `samples.jsonl`: one row per sample. The fields are `arm`, `ref`, `flags`,
  `repo_sha`, `sandbox`, `scenario`, `sample`, `order`, `session_id`,
  `prompts`, `prompts_run`, `status`, `incomplete_reason`, `stop_signals`,
  `exit_code` / `exit_codes`, `tokens` (proxy), `cost_usd` + `cost_source` +
  `cli_cost_usd` + `cost_mismatch_usd`, `proxy`, `metrics` (advisory),
  `compact_boundaries`, `task_base`, `exploit` and `scan`;
- `proxy-<tag>.log`: the authoritative per-request record for that sample;
- `summary.json`;
- `transcripts/<tag>.jsonl`;
- `claude-<tag>.log`, `proxy-<tag>.log`, `install-<tag>.log`, and
  `score-<tag>.json` / `.err`.

Every one of these is written by the host; no container mounts it.

The structural caveat below still applies. The resumed multi-prompt session
may cross a compaction boundary, but whether it does is UNVERIFIED for headless
runs. `compact_boundaries` counts `"subtype":"compact_boundary"` transcript
records, and that record shape is also UNVERIFIED. A 0 there means the benefit
side was not exercised in that sample.

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

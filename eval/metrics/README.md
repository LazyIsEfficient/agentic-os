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

```
node session-metrics.mjs <transcript.jsonl> [--json]
node session-metrics-cursor.mjs <transcript.jsonl> [--json]
node compare.mjs <on.jsonl> <off.jsonl> [--json]   # auto-detects Claude vs Cursor per file
bash run-arms.sh "<scenario prompt>"
bash session-metrics-test.sh && bash compare-test.sh   # Claude + Cursor self-tests
```

## The two arms

- **ON** — `claude --settings .claude/settings.json`: the awareness hooks are
  active (SESSION-STATE injected at SessionStart + digested each turn; survey-guard).
- **OFF** — `claude --settings '{"hooks":{}}'`: no awareness hooks, everything else
  equal — the clean baseline. (`--bare` also strips LSP/plugins, so it confounds the
  comparison; empty-hooks settings isolates the harness itself.)

Both run the **same** scenario; the only difference is the harness. `compare.mjs`
reports how much *more* the OFF arm spent (positive Δ / `saved%` = the harness helped).

## Cursor transcripts

Cursor agent sessions are captured as JSONL under:

`~/.cursor/projects/<workspace-slug>/agent-transcripts/<session-id>/<session-id>.jsonl`

(subagent runs: `.../agent-transcripts/<parent-id>/subagents/<subagent-id>.jsonl`)

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

# Data Model

Canonical catalog of data contracts that cross a boundary in this repo — the
cross-session memory files and the Claude Code Stop-hook memory-extraction
contracts.

**Last updated:** 2026-10-19

## Change log

| Date | Run | Summary |
|---|---|---|
| 2026-10-19 | fix/audit-reviewer-contract | Added `ReviewVerdict` (reviewer-emitted `agentic-os/review-verdict@1` fenced JSON block) and `ReviewVerdictNormalized` (`scripts/parse-verdict.sh` stdout + exit codes, incl. `demoted_from` / `verdict_demoted_from`). |
| 2026-07-13 | remove-dispatch-gate | Removed the dispatch-gate contracts (`DispatchGateAuditRecord`, `DispatchGateHookDecision`, `DispatchGateHookEventPayload`, `DispatchGateLedger`, `DispatchGatePolicyConfig`); that gate was retired and its scripts and config deleted. |
| 2026-07-13 | feat/memory-extraction | Added memory-encoding contracts (issue #217): `MemoryEntryFile` + `MemoryIndexLine` (memory-extraction skill on-disk format), `MemoryExtractHookState` (hook-owned per-session turn counter), and `MemoryExtractStopHookIO` (Stop-hook stdin/stdout). |
| 2026-07-07 | feat/claude-md-flatten | No-op: `scripts/build-claude-md.sh` + `validate.sh` `claude-flat-sync` exchange generated markdown via BEGIN/END RULE marker comments — an internal build-artifact convention with no fields, not a data contract. No API/persistence/message changes. |
| 2026-07-06 | fix/macos-bash-issue-with-validate-script | No-op: `scripts/validate.sh` changes (ulimit fd bump, check_tombstones grep refactor) are internal control flow only — no data contracts affected. |

---

### MemoryEntryFile

| Field | Value |
|---|---|
| **Kind** | `persistence` |
| **Ingestion route** | One Markdown file per durable fact written to `${CLAUDE_PROJECT_DIR:-.}/.claude/memory/<snake_case>.md` by the `memory-extraction` skill (procedure step 5, `SKILL.md:85`). Append-or-update, never clobber — only the entry file(s) for facts written this run are touched (`SKILL.md:137-157`). |
| **Source** | `.claude/skills/memory-extraction/SKILL.md` (Memory-file format, lines 93–135) |

Filename is `snake_case.md` (underscores), a short subject-descriptive slug (`SKILL.md:97`).

**Shape** (YAML frontmatter + Markdown body; example from `SKILL.md:103-108`):

```
---
name: no-python-use-rust
description: One line — the fact and, for a user/feedback fact, whose it is.
metadata:
  type: feedback
---

<body — Markdown prose; conventions vary by type>
```

| Name | Type | Required | Notes |
|---|---|---|---|
| `name` | string (kebab-case) | yes | Same words as the filename with `_`→`-`, e.g. `no-python-use-rust` — `SKILL.md:100`,`:111-112` |
| `description` | string (one line) | yes | The fact; for a user/feedback fact, whose it is — `SKILL.md:105` |
| `metadata` | object | yes | Container nesting `type` (a top-level `type:` is wrong) — `SKILL.md:99-100`,`:106` |
| `metadata.type` | enum string | yes | `user` \| `feedback` \| `project` \| `reference` — `SKILL.md:113` |
| body | Markdown prose | yes | Per-`type` conventions below — `SKILL.md:114-123` |

Body conventions:

- **feedback** — leads with the rule/directive (quote the correction verbatim when available), then a `**Why:**` line and a `**How to apply:**` line — `SKILL.md:115-117`.
- **project** / **user** — states the fact and why it matters; add `**How to apply:**` when there is a concrete action — `SKILL.md:118-119`.
- Relative dates converted to absolute (`"Thursday"` → `2026-07-13`) — `SKILL.md:120`.
- Sibling cross-references via wikilink `[[other_slug]]` (snake_case filename, no extension) that must resolve to a real sibling — `SKILL.md:121-123`.

---

### MemoryExtractHookState

| Field | Value |
|---|---|
| **Kind** | `persistence` |
| **Ingestion route** | Single hook-owned turn-state file per session at `${CLAUDE_PROJECT_DIR:-.}/.claude/memory/.extract/<sid>` (`memory-extract.sh:28`,`:44-45`). Created via `mkdir -p` (`:54`), overwritten each Stop with `printf '%s %s\n'` (`:59`,`:67`), read back at `:49`. `<sid>` = the Stop event `session_id` sanitized to `[A-Za-z0-9_.-]` with `..` neutralized, defaulting to `last` when empty/`.`/`..` (`:38-42`). The `memory-extraction` skill must NOT write here (`SKILL.md:175-178`). |
| **Source** | `.claude/hooks/memory-extract.sh` (lines 44–67) |

**Shape** — a single line, two space-separated non-negative integers:

```
<turns> <nudged_at>
```

| Name | Type | Required | Notes |
|---|---|---|---|
| `turns` | integer ≥ 0 | yes | Running count of Stop invocations this session; incremented `+1` each run (`memory-extract.sh:52`). Missing/garbled file → `0` (`:48`,`:50`) |
| `nudged_at` | integer ≥ 0 | yes | The `turns` value at the last nudge; `0` = never nudged (`memory-extract.sh:9`,`:66`). Missing/garbled → `0` (`:48`,`:51`). Re-nudge fires when `turns - nudged_at >= N` with `N=3` (`:24`,`:58`) |

Garbled or absent content defaults the whole pair to `0 0` (`memory-extract.sh:48-51`).

---

### MemoryExtractStopHookIO

| Field | Value |
|---|---|
| **Kind** | `message` |
| **Ingestion route** | The Claude Code **Stop** hook. INPUT is the Stop event JSON read from **stdin** (`event="$(cat)"`, `memory-extract.sh:29`); OUTPUT is one JSON object printed to **stdout** and consumed by the Claude Code hook runtime. Fail-open: any error (no `jq`, empty/malformed stdin, unwritable fs) emits allow `{}` and exits 0 (`memory-extract.sh:26`,`:31-34`,`:54`). |
| **Source** | `.claude/hooks/memory-extract.sh` (lines 26–73) |

**INPUT** (Stop event, stdin) — only `session_id` is consumed:

```json
{ "session_id": "sess_xyz" }
```

| Name | Type | Required | Notes |
|---|---|---|---|
| `session_id` | string | no | Only field read (`.session_id // empty`); empty → `"last"`, then sanitized — `memory-extract.sh:38-39` |

`transcript_path` and `stop_hook_active`, though standard Stop-event fields, are NOT referenced by this hook (verified: no occurrence in the script; the header comment explicitly disclaims any dependence on `stop_hook_active` — `memory-extract.sh:15`).

**OUTPUT** (stdout) — exactly one of:

Allow (`memory-extract.sh:26`):

```json
{}
```

Block / steer (`memory-extract.sh:72`):

```json
{ "decision": "block", "reason": "<nudge text>" }
```

| Name | Type | Required | Notes |
|---|---|---|---|
| `decision` | string | only when blocking | Literal `"block"` — `memory-extract.sh:72` |
| `reason` | string | only when blocking | Nudge instructing the still-live agent to run the `memory-extraction` skill now; interpolates the sanitized `session_id` — `memory-extract.sh:70`,`:72` |

---

### MemoryIndexLine

| Field | Value |
|---|---|
| **Kind** | `persistence` |
| **Ingestion route** | One Markdown list item per entry appended to / updated in `${CLAUDE_PROJECT_DIR:-.}/.claude/memory/MEMORY.md` by the `memory-extraction` skill (procedure step 6, `SKILL.md:86-88`). Exactly one line per NEW entry; the single existing line replaced for an UPDATE; index kept ≤ 200 lines (`SKILL.md:148-154`). |
| **Source** | `.claude/skills/memory-extraction/SKILL.md` (Index line, lines 124–135) |

**Shape** (`SKILL.md:133`):

```
- [<Title Case>](<snake_case_filename>.md) — <one-line hook>
```

| Name | Type | Required | Notes |
|---|---|---|---|
| leading `- ` | literal | yes | Dash + space — `SKILL.md:127` |
| link text | string (Title Case) | yes | Title in `[...]`; the kebab-case `name:` field is NOT used here — `SKILL.md:128`,`:135` |
| link target | string (snake_case filename, incl. `.md`) | yes | e.g. `no_python_use_rust.md` — `SKILL.md:129`,`:133` |
| separator ` — ` | literal | yes | Space, em-dash, space — `SKILL.md:130` |
| hook | string (≤ ~150 chars) | yes | One-line hook — `SKILL.md:131` |

---

### ReviewVerdict

| Field | Value |
|---|---|
| **Kind** | `message` |
| **Ingestion route** | Emitted by gate reviewer agents as the **last** fenced `json` block of their final output (`review-verdict.md:28-30`); consumed by `scripts/parse-verdict.sh` from a file argument or stdin (`parse-verdict.sh:26-33`). Emitters: `code-reviewer`, `security-reviewer`, `library-reviewer` (verdict `pass`\|`fix-before-merge`\|`hold`) and `data-model-verifier` (`pass`\|`hold` subset only) — `review-verdict.md:9-12`; each agent's `## Verdict block` section. `library-investigator` and `adversarial-claims-reviewer` are exempt (`review-verdict.md:14-16`). |
| **Source** | `.claude/references/review-verdict.md` (Shape, lines 26–68); `scripts/parse-verdict.sh` (extraction lines 35–55, validation lines 58–95); emitters `.claude/agents/code-reviewer.md:62-68`, `.claude/agents/security-reviewer.md:67-73`, `.claude/agents/library-reviewer.md:67-73`, `.claude/agents/data-model-verifier.md:72-78`; fixtures `scripts/fixtures/review-verdict/*.txt`, tests `scripts/parse-verdict-test.sh` |

**Framing** (`parse-verdict.sh:37-45`): an opening fence line matching `^[[:space:]]*```json[[:space:]]*$` and a closing line matching `^[[:space:]]*```[[:space:]]*$`. The last complete block wins; text after it is ignored; a trailing unterminated `json` block is invalid. The block body must contain exactly one JSON value, which must be an object (`parse-verdict.sh:55`,`:79-81`).

**Shape** (`review-verdict.md:32-50`):

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

| Name | Type | Required | Notes |
|---|---|---|---|
| `schema` | string literal | yes | Exactly `agentic-os/review-verdict@1` — `parse-verdict.sh:83-84` |
| `agent` | string (non-blank) | yes | Reviewer's `name:`; rejected if not a string or whitespace-only — `parse-verdict.sh:58`,`:85` |
| `base` | string (non-blank) | yes | Base ref diffed against, e.g. `origin/main` — `parse-verdict.sh:86` |
| `head` | string | yes | Full commit SHA, regex `^([0-9a-f]{40}\|[0-9a-f]{64})$` (lowercase hex) — `parse-verdict.sh:87-88` |
| `verdict` | enum string | yes | `pass` \| `fix-before-merge` \| `hold` — `parse-verdict.sh:89-90`. `data-model-verifier` emits only `pass` \| `hold` (prompt-level rule, not parser-enforced) — `review-verdict.md:12` |
| `findings` | array of Finding | yes | May be empty; non-array rejected — `parse-verdict.sh:91-93` |

Finding (each element must be an object — `parse-verdict.sh:62`):

| Name | Type | Required | Notes |
|---|---|---|---|
| `tier` | number | yes | `0` \| `1` \| `2` — `parse-verdict.sh:64-65` |
| `severity` | enum string | yes | `critical` \| `high` \| `medium` \| `low` — `parse-verdict.sh:66-67`. Prose blocking / should-fix / nit map to `high`-or-`critical` / `medium` / `low` — `review-verdict.md:67-68` |
| `file` | string (non-blank) | yes | Contract says repo-relative path (`review-verdict.md:62`); parser checks only non-blank string — `parse-verdict.sh:68-69` |
| `line` | integer ≥ 1 \| null | no | Omitted or `null` = file-level finding — `parse-verdict.sh:70-71` |
| `summary` | string (non-blank) | yes | One sentence — `parse-verdict.sh:72-73` |
| `evidence` | string \| null | no (schema) | Must be a string when present — `parse-verdict.sh:74-75`. Contract-required for tier 0/1 (`review-verdict.md:65`); absence is not a validation error but triggers demotion (see `ReviewVerdictNormalized`) |

Unknown extra keys at either level are not rejected; they are dropped from the normalized output (`parse-verdict.sh:98`,`:106`).

---

### ReviewVerdictNormalized

| Field | Value |
|---|---|
| **Kind** | `message` |
| **Ingestion route** | Output of `bash scripts/parse-verdict.sh [FILE]` (stdin when FILE omitted). On exit `0` or `2` a single line of compact JSON is printed to **stdout** (`parse-verdict.sh:119-125`); on exit `1` nothing is printed to stdout and one `parse-verdict: <reason>` line per error goes to **stderr** (`parse-verdict.sh:22`,`:114-117`). Consumers: gate orchestration / Stop hook / CI. |
| **Source** | `scripts/parse-verdict.sh` (normalization lines 97–125); `.claude/references/review-verdict.md` (Normalization + exit codes, lines 70–94) |

**Exit codes** (`parse-verdict.sh:15-18`,`:122-125`):

| Exit | Meaning |
|---|---|
| `0` | Valid; normalized `verdict` is `pass` or `fix-before-merge` |
| `1` | Invalid: no complete `json` block, unterminated trailing block, invalid JSON, not exactly one value, schema/enum/required-field violation; also usage error, unreadable file, or missing `jq` (`parse-verdict.sh:24-29`,`:50-55`) |
| `2` | Valid; normalized `verdict` is `hold` (at least one tier 0/1 finding survived demotion) |

**Shape** (stdout, compact JSON; example per `scripts/fixtures/review-verdict/hold-unevidenced.txt` input):

```json
{"schema":"agentic-os/review-verdict@1","agent":"code-reviewer","base":"origin/main","head":"0123456789abcdef0123456789abcdef01234567","verdict":"fix-before-merge","findings":[{"demoted_from":1,"tier":2,"severity":"high","file":"src/a.ts","line":3,"summary":"Looks racy","evidence":"  "}],"verdict_demoted_from":"hold"}
```

| Name | Type | Required | Notes |
|---|---|---|---|
| `schema` | string literal | yes | Passed through — `parse-verdict.sh:106` |
| `agent` | string | yes | Passed through — `parse-verdict.sh:106` |
| `base` | string | yes | Passed through — `parse-verdict.sh:106` |
| `head` | string | yes | Passed through — `parse-verdict.sh:106` |
| `verdict` | enum string | yes | `pass` \| `fix-before-merge` \| `hold`. A `hold` with zero findings at tier ≤ 1 after demotion is rewritten to `fix-before-merge` — `parse-verdict.sh:107-108` |
| `findings` | array of NormalizedFinding | yes | Each input finding mapped through `normalize_finding` — `parse-verdict.sh:106` |
| `verdict_demoted_from` | string literal `"hold"` | no | Present only when the `hold` → `fix-before-merge` downgrade fired — `parse-verdict.sh:108` |

NormalizedFinding (`parse-verdict.sh:97-101`):

| Name | Type | Required | Notes |
|---|---|---|---|
| `demoted_from` | number (`0` \| `1`) | no | Present only when the input tier was 0/1 and `evidence` was missing, `null`, or whitespace-only; holds the original tier — `parse-verdict.sh:99-100` |
| `tier` | number | yes | `0` \| `1` \| `2`; set to `2` on demotion — `parse-verdict.sh:100` |
| `severity` | enum string | yes | Passed through |
| `file` | string | yes | Passed through |
| `line` | integer ≥ 1 \| null | yes | Always present; omitted input → `null` — `parse-verdict.sh:98` |
| `summary` | string | yes | Passed through |
| `evidence` | string \| null | yes | Always present; omitted input → `null`; a blank string is kept as-is (even when demoted) — `parse-verdict.sh:98` |

Key order: `demoted_from` is emitted first in a demoted finding; `verdict_demoted_from` last at top level (`parse-verdict.sh:100`,`:108`). Consumers should not rely on key order.

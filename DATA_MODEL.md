# Data Model

Canonical catalog of data contracts that cross a boundary in this repo — the
cross-session memory files, the Claude Code Stop-hook memory-extraction
contracts, and the PreToolUse general-purpose-ban hook I/O.

**Last updated:** 2026-10-19

## Change log

| Date | Run | Summary |
|---|---|---|
| 2026-10-19 | fix/audit-validate-rules | No-op: new `scripts/validate.sh` static checks (R4/R6/R9/R12/R13, skill-length, workflow-agent-type, no-general-purpose), a `warn()` helper emitting `WARN [tag]: path — reason`, and a warning count in the summary line are human-readable CLI output with no machine consumer in the repo (no file outside `scripts/validate*.sh` references the `WARN [` line). Warnings never change the exit code. No API/persistence/message changes. |
| 2026-10-19 | fix/audit-reviewer-contract | Added `ReviewVerdict` (reviewer-emitted `agentic-os/review-verdict@1` fenced JSON block) and `ReviewVerdictNormalized` (`scripts/parse-verdict.sh` stdout + exit codes, incl. `demoted_from` / `verdict_demoted_from`). Second pass: exactly-one-block framing (no trailing text), `agent` enum, parser-enforced `data-model-verifier` pass\|hold, pass-contradiction and duplicate-key rejection, `--expect-head`, exit `3` = `fix-before-merge`; all citations re-cut. |
| 2026-10-19 | fix/audit-gp-ban (PR #284) | Added `BlockGeneralPurposeHookIO`: PreToolUse (`Agent\|Task`) hook stdin fields consumed and the `hookSpecificOutput` deny payload emitted by `.claude/hooks/block-general-purpose.sh`. |
| 2026-07-13 | remove-dispatch-gate | Removed the dispatch-gate contracts (`DispatchGateAuditRecord`, `DispatchGateHookDecision`, `DispatchGateHookEventPayload`, `DispatchGateLedger`, `DispatchGatePolicyConfig`); that gate was retired and its scripts and config deleted. |
| 2026-07-13 | feat/memory-extraction | Added memory-encoding contracts (issue #217): `MemoryEntryFile` + `MemoryIndexLine` (memory-extraction skill on-disk format), `MemoryExtractHookState` (hook-owned per-session turn counter), and `MemoryExtractStopHookIO` (Stop-hook stdin/stdout). |
| 2026-07-07 | feat/claude-md-flatten | No-op: `scripts/build-claude-md.sh` + `validate.sh` `claude-flat-sync` exchange generated markdown via BEGIN/END RULE marker comments — an internal build-artifact convention with no fields, not a data contract. No API/persistence/message changes. |
| 2026-07-06 | fix/macos-bash-issue-with-validate-script | No-op: `scripts/validate.sh` changes (ulimit fd bump, check_tombstones grep refactor) are internal control flow only — no data contracts affected. |

---

### BlockGeneralPurposeHookIO

| Field | Value |
|---|---|
| **Kind** | `message` |
| **Ingestion route** | The Claude Code **PreToolUse** hook, registered with matcher `Agent\|Task` and `"onFailure": "block"` in `.claude/settings.json:22-24` (consumer copy: `assets/consumer/claude-settings.json:12-14`). INPUT is the PreToolUse event JSON read from **stdin** (`input=$(< /dev/stdin)`, `block-general-purpose.sh:40`); OUTPUT is printed to **stdout** for the hook runtime. Always exits 0. **Fails closed**: missing `jq` or any jq error (invalid JSON, non-object payload, missing/non-string `tool_name`, non-string `subagent_type`) emits a deny (`:42-44`, `:46-48`, `:65-67`). No bypass switch (`:25-27`). |
| **Source** | `.claude/hooks/block-general-purpose.sh` (lines 29–68) |

**INPUT** (PreToolUse event, stdin) — only these fields are consumed:

```json
{ "tool_name": "Agent", "tool_input": { "subagent_type": "engineer" } }
```

| Name | Type | Required | Notes |
|---|---|---|---|
| `tool_name` | string (non-empty) | yes | Not a string or `""` → jq `error` → fail-closed deny. Anything other than `"Agent"` / `"Task"` → `skip` (allow) — `block-general-purpose.sh:50-51` |
| `tool_input.subagent_type` | string | no | Absent → `""`. Lowercased with `[^a-z0-9]` stripped; `""` or `generalpurpose` → deny, otherwise allow. A non-string value makes `ascii_downcase` error → fail-closed deny — `block-general-purpose.sh:53-54` |

**OUTPUT** (stdout) — exactly one of:

Allow (named specialist, or not an Agent/Task call): no output, exit 0 (`block-general-purpose.sh:59`).

Deny (`block-general-purpose.sh:36`, `:61-62`):

```json
{ "hookSpecificOutput": { "hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": "<text>" } }
```

| Name | Type | Required | Notes |
|---|---|---|---|
| `hookSpecificOutput` | object | yes (on deny) | Container for the three fields below |
| `hookSpecificOutput.hookEventName` | string | yes | Literal `"PreToolUse"` — `:36`, `:62` |
| `hookSpecificOutput.permissionDecision` | string | yes | Literal `"deny"` — `:36`, `:62` |
| `hookSpecificOutput.permissionDecisionReason` | string | yes | Prefixed `block-general-purpose: `. Gives the cause (general-purpose/untyped, `jq` missing, or unparseable payload) followed by the specialist list `$SPECIALISTS` — `:31`, `:43`, `:61`, `:66` |

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
| **Ingestion route** | Emitted by gate reviewer agents as the **only** fenced `json` block of their final output, placed at the very end (`review-verdict.md:32-36`); consumed by `scripts/parse-verdict.sh [--expect-head <sha>] [FILE]` from the file argument or stdin (`parse-verdict.sh:7-8`,`:31-50`). Emitters: `code-reviewer`, `security-reviewer`, `library-reviewer` (verdict `pass`\|`fix-before-merge`\|`hold`) and `data-model-verifier` (`pass`\|`hold` only, parser-enforced) — `review-verdict.md:11-16`; each agent's `## Verdict block` section. `library-investigator` and `adversarial-claims-reviewer` are exempt (`review-verdict.md:18-20`). |
| **Source** | `.claude/references/review-verdict.md` (Shape lines 30–74, rejections 87–94); `scripts/parse-verdict.sh` (framing lines 52–76, duplicate-key check 78–97, validation 99–145, post-demotion checks 153–161); emitters `.claude/agents/code-reviewer.md:62-68`, `.claude/agents/security-reviewer.md:67-73`, `.claude/agents/library-reviewer.md:67-73`, `.claude/agents/data-model-verifier.md:72-78`; fixtures `scripts/fixtures/review-verdict/*.txt`, tests `scripts/parse-verdict-test.sh` |
| **Notes** | `.claude/references/review-verdict.md` and `scripts/parse-verdict.sh` are repo-side tooling and do NOT ship via `install.sh` (only `.claude/agents/` ships); each emitting agent restates the enum, required fields, and demotion rule inline in its `## Verdict block` (`review-verdict.md:7-9`; e.g. `code-reviewer.md:64`). |

**Framing** (`parse-verdict.sh:52-76`; `review-verdict.md:32-36`): an opening fence line matching `^[[:space:]]*```json[[:space:]]*$` and a closing line matching `^[[:space:]]*```[[:space:]]*$` (`parse-verdict.sh:56-57`). The output must contain **exactly one** such block and only whitespace may follow its closing fence. Rejected with exit `1`: zero blocks (`:61`,`:71`), an unterminated block (`:62`,`:72`), more than one block — including a `json` block quoted inside a longer fence (`:63`,`:73`; fixtures `multiple-blocks.txt`, `nested-quote-override.txt`), or any non-whitespace after the closing fence (`:59`,`:64`,`:74`; fixture `trailing-text.txt`). Text *before* the block is allowed. The block body must parse as JSON (`:99`) and contain exactly one value (`:124`) that is an object (`:126`).

**Duplicate keys** (`parse-verdict.sh:78-97`): when `python3` is on PATH, the block is parsed with `python3 -I` using an `object_pairs_hook` that rejects any repeated key at any object level (stderr `parse-verdict: duplicate JSON key: <k>`, exit `1`; fixture `duplicate-key.txt`). Python syntax errors are ignored there and left to jq (`:91-92`). If `python3` is missing, a stderr warning is printed and the check is skipped (`:96`).

**Shape** (`review-verdict.md:38-56`):

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
| `schema` | string literal | yes | Exactly `agentic-os/review-verdict@1` — `parse-verdict.sh:128-129` |
| `agent` | enum string | yes | One of `code-reviewer` \| `security-reviewer` \| `library-reviewer` \| `data-model-verifier`; anything else rejected (fixture `unknown-agent.txt`) — `parse-verdict.sh:104`,`:130-131`; `review-verdict.md:61` |
| `base` | string (non-blank) | yes | Base ref diffed against, e.g. `origin/main` — `parse-verdict.sh:132` |
| `head` | string | yes | Full commit SHA, regex `^([0-9a-f]{40}\|[0-9a-f]{64})$` (lowercase hex) — `parse-verdict.sh:133-134`. With `--expect-head <sha>`, must equal `<sha>` exactly or exit `1` — `parse-verdict.sh:35-37`,`:135-136`; `review-verdict.md:104` |
| `verdict` | enum string | yes | `pass` \| `fix-before-merge` \| `hold` — `parse-verdict.sh:137-138`. `data-model-verifier` may emit only `pass` \| `hold`; `fix-before-merge` from it is rejected (fixture `verifier-fix-before-merge.txt`) — `parse-verdict.sh:139-140`; `review-verdict.md:64` |
| `findings` | array of Finding | yes | May be empty; non-array rejected — `parse-verdict.sh:141-143` |

Finding (each element must be an object — `parse-verdict.sh:107`):

| Name | Type | Required | Notes |
|---|---|---|---|
| `tier` | number | yes | `0` \| `1` \| `2` — `parse-verdict.sh:109-110` |
| `severity` | enum string | yes | `critical` \| `high` \| `medium` \| `low` — `parse-verdict.sh:111-112`. Prose blocking / should-fix / nit map to `high`-or-`critical` / `medium` / `low` — `review-verdict.md:73-74` |
| `file` | string (non-blank) | yes | Repo-relative path by convention (`review-verdict.md:68`); parser checks only non-blank string — `parse-verdict.sh:113-114` |
| `line` | integer ≥ 1 \| null | no | Omitted or `null` = file-level finding — `parse-verdict.sh:115-116` |
| `summary` | string (non-blank) | yes | One sentence — `parse-verdict.sh:117-118` |
| `evidence` | string \| null | no (schema) | Must be a string when present — `parse-verdict.sh:119-120`. Contract-required for tier 0/1 (`review-verdict.md:71`); absence is not a validation error but triggers demotion (see `ReviewVerdictNormalized`) |

**Cross-field rejections** (evaluated after demotion, only when the schema checks above pass — `parse-verdict.sh:153-168`; `review-verdict.md:87-91`), each exit `1`:

- `verdict: pass` with one or more tier 0/1 findings that still carry evidence after demotion (fixture `pass-contradiction.txt`) — `parse-verdict.sh:157-158`.
- `agent: data-model-verifier` with `verdict: hold` and zero evidenced tier 0/1 findings — rejected, NOT downgraded (fixture `verifier-unevidenced-hold.txt`) — `parse-verdict.sh:159-160`.

Unknown extra keys at either level are not rejected; they are dropped from the normalized output (`parse-verdict.sh:148`,`:166`).

---

### ReviewVerdictNormalized

| Field | Value |
|---|---|
| **Kind** | `message` |
| **Ingestion route** | Output of `bash scripts/parse-verdict.sh [--expect-head <sha>] [FILE]` (stdin when FILE omitted; `parse-verdict.sh:7-8`,`:31-50`). On exit `0`, `2` or `3` a single line of compact JSON is printed to **stdout** (`parse-verdict.sh:183-190`); on exit `1` nothing is printed to stdout and one `parse-verdict: <reason>` line per error goes to **stderr** (`parse-verdict.sh:26`,`:178-180`). Consumers: gate orchestration / Stop hook / CI. |
| **Source** | `scripts/parse-verdict.sh` (exit codes lines 17–22, normalization 147–175, emit 183–190); `.claude/references/review-verdict.md` (Normalization + rejections lines 76–94, exit codes 96–113) |
| **Notes** | Parser and reference doc are repo-side tooling, not shipped by `install.sh` (`review-verdict.md:7-9`). |

**Exit codes** (`parse-verdict.sh:17-22`,`:186-190`; `review-verdict.md:106-113`):

| Exit | Meaning |
|---|---|
| `0` | Valid; normalized `verdict` is `pass` |
| `1` | Invalid: block count/position (zero, >1, unterminated, trailing text), invalid JSON, not exactly one value, duplicate keys, schema/enum/required-field/agent violation, a cross-field rejection (pass contradiction, `data-model-verifier` `fix-before-merge` or unevidenced `hold`), or `--expect-head` mismatch; also usage error, unreadable file, or missing `jq` (`parse-verdict.sh:26-29`,`:36-46`,`:69-76`,`:94`,`:99`,`:178-180`) |
| `2` | Valid; normalized `verdict` is `hold` (at least one tier 0/1 finding survived demotion) |
| `3` | Valid; normalized `verdict` is `fix-before-merge`, including a downgraded unevidenced `hold` |

**Shape** (stdout, compact JSON; example per `scripts/fixtures/review-verdict/hold-unevidenced.txt` input, which exits `3`):

```json
{"schema":"agentic-os/review-verdict@1","agent":"code-reviewer","base":"origin/main","head":"0123456789abcdef0123456789abcdef01234567","verdict":"fix-before-merge","findings":[{"demoted_from":1,"tier":2,"severity":"high","file":"src/a.ts","line":3,"summary":"Looks racy","evidence":"  "}],"verdict_demoted_from":"hold"}
```

| Name | Type | Required | Notes |
|---|---|---|---|
| `schema` | string literal | yes | Passed through — `parse-verdict.sh:166` |
| `agent` | enum string | yes | Passed through (already validated against the four-agent enum) — `parse-verdict.sh:166` |
| `base` | string | yes | Passed through — `parse-verdict.sh:166` |
| `head` | string | yes | Passed through; equals `--expect-head` when that flag was given — `parse-verdict.sh:166` |
| `verdict` | enum string | yes | `pass` \| `fix-before-merge` \| `hold`. A `hold` with zero findings at tier ≤ 1 after demotion is rewritten to `fix-before-merge` — `parse-verdict.sh:170-172`. Never fires for `data-model-verifier` (that case is rejected first — `:159-160`) |
| `findings` | array of NormalizedFinding | yes | Each input finding mapped through `normalize_finding` — `parse-verdict.sh:166` |
| `verdict_demoted_from` | string literal `"hold"` | no | Present only when the `hold` → `fix-before-merge` downgrade fired — `parse-verdict.sh:171` |

NormalizedFinding (`parse-verdict.sh:147-151`):

| Name | Type | Required | Notes |
|---|---|---|---|
| `demoted_from` | number (`0` \| `1`) | no | Present only when the input tier was 0/1 and `evidence` was missing, `null`, or whitespace-only; holds the original tier — `parse-verdict.sh:149-150` |
| `tier` | number | yes | `0` \| `1` \| `2`; set to `2` on demotion — `parse-verdict.sh:150` |
| `severity` | enum string | yes | Passed through — `parse-verdict.sh:148` |
| `file` | string | yes | Passed through — `parse-verdict.sh:148` |
| `line` | integer ≥ 1 \| null | yes | Always present; omitted input → `null` — `parse-verdict.sh:148` |
| `summary` | string | yes | Passed through — `parse-verdict.sh:148` |
| `evidence` | string \| null | yes | Always present; omitted input → `null`; a blank string is kept as-is (even when demoted) — `parse-verdict.sh:148` |

Key order: `demoted_from` is emitted first in a demoted finding; `verdict_demoted_from` last at top level (`parse-verdict.sh:150`,`:171`). Consumers should not rely on key order.

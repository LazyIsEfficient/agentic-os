# Data Model

Canonical catalog of data contracts that cross a boundary in this repo — the
cross-session memory files, the Claude Code Stop-hook memory-extraction
contracts, the PreToolUse general-purpose-ban hook I/O, and the PostToolUse
post-edit scan hook I/O.

**Last updated:** 2026-10-19

## Change log

| Date | Run | Summary |
|---|---|---|
| 2026-10-19 | fix/audit-postedit-hook (review fixes) | Updated `PostEditScanHookIO`: control-character `file_path` / resolved path silently skipped; `MAX_FINDINGS` = 20 cap with early stop and a `...stopped after 20 findings` reason line; syntax findings no longer echo checker messages (`bash -n: line N: syntax error`, `jq: line N, column M: invalid JSON`, `python: line N: <ErrorClass>`; `first_line()` removed); JSONC files skip jq; new `openai-api-key` / `anthropic-api-key` rules; tightened `generic-secret-assignment` (key must end in keyword, unquoted values, `looks_secret()` filters); placeholder list adds `replace` (and documents `change_me`); reason passed to `jq -Rsc` on stdin. All citations re-verified; settings ranges unchanged in content. |
| 2026-10-19 | fix/audit-postedit-hook (issue #259) | Added `PostEditScanHookIO`: PostToolUse (`Edit\|Write\|MultiEdit`) hook stdin field `tool_input.file_path`, `CLAUDE_PROJECT_DIR` containment root, consumed gitleaks report fields (`StartLine`, `RuleID`), and the fail-open `{"decision":"block","reason"}` findings payload emitted by `.claude/hooks/post-edit-scan.sh`. |
| 2026-10-19 | fix/audit-validate-rules | No-op: new `scripts/validate.sh` static checks (R4/R6/R9/R12/R13, skill-length, workflow-agent-type, no-general-purpose), a `warn()` helper emitting `WARN [tag]: path — reason`, and a warning count in the summary line are human-readable CLI output with no machine consumer in the repo (no file outside `scripts/validate*.sh` references the `WARN [` line). Warnings never change the exit code. No API/persistence/message changes. |
| 2026-10-19 | fix/audit-ledger-fp | Added findings-ledger contracts (issue #279): `FindingsLedgerEvent` (append-only JSONL event log; new optional `fingerprint_scheme` / `category` / `symbol` keys, structured scheme-2 fingerprint, RECURRING only on a sighting from a different `run_id`; `add` rejects control characters in `--file`/`--category`/`--symbol`; scheme-2 path/symbol normalization) and `FindingsLedgerExportRow` (new `export` per-fingerprint summary, no claim text but raw `file`/`symbol` free text; refuses `--out` inside the ledger directory, reads under the lock, atomic `mkstemp` + `os.replace` write). Line citations refreshed after PR #288 review fixes. |
| 2026-10-19 | fix/audit-scan-scripts (security fix round 2) | Updated `ReviewScanReport`: new `skipped` reason `"manifest resolves outside the repo root"` (both scripts); new check-imports rules `js-import-outside-root` / `py-import-outside-root`; new security-scan copy/containment `error` reasons (npm-audit, pip-audit, cargo-audit); noted text-output control-char escaping and per-line script prefix; every line citation re-verified and shifted to current files. |
| 2026-10-19 | fix/audit-scan-scripts (gate fixes) | Updated `ReviewScanReport`: new top-level `skipped` array (`{path, reason}`) in both scripts; optional scanner `notes` array (security-scan only); removed stale `"no files in scope"` reason; exit 2 adds missing `--paths` entry, security-scan exit 3 adds no-file-in-scope, check-imports exit 4 adds helper failure / unparseable manifest; added env inputs table (`SECURITY_SCAN_NPM_REGISTRY`, `SECURITY_SCAN_GITLEAKS_CONFIG`, `PYTHONPATH`); `file` path normalization corrected; every line citation re-verified against current files. |
| 2026-10-19 | fix/audit-scan-scripts | Added `ReviewScanReport`: shared `--json` stdout payload + exit-code contract for the new `scripts/security-scan.sh` and `scripts/check-imports.sh` (consumed by reviewers as Tier 0/1 evidence). |
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

### FindingsLedgerEvent

| Field | Value |
|---|---|
| **Kind** | `persistence` |
| **Ingestion route** | Append-only JSONL at `<main repo>/.claude/ledger/findings.jsonl`, resolved via `git rev-parse --git-common-dir` so linked worktrees converge on the main checkout's ledger; falls back to the nearest CWD ancestor containing `.claude/`; `--ledger PATH` overrides (`ledger.py:176-210`,`:239-245`). Written by `cmd_add` (`ledger.py:330-377`) and `_transition` for `promote` / `retire` (`:423-445`) through `append_event`, one `json.dumps(event, sort_keys=True, ensure_ascii=False)` line per event (`:266-277`), under an exclusive sidecar `<ledger>.lock` with a `LOCK_TIMEOUT_S = 20` deadline, exit 2 on timeout (`:98`,`:213-236`). Read back and validated by `read_events` (`:248-263`): every line must carry all `REQUIRED_KEYS` and a `status` in `STATUSES`, else exit 2. `cmd_add` rejects any control character (Unicode category `Cc`, via `has_control_chars`) in `--file` / `--category` / `--symbol` with exit 2 (`:326-334`), so a newline-joined scheme-1 payload cannot collide with a scheme-2 one (`:165-170`, `ledger-format.md:77-83`). Events are never edited or deleted (`ledger-format.md:9-11`). |
| **Source** | `.claude/skills/findings-ledger/scripts/ledger.py` (lines 90-98, 129-173, 248-277, 326-377, 423-457); prose schema `.claude/skills/findings-ledger/references/ledger-format.md` (lines 14-29, 65-83) |

| Name | Type | Required | Notes |
|---|---|---|---|
| `fingerprint` | string (16 hex) | yes | sha256 hex truncated to `FINGERPRINT_LEN = 16` (`ledger.py:94`). Scheme 1: `file.strip() + "\n" + normalize(claim)` (`:129-133`, must stay byte-stable). Scheme 2: `"\n".join(("v2", normalize_path(file), category, normalize_symbol(symbol)))` (`:165-173`) |
| `fingerprint_scheme` | integer `1` \| `2` | no | `2` (`SCHEME_STRUCTURED`) when `add --category` given, else `1` (`SCHEME_TEXT`) — `ledger.py:95-96`,`:343-354`. Absent on pre-#279 events, read as `1` (`:307`,`:432`). Transition events copy it from the fingerprint's first event (`:432`) |
| `category` | string (kebab-case slug) \| null | no | Stripped, lowercased and must match `^[a-z0-9]+(?:-[a-z0-9]+)*$`, else exit 2 (`ledger.py:97`,`:144-147`,`:344-347`); the normalized slug is what is stored (`:365`). No control characters (`:331-334`). Null for scheme 1; absent on legacy events (read via `.get`, `:308`,`:433`) |
| `symbol` | string \| null | no | Stored as passed (`args.symbol`, `ledger.py:366`); normalized only inside the hash — backticks, a trailing `()` and surrounding whitespace peeled in any order until stable, then internal whitespace collapsed (`:150-162`). No control characters (`:331-334`). `--symbol` without `--category` exits 2 (`:350-351`). Null when omitted; absent on legacy events |
| `file` | string | yes | Repo-relative path the finding is about (`ledger.py:505`); stored raw (`:367`). No control characters (`:331-334`). Normalized only in the scheme-2 hash: trimmed, `\` → `/`, empty and `.` segments dropped (so `a//b`, `./a/b`, `a/./b`, `a/b/` all hash as `a/b`), leading `/` kept, `..` left alone (`:136-141`). Scheme 1 uses `file.strip()` only (`:132`) |
| `claim` | string | yes | One-sentence claim summary (`ledger.py:506`). Transition events copy the first event's claim (`:436`) |
| `tier` | integer `1` \| `2` | yes | `--tier` choices `(1, 2)` (`ledger.py:507`); tier 1 without non-blank `--evidence` is demoted to 2 (`:338-342`). Transitions copy the first event's tier (`:437`) |
| `source` | string | yes | Emitting agent on `add` (`ledger.py:509`); default `"triage"` on `promote` / `retire` (`:532`,`:539`) |
| `run_id` | string \| null | yes (key) | Required on `add` (`ledger.py:510`); defaults to null on transitions (`:533`,`:540`). Recurrence counts distinct `run_id`s among `NEW`/`RECURRING` sightings (`:297-301`) |
| `date` | string `YYYY-MM-DD` | yes | Defaults to today; validated with `date.fromisoformat` (`ledger.py:280-284`,`:512`,`:549-550`) |
| `evidence` | string \| null | yes (key) | Evidence artifact path; required non-blank for `PROMOTED` (`ledger.py:451-452`); always null on `RETIRED-NOISE` (`retire` passes no evidence, `_transition` default `None`: `:423`,`:456-457`) |
| `status` | enum string | yes | `NEW` \| `RECURRING` \| `INVESTIGATING` \| `PROMOTED` \| `RETIRED-NOISE` (`ledger.py:90`). On `add`: `RECURRING` only if a prior sighting of the fingerprint came from a **different** `run_id`, else `NEW` (`:359-361`) |

`REQUIRED_KEYS` = `fingerprint, file, claim, tier, source, run_id, date, evidence, status` (`ledger.py:92-93`); `fingerprint_scheme`, `category`, `symbol` are written on every new event but not required on read.

---

### FindingsLedgerExportRow

| Field | Value |
|---|---|
| **Kind** | `persistence` |
| **Ingestion route** | Written by `ledger.py export --out <path>` (`cmd_export`, `ledger.py:464-493`) to a user-supplied path, intended as a committable team-shared artifact outside `.claude/ledger/` (e.g. `.claude/ledger-shared/<name>.jsonl`, `ledger-format.md:168-169`). Refuses any `--out` that resolves inside the ledger's directory (the ledger, its `.lock` sidecar, or any sibling) with exit 2 (`:467-469`). Reads events under the same `locked()` sidecar lock as writers (`:470-471`). JSONL, one row per fingerprint, sorted by fingerprint, `sort_keys=True, ensure_ascii=False` (`:473`,`:477-478`). Rewritten in full atomically: `tempfile.mkstemp(dir=out.parent, prefix=".<name>.", suffix=".tmp")`, `chmod` to `0o666 & ~umask`, write, then `os.replace` onto `--out`; the temp file is unlinked on any failure (`:479-492`). No claim text, but `file` and `symbol` are reviewer-supplied free text copied verbatim from the first event, so in team-shared mode they land in git history (`ledger-format.md:177-180`). Not read back by `ledger.py` (`ledger-format.md:180`). |
| **Source** | `.claude/skills/findings-ledger/scripts/ledger.py` (lines 295-317, 460-493); prose `.claude/skills/findings-ledger/references/ledger-format.md` (lines 151-182) |

Keys are exactly `EXPORT_KEYS` (`ledger.py:460-461`), derived from `summarize` (`:295-317`):

| Name | Type | Required | Notes |
|---|---|---|---|
| `fingerprint` | string (16 hex) | yes | Group key — `ledger.py:306` |
| `fingerprint_scheme` | integer `1` \| `2` | yes | From first event; `1` when absent (`ledger.py:307`) |
| `category` | string \| null | yes (key) | From first event (`ledger.py:308`) |
| `symbol` | string \| null | yes (key) | From first event (`ledger.py:309`), raw as passed to `add` — reviewer-supplied free text, committed in team-shared mode |
| `file` | string | yes | From first event (`ledger.py:313`), raw as passed to `add` — reviewer-supplied free text, committed in team-shared mode |
| `count` | integer ≥ 0 | yes | Distinct `run_id`s among `NEW`/`RECURRING` events (`ledger.py:297`,`:301`) |
| `status` | enum string | yes | Status of the most recent event (`ledger.py:302`) |
| `first_seen` | string `YYYY-MM-DD` | yes | Earliest sighting date; first event's `date` if no sightings (`ledger.py:304`,`:315`,`:476`) |
| `last_seen` | string `YYYY-MM-DD` | yes | Latest sighting date; first event's `date` if no sightings (`ledger.py:304`,`:316`,`:476`) |

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

### PostEditScanHookIO

| Field | Value |
|---|---|
| **Kind** | `message` |
| **Ingestion route** | The Claude Code **PostToolUse** hook, registered with matcher `Edit\|Write\|MultiEdit` and `"timeout": 30` in `.claude/settings.json:28-34` (consumer copy: `assets/consumer/claude-settings.json:18-24`). INPUT is the PostToolUse event JSON read from **stdin** (`input=$(< /dev/stdin)`, `post-edit-scan.sh:48`); OUTPUT is printed to **stdout** for the hook runtime. Always exits 0. **Fails open** (`:35-38`): missing `jq`, an unparseable payload, a missing/non-string/empty `file_path`, or `mktemp` failure prints one `post-edit-scan: ...` line to stderr and exits 0 with no stdout (`note()`, `:46`, `:49`, `:52-56`, `:89`). |
| **Source** | `.claude/hooks/post-edit-scan.sh` (lines 42–238) |

**INPUT** (PostToolUse event, stdin) — only this field is consumed:

```json
{ "tool_input": { "file_path": "/abs/path/to/edited/file" } }
```

| Name | Type | Required | Notes |
|---|---|---|---|
| `tool_input.file_path` | string (non-empty) | yes | Not a string → jq `error("no file_path")` → fail-open note; `""` → fail-open note — `post-edit-scan.sh:52-56`. A path containing any control character (jq `test("[[:cntrl:]]")`) becomes `"skip"` and exits 0 silently; the path is never echoed — `:51-57`. Symlinks resolved (`resolve()`, `:60-69`); silently skipped (exit 0, no stderr) if resolution fails, the resolved path is outside the project root, the resolved path contains a control character (bash `*[[:cntrl:]]*`), it is not a regular file, or it is over `MAX_BYTES` = 1048576 — `:42`, `:80-86` |

**Environment** consumed:

| Name | Type | Required | Notes |
|---|---|---|---|
| `CLAUDE_PROJECT_DIR` | string (dir path) | no | Containment root. Falls back to `git rev-parse --show-toplevel`, then `pwd -P` — `post-edit-scan.sh:71-78`. Finding paths are relative to this root (`rel`, `:87`) |
| `GITLEAKS_CONFIG`, `GITLEAKS_CONFIG_TOML` | string | no | Deliberately **unset** for the gitleaks run (edited tree is untrusted) — `:176` |

**Consumed external payload** — gitleaks JSON report (`--report-format json`, written to a temp file, `:176-179`). gitleaks runs only if installed and the finding cap was not already hit by the regex pass (`:174`). The report is read only when gitleaks exits 0 within `GITLEAKS_TIMEOUT` = 5 s and is a JSON array (`:44`, `:182-186`); otherwise a stderr line is printed and the regex findings still stand (`:192`).

| Name | Type | Required | Notes |
|---|---|---|---|
| `[].StartLine` | number | yes | Line number in the finding line — `:190` |
| `[].RuleID` | string | yes | Emitted as rule `gitleaks:<RuleID>` — `:190` |

**OUTPUT** (stdout) — exactly one of:

Clean or skipped: no output, exit 0 (`post-edit-scan.sh:225`, plus the skip/fail-open exits above).

Findings (`post-edit-scan.sh:227-237`). The reason text is assembled in a temp file and passed to jq on **stdin** (`jq -Rsc '{decision:"block", reason:rtrimstr("\n")}' < "$tmp/reason"`, `:237`), not via argv:

```json
{"decision":"block","reason":"<text>"}
```

| Name | Type | Required | Notes |
|---|---|---|---|
| `decision` | string | yes | Literal `"block"`. For PostToolUse this attaches `reason` to the tool result; the edit is not undone — `:27-29`, `:237` |
| `reason` | string | yes | Header `post-edit-scan found problems in the file you just edited (<relpath>). The edit was applied; fix these now:` then one `- <finding>` line per unique finding (`sort -u`), at most `MAX_FINDINGS` = 20 (`head -n`) — `:43`, `:228-229`. When the cap is hit, the line `- ...stopped after 20 findings; more may exist. Fix these, and the next edit rescans the file.` follows — `:230-232`. If any finding is a secret, a rotation/remediation sentence is appended — `:233-235`. Trailing newline trimmed (`rtrimstr`) — `:237` |

Finding line formats inside `reason`:

| Format | Rule / checker values | Source |
|---|---|---|
| `<relpath>:<line> secret <rule>` | Case-sensitive regexes: `aws-access-key-id`, `private-key`, `github-token`, `slack-token`, `stripe-live-key`, `openai-api-key` (`sk-proj-`), `anthropic-api-key` (`sk-ant-`), `google-api-key`, `jwt`. Case-insensitive `generic-secret-assignment` (see Notes). `gitleaks:<RuleID>` | `:103-113`, `:119`, `:152-169`, `:190` |
| `<relpath> syntax bash -n: line <N>: syntax error` | `*.sh` files | `:207-211` |
| `<relpath> syntax jq: line <N>, column <M>: invalid JSON` | `*.json` files, except JSONC files (`*.jsonc`, `*/.vscode/*.json`, basename `tsconfig*.json`, `jsconfig*.json`, `devcontainer.json`, `.devcontainer.json`, `.eslintrc*.json`), which skip the jq check | `:199-205`, `:212-216` |
| `<relpath> syntax python: line <N>: <ErrorClass>` | `*.py` files, when `python3` is on PATH. `<ErrorClass>` is the last `^[A-Za-z]+(Error\|Exception)` match (fallback `compile failed`); bytecode goes to a temp `pycache_prefix` | `:217-222` |

In all three syntax formats the `line …: ` prefix is omitted when no `line N(, column M)?` is found in the checker output (`line_of()`, `${pl:+$pl: }`, `:198`, `:210`, `:215`, `:221`). Checker messages themselves are never echoed (`:196-197`).

Notes:
- Secret **values are never emitted** — only `file:line rule`; gitleaks runs with `--redact` (`:12-13`, `:176`). Syntax findings keep only the line/column and error class because checker messages can quote file content (`:17-18`, `:196-197`).
- **Cap:** `add()` increments a counter and sets `capped` at `MAX_FINDINGS` = 20; every scan loop (built-in rules, generic assignment, gitleaks) stops once capped, and gitleaks is not started if the regex pass already capped (`:96-100`, `:153`, `:157`, `:160`, `:168`, `:174`, `:189`). The syntax checks still run and can append one more line, which `head -n 20` may drop after `sort -u` (`:206-229`).
- **`generic-secret-assignment`** (`GENERIC_RE`, `grep -i`, `:114-119`): the key name must END in `password`, `passwd`, `passphrase`, `secret`, `token`, `api[_-]?key`, `access[_-]?key`, or `private[_-]?key`, optionally followed by `[_-]?(key|secret)` and an optional closing quote, then `:=`, `=>`, `:` or `=`. The value is either quoted (16+ chars, no quote or whitespace) or unquoted for `.env`/YAML (16+ chars excluding quotes, whitespace, `#,;(){}<>`). The extracted value must also pass `looks_secret()` (`:130-144`): contains a digit AND a letter; no `/` or whitespace; does not start with `$` (rejects `$VAR` and bcrypt/argon hashes); not a dotted identifier (`^[A-Za-z_][A-Za-z0-9_]*(\.[A-Za-z_][A-Za-z0-9_]*)+$`).
- Matches judged placeholders are suppressed, case-insensitively (`is_placeholder()`, `:121-128`): substrings `example`, `xxxx`, `changeme`, `change_me`, `replace`, `placeholder`, `your_`, `your-`, `redacted`, `dummy`, or `<...>`, `${`, `{{`, `://`. Lockfiles skip the built-in regex set but not gitleaks (`:146-151`).
- `.gitleaksignore` and inline `gitleaks:allow` are ignored (`--gitleaks-ignore-path` to an empty temp dir, `--ignore-gitleaks-allow`, `:175-178`). A missing scanner is never reported (`:33`).

---

### ReviewScanReport

| Field | Value |
|---|---|
| **Kind** | `message` |
| **Ingestion route** | CLI stdout + process exit code. `scripts/security-scan.sh [--base <ref>] [--paths <path>...] [--json]` (`security-scan.sh:6`,`:81`) and `scripts/check-imports.sh` (same flags, `check-imports.sh:6`,`:106`), run from the project root. With `--json`, exactly one JSON object is printed to **stdout** (`security-scan.sh:244-245`, `check-imports.sh:659-660`; check-imports' nothing-in-scope early exit prints at `:288-289`); without it, a human-readable text rendering of the same data (not part of this contract, but note: every repo-controlled string has C0/C1 control chars and DEL escaped as `\xNN`, and every line is prefixed `security-scan: ` / `check-imports: ` so none can start with a `::` workflow command — `security-scan.sh:235-238`,`:247-257`, `check-imports.sh:87-88`,`:273-285`,`:292`). Consumed by reviewer agents as Tier 0/1 evidence. Usage errors go to stderr only, with no JSON. |
| **Source** | `scripts/security-scan.sh` (header lines 1–72; env lines 76–78; `in_root` lines 176–183; `skip` lines 185–188; `emit`/`notes_json` lines 211–223; `finish` result/exit lines 240–267), `scripts/check-imports.sh` (header lines 1–100; `skip`/`skip_once` lines 203–209; nothing-in-scope lines 287–295; `emit`/`finding`/`status_of` lines 299–309; result/exit lines 657–669) |

**Inputs** (environment; affect which findings appear, not the payload shape):

| Variable | Script | Default | Notes |
|---|---|---|---|
| `SEMGREP_CONFIG` | security-scan | `p/security-audit` | Registry name fetches rules over the network; may be a local file/dir — `security-scan.sh:34-37`,`:76` |
| `SECURITY_SCAN_NPM_REGISTRY` | security-scan | `https://registry.npmjs.org/` | Passed as explicit `--registry` to `npm audit`; a repo `.npmrc` is never read — `security-scan.sh:45-47`,`:77`,`:425` |
| `SECURITY_SCAN_GITLEAKS_CONFIG` | security-scan | unset (gitleaks default rules) | When set, passed as `--config` to `gitleaks dir` — `security-scan.sh:27-28`,`:78`,`:278` |
| `PYTHON` | check-imports | `python3` | Interpreter for Python import resolution / `pyproject.toml` parsing — `check-imports.sh:38`,`:103` |
| `PYTHONPATH` | check-imports | unset | Helper runs under `python -I` (which ignores it), then re-appends each non-empty entry to `sys.path`; empty entries (= cwd) dropped — `check-imports.sh:39-42`,`:461-463` |

**Shape** (both scripts — `security-scan.sh:57-62`, `check-imports.sh:76-78`; built at `security-scan.sh:242-243`, `check-imports.sh:657`):

```json
{
  "scanners": [
    {
      "name": "npm-audit",
      "status": "findings",
      "reason": "optional string",
      "notes": ["ignored repo-local .npmrc"],
      "findings": [
        { "file": "package-lock.json", "line": null, "rule": "https://github.com/advisories/GHSA-...",
          "severity": "HIGH", "message": "..." }
      ]
    }
  ],
  "skipped": [
    { "path": "link-to-etc-passwd", "reason": "resolves outside the repo root" }
  ]
}
```

| Name | Type | Required | Notes |
|---|---|---|---|
| `scanners` | array of Scanner | yes | One element per `emit` call, in run order (slurped from `results.jsonl`, `security-scan.sh:242`, `check-imports.sh:657`). A name may repeat (e.g. `npm-audit` / `dependency-audit` emitted once per lockfile, `security-scan.sh:501-514`). `[]` when nothing is in scope: security-scan calls `finish` before any scanner (`:270`); check-imports prints `{scanners: [], skipped: $k}` and exits 3 (`:287-294`) |
| `skipped` | array of Skipped | yes | Always present (may be `[]`); paths (in-scope files, lockfiles, manifests) dropped without being read (`security-scan.sh:185-188`, `check-imports.sh:203-209`) |

Scanner object (`emit`, `security-scan.sh:212-219`, `check-imports.sh:299-303`):

| Name | Type | Required | Notes |
|---|---|---|---|
| `name` | string | yes | security-scan: `gitleaks`, `semgrep`, `osv-scanner`, `npm-audit`, `pip-audit`, `cargo-audit`, `dependency-audit` (`:275-512`). check-imports: `js-imports`, `py-imports`, `unused-deps` (`:449`,`:543`,`:650`), each emitted only when files of that kind are in scope (`:653-655`) |
| `status` | enum string | yes | `ran` (no findings) \| `findings` \| `unavailable` \| `error` (`security-scan.sh:55`). check-imports never emits `unavailable` — only `ran`/`findings` (`status_of`, `:309`) and `error` (`:504`,`:534`,`:585`,`:588`,`:631`); header `:78` |
| `reason` | string | no | Key omitted when empty (`security-scan.sh:216`, `check-imports.sh:301`). Set for `unavailable`/`error`; also on one `ran` entry: `"no packages found in lockfiles"` (osv-scanner exit 128, `security-scan.sh:385`). security-scan copy/containment `error` reasons: npm-audit `"<dir/>package.json resolves outside the repo root; not copied"` (`:412`), `"cannot copy <dir/>package.json: …"` (`:415`), `"cannot copy <lock>: …"` (`:419`); pip-audit `"cannot read <lock>: …"` (`:448`); cargo-audit `"cannot copy <lock>: …"` (`:479`) |
| `notes` | array of string | no | **security-scan only.** Key omitted when empty (`security-scan.sh:217`); de-duplicated and sorted via `jq 'unique'` (`notes_json`, `:221-223`). Lists repo-local config deliberately ignored (`:62`): `"ignored repo-local <path>"` for `.gitleaks.toml` / `.gitleaksignore` at repo root or cwd (gitleaks, `:279-284`), `osv-scanner.toml` beside a lockfile (`:376-377`), `.npmrc` beside a lockfile (`:406`); `"stripped <N> option line(s) (e.g. --index-url, -r) from <lockfile>"` (pip-audit, `:451-452`). Carried on gitleaks `error`/result (`:297`,`:300`,`:308`), osv-scanner all outcomes (`:385`,`:387`,`:396`), npm-audit all outcomes (`:412`,`:415`,`:419`,`:427`,`:437`), pip-audit (`:460`,`:467`; not on the `cannot read` error, `:448`); never on `unavailable`, semgrep, or cargo-audit. check-imports' `emit` has no `notes` (`check-imports.sh:299-303`) |
| `findings` | array of Finding | yes | Always present; `[]` for `ran`/`unavailable`/`error` |

Finding object (security-scan per-scanner `jqr` mappings `:305-490`; check-imports `finding`, `:304-308`):

| Name | Type | Required | Notes |
|---|---|---|---|
| `file` | string | yes | In-scope paths are symlink-resolved and rewritten `./<relative>` when under the physical cwd (`security-scan.sh:203`, `check-imports.sh:262`); a file inside the repo root but outside cwd keeps its physical absolute path (check-imports `:262`). security-scan `REL_FILTER` then strips a leading `$PWD/`, physical-cwd `/`, or `./` (`:230`); check-imports strips a leading `./` (`${2#./}`, `:306`) |
| `line` | integer \| null | yes | `null` for all dependency-audit findings (`security-scan.sh:61`, `:393`,`:433`,`:465`,`:488`). check-imports: `($line \| tonumber? // null)` (`:307`) — `null` for an `unused-dependency` whose name was not found by grep in the manifest (`:646`) |
| `rule` | string | yes | security-scan: gitleaks `.RuleID` (`:306`), semgrep `.check_id` (`:328`), osv/pip `.id` (`:393`,`:465`), npm advisory `url` (or `source`, or literal `npm-audit`) (`:434`), cargo `.advisory.id` (or `cargo-audit`) (`:488`). check-imports: `js-import-outside-root` (`:434`), `js-unresolved-relative` (`:436`), `js-undeclared-package` (`:446`), `py-import-outside-root` (`:517`), `py-unresolved-relative` (`:522`), `py-unresolved-module` (`:539`), `unused-dependency` (`:647`); header `:79-81`. `*-import-outside-root` fires when a relative or absolute import's lexically normalized target is outside the repo root; nothing outside is stat'ed (`:82-84`,`:431-434`,`:515-518`) |
| `severity` | string | yes | Not a closed enum. security-scan: gitleaks always `HIGH` (`:307`); semgrep `.extra.severity` else `UNKNOWN` (`:329`); osv `.database_specific.severity` else `UNKNOWN` (`:394`); npm upper-cased severity else `UNKNOWN` (`:435`); pip/cargo `UNKNOWN` (`:465`,`:489`). check-imports: `ERROR` for import rules (`:434`,`:436`,`:446`,`:517`,`:522`,`:539`), `WARNING` for `unused-dependency` (`:647`) |
| `message` | string | yes | Human-readable description. gitleaks runs with `--redact`, so secrets are not included (`security-scan.sh:24`,`:293`) |

Skipped object (`skip`, `security-scan.sh:186-188`, `check-imports.sh:204-206`):

| Name | Type | Required | Notes |
|---|---|---|---|
| `path` | string | yes | The path as collected, leading `./` stripped (`${1#./}`) |
| `reason` | string | yes | Free text, currently one of: `"broken symlink or unresolvable path"` (`security-scan.sh:196`, `check-imports.sh:255`), `"resolves outside the repo root"` (`security-scan.sh:200`, `check-imports.sh:259`), `"lockfile resolves outside the repo root"` (security-scan cwd lockfile sweep, `:355`), `"manifest resolves outside the repo root"` (security-scan: `package.json` beside an npm lockfile, `:409-411`; check-imports: an ancestor `package.json` during JS package lookup, added once per path via `skip_once`, `:207-209`,`:384-386`). Repo root = git toplevel, else cwd (`security-scan.sh:122-126`, `check-imports.sh:184-188`) |

**Exit codes** (precedence in code: findings, then error, then nothing-ran — `security-scan.sh:263-265`, `check-imports.sh:667-668`; check-imports' exit 3 is only the early exit at `:294`):

| Code | security-scan.sh (`:64-70`) | check-imports.sh (`:90-97`) |
|---|---|---|
| 0 | no findings, at least one scanner `ran`/`findings` (`:266`) | checked, clean (`:669`) |
| 1 | at least one finding (`:263`) | findings (`:667`) |
| 2 | usage error: bad flag (`:108`), no `jq` (`:85`), `--base` with `--paths` (`:112-113`), not a git work tree without `--paths` (`:131`), invalid / unresolvable `--base` (`:133-135`), missing `--paths` entry (`:150-151`) | usage error: bad flag (`:133`), no `jq` (`:110`), `--base` with `--paths` (`:137-138`), `--base` outside git (`:149`), invalid / unresolvable `--base` (`:150-152`), not a git work tree without `--paths` (`:159`), missing `--paths` entry (`:170-171`) |
| 3 | nothing checked: no file in scope (`:270`), or no scanner ran (all `unavailable`) (`:265`) | nothing to check — no JS/TS/Python sources or manifests in scope (`:287-294`) |
| 4 | a scanner errored and none produced findings (`:264`) | a check could not run and nothing was found: `$PYTHON` missing (`:504`,`:585`), Python helper failed (`:534`,`:631`), manifest unparseable (`:588`) (`:668`) |

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

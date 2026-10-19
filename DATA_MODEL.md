# Data Model

Canonical catalog of data contracts that cross a boundary in this repo — the
cross-session memory files, the Claude Code Stop-hook memory-extraction
contracts, and the findings-ledger event log and export.

**Last updated:** 2026-10-19

## Change log

| Date | Run | Summary |
|---|---|---|
| 2026-10-19 | fix/audit-ledger-fp | Added findings-ledger contracts (issue #279): `FindingsLedgerEvent` (append-only JSONL event log; new optional `fingerprint_scheme` / `category` / `symbol` keys, structured scheme-2 fingerprint, RECURRING only on a sighting from a different `run_id`; `add` rejects control characters in `--file`/`--category`/`--symbol`; scheme-2 path/symbol normalization) and `FindingsLedgerExportRow` (new `export` per-fingerprint summary, no claim text but raw `file`/`symbol` free text; refuses `--out` inside the ledger directory, reads under the lock, atomic `mkstemp` + `os.replace` write). Line citations refreshed after PR #288 review fixes. |
| 2026-07-13 | remove-dispatch-gate | Removed the dispatch-gate contracts (`DispatchGateAuditRecord`, `DispatchGateHookDecision`, `DispatchGateHookEventPayload`, `DispatchGateLedger`, `DispatchGatePolicyConfig`); that gate was retired and its scripts and config deleted. |
| 2026-07-13 | feat/memory-extraction | Added memory-encoding contracts (issue #217): `MemoryEntryFile` + `MemoryIndexLine` (memory-extraction skill on-disk format), `MemoryExtractHookState` (hook-owned per-session turn counter), and `MemoryExtractStopHookIO` (Stop-hook stdin/stdout). |
| 2026-07-07 | feat/claude-md-flatten | No-op: `scripts/build-claude-md.sh` + `validate.sh` `claude-flat-sync` exchange generated markdown via BEGIN/END RULE marker comments — an internal build-artifact convention with no fields, not a data contract. No API/persistence/message changes. |
| 2026-07-06 | fix/macos-bash-issue-with-validate-script | No-op: `scripts/validate.sh` changes (ulimit fd bump, check_tombstones grep refactor) are internal control flow only — no data contracts affected. |

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

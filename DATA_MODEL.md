# Data Model

Canonical catalog of data contracts that cross a boundary in this repo — the
cross-session memory files, the Claude Code Stop-hook memory-extraction
contracts, and the deterministic review-script JSON reports.

**Last updated:** 2026-10-19

## Change log

| Date | Run | Summary |
|---|---|---|
| 2026-10-19 | fix/audit-scan-scripts | Added `ReviewScanReport`: shared `--json` stdout payload + exit-code contract for the new `scripts/security-scan.sh` and `scripts/check-imports.sh` (consumed by reviewers as Tier 0/1 evidence). |
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

### ReviewScanReport

| Field | Value |
|---|---|
| **Kind** | `message` |
| **Ingestion route** | CLI stdout + process exit code. `scripts/security-scan.sh [--base <ref>] [--paths <file>...] [--json]` and `scripts/check-imports.sh` (same flags), run from the project root. With `--json`, exactly one JSON object is printed to **stdout** (`security-scan.sh:325-326`, `check-imports.sh:481-482`); without it, a human-readable text rendering of the same data (not part of this contract). Consumed by reviewer agents as Tier 0/1 evidence. Usage errors go to stderr only, with no JSON. |
| **Source** | `scripts/security-scan.sh` (header lines 34–46; `emit` lines 125–130; result/exit lines 323–340), `scripts/check-imports.sh` (header lines 60–70; `emit`/`finding` lines 160–171; result/exit lines 479–493) |

**Shape** (both scripts — `security-scan.sh:36-39`, `check-imports.sh:60-61`):

```json
{
  "scanners": [
    {
      "name": "gitleaks",
      "status": "findings",
      "reason": "optional string",
      "findings": [
        { "file": "src/x.ts", "line": 12, "rule": "aws-access-token",
          "severity": "HIGH", "message": "..." }
      ]
    }
  ]
}
```

| Name | Type | Required | Notes |
|---|---|---|---|
| `scanners` | array of Scanner | yes | One element per `emit` call, in run order (`security-scan.sh:323`, `check-imports.sh:479`). A name may repeat (e.g. `npm-audit` / `dependency-audit` emitted once per lockfile, `security-scan.sh:303-316`). `check-imports.sh` prints `{"scanners":[]}` and exits 3 when nothing is in scope (`:155-157`) |

Scanner object (`emit`, `security-scan.sh:126-130`, `check-imports.sh:161-165`):

| Name | Type | Required | Notes |
|---|---|---|---|
| `name` | string | yes | security-scan: `gitleaks`, `semgrep`, `osv-scanner`, `npm-audit`, `pip-audit`, `cargo-audit`, `dependency-audit` (`:141-314`). check-imports: `js-imports`, `py-imports`, `unused-deps`, each emitted only when files of that kind are in scope (`:475-477`) |
| `status` | enum string | yes | `ran` (no findings) \| `findings` \| `unavailable` \| `error` (`security-scan.sh:34`). check-imports never emits `unavailable` — only `ran`, `findings`, `error` (`:171`,`:341`,`:415`,`:419`) |
| `reason` | string | no | Key omitted when empty (`... + (if $reason == "" then {} else {reason:$reason} end)`). Set for `unavailable`/`error`, and also on some `ran` entries: `"no files in scope"` (`security-scan.sh:144`,`:177`), `"no packages found in lockfiles"` (`:229`) |
| `findings` | array of Finding | yes | Always present; `[]` for `ran`/`unavailable`/`error` |

Finding object:

| Name | Type | Required | Notes |
|---|---|---|---|
| `file` | string | yes | Project-relative path. security-scan strips a leading `$PWD/` or `./` (`REL_FILTER`, `:134`); check-imports strips only a leading `./` (`${2#./}`, `:168`), so absolute `--paths` stay absolute |
| `line` | integer \| null | yes | `null` for all dependency-audit findings (`security-scan.sh:39`). check-imports: `($line \| tonumber? // null)` (`:169`) — `null` for an `unused-dependency` whose name was not found by grep in the manifest (`:468`) |
| `rule` | string | yes | security-scan: gitleaks `.RuleID`, semgrep `.check_id`, osv/pip `.id`, npm advisory `url` (or `source`, or literal `npm-audit`), cargo `.advisory.id` (or `cargo-audit`) (`:166-291`). check-imports: `js-unresolved-relative`, `js-undeclared-package`, `py-unresolved-relative`, `py-unresolved-module`, `unused-dependency` (`:62-63`) |
| `severity` | string | yes | Not a closed enum. security-scan: gitleaks always `HIGH`; semgrep `.extra.severity` else `UNKNOWN`; osv `.database_specific.severity` else `UNKNOWN`; npm upper-cased severity; pip/cargo `UNKNOWN`. check-imports: `ERROR` for import rules, `WARNING` for `unused-dependency` |
| `message` | string | yes | Human-readable description. gitleaks runs with `--redact`, so secrets are not included (`security-scan.sh:18-19`,`:154`) |

**Exit codes** (precedence in code: findings, then error, then nothing-ran — `security-scan.sh:337-340`, `check-imports.sh:491-493`):

| Code | security-scan.sh (`:41-46`) | check-imports.sh (`:65-70`) |
|---|---|---|
| 0 | no findings, at least one scanner `ran`/`findings` | checked, clean |
| 1 | at least one finding | findings |
| 2 | usage error (bad flag, unresolvable `--base`, not a git repo, `--base` with `--paths`, no `jq` — `:58`,`:85-87`) | usage error (same, plus no `jq`) |
| 3 | no scanner ran (all `unavailable`) | nothing to check (no JS/TS/Python sources or manifests in scope) |
| 4 | a scanner errored and none produced findings | a check could not run (e.g. Python in scope but no `$PYTHON`) |

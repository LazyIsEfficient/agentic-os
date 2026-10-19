# Data Model

Canonical catalog of data contracts that cross a boundary in this repo — the
cross-session memory files, the Claude Code Stop-hook memory-extraction
contracts, and the deterministic review-script JSON reports.

**Last updated:** 2026-10-19

## Change log

| Date | Run | Summary |
|---|---|---|
| 2026-10-19 | fix/audit-scan-scripts (gate fixes) | Updated `ReviewScanReport`: new top-level `skipped` array (`{path, reason}`) in both scripts; optional scanner `notes` array (security-scan only); removed stale `"no files in scope"` reason; exit 2 adds missing `--paths` entry, security-scan exit 3 adds no-file-in-scope, check-imports exit 4 adds helper failure / unparseable manifest; added env inputs table (`SECURITY_SCAN_NPM_REGISTRY`, `SECURITY_SCAN_GITLEAKS_CONFIG`, `PYTHONPATH`); `file` path normalization corrected; every line citation re-verified against current files. |
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
| **Ingestion route** | CLI stdout + process exit code. `scripts/security-scan.sh [--base <ref>] [--paths <path>...] [--json]` (`security-scan.sh:6`,`:81`) and `scripts/check-imports.sh` (same flags, `check-imports.sh:6`,`:96`), run from the project root. With `--json`, exactly one JSON object is printed to **stdout** (`security-scan.sh:230-231`, `check-imports.sh:581-582`; check-imports' nothing-in-scope early exit prints at `:223-224`); without it, a human-readable text rendering of the same data (not part of this contract). Consumed by reviewer agents as Tier 0/1 evidence. Usage errors go to stderr only, with no JSON. |
| **Source** | `scripts/security-scan.sh` (header lines 1–72; env lines 76–78; `skip` lines 176–179; `emit`/`notes_json` lines 202–214; `finish` result/exit lines 226–248), `scripts/check-imports.sh` (header lines 1–90; `skip` lines 193–196; nothing-in-scope lines 222–230; `emit`/`finding` lines 234–243; result/exit lines 579–594) |

**Inputs** (environment; affect which findings appear, not the payload shape):

| Variable | Script | Default | Notes |
|---|---|---|---|
| `SEMGREP_CONFIG` | security-scan | `p/security-audit` | Registry name fetches rules over the network; may be a local file/dir — `security-scan.sh:34-37`,`:76` |
| `SECURITY_SCAN_NPM_REGISTRY` | security-scan | `https://registry.npmjs.org/` | Passed as explicit `--registry` to `npm audit`; a repo `.npmrc` is never read — `security-scan.sh:45-47`,`:77`,`:395` |
| `SECURITY_SCAN_GITLEAKS_CONFIG` | security-scan | unset (gitleaks default rules) | When set, passed as `--config` to `gitleaks dir` — `security-scan.sh:27-28`,`:78`,`:259` |
| `PYTHON` | check-imports | `python3` | Interpreter for Python import resolution / `pyproject.toml` parsing — `check-imports.sh:38`,`:93` |
| `PYTHONPATH` | check-imports | unset | Helper runs under `python -I` (which ignores it), then re-appends each non-empty entry to `sys.path`; empty entries (= cwd) dropped — `check-imports.sh:39-42`,`:388-390` |

**Shape** (both scripts — `security-scan.sh:57-62`, `check-imports.sh:74-76`; built at `security-scan.sh:228-229`, `check-imports.sh:579`):

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
| `scanners` | array of Scanner | yes | One element per `emit` call, in run order (slurped from `results.jsonl`, `security-scan.sh:228`, `check-imports.sh:579`). A name may repeat (e.g. `npm-audit` / `dependency-audit` emitted once per lockfile, `security-scan.sh:467-479`). `[]` when nothing is in scope: security-scan calls `finish` before any scanner (`:251`); check-imports prints `{scanners: [], skipped: $k}` and exits 3 (`:222-229`) |
| `skipped` | array of Skipped | yes | Always present (may be `[]`); in-scope paths dropped without being read (`security-scan.sh:176-179`, `check-imports.sh:193-196`) |

Scanner object (`emit`, `security-scan.sh:203-210`, `check-imports.sh:234-238`):

| Name | Type | Required | Notes |
|---|---|---|---|
| `name` | string | yes | security-scan: `gitleaks`, `semgrep`, `osv-scanner`, `npm-audit`, `pip-audit`, `cargo-audit`, `dependency-audit` (`:256-478`). check-imports: `js-imports`, `py-imports`, `unused-deps`, each emitted only when files of that kind are in scope (`:575-577`) |
| `status` | enum string | yes | `ran` (no findings) \| `findings` \| `unavailable` \| `error` (`security-scan.sh:55`). check-imports never emits `unavailable` — only `ran`/`findings` (`status_of`, `:244`) and `error` (`:431`,`:456`,`:507`,`:510`,`:553`); header `:76` |
| `reason` | string | no | Key omitted when empty (`security-scan.sh:207`, `check-imports.sh:236`). Set for `unavailable`/`error`; also on one `ran` entry: `"no packages found in lockfiles"` (osv-scanner exit 128, `security-scan.sh:366`) |
| `notes` | array of string | no | **security-scan only.** Key omitted when empty (`security-scan.sh:208`); de-duplicated and sorted via `jq 'unique'` (`notes_json`, `:212-214`). Lists repo-local config deliberately ignored (`:62`): `"ignored repo-local <path>"` for `.gitleaks.toml` / `.gitleaksignore` at repo root or cwd (gitleaks, `:260-266`), `osv-scanner.toml` beside a lockfile (`:357-358`), `.npmrc` beside a lockfile (`:390`); `"stripped <N> option line(s) (e.g. --index-url, -r) from <lockfile>"` (pip-audit, `:419-420`). Carried on gitleaks `error`/result (`:278`,`:281`,`:289`), osv-scanner all outcomes (`:366`,`:368`,`:377`), npm-audit (`:397`,`:407`), pip-audit (`:428`,`:435`); never on `unavailable`, semgrep, or cargo-audit. check-imports' `emit` has no `notes` (`check-imports.sh:234-238`) |
| `findings` | array of Finding | yes | Always present; `[]` for `ran`/`unavailable`/`error` |

Finding object (security-scan per-scanner `jqr` mappings `:286-456`; check-imports `finding`, `:240-243`):

| Name | Type | Required | Notes |
|---|---|---|---|
| `file` | string | yes | In-scope paths are symlink-resolved and rewritten `./<relative>` when under the physical cwd (`security-scan.sh:194`, `check-imports.sh:211`); a file inside the repo root but outside cwd keeps its physical absolute path (check-imports `:211`). security-scan `REL_FILTER` then strips a leading `$PWD/`, physical-cwd `/`, or `./` (`:221`); check-imports strips a leading `./` (`${2#./}`, `:241`) |
| `line` | integer \| null | yes | `null` for all dependency-audit findings (`security-scan.sh:61`, `:374`,`:403`,`:433`,`:454`). check-imports: `($line \| tonumber? // null)` (`:242`) — `null` for an `unused-dependency` whose name was not found by grep in the manifest (`:568`) |
| `rule` | string | yes | security-scan: gitleaks `.RuleID` (`:287`), semgrep `.check_id` (`:309`), osv/pip `.id` (`:374`,`:433`), npm advisory `url` (or `source`, or literal `npm-audit`) (`:404`), cargo `.advisory.id` (or `cargo-audit`) (`:454`). check-imports: `js-unresolved-relative` (`:360`,`:364`), `js-undeclared-package` (`:373`), `py-unresolved-relative` (`:444`), `py-unresolved-module` (`:461`), `unused-dependency` (`:569`); header `:77-78` |
| `severity` | string | yes | Not a closed enum. security-scan: gitleaks always `HIGH` (`:288`); semgrep `.extra.severity` else `UNKNOWN` (`:310`); osv `.database_specific.severity` else `UNKNOWN` (`:375`); npm upper-cased severity else `UNKNOWN` (`:405`); pip/cargo `UNKNOWN` (`:433`,`:455`). check-imports: `ERROR` for import rules, `WARNING` for `unused-dependency` (`:569`) |
| `message` | string | yes | Human-readable description. gitleaks runs with `--redact`, so secrets are not included (`security-scan.sh:24`,`:274`) |

Skipped object (`skip`, `security-scan.sh:177-179`, `check-imports.sh:194-196`):

| Name | Type | Required | Notes |
|---|---|---|---|
| `path` | string | yes | The path as collected, leading `./` stripped (`${1#./}`) |
| `reason` | string | yes | Free text, currently one of: `"broken symlink or unresolvable path"` (`security-scan.sh:187`, `check-imports.sh:204`), `"resolves outside the repo root"` (`security-scan.sh:191`, `check-imports.sh:208`), `"lockfile resolves outside the repo root"` (security-scan cwd lockfile sweep, `:336`). Repo root = git toplevel, else cwd (`security-scan.sh:122-126`, `check-imports.sh:174-178`) |

**Exit codes** (precedence in code: findings, then error, then nothing-ran — `security-scan.sh:244-246`, `check-imports.sh:592-593`; check-imports' exit 3 is only the early exit at `:229`):

| Code | security-scan.sh (`:64-70`) | check-imports.sh (`:80-87`) |
|---|---|---|
| 0 | no findings, at least one scanner `ran`/`findings` (`:247`) | checked, clean (`:594`) |
| 1 | at least one finding | findings |
| 2 | usage error: bad flag (`:108`), no `jq` (`:85`), `--base` with `--paths` (`:112-113`), not a git work tree without `--paths` (`:131`), invalid / unresolvable `--base` (`:133-135`), missing `--paths` entry (`:150-151`) | usage error: bad flag (`:123`), no `jq` (`:100`), `--base` with `--paths` (`:127-128`), `--base` outside git (`:139`), invalid / unresolvable `--base` (`:140-142`), not a git work tree without `--paths` (`:149`), missing `--paths` entry (`:160-161`) |
| 3 | nothing checked: no file in scope (`:251`), or no scanner ran (all `unavailable`) (`:246`) | nothing to check — no JS/TS/Python sources or manifests in scope (`:222-229`) |
| 4 | a scanner errored and none produced findings (`:245`) | a check could not run and nothing was found: `$PYTHON` missing (`:431`,`:507`), Python helper failed (`:456`,`:553`), manifest unparseable (`:510`) (`:593`) |

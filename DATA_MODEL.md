# Data Model

Canonical catalog of data contracts that cross a boundary in this repo — the
cross-session memory files, the Claude Code Stop-hook memory-extraction
contracts, and the deterministic review-script JSON reports.

**Last updated:** 2026-10-19

## Change log

| Date | Run | Summary |
|---|---|---|
| 2026-10-19 | fix/audit-scan-scripts (security fix round 2) | Updated `ReviewScanReport`: new `skipped` reason `"manifest resolves outside the repo root"` (both scripts); new check-imports rules `js-import-outside-root` / `py-import-outside-root`; new security-scan copy/containment `error` reasons (npm-audit, pip-audit, cargo-audit); noted text-output control-char escaping and per-line script prefix; every line citation re-verified and shifted to current files. |
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

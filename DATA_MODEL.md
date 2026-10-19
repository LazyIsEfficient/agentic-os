# Data Model

Canonical catalog of data contracts that cross a boundary in this repo — the
cross-session memory files, the Claude Code Stop-hook memory-extraction
contracts, the PreToolUse general-purpose-ban hook I/O, and the reviewer
verdict contract with its SubagentStop capture / Stop gate hooks.

**Last updated:** 2026-10-19

## Change log

| Date | Run | Summary |
|---|---|---|
| 2026-10-19 | fix/audit-stop-gate (#258) | Added `ReviewVerdictArtifact` (`.claude/reviews/<HEAD>-<agent>.json`, content = `ReviewVerdictNormalized`), `ReviewVerdictCaptureHookIO` (SubagentStop `review-verdict-capture.sh`), and `ReviewGateStopHookIO` (Stop `review-gate-stop.sh`, `{"decision":"block","reason"}`). Updated `ReviewVerdict` / `ReviewVerdictNormalized`: parser moved to `.claude/hooks/lib/parse-verdict.sh` (`scripts/parse-verdict.sh` is now a wrapper) and now ships with hooks; duplicate-key check is `jq --stream` (python3 dependency removed; new fixture `duplicate-key-nested.txt`); all parser line citations re-cut. |
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

### ReviewGateStopHookIO

| Field | Value |
|---|---|
| **Kind** | `message` |
| **Ingestion route** | The Claude Code **Stop** hook, registered in `.claude/settings.json:41-44` (alongside `memory-extract.sh`; consumer copy `assets/consumer/claude-settings.json:28-30`). INPUT is the Stop event JSON on **stdin**, truncated to the first 4 MiB (`head -c 4194304`, `review-gate-stop.sh:47`). Reads `ReviewVerdictArtifact` files and git state only — never LLM output (`:3-6`). **Fails open**: missing `jq`/`git`, unparseable payload, no HEAD, no default branch, git or planner errors → one stderr line `review-gate-stop: <reason> — gate skipped (fail-open)`, exit 0 (`:33-35`,`:41`). |
| **Source** | `.claude/hooks/review-gate-stop.sh` (lines 37–138) |

**INPUT** (Stop event, stdin) — only these fields are consumed:

```json
{ "stop_hook_active": false, "cwd": "/repo" }
```

| Name | Type | Required | Notes |
|---|---|---|---|
| `stop_hook_active` | boolean | no | `.stop_hook_active // false`; `true` → allow (exit 0, no output) — one block per stop attempt — `:10`,`:48-49` |
| `cwd` | string | no | Used to locate the git root only when `CLAUDE_PROJECT_DIR` is unset/empty; else `$PWD`. Not a git repo → allow silently — `:51-54` |

**Environment:**

| Var | Use |
|---|---|
| `AGENTIC_OS_REVIEW_GATE` | Exactly `off` → allow immediately (opt-out) — `:9`,`:43` |
| `CLAUDE_PROJECT_DIR` | Preferred directory for `git rev-parse --show-toplevel` — `:51`,`:54` |
| `SHIP_GATES_CHANGED_FILES` | Not read from the caller; set by the hook when invoking `scripts/gate-plan.sh --checkboxes` (only when the hook runs from the same repo's `.claude/hooks/`) — `:73-77`,`:83` |

**Decision inputs** (`:58-101`): default branch ref first of `origin/HEAD`, `origin/main`, `main`; changed paths = `merge-base..HEAD` + tracked-dirty + untracked, minus `.claude/reviews/`; required reviewers = planner output ∩ the four reviewer names, or (consumer fallback) `code-reviewer` + `security-reviewer` whenever any changed path is not docs (`*.md` other than `DATA_MODEL.md`, `LICENSE`, `NOTICE`, `docs/*`) — `:80-98`. No changes or no required reviewers → allow.

**OUTPUT** (stdout) — exactly one of:

Allow: no output, exit 0 (`:43`,`:49`,`:54`,`:71`,`:101`,`:129`).

Block (`:103`, built with `jq -cn`):

```json
{"decision":"block","reason":"review-gate: <text>"}
```

| Name | Type | Required | Notes |
|---|---|---|---|
| `decision` | string | only when blocking | Literal `"block"` — `:103` |
| `reason` | string | only when blocking | Prefixed `review-gate: `. Either (a) uncommitted/untracked qualifying changes — lists up to 5 dirty paths and says commit first, then dispatch the required agents (`:107-112`); or (b) `HEAD <12-char sha> has changes vs <ref> that require review.` plus `No captured verdict ... from: <agents>` (`:133`), `Evidenced hold from: <agents>` (`:135`), and advisory `fix-before-merge from: <agents>` info (`:137`) |

Always exits `0` (`:103`; blocks via the JSON `decision`, not the exit code). `fix-before-merge` never blocks on its own (`:23-24`,`:123`,`:129`).

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

### ReviewVerdict

| Field | Value |
|---|---|
| **Kind** | `message` |
| **Ingestion route** | Emitted by gate reviewer agents as the **only** fenced `json` block of their final output, placed at the very end (`review-verdict.md:32-36`); consumed by the parser `.claude/hooks/lib/parse-verdict.sh [--expect-head <sha>] [FILE]` from the file argument or stdin (`lib/parse-verdict.sh:10-12`,`:35-54`). `scripts/parse-verdict.sh` is now a one-line wrapper that `exec`s it (`scripts/parse-verdict.sh:4`; `review-verdict.md:98-99`). In-session consumer: the SubagentStop hook `review-verdict-capture.sh` (see `ReviewVerdictCaptureHookIO`). Emitters: `code-reviewer`, `security-reviewer`, `library-reviewer` (verdict `pass`\|`fix-before-merge`\|`hold`) and `data-model-verifier` (`pass`\|`hold` only, parser-enforced) — `review-verdict.md:11-16`; each agent's `## Verdict block` section. `library-investigator` and `adversarial-claims-reviewer` are exempt (`review-verdict.md:18-20`). |
| **Source** | `.claude/references/review-verdict.md` (Shape lines 30–74, rejections 87–94); `.claude/hooks/lib/parse-verdict.sh` (framing lines 56–80, duplicate-key check 84–104, validation 106–150, post-demotion checks 159–166); wrapper `scripts/parse-verdict.sh`; emitters `.claude/agents/code-reviewer.md:62-68`, `.claude/agents/security-reviewer.md:67-73`, `.claude/agents/library-reviewer.md:67-73`, `.claude/agents/data-model-verifier.md:72-78`; fixtures `scripts/fixtures/review-verdict/*.txt`, tests `scripts/parse-verdict-test.sh` |
| **Notes** | The parser now ships to consumers with the hooks (`lib/parse-verdict.sh:6-8`; `review-verdict.md:98-99`; `install.sh:336` `install_dir "hooks"`). `.claude/references/review-verdict.md` and `scripts/` remain repo-side and do NOT ship (`review-verdict.md:7-9`), so each emitting agent restates the enum, required fields, and demotion rule inline in its `## Verdict block` (e.g. `code-reviewer.md:64`). Agent emitter line ranges not re-verified this run. |

**Framing** (`lib/parse-verdict.sh:56-80`; `review-verdict.md:32-36`): an opening fence line matching `^[[:space:]]*```json[[:space:]]*$` and a closing line matching `^[[:space:]]*```[[:space:]]*$` (`lib/parse-verdict.sh:60-61`). The output must contain **exactly one** such block and only whitespace may follow its closing fence. Rejected with exit `1`: zero blocks (`:65`,`:75`), an unterminated block (`:66`,`:76`), more than one block — including a `json` block quoted inside a longer fence (`:67`,`:77`; fixtures `multiple-blocks.txt`, `nested-quote-override.txt`), or any non-whitespace after the closing fence (`:63`,`:68`,`:78`; fixture `trailing-text.txt`). Text *before* the block is allowed. The block body must parse as JSON (`:82`) and contain exactly one value (`:129`) that is an object (`:131`).

**Duplicate keys** (`lib/parse-verdict.sh:84-104`; `review-verdict.md:92-94`): checked with `jq --stream` over raw tokens (before jq's last-key-wins collapse) — a value path that is "closed" and then seen again means its key was repeated, at any depth. Rejection: stderr `parse-verdict: duplicate JSON key: <dot.path>` (`:98`,`:103`), exit `1` (fixtures `duplicate-key.txt`, `duplicate-key-nested.txt`); a scan failure is also exit `1` (`:102`). Runs only when the block holds exactly one JSON value (`:89`); the multi-value case is rejected by validation. The former `python3` check is gone — no python dependency, because the parser now lives under `.claude/hooks/`, where Invariant 8 bans inline interpreters (`:84-85`).

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
| `schema` | string literal | yes | Exactly `agentic-os/review-verdict@1` — `lib/parse-verdict.sh:133-134` |
| `agent` | enum string | yes | One of `code-reviewer` \| `security-reviewer` \| `library-reviewer` \| `data-model-verifier`; anything else rejected (fixture `unknown-agent.txt`) — `lib/parse-verdict.sh:109`,`:135-136`; `review-verdict.md:61` |
| `base` | string (non-blank) | yes | Base ref diffed against, e.g. `origin/main` — `lib/parse-verdict.sh:137` |
| `head` | string | yes | Full commit SHA, regex `^([0-9a-f]{40}\|[0-9a-f]{64})$` (lowercase hex) — `lib/parse-verdict.sh:138-139`. With `--expect-head <sha>`, must equal `<sha>` exactly or exit `1` — `lib/parse-verdict.sh:39-41`,`:140-141`; `review-verdict.md:107` |
| `verdict` | enum string | yes | `pass` \| `fix-before-merge` \| `hold` — `lib/parse-verdict.sh:142-143`. `data-model-verifier` may emit only `pass` \| `hold`; `fix-before-merge` from it is rejected (fixture `verifier-fix-before-merge.txt`) — `lib/parse-verdict.sh:144-145`; `review-verdict.md:64` |
| `findings` | array of Finding | yes | May be empty; non-array rejected — `lib/parse-verdict.sh:146-148` |

Finding (each element must be an object — `lib/parse-verdict.sh:112`):

| Name | Type | Required | Notes |
|---|---|---|---|
| `tier` | number | yes | `0` \| `1` \| `2` — `lib/parse-verdict.sh:114-115` |
| `severity` | enum string | yes | `critical` \| `high` \| `medium` \| `low` — `lib/parse-verdict.sh:116-117`. Prose blocking / should-fix / nit map to `high`-or-`critical` / `medium` / `low` — `review-verdict.md:73-74` |
| `file` | string (non-blank) | yes | Repo-relative path by convention (`review-verdict.md:68`); parser checks only non-blank string — `lib/parse-verdict.sh:118-119` |
| `line` | integer ≥ 1 \| null | no | Omitted or `null` = file-level finding — `lib/parse-verdict.sh:120-121` |
| `summary` | string (non-blank) | yes | One sentence — `lib/parse-verdict.sh:122-123` |
| `evidence` | string \| null | no (schema) | Must be a string when present — `lib/parse-verdict.sh:124-125`. Contract-required for tier 0/1 (`review-verdict.md:71`); absence is not a validation error but triggers demotion (see `ReviewVerdictNormalized`) |

**Cross-field rejections** (evaluated after demotion, only when the schema checks above pass — `lib/parse-verdict.sh:159-173`; `review-verdict.md:87-91`), each exit `1`:

- `verdict: pass` with one or more tier 0/1 findings that still carry evidence after demotion (fixture `pass-contradiction.txt`) — `lib/parse-verdict.sh:162-163`.
- `agent: data-model-verifier` with `verdict: hold` and zero evidenced tier 0/1 findings — rejected, NOT downgraded (fixture `verifier-unevidenced-hold.txt`) — `lib/parse-verdict.sh:164-165`.

Unknown extra keys at either level are not rejected; they are dropped from the normalized output (`lib/parse-verdict.sh:153`,`:171`).

---

### ReviewVerdictArtifact

| Field | Value |
|---|---|
| **Kind** | `persistence` |
| **Ingestion route** | One JSON file per (HEAD, reviewer) at `<git-root>/.claude/reviews/<HEAD-sha>-<agent>.json`. **Writer:** only the SubagentStop hook `review-verdict-capture.sh` (reviewers are read-only and never write it — `review-verdict-capture.sh:3-4`; `review-verdict.md:120-126`). **Reader:** only the Stop hook `review-gate-stop.sh` (`review-gate-stop.sh:116-120`; `review-verdict.md:126-128`). |
| **Source** | `.claude/hooks/review-verdict-capture.sh` (lines 47–52, 77–97); `.claude/hooks/review-gate-stop.sh` (lines 115–127); `.claude/references/review-verdict.md` (lines 118–128); `.gitignore:29-31` |

**Content:** exactly the `ReviewVerdictNormalized` JSON (see that section — fields are not duplicated here): the parser's stdout written verbatim plus a trailing newline (`printf '%s\n' "$out"`, `review-verdict-capture.sh:93`).

**Write conditions** (all must hold, else nothing is written — `review-verdict-capture.sh`):

| Rule | Detail |
|---|---|
| Agent allowlist | `agent_type` exactly one of `code-reviewer` \| `security-reviewer` \| `library-reviewer` \| `data-model-verifier`; anything else exits silently — `:42-45` |
| HEAD-bound parse | Parser run as `lib/parse-verdict.sh --expect-head "$head"`, where `head` = `git rev-parse --verify -q HEAD` of the git root — `:50-51`, `:77` |
| Exit filter | Only parse exits `0` / `2` / `3` (pass / hold / fix-before-merge); exit `1` (invalid, stale head) writes nothing — `:78-82` |
| Agent match | Normalized `.agent` must equal the subagent's `agent_type` — `:84-85` |
| Directory safety | Refuses when `.claude/reviews` is a symlink — `:88` |

**Filename:** `<head>-<agent>.json`; `head` must match `^([0-9a-f]{40}|[0-9a-f]{64})$` (`:52`) and `agent` is the allowlisted `agent_type`, so the name cannot leave `.claude/reviews/` (`:17-18`).

**Atomic write / overwrite:** temp file `mktemp "$reviews/.tmp.XXXXXX"` then `mv -f` onto the final name (`:92-93`); a re-review of the same HEAD by the same agent overwrites the prior file. On failure the temp file is removed (`:96`).

**Self-gitignore:** on first creation of the dir, a `.claude/reviews/.gitignore` containing the single line `*` is written if absent (`review-verdict-capture.sh:89-90`). The repo `.gitignore` also lists `.claude/reviews/` (`.gitignore:31`), and `review-gate-stop.sh` excludes `^\.claude/reviews/` from its changed-path set (`review-gate-stop.sh:65`,`:69-70`).

**Read rules** (`review-gate-stop.sh:116-127`): for each required reviewer `a`, reads `$root/.claude/reviews/$head-$a.json` and accepts it only when `.agent == a` AND `.head == <current HEAD>` and `.verdict` is in `pass` \| `fix-before-merge` \| `hold` (`:118-120`). `pass` → satisfied; `fix-before-merge` → satisfied (listed as advisory info); `hold` → block; missing / malformed / mismatched → treated as missing → block (`:121-126`).

---

### ReviewVerdictCaptureHookIO

| Field | Value |
|---|---|
| **Kind** | `message` |
| **Ingestion route** | The Claude Code **SubagentStop** hook, registered with matcher `code-reviewer\|security-reviewer\|library-reviewer\|data-model-verifier` in `.claude/settings.json:45-47` (consumer copy: `assets/consumer/claude-settings.json:31-33`, path `$HOME/.claude/hooks/review-verdict-capture.sh`). INPUT is the SubagentStop event JSON on **stdin**, truncated to the first 4 MiB (`head -c $((MAX_BYTES * 4))`, `MAX_BYTES=1048576` — `review-verdict-capture.sh:28`,`:39`). Side effect: writes `ReviewVerdictArtifact`. **Fails open**: every error prints one `review-verdict-capture: <note>` line to stderr and exits 0 (`:23-24`,`:30`). |
| **Source** | `.claude/hooks/review-verdict-capture.sh` (lines 26–97) |

**INPUT** (SubagentStop event, stdin) — only these fields are consumed:

```json
{ "agent_type": "code-reviewer", "last_assistant_message": "<final text>", "agent_transcript_path": "~/.claude/projects/.../x.jsonl", "cwd": "/repo" }
```

| Name | Type | Required | Notes |
|---|---|---|---|
| `agent_type` | string | yes (effectively) | Read as `.agent_type // empty \| strings`; not in the 4-name allowlist → exit 0, no output — `:40`,`:42-45`. Unparseable payload → fail-open note — `:40` |
| `last_assistant_message` | string | no | Primary source of the reviewer's final message — `:54`. Over `MAX_BYTES` (1 MiB) or empty → not captured — `:74-75` |
| `agent_transcript_path` | string | no | Fallback only when `last_assistant_message` is empty — `:56-57`. Leading `~` expanded; must be a regular non-symlink `*.jsonl` file whose dir resolves under `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects` — `:59-63`. Only the last `MAX_BYTES` read; the last `type == "assistant"` entry's `.message.content` (string, or joined `text` parts of an array) is used — `:64-71` |
| `cwd` | string | no | Used to locate the git root only when `CLAUDE_PROJECT_DIR` is unset/empty; else falls back to `$PWD` — `:47-50` |

**Environment:**

| Var | Use |
|---|---|
| `CLAUDE_PROJECT_DIR` | Preferred directory for `git rev-parse --show-toplevel` — `:47`,`:50` |
| `CLAUDE_CONFIG_DIR` | Root of the transcript containment check (`<dir>/projects`), default `$HOME/.claude` — `:61` |

Requires `jq` and `git` on PATH and `lib/parse-verdict.sh` next to the hook; absence of any → fail-open note (`:32-37`).

**OUTPUT:** nothing on stdout in any path; always exit `0` (`:30`,`:44`,`:94`,`:97`). Diagnostics go to stderr only.

---

### ReviewVerdictNormalized

| Field | Value |
|---|---|
| **Kind** | `message` |
| **Ingestion route** | Output of `bash .claude/hooks/lib/parse-verdict.sh [--expect-head <sha>] [FILE]` (or the `scripts/parse-verdict.sh` wrapper, `scripts/parse-verdict.sh:4`); stdin when FILE omitted (`lib/parse-verdict.sh:10-12`,`:35-54`). On exit `0`, `2` or `3` a single line of compact JSON is printed to **stdout** (`lib/parse-verdict.sh:188-195`); on exit `1` nothing is printed to stdout and one `parse-verdict: <reason>` line per error goes to **stderr** (`lib/parse-verdict.sh:30`,`:183-185`). Consumer: `review-verdict-capture.sh` (SubagentStop), which persists the stdout JSON as `ReviewVerdictArtifact` (`review-verdict-capture.sh:77-93`); also CI / manual use. |
| **Source** | `.claude/hooks/lib/parse-verdict.sh` (exit codes lines 21–26, normalization 152–180, emit 188–195); `.claude/references/review-verdict.md` (Normalization + rejections lines 76–94, exit codes 107–116) |
| **Notes** | The parser ships with the hooks (`lib/parse-verdict.sh:6-8`; `review-verdict.md:98-99`); the reference doc is repo-side only (`review-verdict.md:7-9`). |

**Exit codes** (`lib/parse-verdict.sh:21-26`,`:191-195`; `review-verdict.md:109-116`):

| Exit | Meaning |
|---|---|
| `0` | Valid; normalized `verdict` is `pass` |
| `1` | Invalid: block count/position (zero, >1, unterminated, trailing text), invalid JSON, not exactly one value, duplicate keys, schema/enum/required-field/agent violation, a cross-field rejection (pass contradiction, `data-model-verifier` `fix-before-merge` or unevidenced `hold`), or `--expect-head` mismatch; also usage error, unreadable file, missing `jq`, or duplicate-key scan failure (`lib/parse-verdict.sh:30-33`,`:40-44`,`:50`,`:73-80`,`:82`,`:102-103`,`:181`,`:183-185`) |
| `2` | Valid; normalized `verdict` is `hold` (at least one tier 0/1 finding survived demotion) |
| `3` | Valid; normalized `verdict` is `fix-before-merge`, including a downgraded unevidenced `hold` |

**Shape** (stdout, compact JSON; example per `scripts/fixtures/review-verdict/hold-unevidenced.txt` input, which exits `3`):

```json
{"schema":"agentic-os/review-verdict@1","agent":"code-reviewer","base":"origin/main","head":"0123456789abcdef0123456789abcdef01234567","verdict":"fix-before-merge","findings":[{"demoted_from":1,"tier":2,"severity":"high","file":"src/a.ts","line":3,"summary":"Looks racy","evidence":"  "}],"verdict_demoted_from":"hold"}
```

| Name | Type | Required | Notes |
|---|---|---|---|
| `schema` | string literal | yes | Passed through — `lib/parse-verdict.sh:171` |
| `agent` | enum string | yes | Passed through (already validated against the four-agent enum) — `lib/parse-verdict.sh:171` |
| `base` | string | yes | Passed through — `lib/parse-verdict.sh:171` |
| `head` | string | yes | Passed through; equals `--expect-head` when that flag was given — `lib/parse-verdict.sh:171` |
| `verdict` | enum string | yes | `pass` \| `fix-before-merge` \| `hold`. A `hold` with zero findings at tier ≤ 1 after demotion is rewritten to `fix-before-merge` — `lib/parse-verdict.sh:175-177`. Never fires for `data-model-verifier` (that case is rejected first — `:164-165`) |
| `findings` | array of NormalizedFinding | yes | Each input finding mapped through `normalize_finding` — `lib/parse-verdict.sh:171` |
| `verdict_demoted_from` | string literal `"hold"` | no | Present only when the `hold` → `fix-before-merge` downgrade fired — `lib/parse-verdict.sh:176` |

NormalizedFinding (`lib/parse-verdict.sh:152-156`):

| Name | Type | Required | Notes |
|---|---|---|---|
| `demoted_from` | number (`0` \| `1`) | no | Present only when the input tier was 0/1 and `evidence` was missing, `null`, or whitespace-only; holds the original tier — `lib/parse-verdict.sh:154-155` |
| `tier` | number | yes | `0` \| `1` \| `2`; set to `2` on demotion — `lib/parse-verdict.sh:155` |
| `severity` | enum string | yes | Passed through — `lib/parse-verdict.sh:153` |
| `file` | string | yes | Passed through — `lib/parse-verdict.sh:153` |
| `line` | integer ≥ 1 \| null | yes | Always present; omitted input → `null` — `lib/parse-verdict.sh:153` |
| `summary` | string | yes | Passed through — `lib/parse-verdict.sh:153` |
| `evidence` | string \| null | yes | Always present; omitted input → `null`; a blank string is kept as-is (even when demoted) — `lib/parse-verdict.sh:153` |

Key order: `demoted_from` is emitted first in a demoted finding; `verdict_demoted_from` last at top level (`lib/parse-verdict.sh:155`,`:176`). Consumers should not rely on key order.

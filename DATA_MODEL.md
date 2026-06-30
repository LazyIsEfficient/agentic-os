# Data Model

Canonical catalog of data contracts that cross a boundary in this repo —
persistence files, config policy, and the JSON payloads/decisions exchanged
between Cursor's hook runtime and the dispatch-enforcement library.

**Last updated:** 2026-06-29

## Change log

| Date | Run | Summary |
|---|---|---|
| 2026-06-29 | dispatch-enforcement docs | Initial catalog: dispatch-gate policy config, per-session ledger, audit log, hook event payload, and hook decision shapes. |

---

### DispatchGateAuditRecord

| Field | Value |
|---|---|
| **Kind** | `persistence` |
| **Ingestion route** | One JSON object appended per line (JSONL) to `.cursor/dispatch-gate-audit.jsonl` by `dispatch_gate_audit_log()`; gitignored. Append site: `scripts/lib/dispatch-gate-lib.sh:154`. Best-effort: suppressed when `jq` is unavailable or the dir cannot be created (`scripts/lib/dispatch-gate-lib.sh:145`). |
| **Source** | `scripts/lib/dispatch-gate-lib.sh` (`dispatch_gate_audit_log`, lines 137–155) |

The audit log **is** written. `dispatch_gate_audit_log` is invoked from the
pre-tool router (`scripts/lib/dispatch-gate-lib.sh:572`, `:577`, `:582`), the
impl gate (`:533`, `:537`, `:553`), and the before-read gate (`:660`, `:663`,
`:671`).

**Shape** (`jq -c -n`, `scripts/lib/dispatch-gate-lib.sh:148-154`):

```json
{
  "ts": "2026-06-29T00:00:00Z",
  "event": "preToolUse",
  "decision": "enforce-impl",
  "tool_name": "Write",
  "hook_event_name": "preToolUse",
  "subagent_id": null,
  "file_path": null
}
```

| Name | Type | Required | Notes |
|---|---|---|---|
| `ts` | string (ISO-8601 UTC) | yes | `date -u +%Y-%m-%dT%H:%M:%SZ` — `dispatch-gate-lib.sh:149` |
| `event` | string | yes | Caller-supplied event label, e.g. `preToolUse`, `preToolUse-impl`, `beforeReadFile` — `dispatch-gate-lib.sh:148`,`:152` |
| `decision` | string | yes | Caller-supplied outcome label, e.g. `enforce-research`, `enforce-impl`, `allow-pass-through`, `check`, `deny`, `deny:no-path`, `deny:<path>`, `allow`, `record` — `dispatch-gate-lib.sh:150`,`:153` |
| `tool_name` | string \| null | yes | From payload `.tool_name`; `null` when absent — `dispatch-gate-lib.sh:153` |
| `hook_event_name` | string \| null | yes | From payload `.hook_event_name`; `null` when absent — `dispatch-gate-lib.sh:153` |
| `subagent_id` | string \| null | yes | From payload `.subagent_id`; `null` when absent — `dispatch-gate-lib.sh:153` |
| `file_path` | string \| null | yes | From payload `.file_path`; `null` when absent — `dispatch-gate-lib.sh:153` |

---

### DispatchGateHookDecision

| Field | Value |
|---|---|
| **Kind** | `message` |
| **Ingestion route** | JSON object printed to **stdout** by a hook handler; consumed by the Cursor hook runtime (`hooks.json` is `failClosed`, so blocking handlers always emit a `{permission:...}` object). |
| **Source** | `scripts/lib/dispatch-gate-lib.sh` (`dispatch_gate_allow`/`deny`/`stop_ok`/`stop_followup` + per-event handlers) |

The decision shape depends on the hook event the handler serves.

**`preToolUse` / `beforeReadFile`** — always a permission object.

Allow (`dispatch_gate_allow`, `dispatch-gate-lib.sh:384-390`):

```json
{ "permission": "allow" }
```

Deny (`dispatch_gate_deny`, `dispatch-gate-lib.sh:392-400`):

```json
{ "permission": "deny", "agent_message": "…", "user_message": "…" }
```

| Name | Type | Required | Notes |
|---|---|---|---|
| `permission` | string | yes | `"allow"` or `"deny"` — `dispatch-gate-lib.sh:387`,`:398` |
| `agent_message` | string | only when `deny` | Verbose reason shown to the agent — `dispatch-gate-lib.sh:397`,`:399`. Emitted by research gate (`:505`), impl gate (`:538`,`:554`), before-read gate (`:664`) |
| `user_message` | string | only when `deny` | Short reason shown to the user; defaults to `agent_message` — `dispatch-gate-lib.sh:396`,`:399` |

**`sessionStart`** — context injection (`dispatch_gate_handle_session_init`, `dispatch-gate-lib.sh:485`):

```json
{ "additional_context": "=== dispatch-gate (Tier 0 — mechanical) === …" }
```

| Name | Type | Required | Notes |
|---|---|---|---|
| `additional_context` | string | yes | Orchestrator-mode briefing injected at session start — `dispatch-gate-lib.sh:477-485` |

**`stop`** — completion gate (`dispatch_gate_handle_stop`).

Allow completion (`dispatch_gate_stop_ok`, `dispatch-gate-lib.sh:402-404`):

```json
{}
```

Block completion with follow-up (`dispatch_gate_stop_followup`, `dispatch-gate-lib.sh:406-409`):

```json
{ "followup_message": "dispatch-gate (Tier 0): …" }
```

| Name | Type | Required | Notes |
|---|---|---|---|
| `followup_message` | string | only when blocking | Missing-reviewer message (`dispatch-gate-lib.sh:742`,`:447-456`) or ungated-edit message (`:749-756`) |

**`postToolUse` / `afterFileEdit` / `subagentStop`** — no stdout decision; these handlers only mutate the ledger and print nothing (`dispatch-gate-lib.sh:678`,`:711`,`:625`).

---

### DispatchGateHookEventPayload

| Field | Value |
|---|---|
| **Kind** | `message` |
| **Ingestion route** | JSON read from **stdin** by each thin hook entry script (`input="$(cat)"` in `.cursor/hooks/dispatch-gate-*.sh`) and passed to the matching `dispatch_gate_handle_*` function, which extracts fields via `jq`. |
| **Source** | `.cursor/hooks/dispatch-gate-*.sh` (entry) + `scripts/lib/dispatch-gate-lib.sh` (jq extraction) |

Only the fields the handlers actually read are documented. All fields are
optional from the gate's perspective — every extraction supplies a fallback or
`empty`.

**Shape** (union across all hook events; fields present depend on the event):

```json
{
  "tool_name": "Write",
  "tool_input": { "path": "scripts/foo.sh", "subagent_type": "engineer" },
  "subagent_id": "sub_123",
  "subagent_type": "code-reviewer",
  "status": "completed",
  "file_path": "/abs/path/scripts/foo.sh",
  "composer_mode": "agent",
  "conversation_id": "conv_abc",
  "parent_conversation_id": "conv_parent",
  "session_id": "sess_xyz",
  "hook_event_name": "preToolUse"
}
```

| Name | Type | Required | Notes |
|---|---|---|---|
| `tool_name` | string | no | Tool being invoked; read at `dispatch-gate-lib.sh:531`,`:570`,`:595`,`:631` |
| `tool_input` | object | no | Tool arguments; read raw at `:214`. Write path resolved from `.path` / `.file_path` / `.target_file` / `.filePath` (`:219-229`) |
| `tool_input.subagent_type` | string | no | Dispatched subagent type (Task tracking); also accepts `.subagentType` — `:607` |
| `subagent_id` | string | no | Presence marks a subagent context (vs main thread) — `:124` |
| `subagent_type` | string | no | Subagent type on `subagentStop` — `:717` |
| `status` | string | no | `"completed"` gates ledger updates on `subagentStop` (`:718`) and `stop` (`:732`) |
| `file_path` | string (absolute) | no | Edited file path on `afterFileEdit` — `:689` |
| `composer_mode` | string | no | Defaults to `"agent"`; gates only enforce in `agent` mode — `:177`,`:497`,`:523` |
| `conversation_id` | string | no | Primary session key — `:474`,`:501`,`:527`,`:598`,`:609`,`:657`,`:686`,`:719`,`:738` |
| `parent_conversation_id` | string | no | Preferred session key on `subagentStop` so completions credit the parent — `:719` |
| `session_id` | string | no | Fallback session key when `conversation_id` absent — same sites as `conversation_id` |
| `hook_event_name` | string | no | Echoed into audit records — `:153` |

---

### DispatchGateLedger

| Field | Value |
|---|---|
| **Kind** | `persistence` |
| **Ingestion route** | Single per-session JSON file at `.cursor/dispatch-ledger.json` (gitignored). Seeded by `dispatch_gate_init_ledger` (`dispatch-gate-lib.sh:73-93`), read via `dispatch_gate_read_ledger` (`:110-113`), rewritten via `dispatch_gate_write_ledger` (`:115-119`) under an `mkdir` advisory lock (`:32-49`). Re-initialized when `conversation_id` changes (`:101-107`). |
| **Source** | `scripts/lib/dispatch-gate-lib.sh` (`dispatch_gate_init_ledger`, lines 78–92) |

**Shape** (`jq -n` seed, `dispatch-gate-lib.sh:80-92`):

```json
{
  "version": 1,
  "conversation_id": "conv_abc",
  "research_reads": 0,
  "explore_dispatched": false,
  "impl_dispatched": false,
  "impl_completed": false,
  "completed_reviews": [],
  "completed_subagents": [],
  "modified_paths": [],
  "ungated_code_edits": [],
  "writes_on_main": 0
}
```

| Name | Type | Required | Notes |
|---|---|---|---|
| `version` | number | yes | Schema version, seeded `1` — `dispatch-gate-lib.sh:82` |
| `conversation_id` | string | yes | Owning session; compared on ensure (`:103-105`), seeded from arg (`:79`) |
| `research_reads` | number | yes | Main-thread Read/Grep/Glob/SemanticSearch count; incremented in `dispatch_gate_record_research_read` (`:299`) |
| `explore_dispatched` | boolean | yes | Set `true` when an `explore`/`generalPurpose` Task is dispatched (`:314`) |
| `impl_dispatched` | boolean | yes | Set `true` when an impl-type Task is dispatched (`:318`) |
| `impl_completed` | boolean | yes | Set `true` when an impl-type subagent stops `completed` (`:333`) |
| `completed_reviews` | array<string> | yes | Reviewer/documenter subagent types that completed; appended + uniqued (`:341`) |
| `completed_subagents` | array<object> | yes | All dispatched subagents; each `{ "type": string, "at": ISO-UTC string }` (entry built `:311`, appended `:312`) |
| `modified_paths` | array<string> | yes | Distinct main-thread write paths; appended + uniqued (`:353-354`) |
| `ungated_code_edits` | array<string> | yes | Code-path edits on main thread with no completed impl Task; appended + uniqued (`:703-705`) |
| `writes_on_main` | number | yes | Total main-thread writes; incremented (`:354`) |

`completed_subagents[]` element:

| Name | Type | Required | Notes |
|---|---|---|---|
| `type` | string | yes | Dispatched `subagent_type` — `dispatch-gate-lib.sh:311` |
| `at` | string (ISO-8601 UTC) | yes | Dispatch timestamp — `dispatch-gate-lib.sh:311` |

---

### DispatchGatePolicyConfig

| Field | Value |
|---|---|
| **Kind** | `persistence` |
| **Ingestion route** | Static JSON policy at `.cursor/dispatch-gate.json`, loaded via `dispatch_gate_load_json_file` from `dispatch_gate_config_path` (`dispatch-gate-lib.sh:19-21`,`:58-62`). Read on every gated hook event. Master switch is `enabled` (`:64-71`); env `DISPATCH_GATE_DISABLED=1` overrides to off (`:65`). |
| **Source** | `.cursor/dispatch-gate.json` |

**Shape** (`.cursor/dispatch-gate.json`):

```json
{
  "version": 1,
  "enabled": false,
  "research_read_threshold": 3,
  "impl_subagent_types": ["engineer", "godot-engineer", "rust-engineer", "web3-engineer", "devops-engineer", "phaser-engineer"],
  "explore_subagent_types": ["explore", "generalPurpose"],
  "review_subagent_types": ["code-reviewer", "security-reviewer", "library-reviewer", "data-model-verifier", "bugbot", "security-review"],
  "documenter_subagent_types": ["data-model-documenter"],
  "write_tools": ["Write", "StrReplace", "Delete"],
  "research_tools": ["Read", "Grep", "Glob", "SemanticSearch"],
  "code_path_prefixes": [".claude/skills/", ".claude/agents/", ".claude/commands/", ".claude/workflows/", "scripts/"],
  "harness_exempt_prefixes": [".cursor/hooks/", ".cursor/dispatch-gate.json", ".cursor/hooks.json", "scripts/lib/dispatch-gate", "scripts/dispatch-gate", "docs/dispatch-enforcement.md", "assets/consumer/cursor-hooks.json", "SESSION-STATE.md", ".cursor/dispatch-ledger.json"],
  "stop_hook_enabled": true,
  "enforce_impl_gate": true,
  "enforce_research_gate": true
}
```

| Name | Type | Required | Notes |
|---|---|---|---|
| `version` | number | yes | Config schema version (`dispatch-gate.json:2`). Not read by the lib. |
| `enabled` | boolean | no (default `true`) | Master switch; read `.enabled // true` at `dispatch-gate-lib.sh:70`. Currently `false` (`dispatch-gate.json:3`). |
| `research_read_threshold` | number | no (default `3`) | Main-thread research reads allowed before deny; read `.research_read_threshold // 3` at `dispatch-gate-lib.sh:364`. |
| `impl_subagent_types` | array<string> | no | Types that flip `impl_dispatched`/`impl_completed`; membership tested at `dispatch-gate-lib.sh:316`,`:332`. |
| `explore_subagent_types` | array<string> | no | Types that flip `explore_dispatched`; tested at `dispatch-gate-lib.sh:313`. |
| `review_subagent_types` | array<string> | no | Reviewer types credited to `completed_reviews`; tested at `dispatch-gate-lib.sh:339`. |
| `documenter_subagent_types` | array<string> | no | Documenter types also credited to `completed_reviews`; tested at `dispatch-gate-lib.sh:340`. |
| `write_tools` | array<string> | no | **Declarative only.** Write tools are classified via a hardcoded `case` in `dispatch_gate_is_write_tool` (`dispatch-gate-lib.sh:160-161`), not this key. |
| `research_tools` | array<string> | no | **Declarative only.** Research tools are classified via a hardcoded `case` in `dispatch_gate_is_research_tool` (`dispatch-gate-lib.sh:169-170`), not this key. |
| `code_path_prefixes` | array<string> | no | Path prefixes treated as code (gated); read by `dispatch_gate_path_is_code` → `dispatch_gate_prefix_match` (`dispatch-gate-lib.sh:208`,`:198`). |
| `harness_exempt_prefixes` | array<string> | no | Prefixes exempt from the impl gate; read by `dispatch_gate_path_exempt` → `dispatch_gate_prefix_match` (`dispatch-gate-lib.sh:203`,`:198`). |
| `stop_hook_enabled` | boolean | no (default `true`) | Enables the completion gate; read `.stop_hook_enabled // true` at `dispatch-gate-lib.sh:736`. |
| `enforce_impl_gate` | boolean | no (default `true`) | Enables impl-edit blocking; read `.enforce_impl_gate // true` at `dispatch-gate-lib.sh:377`. |
| `enforce_research_gate` | boolean | no (default `true`) | Enables research-sprawl blocking; read `.enforce_research_gate // true` at `dispatch-gate-lib.sh:367`. |

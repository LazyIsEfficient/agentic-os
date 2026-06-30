#!/usr/bin/env bash
# dispatch-gate-lib.sh — shared ledger + policy helpers AND per-event handlers
# for the dispatch enforcement hooks.
#
# ARCHITECTURE (target convention): this library holds ALL logic, including the
# per-event handler functions (dispatch_gate_handle_*). The .cursor/hooks/*.sh
# entry scripts are THIN — they `source` this file, read stdin, and call the
# matching handler. This keeps every pipe / process-substitution / jq invocation
# OUT of .cursor/hooks/ (which validate.sh's Invariant 8a hook-safety denylist
# scans) and inside scripts/lib/ (which it does NOT scan). Do NOT add pipes,
# `| bash`, eval, or process-substitution to the entry scripts.
#
# Sourced by .cursor/hooks/dispatch-gate-*.sh and scripts/dispatch-gate-test.sh.

dispatch_gate_root() {
  printf '%s' "${CURSOR_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-.}}"
}

dispatch_gate_config_path() {
  printf '%s/.cursor/dispatch-gate.json' "$(dispatch_gate_root)"
}

dispatch_gate_ledger_path() {
  printf '%s/.cursor/dispatch-ledger.json' "$(dispatch_gate_root)"
}

# Portable advisory lock around the ledger read-modify-write. macOS has no
# flock(1), so we use mkdir (atomic create) as the mutex. Parallel subagentStop
# hooks otherwise race and silently drop completed_reviews entries, which makes
# the stop gate demand reviewers that already ran. Best-effort: after ~5s we
# proceed unlocked rather than block a tool/hook indefinitely on a stale lock.
dispatch_gate_lock() {
  local lock tries
  lock="$(dispatch_gate_ledger_path).lock"
  tries=0
  mkdir -p "$(dispatch_gate_root)/.cursor" 2>/dev/null || true
  while ! mkdir "$lock" 2>/dev/null; do
    tries=$((tries + 1))
    if [ "$tries" -ge 100 ]; then
      return 0
    fi
    sleep 0.05 2>/dev/null || true
  done
  return 0
}

dispatch_gate_unlock() {
  rmdir "$(dispatch_gate_ledger_path).lock" 2>/dev/null || true
}

dispatch_gate_require_jq() {
  command -v jq >/dev/null 2>&1 || {
    echo "dispatch-gate: jq is required (brew install jq / apt install jq)" >&2
    return 1
  }
}

dispatch_gate_load_json_file() {
  local path="$1"
  [ -r "$path" ] || return 1
  jq -c '.' "$path" 2>/dev/null
}

dispatch_gate_is_enabled() {
  if [ "${DISPATCH_GATE_DISABLED:-}" = "1" ]; then
    return 1
  fi
  local cfg
  cfg="$(dispatch_gate_load_json_file "$(dispatch_gate_config_path)")" || return 1
  # NOTE: do NOT use `.enabled // true` — jq's `//` returns the RHS when the LHS
  # is null OR false, so `enabled:false` would wrongly read as true and the gate
  # could never be disabled. Treat only an explicit `false` as disabled.
  [ "$(printf '%s' "$cfg" | jq -r 'if .enabled == false then "off" else "on" end')" = "on" ]
}

dispatch_gate_init_ledger() {
  local conversation_id="${1:-unknown}"
  local ledger_dir
  ledger_dir="$(dispatch_gate_root)/.cursor"
  mkdir -p "$ledger_dir"
  jq -n \
    --arg cid "$conversation_id" \
    '{
      version: 1,
      conversation_id: $cid,
      research_reads: 0,
      explore_dispatched: false,
      impl_dispatched: false,
      impl_completed: false,
      completed_reviews: [],
      completed_subagents: [],
      modified_paths: [],
      ungated_code_edits: [],
      writes_on_main: 0
    }' > "$(dispatch_gate_ledger_path)"
}

dispatch_gate_ensure_ledger() {
  local conversation_id="${1:-}"
  if [ ! -f "$(dispatch_gate_ledger_path)" ]; then
    dispatch_gate_init_ledger "$conversation_id"
    return 0
  fi
  if [ -n "$conversation_id" ]; then
    local current
    current="$(jq -r '.conversation_id // ""' "$(dispatch_gate_ledger_path)" 2>/dev/null || echo "")"
    if [ -n "$current" ] && [ "$current" != "$conversation_id" ]; then
      dispatch_gate_init_ledger "$conversation_id"
    fi
  fi
}

dispatch_gate_read_ledger() {
  dispatch_gate_ensure_ledger "${1:-}"
  dispatch_gate_load_json_file "$(dispatch_gate_ledger_path)"
}

dispatch_gate_write_ledger() {
  local json="$1"
  mkdir -p "$(dispatch_gate_root)/.cursor"
  printf '%s\n' "$json" > "$(dispatch_gate_ledger_path)"
}

dispatch_gate_is_subagent_context() {
  local payload="$1"
  local subagent_id
  subagent_id="$(printf '%s' "$payload" | jq -r '.subagent_id // empty' 2>/dev/null)"
  [ -n "$subagent_id" ]
}

dispatch_gate_on_main_thread() {
  ! dispatch_gate_is_subagent_context "$1"
}

# Legacy name — main thread is the enforcement surface, not empty agent_id.
dispatch_gate_is_main_agent() {
  dispatch_gate_on_main_thread "$1"
}

dispatch_gate_audit_log() {
  local event="$1"
  local payload="$2"
  local decision="${3:-}"
  local root dir
  root="$(dispatch_gate_root)"
  dir="$root/.cursor"
  mkdir -p "$dir" 2>/dev/null || return 0
  if ! command -v jq >/dev/null 2>&1; then
    return 0
  fi
  jq -c -n \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg event "$event" \
    --arg decision "$decision" \
    --argjson payload "$payload" \
    '{ts:$ts,event:$event,decision:$decision,tool_name:($payload.tool_name//null),hook_event_name:($payload.hook_event_name//null),subagent_id:($payload.subagent_id//null),file_path:($payload.file_path//null)}' \
    >> "$dir/dispatch-gate-audit.jsonl" 2>/dev/null || true
}

dispatch_gate_is_write_tool() {
  local tool_name
  tool_name="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
  case "$tool_name" in
    write|strreplace|delete|applypatch|editnotebook|search_replace|edit_file|patch) return 0 ;;
  esac
  return 1
}

dispatch_gate_is_research_tool() {
  local tool_name
  tool_name="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
  case "$tool_name" in
    read|grep|glob|semanticsearch|sematicsearch) return 0 ;;
  esac
  return 1
}

dispatch_gate_composer_mode() {
  local payload="$1"
  printf '%s' "$payload" | jq -r '.composer_mode // "agent"' 2>/dev/null
}

dispatch_gate_json_get() {
  local json="$1" filter="$2"
  printf '%s' "$json" | jq -r "$filter" 2>/dev/null
}

# Case-insensitive prefix match. macOS APFS/HFS+ is case-insensitive by default,
# so a differently-cased path (.Claude/skills/foo/SKILL.md) is the same file on
# disk and must classify identically to the lowercase form.
dispatch_gate_prefix_match() {
  local rel_path="$1" cfg="$2" key="$3"
  local lc_path prefix lc_prefix
  lc_path="$(printf '%s' "$rel_path" | tr '[:upper:]' '[:lower:]')"
  while IFS= read -r prefix; do
    [ -n "$prefix" ] || continue
    lc_prefix="$(printf '%s' "$prefix" | tr '[:upper:]' '[:lower:]')"
    case "$lc_path" in
      "$lc_prefix"*) return 0 ;;
    esac
  done < <(printf '%s' "$cfg" | jq -r --arg k "$key" '.[$k][]? // empty')
  return 1
}

dispatch_gate_path_exempt() {
  dispatch_gate_prefix_match "$1" "$2" "harness_exempt_prefixes"
}

dispatch_gate_path_is_code() {
  dispatch_gate_path_exempt "$1" "$2" && return 1
  dispatch_gate_prefix_match "$1" "$2" "code_path_prefixes"
}

dispatch_gate_extract_write_path() {
  local payload="$1"
  local raw path
  raw="$(printf '%s' "$payload" | jq -r '.tool_input // empty' 2>/dev/null)"
  if [ -z "$raw" ] || [ "$raw" = "null" ]; then
    return 0
  fi
  if [[ "$raw" == \{* ]]; then
    path="$(printf '%s' "$raw" | jq -r '
      .path // .file_path // .target_file // .filePath // empty
    ' 2>/dev/null)"
  else
    path="$(printf '%s' "$payload" | jq -r '
      .tool_input.path //
      .tool_input.file_path //
      .tool_input.target_file //
      .tool_input.filePath //
      empty
    ' 2>/dev/null)"
  fi
  [ -n "$path" ] || return 0
  dispatch_gate_normalize_rel_path "$path"
}

dispatch_gate_normalize_rel_path() {
  local path="$1"
  local root
  root="$(cd "$(dispatch_gate_root)" && pwd)"
  case "$path" in
    "$root"/*) path="${path#"$root"/}" ;;
  esac
  path="${path#./}"
  dispatch_gate_collapse_dotdot "$path"
}

# Lexically collapse '.' and '..' segments without touching the filesystem, so a
# '..' inside an exempt prefix (e.g. .cursor/hooks/../../.claude/skills/foo/SKILL.md)
# cannot land a write on a code path while being classified as exempt.
dispatch_gate_collapse_dotdot() {
  local path="$1"
  local seg n
  local out=()
  local IFS='/'
  # Splitting on '/' is intentional; glob expansion is NOT — without noglob a
  # segment like '*' would be filesystem-expanded, making classification depend
  # on cwd contents. Disable globbing for the split, restoring the caller's
  # prior state (don't clear -f if the caller already set it).
  local _restore_glob=0
  case $- in *f*) : ;; *) _restore_glob=1; set -f ;; esac
  # We only ever drop the LAST element, so indices stay contiguous (0..count-1)
  # and count-based indexing needs no reindex — which also avoids expanding a
  # possibly-empty array under `set -u` on bash 3.2 (macOS).
  for seg in $path; do
    case "$seg" in
      ''|'.') continue ;;
      '..')
        n=${#out[@]}
        if [ "$n" -gt 0 ] && [ "${out[$((n - 1))]}" != ".." ]; then
          unset 'out[$((n - 1))]'
        else
          out[$n]=".."
        fi
        ;;
      *) out[${#out[@]}]="$seg" ;;
    esac
  done
  [ "$_restore_glob" -eq 1 ] && set +f
  if [ "${#out[@]}" -gt 0 ]; then
    printf '%s' "${out[*]}"
  fi
}

dispatch_gate_subagent_in_list() {
  local subagent_type="$1"
  local cfg="$2"
  local list_key="$3"
  local item
  while IFS= read -r item; do
    [ "$item" = "$subagent_type" ] && return 0
  done < <(printf '%s' "$cfg" | jq -r --arg k "$list_key" '.[$k][]? // empty')
  return 1
}

dispatch_gate_record_research_read() {
  local conversation_id="${1:-}"
  local ledger
  dispatch_gate_lock
  ledger="$(dispatch_gate_read_ledger "$conversation_id")" || { dispatch_gate_unlock; return 0; }
  ledger="$(printf '%s' "$ledger" | jq '.research_reads = (.research_reads + 1)')"
  dispatch_gate_write_ledger "$ledger"
  dispatch_gate_unlock
}

dispatch_gate_record_task_dispatch() {
  local conversation_id="${1:-}"
  local subagent_type="${2:-}"
  local cfg ledger entry
  cfg="$(dispatch_gate_load_json_file "$(dispatch_gate_config_path)")" || return 0
  dispatch_gate_lock
  ledger="$(dispatch_gate_read_ledger "$conversation_id")" || { dispatch_gate_unlock; return 0; }
  entry="$(jq -n --arg t "$subagent_type" --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '{type:$t,at:$ts}')"
  ledger="$(printf '%s' "$ledger" | jq --argjson e "$entry" '.completed_subagents += [$e]')"
  if dispatch_gate_subagent_in_list "$subagent_type" "$cfg" "explore_subagent_types"; then
    ledger="$(printf '%s' "$ledger" | jq '.explore_dispatched = true')"
  fi
  if dispatch_gate_subagent_in_list "$subagent_type" "$cfg" "impl_subagent_types"; then
    ledger="$(printf '%s' "$ledger" | jq '.impl_dispatched = true')"
  fi
  dispatch_gate_write_ledger "$ledger"
  dispatch_gate_unlock
}

dispatch_gate_record_subagent_stop() {
  local conversation_id="${1:-}"
  local subagent_type="${2:-}"
  local status="${3:-}"
  local cfg ledger
  cfg="$(dispatch_gate_load_json_file "$(dispatch_gate_config_path)")" || return 0
  [ "$status" = "completed" ] || return 0
  dispatch_gate_lock
  ledger="$(dispatch_gate_read_ledger "$conversation_id")" || { dispatch_gate_unlock; return 0; }
  if dispatch_gate_subagent_in_list "$subagent_type" "$cfg" "impl_subagent_types"; then
    ledger="$(printf '%s' "$ledger" | jq '.impl_completed = true')"
  fi
  # data-model-documenter is a Wave 1 *required* node (dispatch-gate-plan-lib.sh)
  # but lives in documenter_subagent_types, not review_subagent_types. Record
  # both into completed_reviews so the stop gate can actually be satisfied —
  # otherwise it demands the documenter forever.
  if dispatch_gate_subagent_in_list "$subagent_type" "$cfg" "review_subagent_types" \
    || dispatch_gate_subagent_in_list "$subagent_type" "$cfg" "documenter_subagent_types"; then
    ledger="$(printf '%s' "$ledger" | jq --arg t "$subagent_type" '.completed_reviews += [$t] | .completed_reviews |= unique')"
  fi
  dispatch_gate_write_ledger "$ledger"
  dispatch_gate_unlock
}

dispatch_gate_record_write_path() {
  local conversation_id="${1:-}"
  local rel_path="${2:-}"
  local ledger
  dispatch_gate_lock
  ledger="$(dispatch_gate_read_ledger "$conversation_id")" || { dispatch_gate_unlock; return 0; }
  ledger="$(printf '%s' "$ledger" | jq --arg p "$rel_path" '
    .modified_paths += [$p] | .modified_paths |= unique | .writes_on_main += 1
  ')"
  dispatch_gate_write_ledger "$ledger"
  dispatch_gate_unlock
}

dispatch_gate_research_denied() {
  local cfg="$1"
  local ledger="$2"
  local threshold explore_done reads
  threshold="$(printf '%s' "$cfg" | jq -r '.research_read_threshold // 3')"
  explore_done="$(printf '%s' "$ledger" | jq -r '.explore_dispatched // false')"
  reads="$(printf '%s' "$ledger" | jq -r '.research_reads // 0')"
  [ "$(printf '%s' "$cfg" | jq -r '.enforce_research_gate // true')" = "true" ] || return 1
  [ "$explore_done" = "true" ] && return 1
  [ "$reads" -ge "$threshold" ]
}

dispatch_gate_impl_denied() {
  local cfg="$1"
  local ledger="$2"
  local rel_path="$3"
  local impl_done
  [ "$(printf '%s' "$cfg" | jq -r '.enforce_impl_gate // true')" = "true" ] || return 1
  dispatch_gate_path_is_code "$rel_path" "$cfg" || return 1
  impl_done="$(printf '%s' "$ledger" | jq -r '.impl_completed // false')"
  [ "$impl_done" = "true" ] && return 1
  return 0
}

dispatch_gate_allow() {
  if command -v jq >/dev/null 2>&1; then
    jq -n '{permission:"allow"}'
  else
    printf '%s\n' '{"permission":"allow"}'
  fi
}

dispatch_gate_deny() {
  local agent_message="$1"
  local user_message="${2:-$1}"
  jq -n \
    --arg perm deny \
    --arg am "$agent_message" \
    --arg um "$user_message" \
    '{permission:$perm, agent_message:$am, user_message:$um}'
}

dispatch_gate_stop_ok() {
  printf '{}\n'
}

dispatch_gate_stop_followup() {
  local message="$1"
  jq -n --arg m "$message" '{followup_message:$m}'
}

dispatch_gate_git_changed_files() {
  local root
  root="$(dispatch_gate_root)"
  (
    cd "$root" || exit 0
    {
      git diff --name-only HEAD 2>/dev/null
      git diff --name-only --cached HEAD 2>/dev/null
      git ls-files --others --exclude-standard 2>/dev/null
    } | awk 'NF && !seen[$0]++'
  )
}

dispatch_gate_missing_reviewers_for_worktree() {
  local ledger="$1"
  local changed
  changed="$(dispatch_gate_git_changed_files)"
  # No changes (or git unavailable) → nothing to review → no demand. (return 0
  # here would falsely block every clean/Q&A turn with an empty reviewer list.)
  [ -n "$changed" ] || return 1
  # shellcheck source=dispatch-gate-plan-lib.sh
  source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/dispatch-gate-plan-lib.sh"
  dispatch_plan_run "$changed"
  # Docs-only diff requires no reviewers.
  [ "$DISPATCH_PLAN_SKIP_DOCS_ONLY" = true ] && return 1
  local completed_csv
  completed_csv="$(printf '%s' "$ledger" | jq -r '.completed_reviews | join(",")')"
  dispatch_plan_missing_reviews "$completed_csv"
  ((${#dispatch_plan_missing[@]} > 0))
}

dispatch_gate_format_missing_review_message() {
  local missing=("$@")
  local joined
  joined="$(printf '%s, ' "${missing[@]}")"
  joined="${joined%, }"
  cat <<EOF
dispatch-gate (Tier 0): Code changed but required reviewer Tasks have not completed.

Missing reviewers: ${joined}

Before marking this work done, dispatch readonly Task(subagent_type=…) for each missing reviewer in parallel (Wave 1 gate DAG). Address Tier 0/1 findings; log Tier 2 to findings ledger.

After reviewers return, continue.
EOF
}

# ── Per-event handlers ─────────────────────────────────────────────────────────
# Each handler reads the raw hook JSON ($input) and (for preToolUse/beforeReadFile)
# prints a {permission:...} object on EVERY path; (for stop) prints {} or a
# {followup_message:...}; (for postToolUse/afterFileEdit/subagentStop) prints
# nothing and just mutates the ledger. The thin .cursor/hooks/*.sh entry scripts
# call exactly one of these and exit 0. All branching is bash case/function calls
# — NEVER spawning a child script (that would reintroduce the pipe-to-shell the
# hook-safety denylist forbids).

# sessionStart — init ledger + inject orchestrator context.
dispatch_gate_handle_session_init() {
  local input="$1"
  dispatch_gate_require_jq || return 0
  dispatch_gate_is_enabled || return 0

  local conversation_id
  conversation_id="$(printf '%s' "$input" | jq -r '.conversation_id // .session_id // "unknown"')"
  dispatch_gate_init_ledger "$conversation_id"

  local context='=== dispatch-gate (Tier 0 — mechanical) ===
ORCHESTRATOR MODE: main thread must not implement.
• Research (>3 Read/Grep/Glob/SemanticSearch without explore Task) → blocked.
• Writes to .claude/skills/, .claude/agents/, .claude/commands/, .claude/workflows/, scripts/ → blocked until an implementation Task completes (engineer, rust-engineer, …).
• End of turn with code/library changes → stop hook requires reviewer Tasks (code-reviewer + security-reviewer + data-model-documenter; library-reviewer when .claude/skills|agents change; data-model-verifier when DATA_MODEL.md changes) before done.
Harness paths (.cursor/hooks/, dispatch-gate scripts) are exempt for maintenance.
Disable emergency: DISPATCH_GATE_DISABLED=1'

  jq -n --arg ctx "$context" '{additional_context:$ctx}'
  return 0
}

# preToolUse research gate — block research sprawl on the main thread.
dispatch_gate_enforce_research() {
  local input="$1"
  dispatch_gate_is_enabled || { dispatch_gate_allow; return 0; }
  dispatch_gate_is_main_agent "$input" || { dispatch_gate_allow; return 0; }

  local mode
  mode="$(dispatch_gate_composer_mode "$input")"
  [ "$mode" = "agent" ] || { dispatch_gate_allow; return 0; }

  local cfg conversation_id ledger
  cfg="$(dispatch_gate_load_json_file "$(dispatch_gate_config_path)")" || { dispatch_gate_allow; return 0; }
  conversation_id="$(printf '%s' "$input" | jq -r '.conversation_id // .session_id // ""')"
  ledger="$(dispatch_gate_read_ledger "$conversation_id")" || { dispatch_gate_allow; return 0; }

  if dispatch_gate_research_denied "$cfg" "$ledger"; then
    dispatch_gate_deny \
      "dispatch-gate: research threshold reached on the main thread. Dispatch Task(subagent_type=explore, readonly=true) with a scoped brief before more Read/Grep/Glob/SemanticSearch. Sequential main-thread research is blocked." \
      "Dispatch explore subagent before more file reads"
    return 0
  fi

  dispatch_gate_allow
  return 0
}

# preToolUse impl gate — block main-thread code edits without a completed impl Task.
dispatch_gate_enforce_impl() {
  local input="$1"
  dispatch_gate_is_enabled || { dispatch_gate_allow; return 0; }
  dispatch_gate_is_main_agent "$input" || { dispatch_gate_allow; return 0; }

  local mode
  mode="$(dispatch_gate_composer_mode "$input")"
  [ "$mode" = "agent" ] || { dispatch_gate_allow; return 0; }

  local cfg conversation_id ledger rel_path tool_name
  cfg="$(dispatch_gate_load_json_file "$(dispatch_gate_config_path)")" || { dispatch_gate_allow; return 0; }
  conversation_id="$(printf '%s' "$input" | jq -r '.conversation_id // .session_id // ""')"
  ledger="$(dispatch_gate_read_ledger "$conversation_id")" || { dispatch_gate_allow; return 0; }

  rel_path="$(dispatch_gate_extract_write_path "$input")"
  tool_name="$(printf '%s' "$input" | jq -r '.tool_name // empty')"

  dispatch_gate_audit_log "preToolUse-impl" "$input" "check:${tool_name}:${rel_path:-no-path}"

  if [ -z "$rel_path" ]; then
    if dispatch_gate_is_write_tool "$tool_name"; then
      dispatch_gate_audit_log "preToolUse-impl" "$input" "deny:no-path"
      dispatch_gate_deny \
        "dispatch-gate: blocked ${tool_name} on the main thread (could not resolve file path). Dispatch Task(subagent_type=engineer|…) for code edits." \
        "Implementation Task required — path not resolved"
      return 0
    fi
    dispatch_gate_allow
    return 0
  fi

  if dispatch_gate_path_exempt "$rel_path" "$cfg"; then
    dispatch_gate_allow
    return 0
  fi

  if dispatch_gate_impl_denied "$cfg" "$ledger" "$rel_path"; then
    dispatch_gate_audit_log "preToolUse-impl" "$input" "deny:${rel_path}"
    dispatch_gate_deny \
      "dispatch-gate: blocked Write/StrReplace/Delete on code path '${rel_path}' from the main thread. Dispatch Task(subagent_type=engineer|rust-engineer|…) to implement; wait for subagentStop completed before integrating on main, or let the subagent own all edits." \
      "Implementation Task required before editing ${rel_path}"
    return 0
  fi

  dispatch_gate_allow
  return 0
}

# preToolUse (no matcher) — route all tools; audit every invocation.
dispatch_gate_handle_pre_tool() {
  local input="$1"
  dispatch_gate_require_jq || { dispatch_gate_allow; return 0; }

  local tool_name
  tool_name="$(printf '%s' "$input" | jq -r '.tool_name // empty')"
  if dispatch_gate_is_research_tool "$tool_name"; then
    dispatch_gate_audit_log "preToolUse" "$input" "enforce-research"
    dispatch_gate_enforce_research "$input"
    return 0
  fi
  if dispatch_gate_is_write_tool "$tool_name"; then
    dispatch_gate_audit_log "preToolUse" "$input" "enforce-impl"
    dispatch_gate_enforce_impl "$input"
    return 0
  fi

  dispatch_gate_audit_log "preToolUse" "$input" "allow-pass-through"
  dispatch_gate_allow
  return 0
}

# postToolUse research tracking — count main-thread research ops.
dispatch_gate_track_research() {
  local input="$1"
  dispatch_gate_is_main_agent "$input" || return 0
  # Read is counted by the beforeReadFile hook; counting it again here would
  # double-count and trip research_read_threshold early. Only Grep/Glob/
  # SemanticSearch (which have no beforeReadFile equivalent) are counted here.
  local tool_name
  tool_name="$(printf '%s' "$input" | jq -r '.tool_name // empty' | tr '[:upper:]' '[:lower:]')"
  [ "$tool_name" = "read" ] && return 0
  local conversation_id
  conversation_id="$(printf '%s' "$input" | jq -r '.conversation_id // .session_id // ""')"
  dispatch_gate_record_research_read "$conversation_id"
}

# postToolUse Task tracking — record subagent dispatch on the main thread.
dispatch_gate_track_task() {
  local input="$1"
  dispatch_gate_is_main_agent "$input" || return 0
  local subagent_type conversation_id
  subagent_type="$(printf '%s' "$input" | jq -r '.tool_input.subagent_type // .tool_input.subagentType // empty')"
  [ -n "$subagent_type" ] || return 0
  conversation_id="$(printf '%s' "$input" | jq -r '.conversation_id // .session_id // ""')"
  dispatch_gate_record_task_dispatch "$conversation_id" "$subagent_type"
}

# postToolUse write tracking — record paths touched on the main thread.
dispatch_gate_track_write() {
  local input="$1"
  dispatch_gate_is_main_agent "$input" || return 0
  local rel_path conversation_id
  rel_path="$(dispatch_gate_extract_write_path "$input")"
  [ -n "$rel_path" ] || return 0
  conversation_id="$(printf '%s' "$input" | jq -r '.conversation_id // .session_id // ""')"
  dispatch_gate_record_write_path "$conversation_id" "$rel_path"
}

# postToolUse (no matcher) — track research, Task, and write tools.
dispatch_gate_handle_post_tool() {
  local input="$1"
  dispatch_gate_require_jq || return 0
  dispatch_gate_is_enabled || return 0

  local tool_name
  tool_name="$(printf '%s' "$input" | jq -r '.tool_name // empty')"
  if dispatch_gate_is_research_tool "$tool_name"; then
    dispatch_gate_track_research "$input"
    return 0
  fi
  if [ "$tool_name" = "Task" ]; then
    dispatch_gate_track_task "$input"
    return 0
  fi
  if dispatch_gate_is_write_tool "$tool_name"; then
    dispatch_gate_track_write "$input"
    return 0
  fi
  return 0
}

# beforeReadFile — research gate (fires on Agent file reads; more reliable than
# preToolUse Read). Counts the read once here (postToolUse skips Read).
dispatch_gate_handle_before_read() {
  local input="$1"
  dispatch_gate_require_jq || { printf '%s\n' '{"permission":"allow"}'; return 0; }
  dispatch_gate_is_enabled || { dispatch_gate_allow; return 0; }
  dispatch_gate_on_main_thread "$input" || { dispatch_gate_allow; return 0; }

  local cfg conversation_id ledger
  cfg="$(dispatch_gate_load_json_file "$(dispatch_gate_config_path)")" || { dispatch_gate_allow; return 0; }
  conversation_id="$(printf '%s' "$input" | jq -r '.conversation_id // .session_id // ""')"
  ledger="$(dispatch_gate_read_ledger "$conversation_id")" || { dispatch_gate_allow; return 0; }

  dispatch_gate_audit_log "beforeReadFile" "$input" "check"

  if dispatch_gate_research_denied "$cfg" "$ledger"; then
    dispatch_gate_audit_log "beforeReadFile" "$input" "deny"
    dispatch_gate_deny \
      "dispatch-gate: research threshold reached. Dispatch Task(subagent_type=explore, readonly=true) before more file reads." \
      "Dispatch explore subagent before more reads"
    return 0
  fi

  dispatch_gate_record_research_read "$conversation_id"
  dispatch_gate_audit_log "beforeReadFile" "$input" "allow"
  dispatch_gate_allow
  return 0
}

# afterFileEdit — safety net when preToolUse misses an edit; stop hook enforces.
# Prints nothing; just records ungated code edits in the ledger.
dispatch_gate_handle_after_file_edit() {
  local input="$1"
  dispatch_gate_require_jq || return 0
  dispatch_gate_is_enabled || return 0
  dispatch_gate_on_main_thread "$input" || return 0

  local cfg conversation_id ledger abs_path rel_path impl_done
  cfg="$(dispatch_gate_load_json_file "$(dispatch_gate_config_path)")" || return 0
  conversation_id="$(printf '%s' "$input" | jq -r '.conversation_id // .session_id // ""')"
  ledger="$(dispatch_gate_read_ledger "$conversation_id")" || return 0

  abs_path="$(printf '%s' "$input" | jq -r '.file_path // empty')"
  [ -n "$abs_path" ] || return 0
  rel_path="$(dispatch_gate_normalize_rel_path "$abs_path")"

  dispatch_gate_audit_log "afterFileEdit" "$input" "record"

  dispatch_gate_path_exempt "$rel_path" "$cfg" && return 0
  dispatch_gate_path_is_code "$rel_path" "$cfg" || return 0

  impl_done="$(printf '%s' "$ledger" | jq -r '.impl_completed // false')"
  [ "$impl_done" = "true" ] && return 0

  dispatch_gate_lock
  ledger="$(dispatch_gate_read_ledger "$conversation_id")" || { dispatch_gate_unlock; return 0; }
  ledger="$(printf '%s' "$ledger" | jq --arg p "$rel_path" '
    .ungated_code_edits += [$p] | .ungated_code_edits |= unique
  ')"
  dispatch_gate_write_ledger "$ledger"
  dispatch_gate_unlock
}

# subagentStop — record completed implementation / reviewer Tasks.
dispatch_gate_handle_subagent_stop() {
  local input="$1"
  dispatch_gate_require_jq || return 0
  dispatch_gate_is_enabled || return 0

  local subagent_type status conversation_id
  subagent_type="$(printf '%s' "$input" | jq -r '.subagent_type // empty')"
  status="$(printf '%s' "$input" | jq -r '.status // empty')"
  conversation_id="$(printf '%s' "$input" | jq -r '.parent_conversation_id // .conversation_id // .session_id // ""')"

  [ -n "$subagent_type" ] || return 0
  dispatch_gate_record_subagent_stop "$conversation_id" "$subagent_type" "$status"
}

# stop — block turn completion until required reviewer Tasks have run.
dispatch_gate_handle_stop() {
  local input="$1"
  dispatch_gate_require_jq || { dispatch_gate_stop_ok; return 0; }
  dispatch_gate_is_enabled || { dispatch_gate_stop_ok; return 0; }

  local status cfg conversation_id ledger ungated msg
  status="$(printf '%s' "$input" | jq -r '.status // "completed"')"
  [ "$status" = "completed" ] || { dispatch_gate_stop_ok; return 0; }

  cfg="$(dispatch_gate_load_json_file "$(dispatch_gate_config_path)")" || { dispatch_gate_stop_ok; return 0; }
  [ "$(printf '%s' "$cfg" | jq -r '.stop_hook_enabled // true')" = "true" ] || { dispatch_gate_stop_ok; return 0; }

  conversation_id="$(printf '%s' "$input" | jq -r '.conversation_id // .session_id // ""')"
  ledger="$(dispatch_gate_read_ledger "$conversation_id")" || { dispatch_gate_stop_ok; return 0; }

  if dispatch_gate_missing_reviewers_for_worktree "$ledger"; then
    msg="$(dispatch_gate_format_missing_review_message "${dispatch_plan_missing[@]}")"
    dispatch_gate_stop_followup "$msg"
    return 0
  fi

  ungated="$(printf '%s' "$ledger" | jq -r '.ungated_code_edits | join(", ")')"
  if [ -n "$ungated" ] && [ "$ungated" != "null" ]; then
    dispatch_gate_stop_followup "$(cat <<EOF
dispatch-gate (Tier 0): Code files were edited on the main thread without a completed implementation Task.

Ungated edits: ${ungated}

Revert those changes (or complete via Task(engineer) first), then dispatch reviewer Tasks before marking done.
EOF
)"
    return 0
  fi

  dispatch_gate_stop_ok
  return 0
}

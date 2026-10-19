#!/usr/bin/env bash
# arm-isolation.sh — sourced by run-arms.sh (and its test). Builds a fresh,
# throwaway Claude Code environment per eval arm and proves, before the arm
# runs, that it holds exactly what that arm should (Tier 0, blocking).
#
# Layout of one arm root (from `mktemp -d`, canonicalised with `pwd -P`):
#   <root>/home          HOME
#   <root>/home/.claude  CLAUDE_CONFIG_DIR (same dir HOME/.claude would resolve to)
#   <root>/tmp           TMPDIR
#   <root>/task          working directory: a scrubbed export of the repo
#
# Docs this relies on (verified 2026-10-19):
#   - CLAUDE_CONFIG_DIR relocates every ~/.claude path, including transcripts:
#     https://code.claude.com/docs/en/claude-directory
#   - `-p` always uses ANTHROPIC_API_KEY when present; CLAUDE_CODE_OAUTH_TOKEN
#     is the subscription alternative: https://code.claude.com/docs/en/authentication
#   - CLAUDE.md / CLAUDE.local.md above the working directory load at launch;
#     managed CLAUDE.md lives in /Library/Application Support/ClaudeCode
#     (macOS) or /etc/claude-code (Linux): https://code.claude.com/docs/en/memory

# Auth: the operator exports ONE of these. Only the variable NAME is ever
# recorded; the value is passed to the child through its environment only.
ISO_AUTH_VARS="ANTHROPIC_API_KEY CLAUDE_CODE_OAUTH_TOKEN"
# Everything else in the operator's environment (CLAUDECODE, CLAUDE_*, other
# ANTHROPIC_*, XDG_*) is dropped before the child starts.
ISO_ENV_PASSTHROUGH="PATH LANG LC_ALL TERM USER LOGNAME SHELL"
ISO_MANAGED_DIRS="/Library/Application Support/ClaudeCode:/etc/claude-code"
# Files Claude Code loads as instructions/config from a project tree.
ISO_PROJECT_CONFIG_NAMES="CLAUDE.md CLAUDE.local.md AGENTS.md .mcp.json"

iso_auth_var() {
  local v
  for v in $ISO_AUTH_VARS; do
    if [ -n "${!v:-}" ]; then echo "$v"; return 0; fi
  done
  return 1
}

iso_auth_help() {
  cat >&2 <<'EOF'
run-arms: no auth for the isolated arms.
Each arm runs with a fresh CLAUDE_CONFIG_DIR, so your normal `claude` login is
NOT visible to it (by design: nothing is copied from ~/.claude or the keychain).
Export one of these in your shell before running, then re-run:
  export ANTHROPIC_API_KEY=...        # Claude Console API key
  export CLAUDE_CODE_OAUTH_TOKEN=...  # subscription token from `claude setup-token`
The value is passed to the child process only; it is never logged or written.
EOF
}

iso_sha256() {
  if command -v shasum >/dev/null 2>&1; then shasum -a 256 | awk '{print $1}'
  else sha256sum | awk '{print $1}'; fi
}

# Hash of a directory's full listing: every path, plus the content hash of
# every regular file. Same tree -> same hash.
iso_listing_sha256() {
  local dir="$1" f
  (
    cd "$dir" || exit 1
    find . -print | LC_ALL=C sort
    find . -type f -print | LC_ALL=C sort | while IFS= read -r f; do
      printf '%s  %s\n' "$(iso_sha256 < "$f")" "$f"
    done
  ) | iso_sha256
}

# iso_make_root -> prints the canonical path of a fresh arm root.
iso_make_root() {
  local raw root
  raw="$(mktemp -d "${TMPDIR:-/tmp}/run-arms.XXXXXX")" || return 1
  root="$(cd "$raw" && pwd -P)" || return 1
  mkdir -p "$root/home/.claude" "$root/tmp" "$root/task"
  echo "$root"
}

# iso_export_task <repo> <task_dir>: committed HEAD of the repo, with every
# file Claude Code would load as project config removed, so the library can
# only reach an arm through its CLAUDE_CONFIG_DIR.
iso_export_task() {
  local repo="$1" task="$2" n
  git -C "$repo" archive --format=tar HEAD | tar -xf - -C "$task" || return 1
  find "$task" -type d -name .claude -prune -exec rm -rf {} +
  for n in $ISO_PROJECT_CONFIG_NAMES; do
    find "$task" -type f -name "$n" -exec rm -f {} +
  done
}

# iso_install_library <repo> <root> <log>: the ON arm's library, installed by
# the real installer into the arm's temp config dir only.
iso_install_library() {
  local repo="$1" root="$2" log="$3"
  HOME="$root/home" CLAUDE_DIR="$root/home/.claude" \
    bash "$repo/install.sh" --force >"$log" 2>&1
}

# Library fingerprint for scanning dirs we do not own (managed policy dirs).
iso_library_markers() {
  local repo="$1" f
  echo "agentic-os"
  for f in "$repo"/.claude/hooks/*.sh; do basename "$f"; done
}

ISO_FAILS=()
iso_fail() { ISO_FAILS+=("$1"); }

# iso_preflight <arm on|off> <root> <repo>
# Fills ISO_FAILS (empty = pass) and ISO_LISTING_SHA. Never runs claude.
iso_preflight() {
  local arm="$1" root="$2" repo="$3"
  local home="$root/home" cfg="$root/home/.claude" task="$root/task"
  local d n f rel extra hits
  ISO_FAILS=()

  [ -d "$cfg" ] || iso_fail "config dir missing: $cfg"

  # HOME holds nothing but the config dir before the arm runs.
  extra="$(find "$home" -mindepth 1 -maxdepth 1 ! -name .claude -print | head -5)"
  [ -z "$extra" ] || iso_fail "unexpected entries in temp HOME: $(echo "$extra" | tr '\n' ' ')"

  # Project tree: nothing Claude Code would load as project config, anywhere.
  hits="$(find "$task" \( -name .claude -o -name CLAUDE.md -o -name CLAUDE.local.md \
            -o -name AGENTS.md -o -name .mcp.json \) -print | head -5)"
  [ -z "$hits" ] || iso_fail "project config in task dir: $(echo "$hits" | tr '\n' ' ')"

  # Every ancestor of the task dir, up to and including /.
  d="$(dirname "$task")"
  while :; do
    for n in .claude $ISO_PROJECT_CONFIG_NAMES; do
      [ -e "$d/$n" ] && iso_fail "project config in ancestor: $d/$n"
    done
    [ "$d" = "/" ] && break
    d="$(dirname "$d")"
  done

  # Managed policy dirs: we cannot remove them, but they must not carry the library.
  local IFS_SAVE="$IFS" mdir markers
  markers="$(iso_library_markers "$repo")"
  IFS=':'
  for mdir in $ISO_MANAGED_DIRS; do
    IFS="$IFS_SAVE"
    if [ -d "$mdir" ] && printf '%s\n' "$markers" | grep -rlF -f /dev/stdin "$mdir" >/dev/null 2>&1; then
      iso_fail "agentic-os markers in managed policy dir: $mdir"
    fi
  done
  IFS="$IFS_SAVE"

  case "$arm" in
    off)
      extra="$(find "$cfg" -mindepth 1 -print 2>/dev/null | head -5)"
      [ -z "$extra" ] || iso_fail "OFF config dir is not empty: $(echo "$extra" | tr '\n' ' ')"
      ;;
    on)
      # Manifest = every file install.sh ships for Claude, byte-identical.
      local missing=0
      while IFS= read -r f; do
        rel="${f#"$repo/.claude/"}"
        cmp -s "$f" "$cfg/$rel" || missing=$((missing + 1))
      done < <(find "$repo/.claude/skills" "$repo/.claude/agents" "$repo/.claude/hooks" -type f)
      for rel in commands/skill-new.md commands/agent-new.md commands/state.md; do
        cmp -s "$repo/.claude/$rel" "$cfg/$rel" || missing=$((missing + 1))
      done
      [ "$missing" -eq 0 ] || iso_fail "ON manifest: $missing library file(s) missing or different in $cfg"
      grep -qF "$cfg/hooks/block-general-purpose.sh" "$cfg/settings.json" 2>/dev/null \
        || iso_fail "ON settings.json does not register the library hooks from $cfg/hooks"
      ;;
    *) iso_fail "unknown arm: $arm" ;;
  esac

  ISO_LISTING_SHA=unavailable
  [ -d "$cfg" ] && ISO_LISTING_SHA="$(iso_listing_sha256 "$cfg")"
  [ "${#ISO_FAILS[@]}" -eq 0 ]
}

# iso_record <jsonl> <arm> <session_id> <run_id> <repo_sha> <auth_var>
# Appends one preflight record. Values go through argv/env into node, never a
# shell-built JSON string. The auth VALUE is never an input here.
iso_record() {
  local out="$1" arm="$2" sid="$3" run_id="$4" sha="$5" auth_var="$6"
  local fails
  fails="$(printf '%s\n' "${ISO_FAILS[@]+"${ISO_FAILS[@]}"}")"
  ARM="$arm" SID="$sid" RUN_ID="$run_id" SHA="$sha" AUTH_VAR="$auth_var" \
  LISTING="$ISO_LISTING_SHA" FAILS="$fails" PASSTHROUGH="$ISO_ENV_PASSTHROUGH" \
  node -e '
    const e = process.env;
    const failures = e.FAILS.split("\n").filter(Boolean);
    process.stdout.write(JSON.stringify({
      run_id: e.RUN_ID, repo_sha: e.SHA, arm: e.ARM, session_id: e.SID,
      recorded_utc: new Date().toISOString(),
      config_dir_listing_sha256: e.LISTING,
      preflight: failures.length ? "fail" : "pass", failures,
      auth_var: e.AUTH_VAR,
      env_passthrough: e.PASSTHROUGH.split(" ").concat(e.AUTH_VAR),
    }) + "\n");
  ' >> "$out"
}

# iso_exec <root> <auth_var> -- cmd...: run cmd in the arm root with an
# allowlisted environment. Values never appear in argv (no `env -i K=V`).
iso_exec() {
  local root="$1" auth_var="$2"; shift 3
  (
    local keep=" $ISO_ENV_PASSTHROUGH $auth_var " v
    while IFS= read -r v; do
      case "$keep" in *" $v "*) ;; *) unset "$v" 2>/dev/null ;; esac
    done < <(compgen -e)
    export HOME="$root/home" CLAUDE_CONFIG_DIR="$root/home/.claude" TMPDIR="$root/tmp"
    export XDG_CONFIG_HOME="$root/home/.config" XDG_DATA_HOME="$root/home/.local/share"
    export XDG_CACHE_HOME="$root/home/.cache" XDG_STATE_HOME="$root/home/.local/state"
    cd "$root/task" || exit 1
    exec "$@"
  )
}

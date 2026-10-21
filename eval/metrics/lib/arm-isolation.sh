#!/usr/bin/env bash
# arm-isolation.sh — sourced by run-arms.sh (and its test). Builds a fresh,
# throwaway Claude Code environment per eval arm and proves, before the arm
# runs, that it holds exactly what that arm should (Tier 0, blocking).
#
# Layout of one arm root (from `mktemp -d`, canonicalised with `pwd -P`):
#   <root>/home          HOME
#   <root>/home/.claude  CLAUDE_CONFIG_DIR (same dir HOME/.claude would resolve to)
#   <root>/tmp           TMPDIR
#   <root>/task          working directory: a scrubbed export of HEAD
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
# ANTHROPIC_*, XDG_*) is dropped before the child starts. PATH is kept by name
# but its value is replaced by iso_child_path.
ISO_ENV_PASSTHROUGH="PATH LANG LC_ALL TERM USER LOGNAME SHELL"
ISO_SYSTEM_PATH="/usr/bin:/bin:/usr/sbin:/sbin"
ISO_MANAGED_DIRS="/Library/Application Support/ClaudeCode:/etc/claude-code"
# Before the arm runs, the ON config dir holds exactly the install manifest
# plus these paths (relative to the config dir). install.sh writes both;
# Claude Code has not run yet, so it has created nothing.
ISO_ON_ALLOWLIST="settings.json .agentic-os-manifest.json"
ISO_SHIPPED_COMMANDS="commands/skill-new.md commands/agent-new.md commands/state.md"
# Case-insensitive match for anything Claude Code loads as project config:
# files, dirs and symlinks alike.
ISO_CONFIG_FIND=( \( -iname .claude -o -iname CLAUDE.md -o -iname CLAUDE.local.md -o -iname AGENTS.md -o -iname .mcp.json \) )

# Prints the name of the first auth variable that is set and non-empty.
# xtrace is suspended so `bash -x` never prints the credential.
iso_auth_var() {
  local v found="" xt=0
  case "$-" in *x*) xt=1; { set +x; } 2>/dev/null ;; esac
  for v in $ISO_AUTH_VARS; do
    if [ -n "${!v:-}" ]; then found="$v"; break; fi
  done
  [ "$xt" = 1 ] && set -x
  [ -n "$found" ] && echo "$found"
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

# System default PATH plus the dirs holding claude, node and jq, resolved from
# the operator PATH. The ON hooks need jq; an npm-installed claude needs node.
iso_child_path() {
  local p="$ISO_SYSTEM_PATH" b d
  for b in claude node jq; do
    d="$(command -v "$b" 2>/dev/null)" || continue
    d="$(dirname "$d")"
    case ":$p:" in *":$d:"*) ;; *) p="$p:$d" ;; esac
  done
  echo "$p"
}

# iso_make_root -> prints the canonical path of a fresh arm root.
iso_make_root() {
  local raw root
  raw="$(mktemp -d "${TMPDIR:-/tmp}/run-arms.XXXXXX")" || return 1
  root="$(cd "$raw" && pwd -P)" || return 1
  mkdir -p "$root/home/.claude" "$root/tmp" "$root/task"
  echo "$root"
}

# iso_export_src <repo> <dir>: committed HEAD only. The ON install, the ON
# manifest and every task dir come from this export, so uncommitted changes
# never reach an arm and the recorded repo_sha is exactly what ran.
iso_export_src() {
  git -C "$1" archive --format=tar HEAD | tar -xf - -C "$2"
}

# iso_export_task <src> <task_dir>: copy of the export with every
# project-config file, dir or symlink removed, so the library can only reach
# an arm through its CLAUDE_CONFIG_DIR.
iso_export_task() {
  local src="$1" task="$2"
  cp -R "$src/." "$task/" || return 1
  find "$task" -mindepth 1 "${ISO_CONFIG_FIND[@]}" -prune -exec rm -rf {} +
}

# iso_install_library <src> <root> <log>: the ON arm's library, installed by
# the real installer from the HEAD export into the arm's temp config dir only.
iso_install_library() {
  local src="$1" root="$2" log="$3"
  env -i HOME="$root/home" CLAUDE_DIR="$root/home/.claude" TMPDIR="$root/tmp" \
    PATH="$(iso_child_path)" bash "$src/install.sh" --force >"$log" 2>&1
}

# iso_on_manifest <src>: relative paths install.sh copies into the config dir.
# A default install is core only: the items of the opt-in packs listed in
# assets/packs/*.txt are not copied (the list goes through ENVIRON: BSD awk
# rejects a newline in a -v value).
iso_on_manifest() {
  local src="$1" rel packs=""
  if [ -d "$src/assets/packs" ]; then packs="$(cat "$src"/assets/packs/*.txt)" || return 1; fi
  ( cd "$src/.claude" && find skills agents hooks ! -type d -print ) \
    | ISO_PACKS="$packs" awk '
        BEGIN { n = split(ENVIRON["ISO_PACKS"], L, "\n"); for (i = 1; i <= n; i++) if (L[i] !~ /^[[:space:]]*(#|$)/) p[L[i]] = 1 }
        { k = $0; if (k ~ /^skills\//) { split(k, a, "/"); k = "skills/" a[2] } if (!(k in p)) print }'
  for rel in $ISO_SHIPPED_COMMANDS; do echo "$rel"; done
}

# Library fingerprint for scanning dirs we do not own (managed policy dirs).
iso_library_markers() {
  local src="$1" f
  echo "agentic-os"
  for f in "$src"/.claude/hooks/*.sh; do basename "$f"; done
}

ISO_FAILS=()
iso_fail() { ISO_FAILS+=("$1"); }
iso_join() { head -5 | tr '\n' ' '; }

# iso_hook_commands <settings.json>: every hook command, sorted, duplicates kept.
iso_hook_commands() {
  jq -r '[.. | objects | select(has("command")) | .command] | .[]' "$1" | LC_ALL=C sort
}

# iso_check_on_settings <src> <cfg>: settings.json must be exactly what
# install.sh writes, i.e. the consumer template with $HOME/.claude/hooks
# rewritten to $cfg/hooks (the same jq rewrite as install-hook-settings.sh).
# The narrower checks run first so a failure says what is wrong.
iso_check_on_settings() {
  local src="$1" cfg="$2" settings="$2/settings.json" expected keys cmd bad
  if ! jq -e 'type == "object"' "$settings" >/dev/null 2>&1; then
    iso_fail "ON settings.json is missing or not a JSON object"
    return
  fi
  expected="$(jq -S --arg hd "$cfg/hooks" '
    walk(if type == "object" and has("command")
         then .command |= gsub("\\$HOME/.claude/hooks"; $hd) else . end)
    | {hooks: .hooks}' "$src/assets/consumer/claude-settings.json")"
  keys="$(jq -c 'keys' "$settings")"
  [ "$keys" = '["hooks"]' ] || iso_fail "ON settings.json top-level keys are $keys, expected [\"hooks\"]"
  bad="$(iso_hook_commands "$settings" | while IFS= read -r cmd; do
      case "$cmd" in "bash $cfg/hooks/"*.sh) ;; *) echo "$cmd" ;; esac
    done | iso_join)"
  [ -z "$bad" ] || iso_fail "ON settings.json has hook commands outside $cfg/hooks: $bad"
  [ "$(iso_hook_commands "$settings")" = "$(echo "$expected" | jq -r '[.. | objects | select(has("command")) | .command] | .[]' | LC_ALL=C sort)" ] \
    || iso_fail "ON settings.json hook commands differ from what install.sh registers"
  [ "$(jq -S . "$settings")" = "$expected" ] \
    || iso_fail "ON settings.json differs from what install.sh writes"
}

# iso_preflight <arm on|off> <root> <src>   (src = an iso_export_src dir)
# Fills ISO_FAILS (empty = pass) and ISO_LISTING_SHA. Never runs claude.
iso_preflight() {
  local arm="$1" root="$2" src="$3"
  local home="$root/home" cfg="$root/home/.claude" task="$root/task"
  local d rel extra hits
  ISO_FAILS=()

  [ -d "$cfg" ] || iso_fail "config dir missing: $cfg"

  # HOME holds nothing but the config dir before the arm runs.
  extra="$(find "$home" -mindepth 1 -maxdepth 1 ! -name .claude -print | iso_join)"
  [ -z "$extra" ] || iso_fail "unexpected entries in temp HOME: $extra"

  # Project tree: nothing Claude Code would load as project config, anywhere.
  hits="$(find "$task" -mindepth 1 "${ISO_CONFIG_FIND[@]}" -print | iso_join)"
  [ -z "$hits" ] || iso_fail "project config in task dir: $hits"

  # Every ancestor of the task dir, up to and including /.
  d="$(dirname "$task")"
  while :; do
    hits="$(find "$d" -mindepth 1 -maxdepth 1 "${ISO_CONFIG_FIND[@]}" -print 2>/dev/null | iso_join)"
    [ -z "$hits" ] || iso_fail "project config in ancestor: $hits"
    [ "$d" = "/" ] && break
    d="$(dirname "$d")"
  done

  # Managed policy dirs: we cannot remove them, but they must not carry the library.
  local IFS_SAVE="$IFS" mdir markers
  markers="$(iso_library_markers "$src")"
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
      extra="$(find "$cfg" -mindepth 1 -print 2>/dev/null | iso_join)"
      [ -z "$extra" ] || iso_fail "OFF config dir is not empty: $extra"
      ;;
    on)
      # Exact: the config dir's file set == manifest + allowlist, and every
      # manifest file is byte-identical to HEAD.
      local expected actual changed=0
      # shellcheck disable=SC2086  # allowlist is a space-separated literal
      expected="$( { iso_on_manifest "$src"; printf '%s\n' $ISO_ON_ALLOWLIST; } | LC_ALL=C sort -u)"
      actual="$( (cd "$cfg" && find . ! -type d -print) | sed 's|^\./||' | LC_ALL=C sort)"
      extra="$(LC_ALL=C comm -13 <(echo "$expected") <(echo "$actual") | iso_join)"
      [ -z "$extra" ] || iso_fail "ON config has files outside the install manifest: $extra"
      extra="$(LC_ALL=C comm -23 <(echo "$expected") <(echo "$actual") | iso_join)"
      [ -z "$extra" ] || iso_fail "ON config is missing manifest files: $extra"
      while IFS= read -r rel; do
        [ -e "$cfg/$rel" ] || continue
        cmp -s "$src/.claude/$rel" "$cfg/$rel" || changed=$((changed + 1))
      done < <(iso_on_manifest "$src")
      [ "$changed" -eq 0 ] || iso_fail "ON manifest: $changed library file(s) differ from HEAD in $cfg"
      iso_check_on_settings "$src" "$cfg"
      ;;
    *) iso_fail "unknown arm: $arm" ;;
  esac

  ISO_LISTING_SHA=unavailable
  [ -d "$cfg" ] && ISO_LISTING_SHA="$(iso_listing_sha256 "$cfg")"
  [ "${#ISO_FAILS[@]}" -eq 0 ]
}

# iso_harness_dirty <repo>: "true" when eval/metrics/ (the harness, which runs
# from the working tree, unlike the arms) has uncommitted or untracked changes.
iso_harness_dirty() {
  if [ -n "$(git -C "$1" status --porcelain -- eval/metrics 2>/dev/null)" ]; then echo true; else echo false; fi
}

# iso_record <jsonl> <arm> <session_id> <run_id> <repo_sha> <auth_var> <harness_dirty>
# Appends one preflight record. Values go through argv/env into node, never a
# shell-built JSON string. The auth VALUE is never an input here.
iso_record() {
  local out="$1" arm="$2" sid="$3" run_id="$4" sha="$5" auth_var="$6" hdirty="$7"
  local fails
  fails="$(printf '%s\n' "${ISO_FAILS[@]+"${ISO_FAILS[@]}"}")"
  HARNESS_DIRTY="$hdirty" \
  ARM="$arm" SID="$sid" RUN_ID="$run_id" SHA="$sha" AUTH_VAR="$auth_var" \
  LISTING="$ISO_LISTING_SHA" FAILS="$fails" PASSTHROUGH="$ISO_ENV_PASSTHROUGH" \
  node -e '
    const e = process.env;
    const failures = e.FAILS.split("\n").filter(Boolean);
    process.stdout.write(JSON.stringify({
      run_id: e.RUN_ID, repo_sha: e.SHA, harness_dirty: e.HARNESS_DIRTY === "true",
      arm: e.ARM, session_id: e.SID,
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
    local keep=" $ISO_ENV_PASSTHROUGH $auth_var " v child_path
    child_path="$(iso_child_path)"
    while IFS= read -r v; do
      case "$keep" in *" $v "*) ;; *) unset "$v" 2>/dev/null ;; esac
    done < <(compgen -e)
    export PATH="$child_path"
    export HOME="$root/home" CLAUDE_CONFIG_DIR="$root/home/.claude" TMPDIR="$root/tmp"
    export XDG_CONFIG_HOME="$root/home/.config" XDG_DATA_HOME="$root/home/.local/share"
    export XDG_CACHE_HOME="$root/home/.cache" XDG_STATE_HOME="$root/home/.local/state"
    cd "$root/task" || exit 1
    exec "$@"
  )
}

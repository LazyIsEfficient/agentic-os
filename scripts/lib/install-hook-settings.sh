# shellcheck shell=bash
# install-hook-settings.sh — merge consumer hook registration into global config,
# and remove it again on uninstall. Sourced by install.sh (not executed directly).

_validate_install_dest() {
  local dest="$1"
  if [[ ! "$dest" =~ ^[/.a-zA-Z0-9._\ -]+$ ]]; then
    echo "Error: unsafe install DEST (reject shell metacharacters in path): $dest" >&2
    exit 1
  fi
}

# Space-separated retired hook basenames → JSON array. Names are validated so
# they can only ever form a `bash <hooks dir>/<name>` command.
_retired_hooks_json() {
  local name
  for name in $1; do
    if [[ ! "$name" =~ ^[A-Za-z0-9._-]+\.sh$ ]]; then
      echo "Error: invalid retired hook name: $name" >&2
      exit 1
    fi
  done
  jq -nc --arg r "$1" '$r | split(" ") | map(select(length > 0))'
}

# Fresh temp file beside $1 (mktemp: O_EXCL, unpredictable name), so a link
# planted at a fixed `.tmp` name can never redirect the write; the caller then
# `mv`s it over $1, which replaces the directory entry instead of writing
# through it. With $1 present, `cp -p` first so its mode (settings.json may
# hold `env` secrets at 0600) survives the rewrite.
_tmp_beside() {
  local t
  t="$(mktemp "$(dirname "$1")/.$(basename "$1").XXXXXX")"
  if [[ -f "$1" ]]; then cp -p "$1" "$t"; fi
  printf '%s' "$t"
}

# settings.json / hooks.json must be a regular file (or absent): a symlink is
# refused rather than written through or silently replaced.
_refuse_link() {
  if [[ -L "$1" ]]; then
    echo "Error: $1 is a symlink — AgenticOS will not rewrite it. Merge the hooks by hand, or replace it with a regular file. Nothing was changed." >&2
    return 1
  fi
}

# Scratch file for an unregister rewrite: beside the target on a real run; a
# dry run writes outside the install dir so it leaves no trace there.
_unregister_tmp() {
  if [[ "$2" == "true" ]]; then mktemp; else _tmp_beside "$1"; fi
}

# Print every hook command present in $1 but not in $2, one per line, prefixed.
_report_removed_hook_commands() {
  local before="$1" after="$2" prefix="$3" cmd
  local q='[.hooks | .. | objects | select(has("command")) | .command | strings] | unique | .[]'
  while IFS= read -r cmd; do
    if [[ -n "$cmd" ]]; then printf '%sunregister hook: %s\n' "$prefix" "$cmd"; fi
  done < <(comm -23 <(jq -r "$q" "$before" | LC_ALL=C sort) <(jq -r "$q" "$after" | LC_ALL=C sort))
}

# ── Codex ──────────────────────────────────────────────────────────────────────

# Rewrite the Codex consumer template from its default ~/.codex/hooks location
# to CODEX_HOME or a project-local .codex/hooks directory. The commands remain
# quoted so project roots containing spaces are safe.
_codex_hooks_json_for_dest() {
  local src="$1" hooks_dir="$2"
  jq --arg hd "$hooks_dir" '
    walk(
      if type == "object" and has("command") then
        .command |= gsub("\\$HOME/.codex/hooks"; $hd)
      else . end
    ) | .hooks
  ' "$src"
}

# A matcher group is AgenticOS-owned when any handler carries the `AgenticOS:`
# status marker. Owned groups are stripped from EVERY event (so a group whose
# event a later release stopped shipping is unregistered too) and events emptied
# by that are dropped; merge then appends the template's groups.
_CODEX_HOOKS_JQ='
  def agenticos_group:
    any(.hooks[]?; ((.statusMessage? // "") | startswith("AgenticOS:")));
  def strip_events: reduce keys_unsorted[] as $e (.;
    if (.[$e] | type) == "array" and any(.[$e][]; agenticos_group)
    then (.[$e] | map(select((agenticos_group | not)))) as $s
      | if ($s | length) == 0 then del(.[$e]) else .[$e] = $s end
    else . end);
  if $mode == "merge" then
    .hooks = reduce ($incoming | keys_unsorted[]) as $event
      ((.hooks // {}) | strip_events;
        .[$event] = ((.[$event] // []) + $incoming[$event]))
  elif .hooks == null then .
  else (.hooks | strip_events) as $h
    | if ($h | length) == 0 and (.hooks | length) > 0 then del(.hooks) else .hooks = $h end
  end
'

# $3 = "check": only verify an existing hooks.json would merge (writes nothing).
merge_codex_hook_settings() {
  local repo_root="$1" dest="$2" mode="${3:-}"
  _validate_install_dest "$dest"
  local src="$repo_root/assets/consumer/codex-hooks.json"
  local dest_file="$dest/hooks.json"
  [[ -f "$src" ]] || return 0
  _refuse_link "$dest_file" || return 1
  if [[ "$mode" == "check" ]]; then
    if [[ ! -f "$dest_file" ]] || ! command -v jq &>/dev/null; then return 0; fi
    local probe
    probe="$(mktemp)"
    if ! jq --arg mode merge --argjson incoming "$(_codex_hooks_json_for_dest "$src" "$dest/hooks")" \
        "$_CODEX_HOOKS_JQ" "$dest_file" > "$probe" 2>/dev/null; then
      rm -f "$probe"
      echo "Error: $dest_file cannot be merged (is it valid JSON?) — fix it first. Nothing was changed." >&2
      return 1
    fi
    rm -f "$probe"
    return 0
  fi
  mkdir -p "$dest"

  if ! command -v jq &>/dev/null; then
    if [[ ! -f "$dest_file" ]]; then
      # Safe because _validate_install_dest rejects sed replacement metacharacters.
      local fresh
      fresh="$(_tmp_beside "$dest_file")"
      sed "s|\\\$HOME/.codex/hooks|$dest/hooks|g" "$src" > "$fresh"
      mv -f "$fresh" "$dest_file"
      echo "  ✓ Codex hooks active → $dest_file"
    else
      echo "  ⚠ jq required to merge AgenticOS hooks into existing $dest_file" >&2
    fi
    return 0
  fi

  local hooks_json
  hooks_json="$(_codex_hooks_json_for_dest "$src" "$dest/hooks")"

  if [[ -f "$dest_file" ]]; then
    # Preserve unrelated Codex hooks; replace only AgenticOS-marked groups, so
    # the merge is idempotent without owning the user's whole hooks object.
    local out
    out="$(_tmp_beside "$dest_file")"
    if ! jq --arg mode merge --argjson incoming "$hooks_json" "$_CODEX_HOOKS_JQ" \
        "$dest_file" > "$out"; then
      rm -f "$out"
      echo "Error: failed to merge AgenticOS hooks into $dest_file (is it valid JSON?)." >&2
      return 1
    fi
    mv -f "$out" "$dest_file"
  else
    local fresh
    fresh="$(_tmp_beside "$dest_file")"
    jq -n --argjson h "$hooks_json" '{hooks: $h}' > "$fresh"
    mv -f "$fresh" "$dest_file"
  fi
  echo "  ✓ Codex hooks active → $dest_file"
}

# Remove AgenticOS-marked groups from $1/hooks.json, printing each command
# removed. $2 = "true" for dry-run (report only).
unregister_codex_hook_settings() {
  local dest="$1" dry="${2:-false}"
  _validate_install_dest "$dest"
  local dest_file="$dest/hooks.json" prefix="  - "
  [[ "$dry" == "true" ]] && prefix="  [dry-run] "
  _refuse_link "$dest_file" || return 1
  if [[ ! -f "$dest_file" ]]; then
    echo "  · no $dest_file — no hook entries to unregister"
    return 0
  fi
  # Fail closed: removing hook files while they stay registered would make
  # every hook invocation error.
  if ! command -v jq &>/dev/null; then
    echo "Error: jq is required to unregister AgenticOS hooks from $dest_file — install jq, or remove its AgenticOS: groups by hand first. Nothing was removed." >&2
    return 1
  fi
  local out
  out="$(_unregister_tmp "$dest_file" "$dry")"
  if ! jq --arg mode uninstall --argjson incoming '{}' "$_CODEX_HOOKS_JQ" \
      "$dest_file" > "$out"; then
    rm -f "$out"
    echo "Error: failed to unregister AgenticOS hooks from $dest_file (is it valid JSON?)." >&2
    return 1
  fi
  _report_removed_hook_commands "$dest_file" "$out" "$prefix"
  if [[ "$dry" == "true" ]]; then rm -f "$out"; else mv "$out" "$dest_file"; fi
}

# ── Claude ─────────────────────────────────────────────────────────────────────

# Rewrite Claude template commands: $HOME/.claude/hooks → $hooks_dir (install DEST).
# Requires jq. Returns JSON object for the hooks key only.
_claude_hooks_json_for_dest() {
  local src="$1" hooks_dir="$2"
  jq --arg hd "$hooks_dir" '
    walk(
      if type == "object" and has("command") then
        .command |= gsub("\\$HOME/.claude/hooks"; $hd)
      else . end
    ) | .hooks
  ' "$src"
}

# A handler is AgenticOS-owned only when its whole command (trimmed, runs of `/`
# collapsed) EQUALS an owned command: a template command, or `bash <hooks
# dir>/<name>` for a RETIRED hook. Each is recognised in the literal
# `$HOME/.claude/hooks/...` form older no-jq installs copied verbatim, and with
# the hooks dir substituted (canonical DEST, or DEST as given, which older
# installs wrote). Compound/piped commands that merely contain our path are the
# consumer's and are kept. Only groups (and events) emptied by stripping are
# dropped, so a consumer's own empty entries survive.
#   merge:     retired handlers are stripped from every event; in each event we
#              ship, template handlers are stripped and our groups appended.
#              Events we don't ship and other top-level keys are untouched;
#              re-running is byte-identical.
#   uninstall: template + retired handlers are stripped from every event.
# A non-object `hooks`, or (merge) a non-array value for an event we ship, fails
# closed.
_CLAUDE_HOOKS_JQ='
  def norm: sub("^\\s+"; "") | sub("\\s+$"; "") | gsub("/+"; "/");
  def forms: ., gsub("\\$HOME/\\.claude/hooks"; $canon), gsub("\\$HOME/\\.claude/hooks"; $given);
  def owned_in($set): (type == "string") and (norm as $c | $set | index([$c]) != null);
  def strip($set):
    map(if (.hooks | type) == "array" and any(.hooks[]; .command? | owned_in($set))
        then (.hooks |= map(select((.command? | owned_in($set)) | not)))
          | select((.hooks | length) > 0)
        else . end);
  def strip_events($set): reduce keys_unsorted[] as $e (.;
    if (.[$e] | type) == "array" and (.[$e] | length) > 0
    then (.[$e] | strip($set)) as $s
      | if ($s | length) == 0 then del(.[$e]) else .[$e] = $s end
    else . end);
  ([$tpl[0] | .. | objects | select(has("command")) | .command | strings | forms | norm] | unique) as $tplset
  | ([$retired[] | "bash $HOME/.claude/hooks/" + . | forms | norm] | unique) as $retset
  | if (.hooks != null and (.hooks | type) != "object")
    then error("hooks is not an object") else . end
  | if $mode == "merge" then
      ((.hooks // {}) | strip_events($retset)) as $existing
      | .hooks = reduce ($incoming | keys_unsorted[]) as $event ($existing;
          if ((.[$event] // []) | type) != "array"
          then error("hooks.\($event) is not an array") else . end
          | .[$event] = (((.[$event] // []) | strip($tplset)) + $incoming[$event]))
    elif .hooks == null then .
    else (.hooks | strip_events($tplset + $retset)) as $h
      | if ($h | length) == 0 and (.hooks | length) > 0 then del(.hooks) else .hooks = $h end
    end
'

# $3 = space-separated retired hook basenames (optional). $4 = "check": only
# verify an existing settings.json would merge (writes and creates nothing).
merge_claude_hook_settings() {
  local repo_root="$1" dest="$2" retired="${3:-}" mode="${4:-}"
  _validate_install_dest "$dest"
  local src="$repo_root/assets/consumer/claude-settings.json"
  [[ -f "$src" ]] || return 0
  _refuse_link "$dest/settings.json" || return 1
  if [[ "$mode" == "check" ]]; then
    if [[ ! -f "$dest/settings.json" ]] || ! command -v jq &>/dev/null; then return 0; fi
    local cdest probe
    cdest="$(cd "$dest" && pwd -P)"
    probe="$(mktemp)"
    if ! jq --arg mode merge --argjson incoming "$(_claude_hooks_json_for_dest "$src" "$cdest/hooks")" \
        --slurpfile tpl "$src" --argjson retired "$(_retired_hooks_json "$retired")" \
        --arg canon "$cdest/hooks" --arg given "${dest%/}/hooks" \
        "$_CLAUDE_HOOKS_JQ" "$cdest/settings.json" > "$probe" 2>/dev/null; then
      rm -f "$probe"
      echo "Error: $cdest/settings.json cannot be merged (needs valid JSON with an object \"hooks\") — fix it first. Nothing was changed." >&2
      return 1
    fi
    rm -f "$probe"
    return 0
  fi

  # Canonicalise DEST (trailing slashes, `..`, symlinks) so `CLAUDE_DIR=~/.claude/`
  # and `~/.claude` produce identical commands and never double-register.
  # `pwd -P`, not realpath: stock macOS lacks a portable realpath.
  local given="$dest"
  mkdir -p "$dest"
  dest="$(cd "$dest" && pwd -P)"
  local dest_file="$dest/settings.json"

  if ! command -v jq &>/dev/null; then
    if [[ ! -f "$dest_file" && "$dest" == "$(cd "$HOME" && pwd -P)/.claude" ]]; then
      local fresh
      fresh="$(_tmp_beside "$dest_file")"
      cp "$src" "$fresh"
      mv -f "$fresh" "$dest_file"
      echo "  ✓ hooks active → $dest_file"
    else
      echo "  ⚠ jq required to install hook registration (custom CLAUDE_DIR needs jq)" >&2
    fi
    return 0
  fi

  local hooks_json retired_json
  hooks_json="$(_claude_hooks_json_for_dest "$src" "$dest/hooks")"
  retired_json="$(_retired_hooks_json "$retired")"

  if [[ -f "$dest_file" ]]; then
    local out
    out="$(_tmp_beside "$dest_file")"
    if ! jq --arg mode merge --argjson incoming "$hooks_json" --slurpfile tpl "$src" \
        --argjson retired "$retired_json" \
        --arg canon "$dest/hooks" --arg given "${given%/}/hooks" \
        "$_CLAUDE_HOOKS_JQ" "$dest_file" > "$out"; then
      rm -f "$out"
      echo "Error: failed to merge AgenticOS hooks into $dest_file (needs valid JSON with an object \"hooks\")." >&2
      return 1
    fi
    mv -f "$out" "$dest_file"
  else
    local fresh
    fresh="$(_tmp_beside "$dest_file")"
    jq -n --argjson h "$hooks_json" '{hooks: $h}' > "$fresh"
    mv -f "$fresh" "$dest_file"
  fi
  echo "  ✓ hooks active → $dest_file"
}

# Remove AgenticOS-owned handlers (template + retired) from $2/settings.json,
# printing each command removed. $4 = "true" for dry-run (report only).
unregister_claude_hook_settings() {
  local repo_root="$1" dest="$2" retired="${3:-}" dry="${4:-false}"
  _validate_install_dest "$dest"
  local src="$repo_root/assets/consumer/claude-settings.json" prefix="  - "
  [[ "$dry" == "true" ]] && prefix="  [dry-run] "
  [[ -d "$dest" ]] || return 0
  local given="$dest"
  dest="$(cd "$dest" && pwd -P)"
  local dest_file="$dest/settings.json"
  _refuse_link "$dest_file" || return 1
  if [[ ! -f "$dest_file" ]]; then
    echo "  · no $dest_file — no hook entries to unregister"
    return 0
  fi
  # Fail closed: removing hook files while they stay registered would make
  # every hook invocation error (and an `onFailure: block` hook deny the tool).
  if ! command -v jq &>/dev/null; then
    echo "Error: jq is required to unregister AgenticOS hooks from $dest_file — install jq, or remove its AgenticOS entries by hand first. Nothing was removed." >&2
    return 1
  fi
  local retired_json
  retired_json="$(_retired_hooks_json "$retired")"
  local out
  out="$(_unregister_tmp "$dest_file" "$dry")"
  if ! jq --arg mode uninstall --argjson incoming '{}' --slurpfile tpl "$src" \
      --argjson retired "$retired_json" \
      --arg canon "$dest/hooks" --arg given "${given%/}/hooks" \
      "$_CLAUDE_HOOKS_JQ" "$dest_file" > "$out"; then
    rm -f "$out"
    echo "Error: failed to unregister AgenticOS hooks from $dest_file (needs valid JSON with an object \"hooks\")." >&2
    return 1
  fi
  _report_removed_hook_commands "$dest_file" "$out" "$prefix"
  if [[ "$dry" == "true" ]]; then rm -f "$out"; else mv "$out" "$dest_file"; fi
}

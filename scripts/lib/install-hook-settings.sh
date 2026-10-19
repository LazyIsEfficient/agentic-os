# install-hook-settings.sh — merge consumer hook registration into global config.
# Sourced by install.sh (not executed directly).

_validate_install_dest() {
  local dest="$1"
  if [[ ! "$dest" =~ ^[/.a-zA-Z0-9._\ -]+$ ]]; then
    echo "Error: unsafe install DEST (reject shell metacharacters in path): $dest" >&2
    exit 1
  fi
}

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

merge_codex_hook_settings() {
  local repo_root="$1" dest="$2"
  _validate_install_dest "$dest"
  local src="$repo_root/assets/consumer/codex-hooks.json"
  local dest_file="$dest/hooks.json"
  [[ -f "$src" ]] || return 0
  mkdir -p "$dest"

  if ! command -v jq &>/dev/null; then
    if [[ ! -f "$dest_file" ]]; then
      # Safe because _validate_install_dest rejects sed replacement metacharacters.
      sed "s|\\\$HOME/.codex/hooks|$dest/hooks|g" "$src" > "$dest_file"
      echo "  ✓ Codex hooks active → $dest_file"
    else
      echo "  ⚠ jq required to merge AgenticOS hooks into existing $dest_file" >&2
    fi
    return 0
  fi

  local hooks_json
  hooks_json="$(_codex_hooks_json_for_dest "$src" "$dest/hooks")"

  if [[ -f "$dest_file" ]]; then
    # Preserve unrelated Codex hooks. Reinstall replaces only matcher groups
    # whose handlers carry the AgenticOS status marker, making the merge
    # idempotent without taking ownership of the user's entire hooks object.
    if ! jq --argjson incoming "$hooks_json" '
      def agenticos_group:
        any(.hooks[]?; ((.statusMessage? // "") | startswith("AgenticOS:")));
      .hooks = reduce ($incoming | keys_unsorted[]) as $event
        (.hooks // {};
          .[$event] = (
            ((.[$event] // []) | map(select((agenticos_group | not))))
            + $incoming[$event]
          )
        )
    ' "$dest_file" > "$dest_file.tmp"; then
      rm -f "$dest_file.tmp"
      echo "Error: failed to merge AgenticOS hooks into $dest_file (is it valid JSON?)." >&2
      return 1
    fi
    mv "$dest_file.tmp" "$dest_file"
  else
    jq -n --argjson h "$hooks_json" '{hooks: $h}' > "$dest_file"
  fi
  echo "  ✓ Codex hooks active → $dest_file"
}

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

merge_claude_hook_settings() {
  local repo_root="$1" dest="$2"
  _validate_install_dest "$dest"
  local src="$repo_root/assets/consumer/claude-settings.json"
  local dest_file="$dest/settings.json"
  [[ -f "$src" ]] || return 0

  if ! command -v jq &>/dev/null; then
    if [[ ! -f "$dest_file" && "$dest" == "${HOME}/.claude" ]]; then
      cp "$src" "$dest_file"
      echo "  ✓ hooks active → $dest_file"
    else
      echo "  ⚠ jq required to install hook registration (custom CLAUDE_DIR needs jq)" >&2
    fi
    return 0
  fi

  local hooks_json
  hooks_json="$(_claude_hooks_json_for_dest "$src" "$dest/hooks")"

  if [[ -f "$dest_file" ]]; then
    # Merge per event; never take ownership of the consumer's hooks object.
    # A hook handler is AgenticOS-owned when its command references one of the
    # scripts our template registers, under either the install hooks dir or the
    # literal `$HOME/.claude/hooks` (what older no-jq installs copied verbatim).
    # Owned handlers are stripped from EVERY event, groups left empty by that
    # are dropped, then our groups are appended. Consumer handlers — including
    # ones they added inside a group we created — are kept in place, other
    # top-level keys are untouched, and re-running is byte-identical.
    local owned_names
    owned_names="$(jq -c '
      [.. | objects | select(has("command")) | .command
        | capture("\\$HOME/\\.claude/hooks/(?<n>[^/\\s\"'"'"']+)") | .n] | unique
    ' "$src")"
    if ! jq --argjson incoming "$hooks_json" --argjson names "$owned_names" \
        --arg hd "$dest/hooks/" '
      def owned_cmd:
        . as $c
        | any($names[] as $n | ("$HOME/.claude/hooks/", $hd) | . + $n;
            . as $p
            | any($c | indices($p)[];
                ($c[. - 1:.] | IN("", " ", "\"", "'"'"'"))
                and ($c[(. + ($p | length)):(. + ($p | length) + 1)]
                     | IN("", " ", "\"", "'"'"'", ";"))));
      def strip_owned:
        map(if (.hooks | type) == "array"
            then .hooks |= map(select(((.command? // "") | owned_cmd) | not))
            else . end)
        | map(select((.hooks | type) != "array" or (.hooks | length) > 0));
      (.hooks // {}) as $existing
      | .hooks = (
          reduce ($existing | keys_unsorted[]) as $event ({};
            ($existing[$event]) as $groups
            | if ($groups | type) != "array" then .[$event] = $groups
              else ($groups | strip_owned) as $kept
                | if ($kept | length) == 0 and ($groups | length) > 0
                     and ($incoming | has($event) | not)
                  then . else .[$event] = $kept end
              end)
          | reduce ($incoming | keys_unsorted[]) as $event (.;
              .[$event] = ((.[$event] // []) + $incoming[$event]))
        )
    ' "$dest_file" > "$dest_file.tmp"; then
      rm -f "$dest_file.tmp"
      echo "Error: failed to merge AgenticOS hooks into $dest_file (is it valid JSON?)." >&2
      return 1
    fi
    mv "$dest_file.tmp" "$dest_file"
  else
    jq -n --argjson h "$hooks_json" '{hooks: $h}' > "$dest_file"
  fi
  echo "  ✓ hooks active → $dest_file"
}

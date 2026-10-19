# shellcheck shell=bash
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
  [[ -f "$src" ]] || return 0

  # Canonicalise DEST (trailing slashes, `..`, symlinks) so `CLAUDE_DIR=~/.claude/`
  # and `~/.claude` produce identical commands and never double-register.
  # `pwd -P`, not realpath: stock macOS lacks a portable realpath.
  local given="$dest"
  mkdir -p "$dest"
  dest="$(cd "$dest" && pwd -P)"
  local dest_file="$dest/settings.json"

  if ! command -v jq &>/dev/null; then
    if [[ ! -f "$dest_file" && "$dest" == "$(cd "$HOME" && pwd -P)/.claude" ]]; then
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
    # A handler is AgenticOS-owned only when its whole command (trimmed, runs of
    # `/` collapsed) EQUALS a template command: in the literal
    # `$HOME/.claude/hooks/...` form older no-jq installs copied verbatim, or
    # with the hooks dir substituted (canonical DEST, or DEST as given, which
    # older installs wrote). Compound/piped commands that merely contain our
    # path are the consumer's and are kept. In each event we ship, owned
    # handlers are stripped, groups left empty by that are dropped, then our
    # groups are appended. Events we don't ship and other top-level keys are
    # untouched; re-running is byte-identical.
    # A non-object `hooks`, or a non-array value for an event we ship, fails
    # closed. `cp -p` first so the rewrite keeps the file's mode (settings.json
    # may hold `env` secrets at 0600).
    cp -p "$dest_file" "$dest_file.tmp"
    if ! jq --argjson incoming "$hooks_json" --slurpfile tpl "$src" \
        --arg canon "$dest/hooks" --arg given "${given%/}/hooks" '
      def norm: sub("^\\s+"; "") | sub("\\s+$"; "") | gsub("/+"; "/");
      ([$tpl[0] | .. | objects | select(has("command")) | .command | strings]
        | map(., gsub("\\$HOME/\\.claude/hooks"; $canon),
                 gsub("\\$HOME/\\.claude/hooks"; $given))
        | map(norm) | unique) as $owned
      | def owned_cmd: (type == "string") and (norm as $c | $owned | index([$c]) != null);
      def strip_owned:
        map(if (.hooks | type) == "array"
            then .hooks |= map(select((.command? | owned_cmd) | not))
            else . end)
        | map(select((.hooks | type) != "array" or (.hooks | length) > 0));
      if (.hooks != null and (.hooks | type) != "object")
      then error("hooks is not an object") else . end
      | (.hooks // {}) as $existing
      | .hooks = reduce ($incoming | keys_unsorted[]) as $event ($existing;
          if ((.[$event] // []) | type) != "array"
          then error("hooks.\($event) is not an array") else . end
          | .[$event] = (((.[$event] // []) | strip_owned) + $incoming[$event]))
    ' "$dest_file" > "$dest_file.tmp"; then
      rm -f "$dest_file.tmp"
      echo "Error: failed to merge AgenticOS hooks into $dest_file (needs valid JSON with an object \"hooks\")." >&2
      return 1
    fi
    mv "$dest_file.tmp" "$dest_file"
  else
    jq -n --argjson h "$hooks_json" '{hooks: $h}' > "$dest_file"
  fi
  echo "  ✓ hooks active → $dest_file"
}

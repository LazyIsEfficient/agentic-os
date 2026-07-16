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
    # Replace the ENTIRE hooks key (own it outright), preserving every other
    # top-level key. `.hooks = $h` — NOT `. * {hooks:$h}`: the recursive-merge
    # form would deep-merge, leaving stale consumer hook events behind and
    # diverging from install.ps1 (Add-Member -Force) and SECURITY.md, which
    # promise re-install replaces the whole hooks object.
    jq --argjson h "$hooks_json" '.hooks = $h' "$dest_file" > "$dest_file.tmp" \
      && mv "$dest_file.tmp" "$dest_file"
  else
    jq -n --argjson h "$hooks_json" '{hooks: $h}' > "$dest_file"
  fi
  echo "  ✓ hooks active → $dest_file"
}

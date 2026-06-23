# install-hook-settings.sh — merge consumer hook registration into global config.
# Sourced by install.sh / install-cursor.sh (not executed directly).

_validate_install_dest() {
  local dest="$1"
  if [[ ! "$dest" =~ ^[/.a-zA-Z0-9._-]+$ ]]; then
    echo "Error: unsafe install DEST (reject shell metacharacters in path): $dest" >&2
    exit 1
  fi
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
    jq --argjson h "$hooks_json" '. * {hooks: $h}' "$dest_file" > "$dest_file.tmp" \
      && mv "$dest_file.tmp" "$dest_file"
  else
    jq -n --argjson h "$hooks_json" '{hooks: $h}' > "$dest_file"
  fi
  echo "  ✓ hooks active → $dest_file"
}

merge_cursor_hook_settings() {
  local repo_root="$1" dest="$2"
  _validate_install_dest "$dest"
  local src="$repo_root/assets/consumer/cursor-hooks.json"
  local dest_file="$dest/hooks.json"
  [[ -f "$src" ]] || return 0

  if command -v jq &>/dev/null; then
    if [[ -f "$dest_file" ]]; then
      jq -s '.[0] * {version: .[1].version, hooks: .[1].hooks}' \
        "$dest_file" "$src" > "$dest_file.tmp" && mv "$dest_file.tmp" "$dest_file"
    else
      cp "$src" "$dest_file"
    fi
  elif [[ ! -f "$dest_file" ]]; then
    cp "$src" "$dest_file"
  else
    echo "  ⚠ $dest_file exists — install jq to activate hooks, or delete it and re-run install" >&2
    return 0
  fi
  echo "  ✓ hooks active → $dest_file"
}

# install-hook-settings.sh — merge consumer hook registration into global config.
# Sourced by install.sh (not executed directly).

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

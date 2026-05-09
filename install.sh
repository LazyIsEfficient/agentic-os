#!/usr/bin/env bash
set -euo pipefail

REPO_OWNER="${SKILLS_DIRECTORY_REPO_OWNER:-YieldGuildGames}"
REPO_NAME="${SKILLS_DIRECTORY_REPO_NAME:-skills-directory}"
REPO_REF="${SKILLS_DIRECTORY_REF:-main}"
GITHUB_TOKEN="${agent_github_token:-${AGENT_GITHUB_TOKEN:-}}"

usage() {
  cat <<'USAGE'
Install skills from YieldGuildGames/skills-directory.

Usage:
  ./install.sh [target ...]
  curl -fsSL -H "Authorization: Bearer ${agent_github_token}" https://raw.githubusercontent.com/YieldGuildGames/skills-directory/main/install.sh | agent_github_token="${agent_github_token}" bash -s -- [target ...]

Targets:
  claude       Install to ./.claude/skills
  cloud        Alias for claude
  cursor       Install to ./.cursor/skills
  codex        Install to ./.codex/skills
  all          Install to claude, cursor, and codex

Compatibility flags:
  --claude, --cloud, --cursor, --codex, --both

Examples:
  ./install.sh
  ./install.sh cursor codex
  ./install.sh all

Default target:
  claude

Private repository authentication:
  Set agent_github_token or AGENT_GITHUB_TOKEN to a GitHub token with read access.
USAGE
}

script_path="${BASH_SOURCE[0]:-}"
script_dir="$(pwd)"
local_source_available=0

if [[ -n "$script_path" && -f "$script_path" ]]; then
  script_dir="$(cd "$(dirname "$script_path")" && pwd)"
  local_source_available=1
fi

project_dir="$(pwd)"
source_root=""
source_dir=""
tmp_dir=""

cleanup() {
  if [[ -n "$tmp_dir" && -d "$tmp_dir" ]]; then
    rm -rf "$tmp_dir"
  fi
}
trap cleanup EXIT

add_target() {
  local target="$1"

  case "$target" in
    claude|--claude|cloud|--cloud)
      targets="$targets claude"
      ;;
    cursor|--cursor)
      targets="$targets cursor"
      ;;
    codex|--codex)
      targets="$targets codex"
      ;;
    all|--all)
      targets="$targets claude cursor codex"
      ;;
    both|--both)
      targets="$targets claude cursor"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown target: $target" >&2
      usage >&2
      exit 2
      ;;
  esac
}

prepare_source() {
  if [[ "$local_source_available" -eq 1 && -d "$script_dir/.claude/skills" ]]; then
    source_root="$script_dir"
    source_dir="$script_dir/.claude/skills"
    return
  fi

  tmp_dir="$(mktemp -d)"
  local archive="$tmp_dir/source.tar.gz"
  local url

  if [[ -n "$GITHUB_TOKEN" ]]; then
    url="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/tarball/$REPO_REF"
  else
    url="https://github.com/$REPO_OWNER/$REPO_NAME/archive/refs/heads/$REPO_REF.tar.gz"
  fi

  echo "downloading skills from $url"
  if [[ -n "$GITHUB_TOKEN" ]]; then
    curl -fsSL \
      -H "Authorization: Bearer $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github+json" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "$url" \
      -o "$archive"
  else
    curl -fsSL "$url" -o "$archive"
  fi

  tar -xzf "$archive" -C "$tmp_dir"

  for extracted_path in "$tmp_dir"/*; do
    if [[ -d "$extracted_path" ]]; then
      source_root="$extracted_path"
      break
    fi
  done

  if [[ -z "$source_root" ]]; then
    echo "error: downloaded archive did not extract a repository directory" >&2
    exit 1
  fi

  source_dir="$source_root/.claude/skills"

  if [[ ! -d "$source_dir" ]]; then
    echo "error: downloaded archive does not contain .claude/skills" >&2
    exit 1
  fi
}

install_to() {
  local target_name="$1"
  local target_dir="$2"
  local count=0

  mkdir -p "$target_dir"

  local source_real
  local target_real
  source_real="$(cd "$source_dir" && pwd -P)"
  target_real="$(cd "$target_dir" && pwd -P)"

  if [[ "$source_real" == "$target_real" ]]; then
    echo "source and target are the same for $target_name -> $target_dir"
    return
  fi

  while IFS= read -r -d '' skill_dir; do
    local skill_name
    skill_name="$(basename "$skill_dir")"

    if [[ ! -f "$skill_dir/SKILL.md" ]]; then
      echo "skip: $skill_name has no SKILL.md" >&2
      continue
    fi

    rm -rf "$target_dir/$skill_name"
    cp -R "$skill_dir" "$target_dir/$skill_name"
    count=$((count + 1))
  done < <(find "$source_dir" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)

  echo "installed $count skills for $target_name -> $target_dir"
}

install_instruction_file() {
  local source_file="$1"
  local target_file="$2"
  local label="$3"

  if [[ ! -f "$source_file" ]]; then
    echo "skip: $label instruction file not found at $source_file" >&2
    return
  fi

  if [[ -f "$target_file" ]] && cmp -s "$source_file" "$target_file"; then
    echo "$label instruction file already current -> $target_file"
    return
  fi

  cp "$source_file" "$target_file"
  echo "installed $label instruction file -> $target_file"
}

targets=""
if [[ $# -eq 0 ]]; then
  targets="claude"
else
  while [[ $# -gt 0 ]]; do
    add_target "$1"
    shift
  done
fi

unique_targets=""
for target in $targets; do
  already_added=0
  for existing in $unique_targets; do
    if [[ "$existing" == "$target" ]]; then
      already_added=1
      break
    fi
  done
  if [[ "$already_added" -eq 0 ]]; then
    unique_targets="$unique_targets $target"
  fi
done

prepare_source

for target in $unique_targets; do
  case "$target" in
    claude)
      install_to "claude" "$project_dir/.claude/skills"
      install_instruction_file "$source_root/CLAUDE.md" "$project_dir/CLAUDE.md" "claude"
      ;;
    cursor)
      install_to "cursor" "$project_dir/.cursor/skills"
      ;;
    codex)
      install_to "codex" "$project_dir/.codex/skills"
      install_instruction_file "$source_root/AGENTS.md" "$project_dir/AGENTS.md" "codex"
      ;;
  esac
done

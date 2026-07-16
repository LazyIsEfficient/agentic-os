#!/usr/bin/env bash
# install-codex-smoke-test.sh — Codex user/project install, conversion, and merge.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

fail() { echo "FAIL install-codex-smoke: $*" >&2; exit 1; }

home="$tmp/home"
config="$home/.codex"
skills="$home/.agents/skills"
mkdir -p "$home"

HOME="$home" CODEX_HOME="$config" CODEX_SKILLS_DIR="$skills" \
  bash "$REPO/install.sh" --codex >/dev/null

want_skills="$(find "$REPO/.claude/skills" -name SKILL.md -type f | wc -l | tr -d ' ')"
got_skills="$(find "$skills" -name SKILL.md -type f | wc -l | tr -d ' ')"
[[ "$got_skills" == "$want_skills" ]] || fail "skill count got=$got_skills want=$want_skills"

want_agents="$(find "$REPO/.claude/agents" -maxdepth 1 -name '*.md' -type f | wc -l | tr -d ' ')"
got_agents="$(find "$config/agents" -maxdepth 1 -name '*.toml' -type f | wc -l | tr -d ' ')"
[[ "$got_agents" == "$want_agents" ]] || fail "agent count got=$got_agents want=$want_agents"
grep -q "^name = 'engineer'$" "$config/agents/engineer.toml" || fail "engineer TOML missing name"
grep -q "^developer_instructions = '''$" "$config/agents/engineer.toml" || fail "engineer TOML missing instructions"
grep -qF "(<$skills/browser-testing-with-devtools/SKILL.md>)" "$config/agents/engineer.toml" || fail "skill links not converted"
grep -q "^sandbox_mode = 'workspace-write'$" "$config/agents/engineer.toml" || fail "writer sandbox not converted"
grep -q "^sandbox_mode = 'read-only'$" "$config/agents/code-reviewer.toml" || fail "reviewer sandbox not converted"

[[ -x "$config/hooks/session-state-inject.sh" ]] || fail "SessionStart hook missing or not executable"
[[ -x "$config/hooks/session-state-checkpoint.sh" ]] || fail "PreCompact hook missing or not executable"
[[ ! -e "$config/hooks/memory-extract.sh" ]] || fail "Claude memory hook should not install for Codex"
[[ ! -d "$home/.claude" ]] || fail "Codex install polluted Claude home"

# When Codex is available locally, make it load the generated configuration.
if command -v codex &>/dev/null; then
  CODEX_HOME="$config" codex debug prompt-input 'config smoke test' >/dev/null 2>&1 \
    || fail "Codex rejected generated config/agents"
fi

if command -v jq &>/dev/null; then
  jq -e '.hooks.SessionStart | length == 1' "$config/hooks.json" >/dev/null || fail "SessionStart registration missing"
  jq -e '.hooks.PreCompact | length == 1' "$config/hooks.json" >/dev/null || fail "PreCompact registration missing"
  jq -e --arg p "$config/hooks/session-state-inject.sh" \
    '.hooks.SessionStart[0].hooks[0].command | contains($p)' "$config/hooks.json" >/dev/null || fail "hook path not rewritten"

  jq '.hooks.Stop = [{"hooks":[{"type":"command","command":"bash /tmp/user-stop.sh"}]}]' \
    "$config/hooks.json" > "$config/hooks.json.tmp"
  mv "$config/hooks.json.tmp" "$config/hooks.json"
  HOME="$home" CODEX_HOME="$config" CODEX_SKILLS_DIR="$skills" \
    bash "$REPO/install.sh" --codex >/dev/null
  jq -e '.hooks.Stop[0].hooks[0].command == "bash /tmp/user-stop.sh"' "$config/hooks.json" >/dev/null || fail "unrelated hook was not preserved"
  jq -e '.hooks.SessionStart | length == 1' "$config/hooks.json" >/dev/null || fail "Codex hook merge is not idempotent"
fi

marker="$skills/autoresearch/SKILL.md"
printf '\nlocal-customization\n' >> "$marker"
HOME="$home" CODEX_HOME="$config" CODEX_SKILLS_DIR="$skills" \
  bash "$REPO/install.sh" --codex >/dev/null
grep -q 'local-customization' "$marker" || fail "default reinstall overwrote customization"
HOME="$home" CODEX_HOME="$config" CODEX_SKILLS_DIR="$skills" \
  bash "$REPO/install.sh" --codex --force >/dev/null
! grep -q 'local-customization' "$marker" || fail "--force did not refresh skill"

project="$tmp/project with spaces"
mkdir -p "$project"
HOME="$home" CODEX_PROJECT_DIR="$project" bash "$REPO/install.sh" --codex --project >/dev/null
[[ -f "$project/.agents/skills/autoresearch/SKILL.md" ]] || fail "project skill install missing"
[[ -f "$project/.codex/agents/engineer.toml" ]] || fail "project agent install missing"
[[ -f "$project/.codex/hooks.json" ]] || fail "project hook registration missing"
if command -v jq &>/dev/null; then
  jq -e --arg p "$project/.codex/hooks/session-state-inject.sh" \
    '.hooks.SessionStart[0].hooks[0].command | contains($p)' "$project/.codex/hooks.json" >/dev/null \
    || fail "project hook path with spaces was not preserved"
fi

if HOME="$home" bash "$REPO/install.sh" --project >/dev/null 2>&1; then
  fail "--project without --codex should fail"
fi
if HOME="$home" CODEX_HOME='/tmp/evil;whoami' bash "$REPO/install.sh" --codex >/dev/null 2>&1; then
  fail "unsafe CODEX_HOME should fail"
fi
if HOME="$home" bash "$REPO/install.sh" --not-a-real-option >/dev/null 2>&1; then
  fail "unknown option should fail"
fi

echo "install-codex-smoke-test: OK"

#!/usr/bin/env bash
# session-state-test.sh — deterministic test of the SESSION-STATE mechanism:
# the writer (.claude/skills/session-state/scripts/session-state.sh) and the three
# hooks. The temp dir mirrors the SHIPPED layout (skill-local writer + assets) so
# the script-relative template resolution is exercised exactly as a consumer hits
# it. No live Claude
# needed (the platform-invocation contract is proven by eval/spikes/s0-*). Runs
# everything in a temp dir via CLAUDE_PROJECT_DIR so it never touches the repo's
# own SESSION-STATE.md.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/.." && pwd)"

T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
SKILL_SRC="$REPO/.claude/skills/session-state"
SKILL="$T/.claude/skills/session-state"
mkdir -p "$T/.claude/hooks" "$SKILL/scripts" "$SKILL/assets"
cp "$SKILL_SRC/assets/SESSION-STATE.template.md" "$SKILL/assets/"
cp "$SKILL_SRC/scripts/session-state.sh" "$SKILL/scripts/"
cp "$REPO/.claude/hooks/session-state-inject.sh" "$T/.claude/hooks/"
cp "$REPO/.claude/hooks/session-state-digest.sh" "$T/.claude/hooks/"
cp "$REPO/.claude/hooks/session-state-checkpoint.sh" "$T/.claude/hooks/"

export CLAUDE_PROJECT_DIR="$T"
SS="$SKILL/scripts/session-state.sh"
P=0; F=0
ok(){ printf 'PASS  %s\n' "$1"; P=$((P+1)); }
no(){ printf 'FAIL  %s — %s\n' "$1" "$2"; F=$((F+1)); }
has(){ printf '%s' "$2" | grep -q -- "$3" && ok "$1" || no "$1" "got: $2"; }
hasnt(){ printf '%s' "$2" | grep -q -- "$3" && no "$1" "unexpected: $3" || ok "$1"; }

bash "$SS" init >/dev/null
[ -f "$T/SESSION-STATE.md" ] && ok "init creates live doc from template" || no "init" "no file"

orch="$(mktemp -d)"
mkdir -p "$orch/.claude/skills/session-state/scripts" "$orch/.claude/skills/session-state/assets"
cp "$SKILL_SRC/scripts/session-state.sh" "$orch/.claude/skills/session-state/scripts/"
cp "$SKILL_SRC/assets/SESSION-STATE.template.md" "$orch/.claude/skills/session-state/assets/"
export CLAUDE_PROJECT_DIR="$orch"
bash "$orch/.claude/skills/session-state/scripts/session-state.sh" init-orchestrator >/dev/null
orch_live="$(cat "$orch/SESSION-STATE.md")"
has "init-orchestrator adds dispatch constraint" "$orch_live" "dispatch Task(engineer"
has "init-orchestrator adds reviewer constraint" "$orch_live" "Task(code-reviewer)"
bash "$orch/.claude/skills/session-state/scripts/session-state.sh" init-orchestrator 2>&1 | grep -q "already present" \
  && ok "init-orchestrator is idempotent" || no "init-orchestrator idempotent" "second run did not short-circuit"
rm -rf "$orch"
export CLAUDE_PROJECT_DIR="$T"

# Fallback resolution: with NO CLAUDE_PROJECT_DIR (a consumer invoking the writer
# directly), ROOT must resolve four-up from the script to the project root, AND the
# template must still be found script-relative. Run in a fresh tree so it can't
# alias the main $T live doc.
fb="$(mktemp -d)"
mkdir -p "$fb/.claude/skills/session-state/scripts" "$fb/.claude/skills/session-state/assets"
cp "$SKILL_SRC/scripts/session-state.sh"             "$fb/.claude/skills/session-state/scripts/"
cp "$SKILL_SRC/assets/SESSION-STATE.template.md"     "$fb/.claude/skills/session-state/assets/"
env -u CLAUDE_PROJECT_DIR bash "$fb/.claude/skills/session-state/scripts/session-state.sh" init >/dev/null 2>&1
[ -f "$fb/SESSION-STATE.md" ] \
  && ok "init resolves project root via four-up fallback (no CLAUDE_PROJECT_DIR)" \
  || no "fallback init" "live doc not created at four-up project root"
rm -rf "$fb"

bash "$SS" constraint "No Python — Rust only" >/dev/null
bash "$SS" decision "Awareness via deterministic hooks" >/dev/null
bash "$SS" infra "RabbitMQ broker already running on :5552" >/dev/null
bash "$SS" thread "Confirm PreCompact live-fire" >/dev/null

live="$(cat "$T/SESSION-STATE.md")"
has "constraint recorded under its section" "$live" "No Python — Rust only"
has "decision is date-stamped" "$live" "$(printf '\\[%s\\]' "$(date +%F)")"
has "infra finding recorded" "$live" "broker already running on :5552"

# Inject hook (SessionStart) — emits the WHOLE doc
inj="$(bash "$T/.claude/hooks/session-state-inject.sh" < /dev/null)"
has "inject emits constraint" "$inj" "No Python — Rust only"
has "inject emits infra" "$inj" "broker already running on :5552"

# Digest hook (UserPromptSubmit) — Constraints + Decisions + Open threads
dig="$(printf '%s' '{"hook_event_name":"UserPromptSubmit"}' | bash "$T/.claude/hooks/session-state-digest.sh")"
has "digest includes constraint" "$dig" "No Python — Rust only"
has "digest includes decision" "$dig" "Awareness via deterministic hooks"
has "digest includes open thread" "$dig" "Confirm PreCompact live-fire"
hasnt "digest EXCLUDES infra (token discipline)" "$dig" "RabbitMQ broker already running"

# Digest on a FRESH (unedited) template injects nothing (placeholders skipped)
fresh="$(mktemp -d)"; cp "$SKILL_SRC/assets/SESSION-STATE.template.md" "$fresh/SESSION-STATE.md"
empty="$(CLAUDE_PROJECT_DIR="$fresh" bash "$T/.claude/hooks/session-state-digest.sh" </dev/null)"
[ -z "$empty" ] && ok "digest is empty on uninitialized template (no placeholder noise)" || no "empty digest" "got: $empty"
rm -rf "$fresh"

# Checkpoint hook (PreCompact) — writes a marker to the gitignored log
printf '%s' '{"hook_event_name":"PreCompact","trigger":"manual"}' | bash "$T/.claude/hooks/session-state-checkpoint.sh"
[ -s "$T/.claude/session-state.checkpoints" ] && ok "checkpoint writes marker" || no "checkpoint" "no log"
has "checkpoint records trigger" "$(cat "$T/.claude/session-state.checkpoints")" "trigger=manual"

# Regression (code-review Tier 1): mixed-case trigger value must be captured,
# not dropped by a lowercase-only regex.
printf '%s' '{"hook_event_name":"PreCompact","trigger":"Manual"}' | bash "$T/.claude/hooks/session-state-checkpoint.sh"
has "checkpoint captures mixed-case trigger" "$(cat "$T/.claude/session-state.checkpoints")" "trigger=Manual"

# Regression (code-review Tier 1): entry text with backslashes must be stored
# verbatim (awk -v processes escapes; ENVIRON does not).
bash "$SS" constraint 'Windows path C:\Users\dev stays literal' >/dev/null
if grep -qF 'C:\Users\dev' "$T/SESSION-STATE.md"; then
  ok "backslashes in entry text preserved verbatim"
else
  no "backslash preservation" "got: $(grep -i windows "$T/SESSION-STATE.md")"
fi

# drop: prune a stale bullet by substring; leaves other bullets intact.
bash "$SS" thread "TEMP-DROP-ME stale thread" >/dev/null
bash "$SS" drop "TEMP-DROP-ME" >/dev/null
dropped="$(cat "$T/SESSION-STATE.md")"
hasnt "drop removes the matching bullet" "$dropped" "TEMP-DROP-ME"
has "drop leaves other bullets intact" "$dropped" "Confirm PreCompact live-fire"

echo "session-state-test: $P passed, $F failed."
[ "$F" -eq 0 ]

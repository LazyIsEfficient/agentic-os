#!/usr/bin/env bash
# run-release-arms.sh — run scenarios under NAMED arms, each built from its own
# git ref (e.g. a release tag vs main), N samples per arm, and write one
# samples.jsonl row per sample plus a deterministic per-arm summary.
#
# A sibling of run-arms.sh, not a mode of it: run-arms.sh is the fixed ON/OFF
# pair from HEAD with one prompt and a compare; this script has N arms from N
# refs, multi-prompt scenarios, repeats, per-sample scoring and a cost gate.
# Both share the isolation helpers in lib/arm-isolation.sh.
#
# ISOLATION (same model as run-arms.sh): every sample gets its own `mktemp -d`
# root with its own HOME and CLAUDE_CONFIG_DIR and an allowlisted environment.
# Each arm's library is installed by THAT ref's own install.sh, from a
# `git archive <ref>` export (never the working tree), into the sample's temp
# config only; the Tier 0 preflight checks the config holds exactly what that
# ref's installer ships with the arm's flags. Every sample passes preflight
# before any prompt is sent; results go to <out>/isolation.jsonl.
#
# TASKS come from a `git archive HEAD` export of this repo, identical for every
# arm:
#   scenarios/<name>.md         task dir = scrubbed export of HEAD (repo-local)
#   scenarios/<name>/README.md  task dir = scenarios/<name>/app, committed once
#                               as the task base; if exploit-check.mjs exists it
#                               runs after each sample, then security-scan.sh
# A scenario's prompts are the bare ``` fences under "## Scripted prompt
# sequence" (lib/scenario-prompts.mjs). Prompt 1 starts the session
# (--session-id); later prompts continue it (--resume, same session id).
#
# COST: one `claude -p` invocation per prompt, per arm, per run:
#   invocations = arms x runs x (sum of each scenario's prompt count)
# The plan and the count are printed, then --yes or an interactive `y` is
# required before anything is set up or sent.
#
# AUTH: export ANTHROPIC_API_KEY (or CLAUDE_CODE_OAUTH_TOKEN); it is passed to
# the child env only. Samples are STOCHASTIC; read the distribution.
#
# Usage:
#   run-release-arms.sh [options] --scenario NAME [--scenario NAME]... ARM...
#   ARM = NAME=REF[:FLAG[,FLAG]...]   e.g. v301=v3.0.1  main=main
#                                          mainall=main:--with-marketing,--with-games
#   --scenario NAME     repeatable; see TASKS above
#   --runs N            samples per arm per scenario (default 1), interleaved
#   --max-turns N       passed to every `claude -p` (print mode only; the
#                       invocation exits non-zero when the limit is reached)
#   --max-budget-usd X  passed to every `claude -p`: a per-invocation cap on
#                       Claude Code's client-side cost estimate (default 5;
#                       spend can pass it). The cost gate prints the ceiling.
#   --no-max-budget     pass no --max-budget-usd at all
#   --yes               do not ask for confirmation
#   --keep              keep the per-sample temp roots (they hold transcripts)
#   --out DIR           output dir (default: runs/<stamp>-release-arms)
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$DIR/../.." && pwd)"
# shellcheck source=lib/arm-isolation.sh
source "$DIR/lib/arm-isolation.sh"

die() { echo "run-release-arms: $*" >&2; exit 1; }
usage() { sed -n '/^# Usage:/,/^set -uo/p' "${BASH_SOURCE[0]}" | sed '$d; s/^# \{0,1\}//' >&2; exit 2; }

DEFAULT_MAX_BUDGET_USD=5
KEEP=0; YES=0; RUNS=1; OUT=""; MAX_TURNS=""; MAX_BUDGET="$DEFAULT_MAX_BUDGET_USD"
SCENARIOS=(); SPECS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --keep) KEEP=1; shift ;;
    --yes) YES=1; shift ;;
    --out) OUT="${2:?--out needs a directory}"; shift 2 ;;
    --runs) RUNS="${2:?--runs needs a number}"; shift 2 ;;
    --scenario) SCENARIOS+=("${2:?--scenario needs a name}"); shift 2 ;;
    --max-turns) MAX_TURNS="${2:?--max-turns needs a number}"; shift 2 ;;
    --max-budget-usd) MAX_BUDGET="${2:?--max-budget-usd needs an amount}"; shift 2 ;;
    --no-max-budget) MAX_BUDGET=""; shift ;;
    -h|--help) usage ;;
    --) shift; while [ $# -gt 0 ]; do SPECS+=("$1"); shift; done ;;
    -*) echo "unknown option: $1" >&2; exit 2 ;;
    *) SPECS+=("$1"); shift ;;
  esac
done
case "$RUNS" in ''|*[!0-9]*|0*) die "--runs must be a positive integer" ;; esac
if [ -n "$MAX_TURNS" ]; then
  case "$MAX_TURNS" in *[!0-9]*|0*) die "--max-turns must be a positive integer" ;; esac
fi
if [ -n "$MAX_BUDGET" ] && ! printf '%s' "$MAX_BUDGET" | grep -Eq '^[0-9]+(\.[0-9]+)?$'; then
  die "--max-budget-usd must be a number"
fi
[ "${#SPECS[@]}" -gt 0 ] || { echo "no arms given" >&2; usage; }
[ "${#SCENARIOS[@]}" -gt 0 ] || { echo "no --scenario given" >&2; usage; }

command -v claude >/dev/null 2>&1 || die "claude CLI not found"
command -v node   >/dev/null 2>&1 || die "node not found"
command -v jq     >/dev/null 2>&1 || die "jq not found (install.sh needs it to register hooks)"
command -v git    >/dev/null 2>&1 || die "git not found"
AUTH_VAR="$(iso_auth_var)" || { iso_auth_help; exit 1; }

gen_id() { node -e 'console.log(crypto.randomUUID())'; }
RUN_ID="$(gen_id)"
HARNESS_SHA="$(git -C "$REPO" rev-parse --short HEAD 2>/dev/null || echo unknown)"
HARNESS_DIRTY="$(iso_harness_dirty "$REPO")"
GIT_DIR_PATH="$(dirname "$(command -v git)")"

# Arm roots (kept with --keep) and harness-private scratch (always removed).
ROOTS=(); SCRATCH=()
cleanup() {
  local r
  for r in ${SCRATCH[@]+"${SCRATCH[@]}"}; do [ -n "$r" ] && rm -rf "$r"; done
  for r in ${ROOTS[@]+"${ROOTS[@]}"}; do
    [ -n "$r" ] || continue
    if [ "$KEEP" = 1 ]; then [ -e "$r" ] && echo "kept sample root: $r"; else rm -rf "$r"; fi
  done
}
trap cleanup EXIT
# new_scratch <label>: sets SCRATCH_LAST. Not echoed: SCRATCH+= inside a
# $(...) subshell would be lost and the dir never cleaned up.
new_scratch() {
  SCRATCH_LAST="$(mktemp -d "${TMPDIR:-/tmp}/run-release-arms-$1.XXXXXX")" || die "mktemp failed"
  SCRATCH+=("$SCRATCH_LAST")
}

# ---- arms: NAME=REF[:FLAGS], each exported from its own ref ------------------
ARM_NAME=(); ARM_REF=(); ARM_SHA=(); ARM_FLAGS=(); ARM_PACKS=(); ARM_SRC=()
for spec in "${SPECS[@]}"; do
  case "$spec" in *=*) ;; *) die "arm spec must be NAME=REF[:FLAGS]: $spec" ;; esac
  name="${spec%%=*}"; rest="${spec#*=}"
  ref="${rest%%:*}"; flags=""
  case "$rest" in *:*) flags="${rest#*:}" ;; esac
  printf '%s' "$name" | grep -Eq '^[a-z0-9][a-z0-9_-]*$' || die "arm name must match [a-z0-9][a-z0-9_-]*: $name"
  for n in ${ARM_NAME[@]+"${ARM_NAME[@]}"}; do [ "$n" != "$name" ] || die "duplicate arm name: $name"; done
  case "$ref" in ''|-*) die "bad ref in arm $name: '$ref'" ;; esac
  sha="$(git -C "$REPO" rev-parse --verify --quiet "$ref^{commit}")" || die "ref does not resolve in $REPO: $ref (arm $name; fetch it first)"
  packs=""
  if [ -n "$flags" ]; then
    IFS=',' read -r -a fl <<< "$flags"
    for f in ${fl[@]+"${fl[@]}"}; do
      printf '%s' "$f" | grep -Eq '^--with-[a-z0-9-]+$' \
        || die "arm $name: only --with-<pack> install flags are supported (got '$f'); the preflight must know exactly what is installed"
      packs="$packs${packs:+ }${f#--with-}"
    done
  fi
  new_scratch src; src="$SCRATCH_LAST"
  iso_export_ref "$REPO" "$sha" "$src" || die "git archive of $ref failed (arm $name)"
  [ -f "$src/install.sh" ] || die "ref $ref has no install.sh (arm $name)"
  for p in $packs; do
    [ -f "$src/assets/packs/$p.txt" ] || die "arm $name: ref $ref has no pack '$p' (assets/packs/$p.txt)"
  done
  ARM_NAME+=("$name"); ARM_REF+=("$ref"); ARM_SHA+=("$sha"); ARM_FLAGS+=("$flags")
  ARM_PACKS+=("$packs"); ARM_SRC+=("$src")
done
NARMS="${#ARM_NAME[@]}"

# ---- scenarios: from a HEAD export, identical for every arm ------------------
if [ -n "$(git -C "$REPO" status --porcelain 2>/dev/null)" ]; then
  echo "note: working tree is dirty; tasks and scenarios use committed HEAD ($HARNESS_SHA) only." >&2
fi
new_scratch task-src; TASK_SRC="$SCRATCH_LAST"
iso_export_src "$REPO" "$TASK_SRC" || die "export of HEAD failed"
new_scratch prompts; PROMPTS_DIR="$SCRATCH_LAST"
new_scratch checks; CHECKS_DIR="$SCRATCH_LAST"
SCN_NAME=(); SCN_KIND=(); SCN_N=(); SCN_CHECK=()
TOTAL_PROMPTS=0
for j in "${!SCENARIOS[@]}"; do
  s="${SCENARIOS[$j]}"
  printf '%s' "$s" | grep -Eq '^[a-z0-9][a-z0-9_-]*$' || die "scenario name must match [a-z0-9][a-z0-9_-]*: $s"
  base="$TASK_SRC/eval/metrics/scenarios"
  check=""
  if [ -f "$base/$s.md" ]; then
    kind=repo; doc="$base/$s.md"
  elif [ -f "$base/$s/README.md" ] && [ -d "$base/$s/app" ]; then
    kind=app; doc="$base/$s/README.md"
    if [ -f "$base/$s/exploit-check.mjs" ]; then
      # Harness-private copies from HEAD: the check, the pristine app (the
      # scan repo's base) and, once, the scanner itself.
      mkdir -p "$CHECKS_DIR/$s/base"
      cp "$base/$s/exploit-check.mjs" "$CHECKS_DIR/$s/"
      cp -R "$base/$s/app/." "$CHECKS_DIR/$s/base/"
      check="$CHECKS_DIR/$s/exploit-check.mjs"
      if [ ! -d "$CHECKS_DIR/scanner" ]; then
        mkdir -p "$CHECKS_DIR/scanner/scripts" "$CHECKS_DIR/scanner/.claude/skills/security"
        cp "$TASK_SRC/scripts/security-scan.sh" "$CHECKS_DIR/scanner/scripts/" || die "HEAD has no scripts/security-scan.sh"
        cp -R "$TASK_SRC/.claude/skills/security/scripts" "$CHECKS_DIR/scanner/.claude/skills/security/" \
          || die "HEAD has no .claude/skills/security/scripts"
      fi
    fi
  else
    die "scenario not found in HEAD: $s (scenarios/$s.md or scenarios/$s/README.md + app/)"
  fi
  mkdir -p "$PROMPTS_DIR/$j"
  node "$DIR/lib/scenario-prompts.mjs" "$doc" > "$PROMPTS_DIR/$j/all.json" || die "cannot read prompts of $s"
  n="$(node -e 'const a=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"));a.forEach((p,i)=>require("fs").writeFileSync(process.argv[2]+"/"+(i+1)+".txt",p));console.log(a.length)' \
    "$PROMPTS_DIR/$j/all.json" "$PROMPTS_DIR/$j")" || die "cannot split prompts of $s"
  SCN_NAME+=("$s"); SCN_KIND+=("$kind"); SCN_N+=("$n"); SCN_CHECK+=("$check")
  TOTAL_PROMPTS=$((TOTAL_PROMPTS + n))
done
TOTAL=$((NARMS * RUNS * TOTAL_PROMPTS))

# ---- cost gate ----------------------------------------------------------------
echo "run-release-arms plan (harness $HARNESS_SHA, tasks from HEAD):"
for i in "${!ARM_NAME[@]}"; do
  echo "  arm ${ARM_NAME[$i]}: ${ARM_REF[$i]} @ ${ARM_SHA[$i]}${ARM_FLAGS[$i]:+  install flags: ${ARM_FLAGS[$i]}}"
done
for j in "${!SCN_NAME[@]}"; do
  echo "  scenario ${SCN_NAME[$j]}: ${SCN_N[$j]} prompt(s)${SCN_CHECK[$j]:+, exploit check + security-scan}"
done
echo "  runs per arm per scenario: $RUNS${MAX_TURNS:+   --max-turns $MAX_TURNS}"
echo "TOTAL: $TOTAL claude -p invocations ($NARMS arms x $RUNS runs x $TOTAL_PROMPTS prompts across ${#SCN_NAME[@]} scenario(s)), billed to $AUTH_VAR."
if [ -n "$MAX_BUDGET" ]; then
  echo "BUDGET: --max-budget-usd $MAX_BUDGET per invocation; ceiling if every invocation hit it: \$$(awk -v n="$TOTAL" -v b="$MAX_BUDGET" 'BEGIN { printf "%.2f", n * b }') (Claude Code's client-side estimate; spend can pass the cap)."
else
  echo "BUDGET: no per-invocation cap (--no-max-budget)."
fi
if [ "$YES" != 1 ]; then
  if [ -t 0 ]; then
    printf 'Proceed? [y/N] '
    read -r ans || ans=""
    case "$ans" in y|Y|yes|YES) ;; *) echo "aborted; nothing was sent to claude."; exit 1 ;; esac
  else
    die "refusing to start $TOTAL invocations without --yes (stdin is not a terminal); nothing was sent to claude"
  fi
fi

OUT="${OUT:-$DIR/runs/$(date -u +%Y%m%dT%H%M%SZ)-release-arms}"
mkdir -p "$OUT"
LEDGER="$OUT/isolation.jsonl"
SAMPLES="$OUT/samples.jsonl"
: > "$SAMPLES"

# task_git <root> <args...>: git in a sample's task dir with no operator config.
task_git() {
  local root="$1"; shift
  env -i HOME="$root/home" XDG_CONFIG_HOME="$root/home/.config" GIT_CONFIG_NOSYSTEM=1 \
    PATH="$GIT_DIR_PATH:$ISO_SYSTEM_PATH" git -C "$root/task" "$@"
}

# Scanners and the scan repo's git get a scrubbed PATH: the system dirs plus
# the dirs of the tools the scan uses, resolved from the operator PATH.
SCAN_PATH="$ISO_SYSTEM_PATH"
for b in git jq node semgrep gitleaks osv-scanner; do
  d="$(command -v "$b" 2>/dev/null)" || continue
  d="$(dirname "$d")"
  case ":$SCAN_PATH:" in *":$d:"*) ;; *) SCAN_PATH="$SCAN_PATH:$d" ;; esac
done

# scan_git <dir> <args...>: git in a harness-created repo, with no system,
# global or hook/fsmonitor config.
scan_git() {
  local dir="$1"; shift
  env -i HOME="$root/scan-home" PATH="$SCAN_PATH" GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null \
    git -C "$dir" -c core.hooksPath=/dev/null -c core.fsmonitor= "$@"
}

# build_scan_repo <root> <pristine base dir>: never run git in the task dir,
# whose .git/config the model controls. A fresh repo holds the pristine app as
# its base commit, then the task's files (minus every .git; links copied as
# links, never followed) as the working tree. Prints the base sha.
build_scan_repo() {
  local root="$1" pristine="$2" repo="$1/scan-repo"
  [ -n "$root" ] || return 1
  rm -rf "$repo"; mkdir -p "$repo" "$root/scan-home" || return 1
  cp -R "$pristine/." "$repo/" || return 1
  scan_git "$repo" init -q || return 1
  scan_git "$repo" add -A || return 1
  scan_git "$repo" -c user.name=eval -c user.email=eval@example.invalid commit -q -m "task base" || return 1
  find "$repo" -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} + || return 1
  ( cd "$root/task" && tar -cf - --exclude=.git . ) | ( cd "$repo" && tar -xf - ) || return 1
  scan_git "$repo" rev-parse HEAD
}

# ---- set up every sample, interleaved: run r, scenario j, arms rotated by r ----
S_ROOT=(); S_ARM=(); S_SCN=(); S_RUN=(); S_SID=(); S_BASE=()
for r in $(seq 1 "$RUNS"); do
  for j in "${!SCN_NAME[@]}"; do
    for o in $(seq 0 $((NARMS - 1))); do
      i=$(( (o + r - 1) % NARMS ))
      tag="${ARM_NAME[$i]}-${SCN_NAME[$j]}-r$r"
      root="$(iso_make_root)" || die "mktemp failed"
      ROOTS+=("$root")
      if [ "${SCN_KIND[$j]}" = repo ]; then
        iso_export_task "$TASK_SRC" "$root/task" || die "task export failed ($tag)"
      else
        iso_export_task "$TASK_SRC/eval/metrics/scenarios/${SCN_NAME[$j]}/app" "$root/task" || die "task copy failed ($tag)"
      fi
      fl=()
      [ -z "${ARM_FLAGS[$i]}" ] || IFS=',' read -r -a fl <<< "${ARM_FLAGS[$i]}"
      iso_install_library "${ARM_SRC[$i]}" "$root" "$OUT/install-$tag.log" ${fl[@]+"${fl[@]}"} \
        || die "install.sh of ${ARM_REF[$i]} into the $tag temp config failed; see $OUT/install-$tag.log"
      base=""
      if [ "${SCN_KIND[$j]}" = app ]; then
        task_git "$root" init -q || die "git init of the $tag task failed"
        task_git "$root" add -A || die "git add of the $tag task failed"
        task_git "$root" -c user.name=eval -c user.email=eval@example.invalid commit -q -m "task base" \
          || die "task base commit failed ($tag)"
        base="$(task_git "$root" rev-parse HEAD)" || die "task base sha failed ($tag)"
      fi
      sid="$(gen_id)"
      ok=0
      iso_preflight on "$root" "${ARM_SRC[$i]}" "${ARM_PACKS[$i]}" || ok=1
      iso_record "$LEDGER" "${ARM_NAME[$i]}" "$sid" "$RUN_ID" "${ARM_SHA[$i]}" "$AUTH_VAR" "$HARNESS_DIRTY"
      if [ "$ok" != 0 ]; then
        echo "PREFLIGHT FAILED ($tag) — aborting; nothing was sent to claude:" >&2
        for f in "${ISO_FAILS[@]}"; do echo "  - $f" >&2; done
        exit 1
      fi
      S_ROOT+=("$root"); S_ARM+=("$i"); S_SCN+=("$j"); S_RUN+=("$r"); S_SID+=("$sid"); S_BASE+=("$base")
    done
  done
done
# The pristine exports hold the full libraries; drop them before any sample runs.
for d in "${ARM_SRC[@]}" "$TASK_SRC"; do [ -n "$d" ] && rm -rf "$d"; done
echo "all ${#S_ROOT[@]} sample roots passed preflight: $LEDGER"

CLAUDE_OPTS=(--dangerously-skip-permissions)
[ -z "$MAX_TURNS" ] || CLAUDE_OPTS+=(--max-turns "$MAX_TURNS")
[ -z "$MAX_BUDGET" ] || CLAUDE_OPTS+=(--max-budget-usd "$MAX_BUDGET")

# ---- run + score each sample ---------------------------------------------------
for k in "${!S_ROOT[@]}"; do
  root="${S_ROOT[$k]}"; i="${S_ARM[$k]}"; j="${S_SCN[$k]}"; r="${S_RUN[$k]}"; sid="${S_SID[$k]}"
  tag="${ARM_NAME[$i]}-${SCN_NAME[$j]}-r$r"
  log="$OUT/claude-$tag.log"
  : > "$log"
  echo "[$((k + 1))/${#S_ROOT[@]}] $tag (${SCN_N[$j]} prompt(s)) …"
  codes=""
  for n in $(seq 1 "${SCN_N[$j]}"); do
    prompt="$(cat "$PROMPTS_DIR/$j/$n.txt")"
    if [ "$n" = 1 ]; then session=(--session-id "$sid"); else session=(--resume "$sid"); fi
    echo "--- prompt $n ---" >> "$log"
    iso_exec "$root" "$AUTH_VAR" -- claude -p "$prompt" "${session[@]}" "${CLAUDE_OPTS[@]}" >>"$log" 2>&1
    rc=$?
    codes="$codes${codes:+ }$rc"
    # A failed prompt ends the sample: resuming past it would score a
    # different conversation. The row records it as incomplete.
    if [ "$rc" != 0 ]; then
      echo "  (prompt $n of ${SCN_N[$j]} exited $rc; sample stopped, incomplete; see $log)"
      break
    fi
  done

  tx="$(ls "$root"/home/.claude/projects/*/"$sid".jsonl 2>/dev/null | head -1)"
  mjson="$root/metrics.json"; rm -f "$mjson"
  if [ -n "$tx" ] && [ -f "$tx" ]; then
    node "$DIR/session-metrics.mjs" "$tx" --json > "$mjson" 2>/dev/null || rm -f "$mjson"
  else
    echo "  (no transcript for session $sid)"
  fi

  xjson=""; xrc=""; sjson=""; src_rc=""
  if [ -n "${SCN_CHECK[$j]}" ]; then
    mkdir -p "$root/scan-home"
    xjson="$root/exploit.json"
    env -i PATH="$(iso_child_path)" HOME="$root/scan-home" TMPDIR="$root/tmp" \
      node "${SCN_CHECK[$j]}" "$root/task" --json > "$xjson" 2>"$OUT/exploit-$tag.err"
    xrc=$?
    sjson="$root/scan.json"
    if scan_base="$(build_scan_repo "$root" "$CHECKS_DIR/${SCN_NAME[$j]}/base" 2>"$OUT/scan-$tag.err")"; then
      ( cd "$root/scan-repo" || exit 2
        env -i PATH="$SCAN_PATH" HOME="$root/scan-home" TMPDIR="$root/tmp" \
          GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null \
          XDG_CONFIG_HOME="$root/scan-home/.config" XDG_CACHE_HOME="$root/scan-home/.cache" \
          SECURITY_SCAN_OFFLINE=1 bash "$CHECKS_DIR/scanner/scripts/security-scan.sh" --base "$scan_base" --json
      ) > "$sjson" 2>>"$OUT/scan-$tag.err"
      src_rc=$?
    else
      src_rc=2; : > "$sjson"
    fi
    echo "  exploit: $(jq -r '.exploit // "error"' "$xjson" 2>/dev/null || echo error)  security-scan exit: $src_rc"
  fi

  RUN_ID="$RUN_ID" HARNESS_SHA="$HARNESS_SHA" HARNESS_DIRTY="$HARNESS_DIRTY" \
  ARM="${ARM_NAME[$i]}" REF="${ARM_REF[$i]}" FLAGS="${ARM_FLAGS[$i]}" REPO_SHA="${ARM_SHA[$i]}" \
  SCENARIO="${SCN_NAME[$j]}" PROMPTS="${SCN_N[$j]}" SAMPLE="$r" ORDER="$k" SID="$sid" \
  EXIT_CODES="$codes" TRANSCRIPT="$tx" METRICS_JSON="$mjson" TASK_BASE="${S_BASE[$k]}" \
  EXPLOIT_JSON="$xjson" EXPLOIT_RC="$xrc" SCAN_JSON="$sjson" SCAN_RC="$src_rc" \
    node "$DIR/lib/sample-row.mjs" >> "$SAMPLES" || die "could not write the sample row for $tag"
done

node "$DIR/summarize-samples.mjs" "$SAMPLES" --json > "$OUT/summary.json" || die "summary failed"
echo ""
node "$DIR/summarize-samples.mjs" "$SAMPLES"
echo ""
echo "samples: $SAMPLES"
echo "summary: $OUT/summary.json"
echo "NOTE: stochastic samples. Compare distributions (min/max), not one mean; see README.md \"Release arms\"."

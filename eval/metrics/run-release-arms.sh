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
# ISOLATION: every sample gets its own `mktemp -d` root with its own HOME and
# CLAUDE_CONFIG_DIR. Each arm's library is installed by THAT ref's own
# install.sh, from a `git archive <ref>` export (never the working tree), into
# the sample's temp config only; the Tier 0 preflight checks the config holds
# exactly what that ref's installer ships with the arm's flags. Every sample
# passes preflight before any prompt is sent (<out>/isolation.jsonl).
#
# SANDBOX (--sandbox docker, the default; the model runs with
# --dangerously-skip-permissions):
#   - one container PER SAMPLE, on an internal network, with no host mount: the
#     prepared root is copied into a fresh per-sample volume, mounted at the
#     same absolute path so the installed hook paths stay valid. Prompts are
#     sent one `docker exec` at a time from the host, so the model cannot
#     rewrite later prompts. Nothing of one sample is visible to another.
#   - its only route out is a per-sample proxy container (lib/api-proxy.mjs)
#     that allows only the API paths and injects the real ANTHROPIC_API_KEY;
#     the sample gets a placeholder key and never sees the real one.
#   - scoring runs in a FRESH container per sample (network none) whose code
#     is baked into the image from the HEAD export; it reads the sample volume
#     read-only, as data (task tree + transcript), and runs the app under test
#     as a separate uid. The host copies out only the transcript, logs and the
#     score, every log redacted (lib/redact.mjs).
# --sandbox none runs everything on the host: NO containment, for tests with a
# stub claude only.
#
# TASKS come from a `git archive HEAD` export of this repo, identical for every
# arm:
#   scenarios/<name>.md         task dir = scrubbed export of HEAD (repo-local)
#   scenarios/<name>/README.md  task dir = scenarios/<name>/app, committed once
#                               as the task base; if exploit-check.mjs exists it
#                               runs after each sample, then security-scan.sh
# A scenario's prompts are the bare ``` fences under "## Scripted prompt
# sequence" (lib/scenario-prompts.mjs). Prompt 1 starts the session
# (--session-id); later prompts continue it (--resume, same session id). A
# prompt that exits non-zero ends its sample (row status "incomplete").
#
# COST: one `claude -p` invocation per prompt, per arm, per run:
#   invocations = arms x runs x (sum of each scenario's prompt count)
# The plan, the count and the budget ceiling are printed, then --yes or an
# interactive `y` is required before anything is built, set up or sent.
#
# AUTH: export ANTHROPIC_API_KEY (docker sandbox: a Console API key only;
# use a dedicated workspace key with a spend limit and revoke it afterwards).
# --sandbox none also accepts CLAUDE_CODE_OAUTH_TOKEN. The value is never
# written; every log in <out> is redacted. Samples are STOCHASTIC.
#
# Usage:
#   run-release-arms.sh [options] --scenario NAME [--scenario NAME]... ARM...
#   ARM = NAME=REF[:FLAG[,FLAG]...]   e.g. v301=v3.0.1  main=main
#                                          mainall=main:--with-marketing,--with-games
#   --scenario NAME     repeatable; see TASKS above
#   --runs N            samples per arm per scenario (default 1), interleaved
#   --max-turns N       passed to every `claude -p` (print mode only)
#   --max-budget-usd X  passed to every `claude -p`: a per-invocation cap on
#                       Claude Code's client-side cost estimate (default 5;
#                       spend can pass it). The cost gate prints the ceiling.
#   --no-max-budget     pass no --max-budget-usd at all
#   --yes               do not ask for confirmation
#   --out DIR           output dir, outside the repo (default:
#                       $HOME/agentic-os-eval-runs/<stamp>-release-arms)
#   --sandbox MODE      docker (default) | none (host, no containment; tests)
#   --image TAG         docker: image tag (default: derived from the build context)
#   --keep              none: keep the per-sample temp roots
#   test hooks (docker): --stub-claude FILE   put FILE first on the sample's PATH as `claude`
#                        --proxy-upstream echo  the proxy answers locally, no network
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$DIR/../.." && pwd -P)"
# shellcheck source=lib/arm-isolation.sh
source "$DIR/lib/arm-isolation.sh"

die() { echo "run-release-arms: $*" >&2; exit 1; }
usage() { sed -n '/^# Usage:/,/^set -uo/p' "${BASH_SOURCE[0]}" | sed '$d; s/^# \{0,1\}//' >&2; exit 2; }

DEFAULT_MAX_BUDGET_USD=5
KEEP=0; YES=0; RUNS=1; OUT=""; MAX_TURNS=""; MAX_BUDGET="$DEFAULT_MAX_BUDGET_USD"
SANDBOX=docker; IMAGE=""; STUB_CLAUDE=""; PROXY_UPSTREAM="https://api.anthropic.com"
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
    --sandbox) SANDBOX="${2:?--sandbox needs docker or none}"; shift 2 ;;
    --image) IMAGE="${2:?--image needs a tag}"; shift 2 ;;
    --stub-claude) STUB_CLAUDE="${2:?--stub-claude needs a file}"; shift 2 ;;
    --proxy-upstream) PROXY_UPSTREAM="${2:?--proxy-upstream needs a value}"; shift 2 ;;
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
case "$SANDBOX" in docker|none) ;; *) die "--sandbox must be docker or none" ;; esac
case "$PROXY_UPSTREAM" in echo|https://api.anthropic.com) ;; *) die "--proxy-upstream must be echo (test hook)" ;; esac
if [ "$SANDBOX" = none ] && { [ -n "$STUB_CLAUDE" ] || [ -n "$IMAGE" ] || [ "$PROXY_UPSTREAM" = echo ]; }; then
  die "--stub-claude / --image / --proxy-upstream apply to --sandbox docker only"
fi
if [ -n "$STUB_CLAUDE" ]; then [ -f "$STUB_CLAUDE" ] || die "--stub-claude: no such file: $STUB_CLAUDE"; fi
[ "${#SPECS[@]}" -gt 0 ] || { echo "no arms given" >&2; usage; }
[ "${#SCENARIOS[@]}" -gt 0 ] || { echo "no --scenario given" >&2; usage; }

command -v node >/dev/null 2>&1 || die "node not found"
command -v jq   >/dev/null 2>&1 || die "jq not found (install.sh needs it to register hooks)"
command -v git  >/dev/null 2>&1 || die "git not found"
if [ "$SANDBOX" = none ]; then
  command -v claude >/dev/null 2>&1 || die "claude CLI not found"
  AUTH_VAR="$(iso_auth_var)" || { iso_auth_help; exit 1; }
else
  command -v docker >/dev/null 2>&1 || die "docker not found (or use --sandbox none, which has NO containment)"
  docker info >/dev/null 2>&1 || die "docker daemon not reachable"
  [ -n "${ANTHROPIC_API_KEY:-}" ] || die "the docker sandbox needs ANTHROPIC_API_KEY (a Console key; the proxy injects it, so OAuth tokens are not supported)"
  AUTH_VAR=ANTHROPIC_API_KEY
fi

# ---- output dir: never inside the repo (the model must not write into it) -----
# abs_path <path>: absolute physical path; the part that does not exist yet is
# appended as written ("..": refused).
abs_path() {
  local p="$1" tail=""
  case "$p" in /*) ;; *) p="$PWD/$p" ;; esac
  case "/$p/" in */../*|*/./*) return 1 ;; esac
  while [ ! -d "$p" ]; do tail="/$(basename "$p")$tail"; p="$(dirname "$p")"; done
  echo "$(cd "$p" && pwd -P)$tail"
}
OUT="${OUT:-$HOME/agentic-os-eval-runs/$(date -u +%Y%m%dT%H%M%SZ)-release-arms}"
OUT="$(abs_path "$OUT")" || die "--out must not contain . or .. segments"
case "$OUT/" in "$REPO/"*) die "--out must be outside the repo ($REPO): the model must not be able to plant files in it" ;; esac

gen_id() { node -e 'console.log(crypto.randomUUID())'; }
RUN_ID="$(gen_id)"
R8="${RUN_ID:0:8}"
HARNESS_SHA="$(git -C "$REPO" rev-parse --short HEAD 2>/dev/null || echo unknown)"
HARNESS_DIRTY="$(iso_harness_dirty "$REPO")"
GIT_DIR_PATH="$(dirname "$(command -v git)")"
redact() { node "$DIR/lib/redact.mjs"; }

# Arm roots (kept with --keep), harness-private scratch (always removed), and
# every docker object of this run (label aos-run=<run id>).
ROOTS=(); SCRATCH=(); DOCKER_USED=0
cleanup() {
  local r ids
  if [ "$DOCKER_USED" = 1 ]; then
    ids="$(docker ps -aq --filter "label=aos-run=$RUN_ID" 2>/dev/null)"
    # shellcheck disable=SC2086  # ids: whitespace-separated container ids
    [ -z "$ids" ] || docker rm -f $ids >/dev/null 2>&1
    ids="$(docker volume ls -q --filter "label=aos-run=$RUN_ID" 2>/dev/null)"
    # shellcheck disable=SC2086
    [ -z "$ids" ] || docker volume rm -f $ids >/dev/null 2>&1
    ids="$(docker network ls -q --filter "label=aos-run=$RUN_ID" 2>/dev/null)"
    # shellcheck disable=SC2086
    [ -z "$ids" ] || docker network rm $ids >/dev/null 2>&1
  fi
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

# ---- scenarios + scoring harness: from a HEAD export, identical for every arm --
if [ -n "$(git -C "$REPO" status --porcelain 2>/dev/null)" ]; then
  echo "note: working tree is dirty; tasks, scenarios and scoring code use committed HEAD ($HARNESS_SHA) only." >&2
fi
new_scratch task-src; TASK_SRC="$SCRATCH_LAST"
iso_export_src "$REPO" "$TASK_SRC" || die "export of HEAD failed"
new_scratch prompts; PROMPTS_DIR="$SCRATCH_LAST"
# HARNESS: the scoring code, staged from the HEAD export. Docker: baked into the
# image. None: used from this harness-private dir.
new_scratch harness; HARNESS="$SCRATCH_LAST"
mkdir -p "$HARNESS/lib" "$HARNESS/scenarios" "$HARNESS/scanner/scripts" "$HARNESS/scanner/.claude/skills/security"
cp "$TASK_SRC/eval/metrics/session-metrics.mjs" "$HARNESS/" || die "HEAD has no session-metrics.mjs"
for f in score-sample.mjs scan-task.sh api-proxy.mjs; do
  cp "$TASK_SRC/eval/metrics/lib/$f" "$HARNESS/lib/" || die "HEAD has no eval/metrics/lib/$f (commit the harness first)"
done
cp "$TASK_SRC/scripts/security-scan.sh" "$HARNESS/scanner/scripts/" || die "HEAD has no scripts/security-scan.sh"
cp -R "$TASK_SRC/.claude/skills/security/scripts" "$HARNESS/scanner/.claude/skills/security/" || die "HEAD has no security scanner"
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
      mkdir -p "$HARNESS/scenarios/$s/app"
      cp "$base/$s/exploit-check.mjs" "$HARNESS/scenarios/$s/"
      cp -R "$base/$s/app/." "$HARNESS/scenarios/$s/app/"
      check=yes
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
echo "run-release-arms plan (harness $HARNESS_SHA, tasks from HEAD, sandbox: $SANDBOX):"
for i in "${!ARM_NAME[@]}"; do
  echo "  arm ${ARM_NAME[$i]}: ${ARM_REF[$i]} @ ${ARM_SHA[$i]}${ARM_FLAGS[$i]:+  install flags: ${ARM_FLAGS[$i]}}"
done
for j in "${!SCN_NAME[@]}"; do
  echo "  scenario ${SCN_NAME[$j]}: ${SCN_N[$j]} prompt(s)${SCN_CHECK[$j]:+, exploit check + security-scan}"
done
echo "  runs per arm per scenario: $RUNS${MAX_TURNS:+   --max-turns $MAX_TURNS}"
echo "  output: $OUT"
echo "TOTAL: $TOTAL claude -p invocations ($NARMS arms x $RUNS runs x $TOTAL_PROMPTS prompts across ${#SCN_NAME[@]} scenario(s)), billed to $AUTH_VAR."
if [ -n "$MAX_BUDGET" ]; then
  echo "BUDGET: --max-budget-usd $MAX_BUDGET per invocation; ceiling if every invocation hit it: \$$(awk -v n="$TOTAL" -v b="$MAX_BUDGET" 'BEGIN { printf "%.2f", n * b }') (Claude Code's client-side estimate; spend can pass the cap)."
else
  echo "BUDGET: no per-invocation cap (--no-max-budget)."
fi
echo "KEY: use a dedicated Console workspace key with a spend limit for this run, and revoke it afterwards."
[ "$SANDBOX" = docker ] || echo "WARNING: --sandbox none: the model runs on this host with --dangerously-skip-permissions and NO containment. Use it with a stub claude only."
if [ "$YES" != 1 ]; then
  if [ -t 0 ]; then
    printf 'Proceed? [y/N] '
    read -r ans || ans=""
    case "$ans" in y|Y|yes|YES) ;; *) echo "aborted; nothing was sent to claude."; exit 1 ;; esac
  else
    die "refusing to start $TOTAL invocations without --yes (stdin is not a terminal); nothing was sent to claude"
  fi
fi

mkdir -p "$OUT/transcripts" || die "cannot create $OUT"
LEDGER="$OUT/isolation.jsonl"
SAMPLES="$OUT/samples.jsonl"
: > "$SAMPLES"

# ---- docker: image from the HEAD export, networks ------------------------------
if [ "$SANDBOX" = docker ]; then
  new_scratch ctx; CTX="$SCRATCH_LAST"
  cp "$TASK_SRC/eval/metrics/docker/Dockerfile" "$CTX/Dockerfile" || die "HEAD has no eval/metrics/docker/Dockerfile"
  cp -R "$HARNESS" "$CTX/harness"
  if [ -z "$IMAGE" ]; then IMAGE="agentic-os-eval:ctx-$(iso_listing_sha256 "$CTX" | cut -c1-16)"; fi
  if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
    echo "building $IMAGE (pinned tools; harness baked in from HEAD) …"
    docker build -q -t "$IMAGE" "$CTX" >/dev/null || die "docker build failed"
  fi
  DOCKER_USED=1
  NET_INT="aos-int-$R8"; NET_EGRESS="aos-egress-$R8"
  docker network create --internal --label "aos-run=$RUN_ID" "$NET_INT" >/dev/null || die "cannot create network $NET_INT"
  docker network create --label "aos-run=$RUN_ID" "$NET_EGRESS" >/dev/null || die "cannot create network $NET_EGRESS"
fi

# task_git <root> <args...>: git in a sample's task dir with no operator config
# (setup only, before the model has touched it).
task_git() {
  local root="$1"; shift
  env -i HOME="$root/home" XDG_CONFIG_HOME="$root/home/.config" GIT_CONFIG_NOSYSTEM=1 \
    PATH="$GIT_DIR_PATH:$ISO_SYSTEM_PATH" git -C "$root/task" "$@"
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
      case "$root" in *[!A-Za-z0-9/._-]*) die "temp root has characters docker --mount cannot take: $root" ;; esac
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

CLAUDE_OPTS=(--dangerously-skip-permissions --output-format json)
[ -z "$MAX_TURNS" ] || CLAUDE_OPTS+=(--max-turns "$MAX_TURNS")
[ -z "$MAX_BUDGET" ] || CLAUDE_OPTS+=(--max-budget-usd "$MAX_BUDGET")

# ---- docker sample lifecycle -----------------------------------------------------
DOCKER_HARDEN=(--cap-drop ALL --security-opt no-new-privileges --read-only)

# docker_start_sample <k>: volume (copy of the root), proxy, sample container.
docker_start_sample() {
  local k="$1" root="${S_ROOT[$1]}" vol="aos-$R8-$1" i
  docker volume create --label "aos-run=$RUN_ID" "$vol" >/dev/null || return 1
  if [ -n "$STUB_CLAUDE" ]; then mkdir -p "$root/.stub"; cp "$STUB_CLAUDE" "$root/.stub/claude"; chmod +x "$root/.stub/claude"; fi
  # Populate as root (CHOWN only), then hand the tree to uid 1000.
  ( cd "$root" && COPYFILE_DISABLE=1 tar --no-xattrs -cf - . ) | docker run --rm -i --label "aos-run=$RUN_ID" --network none --user 0:0 \
      --cap-drop ALL --cap-add CHOWN --cap-add DAC_OVERRIDE --cap-add FOWNER --security-opt no-new-privileges \
      --mount "type=volume,src=$vol,dst=$root" "$IMAGE" \
      sh -c 'tar -xf - -C "$1" --no-same-owner && chown -R 1000:1000 "$1"' sh "$root" || return 1
  docker run -d --name "aos-proxy-$R8-$k" --label "aos-run=$RUN_ID" --network "$NET_INT" --network-alias aos-api-proxy \
      --user 1000:1000 "${DOCKER_HARDEN[@]}" --pids-limit 64 \
      -e ANTHROPIC_API_KEY -e PROXY_UPSTREAM="$PROXY_UPSTREAM" "$IMAGE" node /opt/harness/lib/api-proxy.mjs >/dev/null || return 1
  docker network connect "$NET_EGRESS" "aos-proxy-$R8-$k" || return 1
  for i in $(seq 1 50); do
    docker logs "aos-proxy-$R8-$k" 2>/dev/null | grep -q '"listening"' && break
    sleep 0.2
  done
  docker run -d --name "aos-sample-$R8-$k" --label "aos-run=$RUN_ID" --network "$NET_INT" \
      --user 1000:1000 "${DOCKER_HARDEN[@]}" --tmpfs /tmp:rw,exec,size=2g --pids-limit 2048 --init \
      --mount "type=volume,src=$vol,dst=$root" -w "$root/task" "$IMAGE" sleep infinity >/dev/null || return 1
}

# docker_prompt <k> <claude args...>: one invocation in the sample container.
# The env is set explicitly: the real key never enters the sample.
docker_prompt() {
  local k="$1" root="${S_ROOT[$1]}" path="/usr/local/bin:/usr/bin:/bin"; shift
  [ -z "$STUB_CLAUDE" ] || path="$root/.stub:$path"
  docker exec -w "$root/task" "aos-sample-$R8-$k" env -i PATH="$path" LANG=C.UTF-8 \
    HOME="$root/home" CLAUDE_CONFIG_DIR="$root/home/.claude" TMPDIR="$root/tmp" \
    XDG_CONFIG_HOME="$root/home/.config" XDG_DATA_HOME="$root/home/.local/share" \
    XDG_CACHE_HOME="$root/home/.cache" XDG_STATE_HOME="$root/home/.local/state" \
    ANTHROPIC_BASE_URL=http://aos-api-proxy:8080 ANTHROPIC_API_KEY=sk-ant-placeholder-the-proxy-injects-the-key \
    CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1 DISABLE_AUTOUPDATER=1 \
    claude "$@"
}

# docker_score <k> <scenario> <out json>: fresh scorer container, network none,
# sample volume read-only; the app under test runs as uid 2000 inside it.
docker_score() {
  local k="$1"
  docker rm -f "aos-sample-$R8-$k" >/dev/null 2>&1
  docker run --rm --label "aos-run=$RUN_ID" --network none --user 0:0 \
      --cap-drop ALL --cap-add SETUID --cap-add SETGID --cap-add KILL --cap-add DAC_READ_SEARCH \
      --security-opt no-new-privileges --read-only --tmpfs /tmp:rw,exec,size=2g --pids-limit 512 \
      --mount "type=volume,src=aos-$R8-$k,dst=/sample,readonly" "$IMAGE" \
      node /opt/harness/lib/score-sample.mjs --root /sample --sid "${S_SID[$k]}" --scenario "$2" \
        --harness /opt/harness --work /tmp/score --app-uid 2000 --emit-transcript > "$3"
}

docker_end_sample() {
  local k="$1" tag="$2"
  docker logs "aos-proxy-$R8-$k" 2>&1 | redact > "$OUT/proxy-$tag.log"
  docker rm -f "aos-proxy-$R8-$k" "aos-sample-$R8-$k" >/dev/null 2>&1
  docker volume rm -f "aos-$R8-$k" >/dev/null 2>&1
}

# ---- run + score each sample ---------------------------------------------------
new_scratch scores; SCORES="$SCRATCH_LAST"
for k in "${!S_ROOT[@]}"; do
  root="${S_ROOT[$k]}"; i="${S_ARM[$k]}"; j="${S_SCN[$k]}"; r="${S_RUN[$k]}"; sid="${S_SID[$k]}"
  tag="${ARM_NAME[$i]}-${SCN_NAME[$j]}-r$r"
  log="$OUT/claude-$tag.log"
  : > "$log"
  echo "[$((k + 1))/${#S_ROOT[@]}] $tag (${SCN_N[$j]} prompt(s)) …"
  if [ "$SANDBOX" = docker ]; then docker_start_sample "$k" || die "could not start the $tag sample container"; fi
  codes=""
  for n in $(seq 1 "${SCN_N[$j]}"); do
    prompt="$(cat "$PROMPTS_DIR/$j/$n.txt")"
    if [ "$n" = 1 ]; then session=(--session-id "$sid"); else session=(--resume "$sid"); fi
    echo "--- prompt $n ---" >> "$log"
    if [ "$SANDBOX" = docker ]; then
      docker_prompt "$k" -p "$prompt" "${session[@]}" "${CLAUDE_OPTS[@]}" 2>&1 | redact >> "$log"
      rc="${PIPESTATUS[0]}"
    else
      iso_exec "$root" "$AUTH_VAR" -- claude -p "$prompt" "${session[@]}" "${CLAUDE_OPTS[@]}" 2>&1 | redact >> "$log"
      rc="${PIPESTATUS[0]}"
    fi
    codes="$codes${codes:+ }$rc"
    # A failed prompt ends the sample: resuming past it would score a
    # different conversation. The row records it as incomplete.
    if [ "$rc" != 0 ]; then
      echo "  (prompt $n of ${SCN_N[$j]} exited $rc; sample stopped, incomplete; see $log)"
      break
    fi
  done

  full="$SCORES/$k-full.json"; score="$SCORES/$k.json"
  if [ "$SANDBOX" = docker ]; then
    docker_score "$k" "${SCN_NAME[$j]}" "$full" 2>"$SCORES/$k.err"
    docker_end_sample "$k" "$tag"
  else
    node "$HARNESS/lib/score-sample.mjs" --root "$root" --sid "$sid" --scenario "${SCN_NAME[$j]}" \
      --harness "$HARNESS" --work "$SCORES/$k-work" --emit-transcript > "$full" 2>"$SCORES/$k.err"
  fi
  # Split the scorer output: the transcript goes to <out>/transcripts (redacted),
  # the rest is the score. A malformed score is an empty object.
  node -e '
    const fs = require("fs"); let o = {};
    try { o = JSON.parse(fs.readFileSync(process.argv[1], "utf8")); } catch {}
    if (typeof o.transcript === "string") fs.writeFileSync(process.argv[3], o.transcript, "latin1");
    delete o.transcript;
    fs.writeFileSync(process.argv[2], JSON.stringify(o));
  ' "$full" "$score" "$SCORES/$k.transcript"
  [ -f "$SCORES/$k.transcript" ] && redact < "$SCORES/$k.transcript" > "$OUT/transcripts/$tag.jsonl"
  redact < "$score" > "$OUT/score-$tag.json"
  redact < "$SCORES/$k.err" > "$OUT/score-$tag.err"
  echo "  exploit: $(jq -r '.exploit.json.exploit // (if .exploit then "error" else "n/a" end)' "$score" 2>/dev/null || echo error)  security-scan exit: $(jq -r '.scan.rc // "n/a"' "$score" 2>/dev/null)"

  RUN_ID="$RUN_ID" HARNESS_SHA="$HARNESS_SHA" HARNESS_DIRTY="$HARNESS_DIRTY" SANDBOX="$SANDBOX" \
  ARM="${ARM_NAME[$i]}" REF="${ARM_REF[$i]}" FLAGS="${ARM_FLAGS[$i]}" REPO_SHA="${ARM_SHA[$i]}" \
  SCENARIO="${SCN_NAME[$j]}" PROMPTS="${SCN_N[$j]}" SAMPLE="$r" ORDER="$k" SID="$sid" \
  EXIT_CODES="$codes" SCORE_JSON="$score" LOG="$log" TASK_BASE="${S_BASE[$k]}" \
    node "$DIR/lib/sample-row.mjs" | redact >> "$SAMPLES" || die "could not write the sample row for $tag"
done

node "$DIR/summarize-samples.mjs" "$SAMPLES" --json > "$OUT/summary.json" || die "summary failed"
echo ""
node "$DIR/summarize-samples.mjs" "$SAMPLES"
echo ""
echo "samples: $SAMPLES"
echo "summary: $OUT/summary.json"
echo "NOTE: stochastic samples. Compare distributions (min/max), not one mean; see README.md \"Release arms\"."

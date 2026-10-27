#!/usr/bin/env bash
# run-release-arms-docker.sh — run run-release-arms.sh inside a container, so
# the model (which runs with --dangerously-skip-permissions) cannot reach the
# operator's account by absolute path.
#
# The container gets:
#   /repo   this repo, bind-mounted READ-ONLY (plus, read-only at its own path,
#           the git common dir when the checkout is a worktree whose .git lives
#           outside it)
#   /out    the host output dir, the ONLY writable mount
#   no host HOME, no docker socket, --cap-drop ALL, no-new-privileges, a
#   read-only root fs with tmpfs /tmp and HOME, a non-root user (the host
#   uid:gid, or 1000:1000 when the host user is root), --init, a pids limit.
# Auth: ANTHROPIC_API_KEY / CLAUDE_CODE_OAUTH_TOKEN are passed BY NAME
# (`-e NAME`), never as a value on the docker command line.
#
# Inside, run-release-arms.sh runs unchanged with --out /out, cost gate
# included: with a TTY the container gets -it so the `y` prompt works;
# without one, --yes is required up front.
#
# Usage:
#   run-release-arms-docker.sh [--out HOSTDIR] [--image TAG] [--no-build]
#                              [--claude-bin-dir DIR] [--] <run-release-arms args>
#   --out HOSTDIR       host output dir (default: eval/metrics/runs/<stamp>-release-arms-docker)
#   --image TAG         image tag (default: agentic-os-eval:<Dockerfile sha256 prefix>)
#   --no-build          use an existing image
#   --claude-bin-dir D  TEST HOOK: mount host dir D read-only first on PATH, so a
#                       stub `claude` replaces the pinned CLI (no API calls)
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$DIR/../.." && pwd -P)"

die() { echo "run-release-arms-docker: $*" >&2; exit 1; }

OUT=""; IMAGE=""; BUILD=1; BIN_DIR=""
while [ $# -gt 0 ]; do
  case "$1" in
    --out) OUT="${2:?--out needs a directory}"; shift 2 ;;
    --image) IMAGE="${2:?--image needs a tag}"; shift 2 ;;
    --no-build) BUILD=0; shift ;;
    --claude-bin-dir) BIN_DIR="${2:?--claude-bin-dir needs a directory}"; shift 2 ;;
    --) shift; break ;;
    *) break ;;
  esac
done
YES=0
for a in "$@"; do
  case "$a" in
    --out) die "--out is set by this wrapper (the container writes to /out); pass it before the run-release-arms args" ;;
    --yes) YES=1 ;;
  esac
done
TTY_FLAGS=(-i)
if [ -t 0 ] && [ -t 1 ]; then
  TTY_FLAGS=(-it)
elif [ "$YES" != 1 ]; then
  die "stdin is not a terminal, so the cost gate cannot ask; pass --yes after reviewing the plan (nothing was built or run)"
fi

command -v docker >/dev/null 2>&1 || die "docker not found"
docker info >/dev/null 2>&1 || die "docker daemon not reachable"

if [ -z "$IMAGE" ]; then
  if command -v shasum >/dev/null 2>&1; then h="$(shasum -a 256 < "$DIR/docker/Dockerfile")"; else h="$(sha256sum < "$DIR/docker/Dockerfile")"; fi
  IMAGE="agentic-os-eval:${h:0:12}"
fi
if [ "$BUILD" = 1 ]; then
  docker build -q -t "$IMAGE" "$DIR/docker" >&2 || die "docker build failed"
fi

OUT="${OUT:-$DIR/runs/$(date -u +%Y%m%dT%H%M%SZ)-release-arms-docker}"
mkdir -p "$OUT" || die "cannot create $OUT"
OUT="$(cd "$OUT" && pwd -P)"

MOUNTS=(-v "$REPO:/repo:ro" -v "$OUT:/out")
GC="$(git -C "$REPO" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || die "not a git checkout: $REPO"
GC="$(cd "$GC" && pwd -P)"
case "$GC/" in "$REPO/"*) ;; *) MOUNTS+=(-v "$GC:$GC:ro") ;; esac
CPATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
if [ -n "$BIN_DIR" ]; then
  BIN_DIR="$(cd "$BIN_DIR" && pwd -P)" || die "no such dir: $BIN_DIR"
  MOUNTS+=(-v "$BIN_DIR:/opt/claude-override:ro")
  CPATH="/opt/claude-override:$CPATH"
fi

AUTH=()
for v in ANTHROPIC_API_KEY CLAUDE_CODE_OAUTH_TOKEN; do
  if [ -n "${!v:-}" ]; then AUTH+=(-e "$v"); fi
done

U="$(id -u):$(id -g)"
[ "$(id -u)" != 0 ] || U="1000:1000"

echo "container: $IMAGE   repo (ro): $REPO   out: $OUT" >&2
exec docker run --rm --init "${TTY_FLAGS[@]}" \
  --user "$U" --cap-drop ALL --security-opt no-new-privileges --pids-limit 2048 \
  --read-only --tmpfs /tmp:rw,exec,size=4g --tmpfs /home/eval:rw,size=256m \
  -e HOME=/home/eval -e PATH="$CPATH" -e GIT_OPTIONAL_LOCKS=0 \
  ${AUTH[@]+"${AUTH[@]}"} "${MOUNTS[@]}" -w /repo \
  "$IMAGE" bash /repo/eval/metrics/run-release-arms.sh --out /out "$@"

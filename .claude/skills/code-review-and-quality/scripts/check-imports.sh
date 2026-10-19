#!/usr/bin/env bash
# check-imports.sh — deterministic check for hallucinated / nonexistent imports and
# for newly added dependencies that nothing imports. Scope: JS/TS and Python.
#
# Run from the project root:
#   check-imports.sh [--base <ref>] [--paths <file>...] [--json]
#
# Scope (same semantics as security-scan.sh):
#   --base <ref>      files changed between merge-base(<ref>, HEAD) and the working
#                     tree, plus untracked non-ignored files. Deleted files skipped.
#   --paths <p>...    these files; a directory expands to every file under it
#                     (.git and node_modules pruned); a missing path is a usage
#                     error (exit 2). Consumes arguments until --json, --base or
#                     `--`; everything after `--` is a path.
#   (neither)         uncommitted changes vs HEAD plus untracked files.
#   Symlinks are resolved; a path whose real location is outside the repo root
#   (git toplevel, else the current directory) is skipped and listed in
#   "skipped", as is a broken symlink. Files are never read outside the root.
#
# Checks:
#   js-imports   in changed .js/.jsx/.mjs/.cjs/.ts/.tsx/.mts/.cts files:
#                - relative specifiers ('./x', '../x', '/x') must resolve to a file
#                  (exact, + known extension, .js→.ts swap, or directory index /
#                  directory package.json);
#                - bare specifiers must be a node builtin (or node:*) or be declared
#                  in dependencies/devDependencies/peerDependencies/
#                  optionalDependencies (or be the `name`) of the nearest
#                  package.json or any ancestor package.json up to the current dir.
#                  A type-only import (`import type … from 'x'` / `export type …`)
#                  is also satisfied by a declared @types/x (@a/b → @types/a__b).
#   py-imports   in changed .py files:
#                - relative imports (from .x import y) must resolve to a module file
#                  or package directory;
#                - absolute imports: the TOP-LEVEL module must be a local module/
#                  package (x.py or x/ in the file's dir, an ancestor dir, or an
#                  ancestor's src/) or be found by
#                  `$PYTHON -I -c '...importlib.util.find_spec(name)...'`.
#                  PYTHON defaults to python3 — point it at the project venv's
#                  interpreter so installed packages resolve. `-I` is kept on
#                  purpose (it stops a repo sitecustomize.py or cwd module from
#                  executing); PYTHONPATH entries are re-added to sys.path
#                  explicitly by the helper, minus empty entries (= the cwd).
#   unused-deps  runtime dependencies ADDED in the diff (package.json
#                `dependencies`, requirements*.txt, pyproject.toml
#                [project].dependencies and [tool.poetry.dependencies]) that no
#                source file under the manifest's directory imports. "Added" is
#                relative to merge-base(--base) or HEAD.
#
# Known limitations (v1):
#   - Dynamic imports with non-literal specifiers, require(variable), template
#     literals and __import__/importlib.import_module calls are not checked.
#   - Aliases are NOT resolved: tsconfig `paths` and bundler aliases are not read.
#     Only specifiers starting with '@/', '~' or '#' (package.json imports) and
#     protocol specifiers containing ':' ('virtual:', 'https:', 'bun:') are
#     skipped unverified; any other alias (e.g. '@app/x', 'components/x') is
#     reported as js-undeclared-package.
#   - Type-only detection is per line: a multi-line `import type {…}` whose
#     `from` sits on a later line is treated as a value import.
#   - Monorepos: workspace hoisting is approximated by accepting a declaration in
#     any ancestor package.json; a package resolved only via a sibling workspace's
#     manifest is reported.
#   - Python: only the top-level module is resolved (submodule typos such as
#     `os.pathx` are not caught); extraction is line-based, so docstrings
#     containing `import x` lines may be read as imports.
#   - Python imports inside a `try:` body are skipped as optional imports. This
#     is a false-positive limitation, NOT a security control: wrapping a
#     hallucinated import in `try:` hides it from this check.
#   - JS extraction is line-based: `from 'x'` inside a string literal can be read
#     as an import; commented lines starting with // or * are skipped.
#   - unused-deps excludes devDependencies (tools used only via CLI or config files
#     would be false positives) and matches Python distributions to import names
#     via importlib.metadata.packages_distributions() when the package is
#     installed, else by normalized name — an uninstalled package whose import
#     name differs from its distribution name (Pillow → PIL) can be misreported.
#
# --json emits {"scanners":[{"name","status","reason"?,"findings":[{"file","line",
#   "rule","severity","message"}]}],"skipped":[{"path","reason"}]} — the same
#   shape as security-scan.sh. Status: ran | findings | error.
#   Rules: js-unresolved-relative, js-undeclared-package, js-import-outside-root,
#   py-unresolved-relative, py-import-outside-root, py-unresolved-module,
#   unused-dependency.
#   Resolution never leaves the repo root: a relative or absolute import whose
#   lexical target is outside it is a *-import-outside-root finding (nothing
#   outside is stat'ed), and a candidate file, package dir or ancestor
#   package.json whose real (symlink-resolved) location is outside the root is
#   treated as absent; such a package.json is also listed in "skipped".
#   Text output escapes control characters in repo-controlled text as \xNN and
#   prefixes every line with "check-imports: " (no line can start with `::`).
#
# Exit codes:
#   0  checked, clean
#   1  findings
#   2  usage error (bad flag, missing --paths entry, --base ref does not resolve,
#      not a git repo, no jq)
#   3  nothing to check (no JS/TS/Python sources or dependency manifests in scope)
#   4  a check could not run and nothing was found (python3 missing, the Python
#      helper failed, a manifest could not be parsed)
#
# Requires bash (3.2+ compatible), jq, awk, git (for --base / default scope / the
# unused-deps baseline) and python3 (for Python files and pyproject.toml).
set -euo pipefail

PYTHON="${PYTHON:-python3}"

usage() {
  echo "usage: check-imports.sh [--base <ref>] [--paths <file>...] [--json]" >&2
  exit 2
}

command -v jq >/dev/null 2>&1 || { echo "check-imports: jq is required" >&2; exit 2; }

BASE=""
JSON=false
PATHS_GIVEN=false
FILES=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base)
      [[ $# -ge 2 ]] || usage
      BASE="$2"; shift 2 ;;
    --json) JSON=true; shift ;;
    --paths)
      PATHS_GIVEN=true; shift
      while [[ $# -gt 0 ]]; do
        case "$1" in
          --json|--base) break ;;
          --) shift; while [[ $# -gt 0 ]]; do FILES+=("$1"); shift; done ;;
          *) FILES+=("$1"); shift ;;
        esac
      done ;;
    -h|--help) usage ;;
    *) echo "check-imports: unknown argument: $1" >&2; usage ;;
  esac
done

if [[ "$PATHS_GIVEN" == true && -n "$BASE" ]]; then
  echo "check-imports: --base and --paths are mutually exclusive" >&2; exit 2
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

IN_GIT=false
git rev-parse --is-inside-work-tree >/dev/null 2>&1 && IN_GIT=true
DIFF_FROM=""

if [[ -n "$BASE" ]]; then
  [[ "$IN_GIT" == true ]] || { echo "check-imports: --base needs a git work tree" >&2; exit 2; }
  [[ "$BASE" != -* ]] || { echo "check-imports: invalid --base ref: $BASE" >&2; exit 2; }
  git rev-parse --verify --quiet "${BASE}^{commit}" >/dev/null || {
    echo "check-imports: --base ref does not resolve: $BASE" >&2; exit 2; }
  DIFF_FROM="$(git merge-base "$BASE" HEAD)"
elif [[ "$IN_GIT" == true ]] && git rev-parse --verify --quiet HEAD >/dev/null; then
  DIFF_FROM="HEAD"
fi

if [[ "$PATHS_GIVEN" == false ]]; then
  [[ "$IN_GIT" == true ]] || { echo "check-imports: not a git work tree (use --paths)" >&2; exit 2; }
  {
    if [[ -n "$DIFF_FROM" ]]; then git diff --name-only -z --diff-filter=d --relative "$DIFF_FROM" --; fi
    git ls-files -z --others --exclude-standard --
  } > "$TMP/files.z"
  while IFS= read -r -d '' f; do FILES+=("$f"); done < "$TMP/files.z"
else
  # Missing paths are a usage error; directories expand to the files under them.
  EXPANDED=()
  for f in ${FILES[@]+"${FILES[@]}"}; do
    case "$f" in /*|./*) ;; *) f="./$f" ;; esac
    if [[ ! -e "$f" && ! -L "$f" ]]; then
      echo "check-imports: --paths entry does not exist: ${f#./}" >&2; exit 2
    fi
    if [[ -d "$f" && ! -L "$f" ]]; then
      while IFS= read -r -d '' g; do EXPANDED+=("$g"); done < <(
        find "$f" \( -name .git -o -name node_modules \) -prune -o \( -type f -o -type l \) -print0)
    else
      EXPANDED+=("$f")
    fi
  done
  FILES=(${EXPANDED[@]+"${EXPANDED[@]}"})
fi

PWDP="$(pwd -P)"
if [[ "$IN_GIT" == true ]]; then
  ROOT="$(cd -P -- "$(git rev-parse --show-toplevel)" && pwd -P)"
else
  ROOT="$PWDP"
fi

# Physical absolute path of $1 with every symlink followed; fails on loops or
# a missing parent directory. $1 always starts with "./" or "/".
resolve() {
  local p="$1" n=0 link dir
  while [[ -L "$p" ]]; do
    n=$((n + 1)); [[ "$n" -le 40 ]] || return 1
    link="$(readlink "$p")" || return 1
    case "$link" in /*) p="$link" ;; *) p="$(dirname "$p")/$link" ;; esac
  done
  dir="$(cd -P -- "$(dirname "$p")" 2>/dev/null && pwd -P)" || return 1
  printf '%s/%s\n' "$dir" "$(basename "$p")"
}

: > "$TMP/skipped.jsonl"
skip() {
  jq -cn --arg path "${1#./}" --arg reason "$2" '{path:$path, reason:$reason}' >> "$TMP/skipped.jsonl"
}
skip_once() {
  jq -e --arg path "${1#./}" 'select(.path == $path)' "$TMP/skipped.jsonl" >/dev/null 2>&1 || skip "$1" "$2"
}

# in_root <path>: true when <path> exists and its real location is inside ROOT.
in_root() {
  local r
  r="$(resolve "$1")" || return 1
  [[ -e "$r" ]] || return 1
  case "$r" in "$ROOT"/*) return 0 ;; esac
  return 1
}
root_file() { in_root "$1" && [[ -f "$1" ]]; }
root_dir() { in_root "$1" && [[ -d "$1" ]]; }

# abs_path <path>: absolute (physical-cwd based) form of a ./relative or /path.
abs_path() {
  case "$1" in
    /*) printf '%s\n' "$1" ;;
    .) printf '%s\n' "$PWDP" ;;
    *) printf '%s/%s\n' "$PWDP" "${1#./}" ;;
  esac
}

# lexnorm <absolute path>: purely lexical normalization of "." and ".." — never
# touches the filesystem, so it is safe on attacker-chosen specifiers.
lexnorm() {
  local parts=() segs=() part
  IFS=/ read -r -a parts <<< "$1"
  for part in ${parts[@]+"${parts[@]}"}; do
    case "$part" in
      ""|.) ;;
      ..) [[ ${#segs[@]} -gt 0 ]] && unset "segs[$(( ${#segs[@]} - 1 ))]" ;;
      *) segs+=("$part") ;;
    esac
  done
  local IFS=/
  printf '/%s\n' "${segs[*]-}"
}

under_root() { case "$1/" in "$ROOT"/*) return 0 ;; esac; return 1; }

# Resolve symlinks and keep regular files inside the repo root (never read files
# outside it), as ./relative when under the current dir (leading-dash safety).
JS=(); PY=(); MANIFESTS=()
for f in ${FILES[@]+"${FILES[@]}"}; do
  case "$f" in /*|./*) ;; *) f="./$f" ;; esac
  if ! real="$(resolve "$f")" || [[ ! -e "$real" ]]; then
    skip "$f" "broken symlink or unresolvable path"; continue
  fi
  case "$real" in
    "$ROOT"/*) ;;
    *) skip "$f" "resolves outside the repo root"; continue ;;
  esac
  [[ -f "$real" ]] || continue
  case "$real" in "$PWDP"/*) f="./${real#"$PWDP"/}" ;; *) f="$real" ;; esac
  case "$f" in
    */node_modules/*) continue ;;
    *.js|*.jsx|*.mjs|*.cjs|*.ts|*.tsx|*.mts|*.cts) JS+=("$f") ;;
    *.py) PY+=("$f") ;;
  esac
  case "$(basename -- "$f")" in
    package.json|pyproject.toml|requirements*.txt) MANIFESTS+=("$f") ;;
  esac
done

# Text output: repo-controlled text has C0/C1 control chars and DEL escaped as
# \xNN (no newline/CR/ESC reaches the terminal) and every line is prefixed with
# "check-imports: ", so none can begin with a `::` workflow command.
text_out() {
  jq -r 'def hex2: [(. / 16 | floor), (. % 16)] | map("0123456789abcdef"[.:(. + 1)]) | add;
    def esc: tostring | [explode[] | if (. < 32) or (. >= 127 and . < 160)
      then ("\\x" + hex2 | explode[]) else . end] | implode;
    ((.scanners[] |
      "\(.name | esc): \(.status)\(if .reason then " (\(.reason | esc))" else "" end)\(if (.findings|length) > 0 then " — \(.findings|length) finding(s)" else "" end)",
      (.findings[] | "  \(.file | esc):\(.line // "-") [\(.rule | esc)] \(.severity | esc): \(.message | esc)")),
     (.skipped[] | "skipped: \(.path | esc) (\(.reason | esc))"))
    | "check-imports: " + .' <<<"$1"
}

if [[ ${#JS[@]} -eq 0 && ${#PY[@]} -eq 0 && ${#MANIFESTS[@]} -eq 0 ]]; then
  if [[ "$JSON" == true ]]; then
    jq -cn --slurpfile k "$TMP/skipped.jsonl" '{scanners: [], skipped: $k}'
  else
    text_out "$(jq -cn --slurpfile k "$TMP/skipped.jsonl" '{scanners: [], skipped: $k}')"
    echo "check-imports: nothing to check"
  fi
  exit 3
fi

: > "$TMP/results.jsonl"
: > "$TMP/empty.jsonl"
# Reasons quote helper stderr, which can name absolute paths. Literal
# substitutions, longest first: temp dir → <tmp>, repo root / cwd → relative,
# $HOME → ~. Empty and "/" values are skipped (a HOME=/ must not rewrite every "/").
SCRUB_SUBS="$(jq -cn --arg t "$TMP" --arg tp "$(cd -P -- "$TMP" && pwd -P)" --arg r "$ROOT" \
  --arg p "$PWDP" --arg l "$PWD" --arg h "${HOME:-}" '
  def ok: length > 1;
  [ (if ($t|ok) then [$t, "<tmp>"] else empty end), (if ($tp|ok) then [$tp, "<tmp>"] else empty end),
    (if ($r|ok) then [$r + "/", ""], [$r, "."] else empty end),
    (if ($p|ok) then [$p + "/", ""] else empty end), (if ($l|ok) then [$l + "/", ""] else empty end),
    (if ($h|ok) then [$h, "~"] else empty end) ]')"

emit() {
  jq -cn --arg name "$1" --arg status "$2" --arg reason "$3" --slurpfile f "$4" --argjson subs "$SCRUB_SUBS" \
    'def scrub: reduce $subs[] as $s (.; split($s[0]) | join($s[1]));
     {name:$name, status:$status, findings:$f} + (if $reason == "" then {} else {reason:($reason | scrub)} end)' \
    >> "$TMP/results.jsonl"
}
# finding <out-file> <file> <line> <rule> <severity> <message>
finding() {
  jq -cn --arg file "${2#./}" --arg line "$3" --arg rule "$4" --arg sev "$5" --arg msg "$6" \
    '{file:$file, line:($line | tonumber? // null), rule:$rule, severity:$sev, message:$msg}' >> "$1"
}
status_of() { if [[ -s "$1" ]]; then echo findings; else echo ran; fi; }

# ── extractors (awk, line-based; print "<line>\t<specifier>[\t<type|->]") ─────
js_specs() {
  awk '{
    s = $0; t = s; sub(/^[ \t]+/, "", t)
    if (t ~ /^(\/\/|\*|\/\*)/) next
    ty = (t ~ /^(import|export)[ \t]+type[ \t{]/) ? "type" : "-"
    while (match(s, /(^|[^A-Za-z0-9_$.])(from|import|require)[ \t]*\(?[ \t]*["\047][^"\047]+["\047]/)) {
      m = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
      sub(/^[^"\047]*["\047]/, "", m); sub(/["\047]$/, "", m)
      print NR "\t" m "\t" ty
    }
  }' "$1"
}

# Python: skips imports nested in a `try:` body (optional-import idiom).
py_specs() {
  awk '
  function indent(x) { match(x, /^[ \t]*/); return RLENGTH }
  {
    line = $0
    if (line ~ /^[ \t]*($|#)/) next
    ind = indent(line)
    if (in_try && ind <= try_ind) in_try = 0
    if (line ~ /^[ \t]*try[ \t]*:[ \t]*(#.*)?$/) { in_try = 1; try_ind = ind; next }
    if (in_try) next
    if (match(line, /^[ \t]*from[ \t]+[.A-Za-z0-9_]+[ \t]+import([ \t(]|$)/)) {
      m = line; sub(/^[ \t]*from[ \t]+/, "", m); sub(/[ \t].*$/, "", m)
      print NR "\t" m; next
    }
    if (match(line, /^[ \t]*import[ \t]+/)) {
      rest = substr(line, RLENGTH + 1); sub(/#.*$/, "", rest)
      n = split(rest, parts, ",")
      for (i = 1; i <= n; i++) {
        p = parts[i]; gsub(/^[ \t(]+|[ \t)\\]+$/, "", p); sub(/[ \t]+as[ \t].*$/, "", p)
        if (p ~ /^[A-Za-z_][A-Za-z0-9_.]*$/) print NR "\t" p
      }
    }
  }' "$1"
}

js_pkg_name() {
  local s="$1"
  if [[ "$s" == @*/* ]]; then
    local scope="${s%%/*}" rest="${s#*/}"
    echo "$scope/${rest%%/*}"
  else
    echo "${s%%/*}"
  fi
}

# @types package that carries the typings for <pkg> (@a/b → @types/a__b).
types_name() {
  local p="$1"
  if [[ "$p" == @*/* ]]; then p="${p#@}"; echo "@types/${p/\//__}"; else echo "@types/$p"; fi
}

NODE_BUILTINS=" assert async_hooks buffer child_process cluster console constants crypto dgram diagnostics_channel dns domain events fs http http2 https inspector module net os path perf_hooks process punycode querystring readline repl stream string_decoder sys timers tls trace_events tty url util v8 vm wasi worker_threads zlib "

# Directories from dirname($1) up to "." or the repo root — never above ROOT.
ancestors() {
  local d
  d="$(dirname -- "$1")"
  while :; do
    case "$d" in /*) under_root "$d" || break ;; esac
    printf '%s\n' "$d"
    [[ "$d" == "." || "$d" == "/" || "$d" == "$ROOT" ]] && break
    d="$(dirname -- "$d")"
  done
}

js_declared() {
  local pkg="$1" file="$2" d
  while IFS= read -r d; do
    [[ -e "$d/package.json" || -L "$d/package.json" ]] || continue
    if ! root_file "$d/package.json"; then
      skip_once "$d/package.json" "manifest resolves outside the repo root"; continue
    fi
    if jq -e --arg p "$pkg" '(.name == $p) or
        ([.dependencies, .devDependencies, .peerDependencies, .optionalDependencies]
         | map(select(type == "object") | has($p)) | any)' "$d/package.json" >/dev/null 2>&1; then
      return 0
    fi
  done < <(ancestors "$file")
  return 1
}

# js_relative_resolves <absolute, lexically-in-root path>: a candidate only counts
# when its real (symlink-resolved) location is inside ROOT.
js_relative_resolves() {
  local p="$1" ext
  root_file "$p" && return 0
  for ext in .ts .tsx .d.ts .js .jsx .mjs .cjs .mts .cts .json; do
    root_file "$p$ext" && return 0
  done
  case "$p" in
    *.js)  { root_file "${p%.js}.ts" || root_file "${p%.js}.tsx"; } && return 0 ;;
    *.jsx) root_file "${p%.jsx}.tsx" && return 0 ;;
    *.mjs) root_file "${p%.mjs}.mts" && return 0 ;;
    *.cjs) root_file "${p%.cjs}.cts" && return 0 ;;
  esac
  if root_dir "$p"; then
    root_file "$p/package.json" && return 0
    for ext in .ts .tsx .js .jsx .mjs .cjs; do
      root_file "$p/index$ext" && return 0
    done
  fi
  return 1
}

check_js() {
  local out="$TMP/js.jsonl" f line spec kind pkg dir
  : > "$out"
  for f in "${JS[@]}"; do
    dir="$(dirname -- "$f")"
    while IFS=$'\t' read -r line spec kind; do
      spec="${spec%%\?*}"
      [[ -n "$spec" ]] || continue
      case "$spec" in
        ./*|../*|.|..|/*)
          local target kindword=relative
          if [[ "$spec" == /* ]]; then target="$(lexnorm "$spec")"; kindword=absolute
          else target="$(lexnorm "$(abs_path "$dir")/$spec")"; fi
          if ! under_root "$target"; then
            finding "$out" "$f" "$line" js-import-outside-root ERROR "$kindword import '$spec' points outside the repo root"
          elif ! js_relative_resolves "$target"; then
            finding "$out" "$f" "$line" js-unresolved-relative ERROR "$kindword import '$spec' does not resolve to a file"
          fi
          continue ;;
        node:*|@/*|~*|\#*|*:*) continue ;;
      esac
      pkg="$(js_pkg_name "$spec")"
      [[ "$NODE_BUILTINS" == *" $pkg "* ]] && continue
      js_declared "$pkg" "$f" && continue
      # A type-only import is satisfied by the package's @types typings.
      [[ "$kind" == type ]] && js_declared "$(types_name "$pkg")" "$f" && continue
      finding "$out" "$f" "$line" js-undeclared-package ERROR "package '$pkg' is not a node builtin and is not declared in any package.json up to the project root"
    done < <(js_specs "$f")
  done
  emit js-imports "$(status_of "$out")" "" "$out"
}

# ── Python helper (static code; data only via argv) ───────────────────────────
# Runs under `python -I` (isolated: no cwd on sys.path, PYTHON* env ignored, no
# user site), so nothing from the untrusted repo (sitecustomize.py, a cwd module
# shadowing a stdlib name) can execute. PYTHONPATH is then re-applied explicitly:
# each non-empty entry is appended to sys.path (empty entries, which would mean
# the cwd, are dropped). find_spec on a top-level name only locates a module; it
# never executes it.
PY_HELPER='
import os, sys
for _p in os.environ.get("PYTHONPATH", "").split(os.pathsep):
    if _p:
        sys.path.append(os.path.abspath(_p))
cmd, args = sys.argv[1], sys.argv[2:]
if cmd == "missing":
    import importlib.util
    for n in args:
        try:
            spec = importlib.util.find_spec(n)
        except Exception:
            spec = None
        if spec is None:
            print(n)
elif cmd == "dists":
    import importlib.metadata as md
    m = md.packages_distributions()
    for n in args:
        for d in m.get(n, []):
            print(n + "\t" + d)
elif cmd == "pyproject":
    import tomllib
    with open(args[0], "rb") as fh:
        data = tomllib.load(fh)
    for dep in data.get("project", {}).get("dependencies", []) or []:
        print(dep)
    poetry = data.get("tool", {}).get("poetry", {}).get("dependencies", {}) or {}
    for name in poetry:
        if name.lower() != "python":
            print(name)
'

py_local_module() {
  local top="$1" file="$2" d
  while IFS= read -r d; do
    { root_file "$d/$top.py" || root_dir "$d/$top" || root_file "$d/src/$top.py" || root_dir "$d/src/$top"; } && return 0
  done < <(ancestors "$file")
  return 1
}

check_py() {
  local out="$TMP/py.jsonl" pending="$TMP/py-pending.tsv" f line spec top
  : > "$out"; : > "$pending"
  if ! command -v "$PYTHON" >/dev/null 2>&1; then
    emit py-imports error "$PYTHON not found; cannot resolve Python imports" "$TMP/empty.jsonl"
    return
  fi
  for f in "${PY[@]}"; do
    while IFS=$'\t' read -r line spec; do
      if [[ "$spec" == .* ]]; then
        local rest="$spec" base dots=0
        while [[ "$rest" == .* ]]; do rest="${rest#.}"; dots=$((dots + 1)); done
        base="$(abs_path "$(dirname -- "$f")")"
        while [[ "$dots" -gt 1 ]]; do base="$base/.."; dots=$((dots - 1)); done
        local p
        p="$(lexnorm "$base/${rest//.//}")"
        if ! under_root "$p"; then
          finding "$out" "$f" "$line" py-import-outside-root ERROR "relative import '$spec' points outside the repo root"
          continue
        fi
        [[ -z "$rest" ]] && continue
        { root_file "$p.py" || root_file "$p.pyi" || root_dir "$p"; } ||
          finding "$out" "$f" "$line" py-unresolved-relative ERROR "relative import '$spec' does not resolve to a module"
        continue
      fi
      top="${spec%%.*}"
      py_local_module "$top" "$f" && continue
      printf '%s\t%s\t%s\n' "$f" "$line" "$top" >> "$pending"
    done < <(py_specs "$f")
  done
  if [[ -s "$pending" ]]; then
    local names=() n missing="$TMP/py-missing.txt"
    while IFS= read -r n; do names+=("$n"); done < <(cut -f3 "$pending" | sort -u)
    if ! "$PYTHON" -I -c "$PY_HELPER" missing "${names[@]}" > "$missing" 2>"$TMP/py.err"; then
      emit py-imports error "$PYTHON helper failed: $(tail -c 300 "$TMP/py.err")" "$TMP/empty.jsonl"
      return
    fi
    while IFS=$'\t' read -r f line top; do
      if grep -qxF -- "$top" "$missing"; then
        finding "$out" "$f" "$line" py-unresolved-module ERROR "module '$top' is not installed for $PYTHON and is not a local module"
      fi
    done < "$pending"
  fi
  emit py-imports "$(status_of "$out")" "" "$out"
}

# ── unused-deps ───────────────────────────────────────────────────────────────
# Runtime dependency names (one per line) from a manifest file.
manifest_deps() {
  local kind="$1" file="$2"
  case "$kind" in
    package.json) jq -r '(.dependencies // {}) | keys[]' "$file" ;;
    requirements)
      awk '{ sub(/#.*/, ""); gsub(/^[ \t]+|[ \t]+$/, "") }
           $0 == "" || /^-/ || /:\/\// { next }
           { if (match($0, /^[A-Za-z0-9][A-Za-z0-9._-]*/)) print substr($0, RSTART, RLENGTH) }' "$file" ;;
    pyproject)
      "$PYTHON" -I -c "$PY_HELPER" pyproject "$file" |
        awk '{ if (match($0, /^[A-Za-z0-9][A-Za-z0-9._-]*/)) print substr($0, RSTART, RLENGTH) }' ;;
  esac
}

py_norm() { tr '[:upper:]' '[:lower:]' | sed -E 's/[-_.]+/_/g'; }

# Source files under a directory (NUL-separated), honoring .gitignore when in git.
sources_under() {
  local dir="$1"
  if [[ "$IN_GIT" == true ]]; then
    git ls-files -z --cached --others --exclude-standard -- "$dir"
  else
    find "$dir" \( -name node_modules -o -name .git -o -name .venv -o -name venv \
      -o -name __pycache__ -o -name dist -o -name build \) -prune -o -type f -print0
  fi
}

check_unused() {
  local out="$TMP/unused.jsonl" m kind dir
  : > "$out"
  for m in "${MANIFESTS[@]}"; do
    case "$(basename -- "$m")" in
      package.json) kind=package.json ;;
      pyproject.toml) kind=pyproject ;;
      *) kind=requirements ;;
    esac
    if [[ "$kind" == pyproject ]] && ! command -v "$PYTHON" >/dev/null 2>&1; then
      emit unused-deps error "$PYTHON not found; cannot parse $m" "$TMP/empty.jsonl"; return
    fi
    if ! manifest_deps "$kind" "$m" 2>"$TMP/manifest.err" | LC_ALL=C sort -u > "$TMP/now.txt"; then
      emit unused-deps error "cannot parse $m: $(tail -c 300 "$TMP/manifest.err")" "$TMP/empty.jsonl"; return
    fi
    : > "$TMP/before.txt"
    local mrel
    mrel="$(resolve "$m")"; mrel="${mrel#"$ROOT"/}"
    if [[ -n "$DIFF_FROM" ]] && git cat-file -e "$DIFF_FROM:$mrel" 2>/dev/null; then
      git show "$DIFF_FROM:$mrel" > "$TMP/base-manifest" 2>/dev/null
      manifest_deps "$kind" "$TMP/base-manifest" 2>/dev/null | LC_ALL=C sort -u > "$TMP/before.txt" || : > "$TMP/before.txt"
    fi
    LC_ALL=C comm -23 "$TMP/now.txt" "$TMP/before.txt" > "$TMP/added.txt"
    [[ -s "$TMP/added.txt" ]] || continue

    # Collect what the sources under this manifest's directory import.
    dir="$(dirname -- "$m")"
    : > "$TMP/used.txt"
    local s spec
    while IFS= read -r -d '' s; do
      case "$s" in /*|./*) ;; *) s="./$s" ;; esac
      if [[ -L "$s" ]]; then
        local sr
        sr="$(resolve "$s")" || continue
        case "$sr" in "$ROOT"/*) ;; *) continue ;; esac
      fi
      [[ -f "$s" ]] || continue
      case "$s" in
        */node_modules/*) ;;
        *.js|*.jsx|*.mjs|*.cjs|*.ts|*.tsx|*.mts|*.cts)
          [[ "$kind" == package.json ]] || continue
          while IFS=$'\t' read -r _ spec _; do js_pkg_name "$spec" >> "$TMP/used.txt"; done < <(js_specs "$s") ;;
        *.py)
          [[ "$kind" != package.json ]] || continue
          while IFS=$'\t' read -r _ spec; do
            [[ "$spec" == .* ]] || printf '%s\n' "${spec%%.*}" >> "$TMP/used.txt"
          done < <(py_specs "$s") ;;
      esac
    done < <(sources_under "$dir")

    if [[ "$kind" != package.json ]]; then
      local tops=()
      while IFS= read -r spec; do tops+=("$spec"); done < <(sort -u "$TMP/used.txt")
      : > "$TMP/dists.tsv"
      if [[ ${#tops[@]} -gt 0 ]] && command -v "$PYTHON" >/dev/null 2>&1; then
        if ! "$PYTHON" -I -c "$PY_HELPER" dists "${tops[@]}" > "$TMP/dists.tsv" 2>"$TMP/py.err"; then
          emit unused-deps error "$PYTHON helper failed: $(tail -c 300 "$TMP/py.err")" "$TMP/empty.jsonl"; return
        fi
      fi
      { py_norm < "$TMP/used.txt"; cut -f2 "$TMP/dists.tsv" | py_norm; } | sort -u > "$TMP/used-norm.txt"
    fi

    local dep ln
    while IFS= read -r dep; do
      if [[ "$kind" == package.json ]]; then
        grep -qxF -- "$dep" "$TMP/used.txt" && continue
      else
        grep -qxF -- "$(printf '%s' "$dep" | py_norm)" "$TMP/used-norm.txt" && continue
      fi
      local needle="$dep"
      [[ "$kind" == package.json ]] && needle="\"$dep\""
      ln="$(grep -nF -- "$needle" "$m" | head -n 1 | cut -d: -f1 || true)"
      finding "$out" "$m" "$ln" unused-dependency WARNING "dependency '$dep' was added but no source file under ${dir#./} imports it"
    done < "$TMP/added.txt"
  done
  emit unused-deps "$(status_of "$out")" "" "$out"
}

[[ ${#JS[@]} -gt 0 ]] && check_js
[[ ${#PY[@]} -gt 0 ]] && check_py
[[ ${#MANIFESTS[@]} -gt 0 ]] && check_unused

RESULT="$(jq -cn --slurpfile s "$TMP/results.jsonl" --slurpfile k "$TMP/skipped.jsonl" '{scanners: $s, skipped: $k}')"

if [[ "$JSON" == true ]]; then
  printf '%s\n' "$RESULT"
else
  text_out "$RESULT"
fi

n_findings="$(jq '[.scanners[].findings | length] | add // 0' <<<"$RESULT")"
n_error="$(jq '[.scanners[] | select(.status == "error")] | length' <<<"$RESULT")"
if [[ "$n_findings" -gt 0 ]]; then exit 1; fi
if [[ "$n_error" -gt 0 ]]; then exit 4; fi
exit 0

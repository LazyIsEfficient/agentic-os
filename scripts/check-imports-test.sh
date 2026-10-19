#!/usr/bin/env bash
# check-imports-test.sh — deterministic, OFFLINE fixture tests for
# .claude/skills/code-review-and-quality/scripts/check-imports.sh (shipped with
# the skills; scripts/check-imports.sh is a wrapper). Builds a throwaway git repo
# with JS/TS and Python sources containing real and nonexistent imports, plus
# manifests that add a used and an unused dependency, then asserts exact findings
# and every exit code (0, 1, 2, 3, 4). Needs bash, git, jq, awk and python3
# (stdlib only).
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECK="$SCRIPT_DIR/../.claude/skills/code-review-and-quality/scripts/check-imports.sh"
WRAPPER="$SCRIPT_DIR/check-imports.sh"
[ -f "$CHECK" ] || { echo "check-imports-test: $CHECK not found" >&2; exit 2; }
command -v python3 >/dev/null 2>&1 || { echo "check-imports-test: python3 required" >&2; exit 2; }

T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
export PYTHON=python3
unset PYTHONPATH

P=0; F=0
ok(){ printf 'PASS  %s\n' "$1"; P=$((P+1)); }
no(){ printf 'FAIL  %s — %s\n' "$1" "$2"; F=$((F+1)); }

G="$T/repo"; mkdir -p "$G"
gitc(){ git -C "$G" -c user.name=t -c user.email=t@t "$@"; }

# ── Base commit: declared deps and an existing module. ────────────────────────
mkdir -p "$G/src" "$G/mypkg"
cat > "$G/package.json" <<'EOF'
{ "name": "fixture", "dependencies": { "left-pad": "1.3.0" } }
EOF
printf 'export const u = 1;\n' > "$G/src/util.ts"
printf '' > "$G/mypkg/__init__.py"
printf 'c = 1\n' > "$G/mypkg/b.py"
printf 'requests==2.31.0\n' > "$G/requirements.txt"
printf 'import requests\n' > "$G/client.py"
git -C "$G" init -q
gitc add . >/dev/null
gitc commit -qm base
BASE_SHA="$(git -C "$G" rev-parse HEAD)"

# ── The change under review. ──────────────────────────────────────────────────
cat > "$G/package.json" <<'EOF'
{ "name": "fixture",
  "dependencies": { "left-pad": "1.3.0", "chalk": "5.3.0", "is-odd": "3.0.1" } }
EOF
cat > "$G/src/app.ts" <<'EOF'
import { u } from './util';
import { gone } from './missing';
import chalk from 'chalk';
import fs from 'fs';
import path from 'node:path';
import pad from 'left-pad';
import { thing } from 'not-a-real-pkg';
// import fake from 'commented-out-pkg';
import { x } from '@/aliased';
export * from './util.js';
const lazy = await import('./util');
EOF
mkdir -p "$G/dir with space"
cat > "$G/dir with space/-dash.js" <<'EOF'
const util = require('../src/util.js');
const nope = require('./nope');
EOF
cat > "$G/mypkg/a.py" <<'EOF'
import os, json as j
from . import b
from .b import c
from .zzz import q
import mypkg.b
import totally_fake_module_xyz
try:
    import ujson_fake_optional as fast
except ImportError:
    fast = None
EOF
printf 'requests==2.31.0\nnot-imported-dist==1.0\n' > "$G/requirements.txt"

run(){ OUT="$(cd "$G" && bash "$CHECK" "$@" 2>"$T/stderr")"; RC=$?; }
jqo(){ printf '%s' "$OUT" | jq -r "$1" 2>/dev/null; }
has(){ # has <rule> <file> <line> <message-substring>
  printf '%s' "$OUT" | jq -e --arg r "$1" --arg f "$2" --arg l "$3" --arg m "$4" \
    '[.scanners[].findings[] | select(.rule==$r and .file==$f and ((.line|tostring)==$l) and (.message|contains($m)))] | length == 1' >/dev/null
}
flagged(){ printf '%s' "$OUT" | jq -e --arg m "$1" '[.scanners[].findings[] | select(.message|contains($m))] | length > 0' >/dev/null; }

# ── exit 1: --base finds hallucinated imports and the unused new dependency ───
run --json --base "$BASE_SHA"
[ "$RC" -eq 1 ] && ok "--base with bad imports → exit 1" || no "--base rc" "rc=$RC $(cat "$T/stderr") $OUT"
has js-unresolved-relative src/app.ts 2 "'./missing'" \
  && ok "nonexistent relative TS import flagged at its line" || no "./missing" "$OUT"
has js-undeclared-package src/app.ts 7 "'not-a-real-pkg'" \
  && ok "undeclared bare package flagged" || no "not-a-real-pkg" "$OUT"
has js-unresolved-relative "dir with space/-dash.js" 2 "'./nope'" \
  && ok "path with spaces + leading dash: finding keeps exact path" || no "spaced path" "$OUT"
has py-unresolved-relative mypkg/a.py 4 "'.zzz'" \
  && ok "nonexistent relative Python import flagged" || no ".zzz" "$OUT"
has py-unresolved-module mypkg/a.py 6 "'totally_fake_module_xyz'" \
  && ok "nonexistent Python module flagged via find_spec" || no "fake module" "$OUT"
has unused-dependency package.json 2 "'is-odd'" \
  && ok "newly added, unused npm dependency flagged" || no "is-odd" "$OUT"
has unused-dependency requirements.txt 2 "'not-imported-dist'" \
  && ok "newly added, unused Python requirement flagged" || no "not-imported-dist" "$OUT"
fp=""
for m in "'./util'" "'chalk'" "'fs'" "node:path" "'left-pad'" "commented-out-pkg" "@/aliased" \
         "'../src/util.js'" "'os'" "'json'" "'mypkg'" "ujson_fake_optional" "'requests'" "'.b'"; do
  flagged "$m" && fp="$fp $m"
done
[ -z "$fp" ] && ok "no false positives (declared, builtin, node:, alias, .js→.ts, local pkg, try-optional, pre-existing dep)" \
  || no "false positives" "$fp — $OUT"
[ "$(jqo '[.scanners[].name] | join(",")')" = "js-imports,py-imports,unused-deps" ] \
  && ok "JSON reports each check by name" || no "check names" "$OUT"

# ── exit 0: clean files ───────────────────────────────────────────────────────
run --json --paths src/util.ts mypkg/b.py
[ "$RC" -eq 0 ] && [ "$(jqo '[.scanners[].status] | join(",")')" = "ran,ran" ] \
  && ok "clean files → exit 0, status ran" || no "clean" "rc=$RC $OUT"

# ── --paths with `--`, leading-dash file, human output ────────────────────────
run --paths -- "dir with space/-dash.js"
{ [ "$RC" -eq 1 ] && printf '%s' "$OUT" | grep -qF "dir with space/-dash.js:2 [js-unresolved-relative]"; } \
  && ok "--paths -- <dash-led spaced file>: human output line" || no "--paths --" "rc=$RC $OUT"

# ── exit 3: nothing to check ──────────────────────────────────────────────────
printf '# readme\n' > "$G/README.md"
run --json --paths README.md
[ "$RC" -eq 3 ] && ok "no JS/TS/Python or manifests in scope → exit 3" || no "exit 3" "rc=$RC $OUT"

# ── exit 4: Python files in scope but no interpreter ──────────────────────────
OUT="$(cd "$G" && PYTHON=/nonexistent/python3 bash "$CHECK" --json --paths mypkg/a.py 2>"$T/stderr")"; RC=$?
[ "$RC" -eq 4 ] && [ "$(jqo '.scanners[0].status')" = "error" ] \
  && ok "python missing → py-imports error, exit 4" || no "exit 4" "rc=$RC $OUT"

# ── exit 2: usage errors ──────────────────────────────────────────────────────
run --bogus
[ "$RC" -eq 2 ] && ok "unknown flag → exit 2" || no "unknown flag" "rc=$RC"
run --base no-such-ref
[ "$RC" -eq 2 ] && ok "unresolvable --base → exit 2" || no "bad base" "rc=$RC"
run --base --output=/tmp/x
[ "$RC" -eq 2 ] && ok "dash-led --base ref rejected → exit 2" || no "dash base" "rc=$RC"

# ── --paths: missing entry → exit 2; directory expands ────────────────────────
run --json --paths src/app.ts src/typo.ts
{ [ "$RC" -eq 2 ] && grep -q 'does not exist: src/typo.ts' "$T/stderr"; } \
  && ok "--paths typo → exit 2 (never a silent clean)" || no "--paths missing" "rc=$RC $(cat "$T/stderr")"

# ── @types satisfies a type-only import (and only a type-only one) ────────────
mkdir -p "$G/typed"
cat > "$G/typed/package.json" <<'EOF'
{ "name": "typed", "devDependencies": { "@types/only-types": "1.0.0", "@types/scope__pkg": "1.0.0" } }
EOF
cat > "$G/typed/x.ts" <<'EOF'
import type { T } from 'only-types';
import type { S } from '@scope/pkg';
import { v } from 'only-types';
export type { U } from 'only-types';
EOF
run --json --paths typed
{ [ "$RC" -eq 1 ] && has js-undeclared-package typed/x.ts 3 "'only-types'" \
  && [ "$(jqo '[.scanners[].findings[]] | length')" = "1" ]; } \
  && ok "--paths <dir>: @types/x satisfies type-only imports; value import still flagged" \
  || no "@types" "rc=$RC $OUT"

# ── symlinks: never followed out of the repo ──────────────────────────────────
mkdir -p "$T/outside"; printf "import x from './nope';\n" > "$T/outside/evil.ts"
ln -s "$T/outside/evil.ts" "$G/escape.ts"
run --json --paths escape.ts
{ [ "$RC" -eq 3 ] && [ "$(jqo '.skipped[0] | "\(.path)|\(.reason)"')" = "escape.ts|resolves outside the repo root" ]; } \
  && ok "symlink outside the repo is skipped and reported, never read" || no "symlink escape" "rc=$RC $OUT"
rm -f "$G/escape.ts"

# ── PYTHONPATH honored explicitly; -I still blocks repo sitecustomize ─────────
mkdir -p "$T/pp"; printf 'X = 1\n' > "$T/pp/extmod_on_pythonpath.py"
printf 'import extmod_on_pythonpath\n' > "$G/uses_pp.py"
printf 'import pathlib\npathlib.Path(%s).write_text("ran")\n' "'$T/sitecustomize-ran'" > "$G/sitecustomize.py"
run --json --paths uses_pp.py
{ [ "$RC" -eq 1 ] && has py-unresolved-module uses_pp.py 1 "'extmod_on_pythonpath'"; } \
  && ok "module only on PYTHONPATH is flagged when PYTHONPATH is unset" || no "pp unset" "rc=$RC $OUT"
OUT="$(cd "$G" && PYTHONPATH="$T/pp" bash "$CHECK" --json --paths uses_pp.py 2>"$T/stderr")"; RC=$?
[ "$RC" -eq 0 ] && ok "PYTHONPATH entries are added to sys.path by the helper" || no "pp set" "rc=$RC $OUT"
[ ! -e "$T/sitecustomize-ran" ] && ok "python -I kept: repo sitecustomize.py never executed" \
  || no "sitecustomize" "repo sitecustomize.py ran"
rm -f "$G/uses_pp.py" "$G/sitecustomize.py"

# ── Python helper failure → exit 4 with a JSON reason (not a bare exit 1) ─────
printf '#!/bin/sh\necho "helper exploded" >&2\nexit 3\n' > "$T/badpython"; chmod +x "$T/badpython"
OUT="$(cd "$G" && PYTHON="$T/badpython" bash "$CHECK" --json --paths mypkg/a.py 2>"$T/stderr")"; RC=$?
{ [ "$RC" -eq 4 ] && jqo '.scanners[0].reason' | grep -q 'helper exploded'; } \
  && ok "Python helper failure → error status with reason, exit 4" || no "helper failure" "rc=$RC out=$OUT"

# ── ancestor package.json symlinked outside the repo is never trusted ─────────
mkdir -p "$G/lnk"
printf '{ "name": "outside", "dependencies": { "evil-dep": "1.0.0" } }\n' > "$T/outside/pkg.json"
ln -s ../../outside/pkg.json "$G/lnk/package.json"
printf "import e from 'evil-dep';\n" > "$G/lnk/a.ts"
run --json --paths lnk/a.ts
{ [ "$RC" -eq 1 ] && has js-undeclared-package lnk/a.ts 1 "'evil-dep'" \
  && [ "$(jqo '.skipped[] | select(.path=="lnk/package.json") | .reason')" = "manifest resolves outside the repo root" ]; } \
  && ok "symlinked ancestor package.json outside the repo is ignored and reported" || no "ancestor manifest" "rc=$RC $OUT"
rm -rf "$G/lnk"

# ── import specifiers pointing outside the root: findings, never stat'ed ──────
mkdir -p "$G/esc"
cat > "$G/esc/b.ts" <<'EOF'
import h from '/etc/hosts';
import p from '../../../../../../../../../../etc/passwd';
EOF
printf 'from ........................ import x\n' > "$G/esc/c.py"
run --json --paths esc
{ [ "$RC" -eq 1 ] && has js-import-outside-root esc/b.ts 1 "'/etc/hosts'" \
  && has js-import-outside-root esc/b.ts 2 "etc/passwd" \
  && has py-import-outside-root esc/c.py 1 "'........................'"; } \
  && ok "absolute / climbing imports outside the root → *-import-outside-root findings" || no "outside-root imports" "rc=$RC $OUT"
rm -rf "$G/esc"

# ── text output: control characters escaped, no line can start with `::` ─────
EVILNAME="$(printf 'evil\n::error::pwned\033[31m.js')"
printf "require('./nope');\n" > "$G/$EVILNAME"
run --paths "$EVILNAME"
esc_byte="$(printf '\033')"
{ [ "$RC" -eq 1 ] \
  && ! printf '%s\n' "$OUT" | grep -q '^::' \
  && [ "$(printf '%s\n' "$OUT" | grep -vc '^check-imports: ')" = "0" ] \
  && ! printf '%s' "$OUT" | grep -qF "$esc_byte" \
  && printf '%s' "$OUT" | grep -qF 'evil\x0a::error::pwned\x1b[31m.js:1'; } \
  && ok "text output escapes newline/ESC in repo paths and prefixes every line" \
  || no "text escaping" "rc=$RC out=$(printf '%s' "$OUT" | od -c | head -5)"
rm -f "$G/$EVILNAME"

# ── scripts/check-imports.sh wrapper execs the shipped check ──────────────────
printf "require('./nope');\n" > "$G/wrapped.js"
OUT="$(cd "$G" && bash "$WRAPPER" --json --paths wrapped.js 2>"$T/stderr")"; RC=$?
{ [ "$RC" -eq 1 ] && has js-unresolved-relative wrapped.js 1 "'./nope'"; } \
  && ok "scripts/check-imports.sh wrapper execs the shipped check" || no "wrapper" "rc=$RC $OUT $(cat "$T/stderr")"
rm -f "$G/wrapped.js"

echo ""
echo "check-imports-test: $P passed, $F failed."
[ "$F" -eq 0 ]

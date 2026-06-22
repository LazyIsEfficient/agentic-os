#!/usr/bin/env bash
# block-bad-bash-test-cursor.sh — deterministic test of Cursor block-bad-bash hook.
# Mirrors .claude/hooks/block-bad-bash.sh rules using beforeShellExecution JSON stdin.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOK="$REPO/.cursor/hooks/block-bad-bash.sh"
P=0; F=0
ok(){ printf 'PASS  %s\n' "$1"; P=$((P+1)); }
no(){ printf 'FAIL  %s — %s\n' "$1" "$2"; F=$((F+1)); }
run(){ printf '%s' "{\"command\":\"$1\",\"cwd\":\"$REPO\",\"sandbox\":false}" | bash "$HOOK"; }

perm_allow(){ printf '%s' "$1" | grep -Eq '"permission"[[:space:]]*:[[:space:]]*"allow"'; }
perm_deny(){ printf '%s' "$1" | grep -Eq '"permission"[[:space:]]*:[[:space:]]*"deny"'; }

out="$(run 'git status')"
perm_allow "$out" && ok "allows plain git status" || no "plain git" "got: $out"

out="$(run 'cd src && ls')"
perm_allow "$out" && ok "allows single && chain" || no "single &&" "got: $out"

out="$(run 'cd repo && git status')"
perm_deny "$out" \
  && printf '%s' "$out" | grep -q 'block-bad-bash' \
  && ok "denies cd && git pattern" \
  || no "cd && git" "got: $out"

out="$(run 'npm install && npm test && npm run build')"
perm_deny "$out" \
  && printf '%s' "$out" | grep -q 'block-bad-bash' \
  && ok "denies 3+ command && chain" \
  || no "long && chain" "got: $out"

out="$(run 'echo \"a && b && c\"')"
perm_deny "$out" \
  && ok "counts && literally (quoted false-positive accepted)" \
  || no "literal && count" "got: $out"

for c in "ls -la" "cargo build --release" "docker ps" "git -C src status"; do
  out="$(run "$c")"
  if perm_deny "$out"; then
    no "false-positive: $c" "got: $out"
  else
    ok "no false-positive: $c"
  fi
done

out="$(printf '%s' '{"command":"","cwd":"'"$REPO"'","sandbox":false}' | bash "$HOOK")"
perm_allow "$out" && ok "allows empty command" || no "empty command" "got: $out"

echo "block-bad-bash-test-cursor: $P passed, $F failed."
[ "$F" -eq 0 ]

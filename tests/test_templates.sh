#!/usr/bin/env bash
# Every template: `new <kind>` into a temp dir, build it when it has a Makefile, then run its
# Robot test headless (renode-test). Usage: tests/test_templates.sh [kind ...]
# `board` and `robot_test` need an ELF from outside and are covered by tests/test_smoke.sh.
set -uo pipefail
HERE=$(cd "$(dirname "$0")/.." && pwd -P)
R="$HERE/renode-box"
pass=0; failn=0
ok()  { printf 'ok    %s\n' "$*"; pass=$((pass+1)); }
bad() { printf 'FAIL  %s\n' "$*"; failn=$((failn+1)); }
# not "renode-*": Renode clears stale /tmp/renode-* folders when it starts
tmp=$(mktemp -d "${TMPDIR:-/tmp}/rbox-templates.XXXXXX")
cleanup() { [ "$BASHPID" = "$$" ] && command -v trash-put >/dev/null && trash-put -- "$tmp" 2>/dev/null; true; }
trap cleanup EXIT

kinds=("$@")
if [ ${#kinds[@]} -eq 0 ]; then
  for d in "$HERE"/templates/*/; do
    k=$(basename "$d")
    case "$k" in board|robot_test) ;; *) kinds+=("$k") ;; esac
  done
fi
for k in "${kinds[@]}"; do
  n="t_$k"; d="$tmp/$n"
  if ! "$R" new "$k" "$n" --dir "$tmp" >"$tmp/$k.new.log" 2>&1; then bad "$k: new"; continue; fi
  if [ -f "$d/Makefile" ] && ! "$R" run make -C "$d" -j4 >"$tmp/$k.make.log" 2>&1; then
    # Rust/Zig templates reach another ID's toolchain; without it they say "skip: needs ..."
    if grep -q '^skip: needs' "$tmp/$k.make.log"; then printf 'skip  %s: %s\n' "$k" "$(grep -m1 '^skip: needs' "$tmp/$k.make.log")"; continue; fi
    bad "$k: build"; tail -5 "$tmp/$k.make.log" | sed 's/^/      /'; continue
  fi
  if timeout 600 "$R" robot "$d/$n.robot" >"$tmp/$k.robot.log" 2>&1 </dev/null \
     && grep -q 'Tests finished successfully' "$tmp/$k.robot.log"; then
    ok "$k: new + build + robot ($(grep -c 'with status .*OK' "$tmp/$k.robot.log") tests)"
  else
    bad "$k: robot"; grep -E '║|failed' "$tmp/$k.robot.log" | head -8 | sed 's/^/      /'
  fi
done
echo "templates: $pass ok, $failn failed"
[ "$failn" -eq 0 ]

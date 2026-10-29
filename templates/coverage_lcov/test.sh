#!/usr/bin/env bash
# @NAME@ coverage run: Robot tests (one trace each) -> renode-retracer .info per test -> info-process merge ->
# per-file summary with checks -> Coverview archive (+ standalone page when the coverview add-on is installed).
# Run: ./renode-box run bash <dir>/@NAME@/test.sh   (after ./renode-box run make -C <dir>/@NAME@)
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd -P)
: "${RENODE_BOX_ROOT:?run through ./renode-box run}"
R=$RENODE_BOX_ROOT/renode-box
o=$here/build/cov
mkdir -p "$o"
for t in led count; do [ -e "$o/$t.bin.gz" ] && mv -f "$o/$t.bin.gz" "$o/$t.bin.gz.prev"; done
"$R" robot "$here/@NAME@.robot" >"$o/robot.log" 2>&1 </dev/null || { tail -20 "$o/robot.log"; exit 1; }
for t in led count; do "$R" covflow info --elf "$here/build/@NAME@.elf" --name "$t" -o "$o/$t.info" "$o/$t.bin.gz"; done
"$R" covflow merge -o "$o/merged.info" "$o/led.info" "$o/count.info"
# every handler the tests drive is hit, cmd_reset is not (no test sends 'r'): add a test, watch it turn green
"$R" covflow summary "$o/merged.info" --only main.c --hit 'main.c:led toggled' --hit 'main.c:"count "' \
  --hit 'main.c:unknown command' --miss 'main.c:reset requested' --min 'main.c:80'
"$R" covflow pack -o "$o/coverage.zip" --title "@NAME@ (Renode trace)" --desc "$o/merged.desc" "$o/merged.info"
if [ -r "$RENODE_BOX_ROOT/install/coverview/index.html" ]; then "$R" covflow html "$o/coverage.zip" -o "$o/coverage.html"; fi
echo "@NAME@: coverage in $o (merged.info, merged.desc, coverage.zip; coverage.html with the coverview add-on)"

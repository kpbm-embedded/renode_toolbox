#!/usr/bin/env bash
# about: line coverage without gcov: Robot test cases -> binary traces -> renode-retracer LCOV .info -> info-process merge -> Coverview (BlackPill F411)
# shellcheck disable=SC2119  # ex_make takes optional make arguments
# Usage (via ./renode-box examples): build | run | test
# shellcheck source-path=SCRIPTDIR source=../fw/ex.sh
. "$(dirname "$0")/../fw/ex.sh"
covflow() { python "$RENODE_BOX_ROOT/lib/covflow.py" "$@"; }
check() {
  local o=$EX_OUT t
  for t in led status; do [ -e "$o/trace_$t.bin.gz" ] && mv -f "$o/trace_$t.bin.gz" "$o/trace_$t.bin.gz.prev"; done
  ex_robot test.robot
  for t in led status; do
    covflow info --elf "$o/cov_demo.elf" --name "$t" -o "$o/$t.info" "$o/trace_$t.bin.gz"
  done
  covflow merge -o "$o/merged.info" "$o/led.info" "$o/status.info"
  # per run: only its own handler; merged: both; never: cmd_reset
  covflow summary "$o/led.info" --only main.c --hit 'main.c:led toggled' --miss 'main.c:status ok'
  covflow summary "$o/status.info" --only main.c --hit 'main.c:status ok' --hit 'main.c:unknown command' --miss 'main.c:led toggled'
  covflow summary "$o/merged.info" --only main.c --hit 'main.c:led toggled' --hit 'main.c:status ok' \
    --miss 'main.c:reset requested' --min 'main.c:85'
  grep -q 'led' "$o/merged.desc" || { echo "FAIL: merged.desc lists no test names"; return 1; }
  covflow pack -o "$o/coverage.zip" --title "cov_demo (BlackPill F411, Renode)" --desc "$o/merged.desc" "$o/merged.info"
  if [ -r "$RENODE_BOX_ROOT/install/coverview/index.html" ]; then
    covflow html "$o/coverage.zip" -o "$o/coverage.html"
    grep -q embeddedZipArchive "$o/coverage.html" || { echo "FAIL: no data in coverage.html"; return 1; }
  else echo "note: Coverview not installed (./renode-box extras install coverview): no coverage.html"; fi
}
case "${1:-run}" in
  build) ex_make ;;
  run)   ex_make >/dev/null; ex_renode "$EX_DIR/cov.resc" ;;
  test)  ex_make; check ;;
  *) echo "usage: example.sh build|run|test" >&2; exit 2 ;;
esac

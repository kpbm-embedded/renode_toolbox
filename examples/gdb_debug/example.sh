#!/usr/bin/env bash
# about: GDB debugging on the BlackPill F411 model: Renode GDB server + arm-none-eabi-gdb batch (break, read, write)
# shellcheck disable=SC2119  # ex_make takes optional make arguments
# Usage (via ./renode-box examples): build | run | test
# run opens the GDB server on port 3333; connect with:
#   ./renode-box run arm-none-eabi-gdb <build>/examples/gdb_debug/gdb_demo.elf -ex 'target remote :3333'
# shellcheck source-path=SCRIPTDIR source=../fw/ex.sh
. "$(dirname "$0")/../fw/ex.sh"
check() {
  local port log=$EX_OUT/renode.log out=$EX_OUT/gdb.log
  port=$(ex_free_port)
  ex_renode_bg "$log" "\$gdb_port=$port; include @$EX_DIR/gdb_demo.resc"
  trap ex_renode_stop EXIT
  ex_wait_port "$port" 60
  timeout 120 arm-none-eabi-gdb -q -batch -nx -ex "target remote :$port" -x "$EX_DIR/check.gdb" \
    "$EX_OUT/gdb_demo.elf" >"$out" 2>&1 </dev/null || true
  cat "$out"
  grep -q 'Breakpoint 1, filter_step' "$out" || { echo "FAIL: breakpoint not hit"; return 1; }
  local first third before in after
  first=$(sed -n 's/^first=//p' "$out"); third=$(sed -n 's/^third=//p' "$out")
  before=$(sed -n 's/^before=//p' "$out"); in=$(sed -n 's/^in=//p' "$out")
  after=$(sed -n 's/^after=\([-0-9]*\) gain=100$/\1/p' "$out")
  [ -n "$first" ] && [ "$third" = $((first + 2)) ] || { echo "FAIL: steps $first -> $third, expected +2"; return 1; }
  # one more step ran with the gain gdb wrote: acc grows by 100 * in
  [ -n "$after" ] && [ "$after" = $((before + 100 * in)) ] || { echo "FAIL: acc $before -> $after with in=$in, gain write had no effect"; return 1; }
  echo "gdb check passed (steps $first -> $third, acc $before -> $after)"
}
case "${1:-run}" in
  build) ex_make ;;
  run)   ex_make >/dev/null; ex_renode "$EX_DIR/gdb_demo.resc" ;;
  test)  ex_make; check ;;
  *) echo "usage: example.sh build|run|test" >&2; exit 2 ;;
esac

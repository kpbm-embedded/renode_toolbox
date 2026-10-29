#!/usr/bin/env bash
# about: Zephyr line coverage from a Renode trace (no gcov): 32_03's ztest-basic on riscv32_virtual -O0 -> retracer -> .info, compared with 32_03's gcov report
# Usage (via ./renode-box examples): build | run | test. Needs 32_03_zephyr ($BOX_ZEPHYR or the sibling folder);
# exits 3 (skip) without it. 32_03's tree is not changed: the build goes to EX_OUT with an extra conf file.
# shellcheck source-path=SCRIPTDIR source=../fw/ex.sh
. "$(dirname "$0")/../fw/ex.sh"
zephyr_id() { # 32_03's folder: $BOX_ZEPHYR (it may point at toolchain/zephyr inside the ID), else the sibling
  local d
  for d in "${BOX_ZEPHYR:-}" "${BOX_ZEPHYR:-}/../.." "$RENODE_BOX_ROOT/../32_03_zephyr"; do
    [ -n "$d" ] && [ -x "$d/scripts/app" ] && { (cd "$d" && pwd -P); return 0; }
  done
  echo "skip: needs 32_03_zephyr (scripts/app) for the Zephyr build: set BOX_ZEPHYR or put the ID next to 32_06_renode" >&2
  exit 3
}
ZID=$(zephyr_id)
ELF=$EX_OUT/zephyr/examples/ztest-basic/riscv32_virtual/zephyr/zephyr.elf
board_resc() { # the board's Renode script from the Zephyr tree 32_03 uses
  local r
  r="$("$ZID/scripts/app" where | awk '$1=="zephyr_base" {print $2}')/boards/renode/riscv32_virtual/support/riscv32_virtual.resc"
  [ -r "$r" ] || r=""
  [ -n "$r" ] || { echo "FAIL: riscv32_virtual.resc not found in 32_03's Zephyr tree" >&2; exit 1; }
  printf '%s' "$r"
}
build() { # 32_03's own launcher, output and extra config redirected here (its tree stays untouched)
  ZEPHYR_OUT="$EX_OUT/zephyr" EXTRA_CONF_FILE="$EX_DIR/coverage.conf" "$ZID/scripts/app" example ztest-basic riscv32_virtual
  grep -q '^CONFIG_NO_OPTIMIZATIONS=y' "$EX_OUT/zephyr/examples/ztest-basic/riscv32_virtual/zephyr/.config"
}
covflow() { python "$RENODE_BOX_ROOT/lib/covflow.py" "$@"; }
check() {
  local o=$EX_OUT gcov
  [ -e "$o/ztest.bin.gz" ] && mv -f "$o/ztest.bin.gz" "$o/ztest.bin.gz.prev"
  ex_robot test.robot --variable "BOARD_RESC:$(board_resc)"
  covflow info --elf "$ELF" --name ztest-basic -o "$o/ztest.info" "$o/ztest.bin.gz"
  echo "== whole image (Zephyr kernel, libc, arch, the test) =="
  covflow summary "$o/ztest.info" --json "$o/summary.json" | tail -1
  echo "== the test's own sources =="
  covflow summary "$o/ztest.info" --only ztest-basic/src/ \
    --min 'src/fifo.c:100' --min 'src/test_fifo.c:97' --hit 'src/fifo.c:return' --hit 'test_fifo.c:ztest_test_skip'
  gcov=$(env -u ZEPHYR_OUT "$ZID/scripts/app" where | awk '$1=="output" {print $2}')/twister/ztest-basic/qemu_riscv32/coverage/coverage.txt
  if [ -r "$gcov" ]; then echo "== 32_03 gcov (qemu_riscv32, scripts/app ztest ztest-basic qemu_riscv32 --coverage) =="; grep -E 'fifo.c|^ +[0-9]|TOTAL' "$gcov"
  else echo "note: no 32_03 gcov report found (run its: scripts/app ztest ztest-basic qemu_riscv32 --coverage)"; fi
  covflow pack -o "$o/coverage.zip" --title "ztest-basic on riscv32_virtual (Renode trace)" "$o/ztest.info"
  if [ -r "$RENODE_BOX_ROOT/install/coverview/index.html" ]; then covflow html "$o/coverage.zip" -o "$o/coverage.html"; fi
}
case "${1:-run}" in
  build) build ;;
  run)   [ -r "$ELF" ] || build >/dev/null; RENODE_BOX_CONSOLE=1 "$RENODE_DIR/renode" --config "$RENODE_CONFIG" --console --disable-gui \
           -e "\$elf=@$ELF; include @$(board_resc); start" ;;
  test)  build; check ;;
  *) echo "usage: example.sh build|run|test" >&2; exit 2 ;;
esac

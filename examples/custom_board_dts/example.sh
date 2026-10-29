#!/usr/bin/env bash
# about: custom board from a devicetree: weact_h743.dts -> dts2repl -> .repl -> STM32H743 firmware + test
# shellcheck disable=SC2119  # ex_make takes optional make arguments
# Usage (via ./renode-box examples): build | run | test
# shellcheck source-path=SCRIPTDIR source=../fw/ex.sh
. "$(dirname "$0")/../fw/ex.sh"
gen() {
  dts2repl "$EX_DIR/weact_h743.dts" -o "$EX_OUT/weact_h743.repl" 2> >(grep -v 'Skipping duplicated block' >&2)
  echo "generated $EX_OUT/weact_h743.repl ($(grep -c ': ' "$EX_OUT/weact_h743.repl") lines with peripherals)"
}
case "${1:-run}" in
  build) gen; ex_make ;;
  run)   gen >/dev/null; ex_make >/dev/null; ex_renode "$EX_DIR/weact_h743.resc" ;;
  test)  gen; ex_make; ex_robot "$EX_DIR/test.robot" ;;
  *) echo "usage: example.sh build|run|test" >&2; exit 2 ;;
esac

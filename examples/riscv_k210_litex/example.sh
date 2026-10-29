#!/usr/bin/env bash
# about: RISC-V bare-metal on Kendryte K210 (rv64, owned board) and LiteX VexRiscv (rv32)
# shellcheck disable=SC2119  # ex_make takes optional make arguments
# Usage (via ./renode-box examples): build | run [k210|litex] | test
# shellcheck source-path=SCRIPTDIR source=../fw/ex.sh
. "$(dirname "$0")/../fw/ex.sh"
case "${1:-run}" in
  build) ex_make BOARD=k210; ex_make BOARD=litex ;;
  run)   b=${2:-k210}; ex_make BOARD="$b" >/dev/null; ex_renode "$EX_DIR/$b.resc" ;;
  test)  ex_make BOARD=k210; ex_make BOARD=litex; ex_robot "$EX_DIR/test.robot" ;;
  *) echo "usage: example.sh build|run [k210|litex]|test" >&2; exit 2 ;;
esac

#!/usr/bin/env bash
# about: FreeRTOS V11.3.2 on the BlackPill F411 model: tasks + queue + timer, LED timing checked
# shellcheck disable=SC2119  # ex_make takes optional make arguments
# Usage (via ./renode-box examples): build | run | test
# shellcheck source-path=SCRIPTDIR source=../fw/ex.sh
. "$(dirname "$0")/../fw/ex.sh"
case "${1:-run}" in
  build) ex_make ;;
  run)   ex_make >/dev/null; ex_renode "$EX_DIR/blackpill_f411.resc" ;;
  test)  ex_make; ex_robot "$EX_DIR/test.robot" ;;
  *) echo "usage: example.sh build|run|test" >&2; exit 2 ;;
esac

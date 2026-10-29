#!/usr/bin/env bash
# about: two BlackPill F411 machines in one emulation, USART2 <-> USART2 through a UART hub (ping/pong, disconnect)
# Usage (via ./renode-box examples): build | run | test
# shellcheck source-path=SCRIPTDIR source=../fw/ex.sh
. "$(dirname "$0")/../fw/ex.sh"
build() { ex_make ROLE=ping; ex_make ROLE=pong; }
case "${1:-run}" in
  build) build ;;
  run)   build >/dev/null; ex_renode "$EX_DIR/two_nodes.resc" ;;
  test)  build; ex_robot "$EX_DIR/test.robot" ;;
  *) echo "usage: example.sh build|run|test" >&2; exit 2 ;;
esac

#!/usr/bin/env bash
# about: nRF52840 nice!nano: bare-metal UART echo + LED P0.15, and the prebuilt Zephyr shell (offline)
# shellcheck disable=SC2119  # ex_make takes optional make arguments
# Usage (via ./renode-box examples): build | run [zephyr] | test
# shellcheck source-path=SCRIPTDIR source=../fw/ex.sh
. "$(dirname "$0")/../fw/ex.sh"
ZEPHYR_SHELL=zephyr_shell_nrf52840.elf-s_1110556-9653ab7fffe1427c50fa6b837e55edab38925681
case "${1:-run}" in
  build) ex_make ;;
  run)
    ex_make >/dev/null
    if [ "${2:-}" = zephyr ]; then ex_renode "$EX_DIR/nicenano.resc" -e "\$elf=@$RENODE_BOX_DEMOS/$ZEPHYR_SHELL"
    else ex_renode "$EX_DIR/nicenano.resc"; fi ;;
  test)  ex_make; ex_robot "$EX_DIR/test.robot" ;;
  *) echo "usage: example.sh build|run [zephyr]|test" >&2; exit 2 ;;
esac

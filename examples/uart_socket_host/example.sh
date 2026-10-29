#!/usr/bin/env bash
# about: nRF52840 UART on a TCP socket (server socket terminal): a host Python client talks to the firmware
# Usage (via ./renode-box examples): build | run [port] | test
# Builds the nice!nano echo firmware of ../nrf52840_nicenano into this example's output.
# shellcheck source-path=SCRIPTDIR source=../fw/ex.sh
. "$(dirname "$0")/../fw/ex.sh"
build() { make --no-print-directory -C "$EX_DIR/../nrf52840_nicenano" FW="$FW_DIR" OUT="$EX_OUT"; }
check() {
  local port; port=$(ex_free_port)
  ex_renode_bg "$EX_OUT/renode.log" "\$port=$port; include @$EX_DIR/socket.resc; start"
  trap ex_renode_stop EXIT
  ex_wait_port "$port" 60
  timeout 120 python "$EX_DIR/host_client.py" "$port"
}
case "${1:-run}" in
  build) build ;;
  run)   build >/dev/null; echo "UART on tcp port ${2:-3456}: e.g. telnet 127.0.0.1 ${2:-3456}"
         ex_renode "$EX_DIR/socket.resc" -e "\$port=${2:-3456}" ;;
  test)  build; check ;;
  *) echo "usage: example.sh build|run [port]|test" >&2; exit 2 ;;
esac

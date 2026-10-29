#!/usr/bin/env bash
# about: external control API (C, Renode 1.17): a host program steps virtual time, watches the LED GPIO, drives KEY and reads registers on the BlackPill F411 model
# Usage (via ./renode-box examples): build | run | test. The client library is Renode's own
# (install/renode/tools/external_control_client, MIT); it is compiled with the host C compiler ($CC or cc;
# exits 3 when there is none: this ID pins only cross compilers).
# shellcheck source-path=SCRIPTDIR source=../fw/ex.sh
. "$(dirname "$0")/../fw/ex.sh"
BP_OUT=$(dirname "$EX_OUT")/stm32f4_blackpill
API=$RENODE_DIR/tools/external_control_client
CC=${CC:-cc}
build() {
  command -v "$CC" >/dev/null || { echo "skip: needs a host C compiler (set CC)" >&2; exit 3; }
  make --no-print-directory -C "$EX_DIR/../stm32f4_blackpill" -j"${BOXT_JOBS:-4}" FW="$FW_DIR" OUT="$BP_OUT"
  "$CC" -O1 -g -Wall -Wextra -Werror -fno-strict-aliasing -I"$API/include" -I"$API/lib" \
    "$EX_DIR/hil_client.c" "$API"/lib/*.c -lpthread -o "$EX_OUT/hil_client"
}
check() {
  local port rc=0
  port=$(ex_free_port); rm -f "$EX_OUT/usart1.txt"
  # the emulation is not started: the client advances time with renode_run_for
  ex_renode_bg "$EX_OUT/renode.log" "\$ex_dir=@$EX_DIR/../stm32f4_blackpill; \$ex_out=@$BP_OUT; include @$EX_DIR/../stm32f4_blackpill/blackpill_f411.resc; sysbus.usart1 CreateFileBackend @$EX_OUT/usart1.txt true; emulation CreateExternalControlServer \"ec\" $port"
  trap ex_renode_stop EXIT
  # wait for the server's log line, not with a probe connection (a client that connects and drops without the
  # handshake makes the 1.17 server shut the emulation down)
  local i; for ((i = 0; i < 240; i++)); do grep -q "ec: Listening for connections" "$EX_OUT/renode.log" 2>/dev/null && break; sleep 0.25; done
  timeout 120 "$EX_OUT/hil_client" "$port" || rc=1
  if grep -q "Hello from BlackPill F411" "$EX_OUT/usart1.txt"; then echo "ok    banner on USART1 (file backend)"; else echo "FAIL  no banner"; rc=1; fi
  if grep -q "KEY pressed" "$EX_OUT/usart1.txt"; then echo "ok    KEY pin driven by the client seen by the firmware"; else echo "FAIL  no KEY pressed"; rc=1; fi
  ex_renode_stop; trap - EXIT
  return $rc
}
case "${1:-run}" in
  build) build ;;
  run)   build >/dev/null; check ;;
  test)  build; check ;;
  *) echo "usage: example.sh build|run|test" >&2; exit 2 ;;
esac

#!/usr/bin/env bash
# @NAME@ self-test: start Renode in server mode (headless; listens on all interfaces, like every 1.17 server) on a free port, run @NAME@.py against it with the cached Zephyr
# shell for nRF52840 (offline), stop the server. Run: ./renode-box run bash <dir>/@NAME@/test.sh
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd -P)
: "${RENODE:?run through ./renode-box run}" "${RENODE_BOX_DEMOS:?}"
elf=$(find "$RENODE_BOX_DEMOS" -maxdepth 1 -name 'zephyr_shell_nrf52840.elf-*' | head -1)
[ -n "$elf" ] || { echo "skip: the cached Zephyr shell demo is missing (./renode-box install)" >&2; exit 3; }
port=$(python -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1",0)); print(s.getsockname()[1])')
log=$(mktemp "${TMPDIR:-/tmp}/srv-@NAME@.XXXXXX")
"$RENODE" --server-mode --server-mode-port "$port" --plain >"$log" 2>&1 </dev/null &
pid=$!
trap 'kill $pid 2>/dev/null; wait $pid 2>/dev/null; rm -f "$log"' EXIT
for _ in $(seq 1 120); do
  python "$RENODE_BOX_ROOT/lib/ws_client.py" --port "$port" --timeout 5 status >/dev/null 2>&1 && break
  sleep 0.25
done
# the prebuilt shell image needs the legacy UART model (@NAME@.repl)
python "$here/@NAME@.py" --port "$port" --repl "$here/@NAME@.repl" --elf "$elf" --uart sysbus.uart0 \
  --expect "uart:~\$" --clear
echo "@NAME@: server-mode client test passed"

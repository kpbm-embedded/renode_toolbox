#!/usr/bin/env bash
# about: Renode 1.17 server mode: built-in WebSocket API (what renode --ui, System Designer and the VS Code extension use), driven headless from Python
# Usage (via ./renode-box examples): build | run | test. `run` starts the server on 21234 for a GUI client
# (renode-box ui, System Designer "Run locally", VS Code extension); `test` needs no display.
# shellcheck source-path=SCRIPTDIR source=../fw/ex.sh
. "$(dirname "$0")/../fw/ex.sh"
BP_OUT=$(dirname "$EX_OUT")/stm32f4_blackpill
build() { make --no-print-directory -C "$EX_DIR/../stm32f4_blackpill" -j"${BOXT_JOBS:-4}" FW="$FW_DIR" OUT="$BP_OUT"; }
check() {
  local port rc=0 i
  port=$(ex_free_port)
  mkdir -p "$EX_OUT/work"; rm -f "$EX_OUT/usart1.txt"
  "$RENODE_DIR/renode" --server-mode --server-mode-port "$port" --server-mode-work-dir "$EX_OUT/work" \
    --config "$RENODE_CONFIG" --plain >"$EX_OUT/renode.log" 2>&1 </dev/null &
  EX_RENODE_PID=$!
  trap ex_renode_stop EXIT
  ex_wait_port "$port" 60
  for ((i = 0; i < 40; i++)); do   # the HTTP listener comes up a moment before the WebSocket endpoint
    python "$RENODE_BOX_ROOT/lib/ws_client.py" --port "$port" --timeout 5 status >/dev/null 2>&1 && break; sleep 0.25
  done
  timeout 120 python "$EX_DIR/api_test.py" "$port" "$EX_DIR" "$BP_OUT" "$EX_OUT" || rc=1
  # 1.17 binds every interface (no option): report it so nobody is surprised
  if command -v ss >/dev/null; then ss -ltn 2>/dev/null | awk -v p=":$port" '$4 ~ p"$" {print "listening on " $4 " (all interfaces: firewall it on untrusted networks)"}'; fi
  ex_renode_stop; trap - EXIT
  return $rc
}
case "${1:-run}" in
  build) build ;;
  run)   build >/dev/null; echo "server mode on ws://localhost:21234/proxy; connect renode-ui, System Designer or VS Code; Ctrl-C stops"
         exec "$RENODE_DIR/renode" --server-mode --server-mode-port 21234 --config "$RENODE_CONFIG" ;;
  test)  build; check ;;
  *) echo "usage: example.sh build|run|test" >&2; exit 2 ;;
esac

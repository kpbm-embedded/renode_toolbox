#!/usr/bin/env bash
# about: experimental renode --ui (Neutralino renode-ui, shipped in Renode 1.17): the test starts it on a private virtual Wayland display (kwin_wayland --virtual) and checks that the UI connects to the server-mode API
# Usage (via ./renode-box examples): build | run | test. run opens the UI on your display with the BlackPill F411
# loaded. test needs GTK3 + WebKitGTK 4.1 and kwin_wayland or weston for the headless display (your desktop is not
# touched); exits 3 (skip) without them or when port 21234 is taken.
# shellcheck source-path=SCRIPTDIR source=../fw/ex.sh
. "$(dirname "$0")/../fw/ex.sh"
R=$RENODE_BOX_ROOT/renode-box
BP_OUT=$(dirname "$EX_OUT")/stm32f4_blackpill
PORT=21234   # renode --ui always serves here
UI_PAT="$(cd -P "$RENODE_DIR" && pwd -P)/platform-lib/[^ ]*/renode-ui"   # renode starts it by its real path
skip() { echo "skip: $*" >&2; exit 3; }
build() { make --no-print-directory -C "$EX_DIR/../stm32f4_blackpill" -j"${BOXT_JOBS:-4}" FW="$FW_DIR" OUT="$BP_OUT"; }
setup_cmds() { printf '%s' "\$ex_dir=@$EX_DIR/../stm32f4_blackpill; \$ex_out=@$BP_OUT; include @$EX_DIR/../stm32f4_blackpill/blackpill_f411.resc"; }
ui_pids=()
stop_all() { # the UI first (it aborts if the server goes away under it), then Renode with `quit` (a signal makes
  local p i  # the .NET runtime abort and dump core), then whatever is left in the process groups
  pkill -TERM -f "$UI_PAT" 2>/dev/null || true
  for ((i = 0; i < 20; i++)); do pgrep -f "$UI_PAT" >/dev/null || break; sleep 0.25; done
  python "$RENODE_BOX_ROOT/lib/ws_client.py" --port "$PORT" --timeout 5 monitor quit >/dev/null 2>&1 || true
  for ((i = 0; i < 20; i++)); do pgrep -f "$RENODE_DIR/renode --ui" >/dev/null || break; sleep 0.25; done
  for p in "${ui_pids[@]+"${ui_pids[@]}"}"; do kill -- "-$p" 2>/dev/null || true; done
  ui_pids=()
}
check() {
  local sock="rbox-ui-$$" i ok=0 conn=0 m
  [ -n "$(ls "$RENODE_DIR"/platform-lib/*/renode-ui 2>/dev/null)" ] || skip "renode-ui is not in this Renode package"
  ldd "$RENODE_DIR"/platform-lib/*/renode-ui | grep 'not found' >/dev/null && skip "renode-ui: system libraries missing (GTK3)"
  ldconfig -p 2>/dev/null | grep 'libwebkit2gtk-4\.[01]' >/dev/null || skip "renode-ui needs WebKitGTK 4.1 (or 4.0) from the system"
  if (exec 3<>"/dev/tcp/127.0.0.1/$PORT") 2>/dev/null; then skip "port $PORT is in use (another Renode server or UI)"; fi
  : "${XDG_RUNTIME_DIR:=/run/user/$(id -u)}"
  trap stop_all EXIT
  if command -v kwin_wayland >/dev/null; then
    setsid kwin_wayland --virtual --socket "$sock" --width 1280 --height 800 >"$EX_OUT/compositor.log" 2>&1 </dev/null &
  elif command -v weston >/dev/null; then
    setsid weston --backend=headless --socket="$sock" >"$EX_OUT/compositor.log" 2>&1 </dev/null &
  else skip "no headless Wayland compositor (kwin_wayland or weston) for the UI test; run: ./renode-box examples run renode_ui"; fi
  ui_pids+=($!)
  for ((i = 0; i < 40; i++)); do [ -S "$XDG_RUNTIME_DIR/$sock" ] && break; sleep 0.25; done
  [ -S "$XDG_RUNTIME_DIR/$sock" ] || { echo "FAIL: virtual display did not start (log: $EX_OUT/compositor.log)"; return 1; }
  WAYLAND_DISPLAY=$sock DISPLAY='' setsid "$R" ui >"$EX_OUT/ui.log" 2>&1 </dev/null &
  ui_pids+=($!)
  for ((i = 0; i < 240; i++)); do   # up to 60 s: Renode start, renode-ui start, page load, WebSocket connect
    pgrep -f "$UI_PAT" >/dev/null && ok=1
    conn=$(ss -Htn state established "( dport = :$PORT )" 2>/dev/null | wc -l)
    [ "$ok" = 1 ] && [ "$conn" -ge 1 ] && break
    sleep 0.25
  done
  if [ "$ok" = 1 ]; then echo "ok    renode-ui process running on the virtual display"; else echo "FAIL  renode-ui did not start (log: $EX_OUT/ui.log)"; return 1; fi
  if [ "$conn" -ge 1 ]; then echo "ok    the UI holds a WebSocket connection to ws://localhost:$PORT/proxy"; else echo "FAIL  the UI did not connect to port $PORT"; return 1; fi
  # a second client loads the BlackPill next to the UI (what the UI's own Monitor pane would do)
  m=$(python "$RENODE_BOX_ROOT/lib/ws_client.py" --port "$PORT" --timeout 30 monitor 'mach create "blackpill"' \
        "machine LoadPlatformDescription @$EX_DIR/../stm32f4_blackpill/blackpill_f411.repl" "sysbus LoadELF @$BP_OUT/blackpill_hello.elf" >"$EX_OUT/api.log" 2>&1 \
      && python "$RENODE_BOX_ROOT/lib/ws_client.py" --port "$PORT" --timeout 10 renode machines 2>&1) || { echo "FAIL  API: $m $(tail -3 "$EX_OUT/api.log")"; return 1; }
  if grep -q blackpill <<<"$m"; then echo "ok    the same server answers a second client: machines $(tr -d ' \n' <<<"$m")"
  else echo "FAIL  machine 'blackpill' not listed: $m"; return 1; fi
  ss -Hltn "( sport = :$PORT )" | awk '{print "note  listening on " $4 " (all interfaces)"}'
  stop_all; trap - EXIT
}
case "${1:-run}" in
  build) build ;;
  run)   build >/dev/null; exec "$R" ui -e "$(setup_cmds)" ;;
  test)  build; check ;;
  *) echo "usage: example.sh build|run|test" >&2; exit 2 ;;
esac

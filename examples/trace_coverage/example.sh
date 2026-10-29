#!/usr/bin/env bash
# about: execution tracing on the BlackPill F411 model: PC trace to a file, function coverage from the ELF (pyelftools)
# shellcheck disable=SC2119  # ex_make takes optional make arguments
# Usage (via ./renode-box examples): build | run | test
# shellcheck source-path=SCRIPTDIR source=../fw/ex.sh
. "$(dirname "$0")/../fw/ex.sh"
check() {
  local trace=$EX_OUT/trace.txt log=$EX_OUT/renode.log
  # Renode renames an existing trace file to trace.txt.1, .2, ...: keep only the previous run
  [ -e "$trace" ] && mv -f "$trace" "$trace.prev"
  # headless: boot for 10 ms, type "l", "s" and "x" on the UART, run 20 ms more, quit (output to a file, not a pipe)
  timeout 120 "$RENODE_DIR/renode" --config "$RENODE_CONFIG" --console --disable-gui --plain \
    -e "\$ex_dir=@$EX_DIR; \$ex_out=@$EX_OUT; \$trace=@$trace; include @$EX_DIR/trace.resc" \
    -e 'emulation RunFor "0.01"; usart1 WriteChar 0x6c; usart1 WriteChar 0x73; usart1 WriteChar 0x78' \
    -e 'emulation RunFor "0.02"; tracer Dispose; quit' >"$log" 2>&1 </dev/null || true
  [ -s "$trace" ] || { echo "FAIL: no trace written"; tail -5 "$log"; return 1; }
  python "$EX_DIR/coverage.py" "$EX_OUT/trace_demo.elf" "$trace" \
    --expect-hit main,cmd_led,cmd_status,cmd_unknown,Reset_Handler --expect-miss cmd_reset
}
case "${1:-run}" in
  build) ex_make ;;
  run)   ex_make >/dev/null; ex_renode "$EX_DIR/trace.resc" ;;
  test)  ex_make; check ;;
  *) echo "usage: example.sh build|run|test" >&2; exit 2 ;;
esac

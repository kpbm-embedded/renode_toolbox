#!/usr/bin/env bash
# Smoke test of the installed tools: Renode headless, renode-test, both GCCs, FreeRTOS,
# dts2repl, `new` templates (board from a DTS + robot test) on freshly built firmware, and every
# other template through tests/test_templates.sh (new + build + its Robot test; one line each).
# Usage: tests/test_smoke.sh
set -uo pipefail
HERE=$(cd "$(dirname "$0")/.." && pwd -P)
R="$HERE/renode-box"
pass=0; failn=0
ok()  { printf 'ok    %s\n' "$*"; pass=$((pass+1)); }
bad() { printf 'FAIL  %s\n' "$*"; failn=$((failn+1)); }
# not "renode-*": Renode clears stale /tmp/renode-* folders when it starts
tmp=$(mktemp -d "${TMPDIR:-/tmp}/rbox-smoke.XXXXXX")
cleanup() { # own temp dir, to the Trash; only in the main shell (not in $(...) subshells)
  [ "$BASHPID" = "$$" ] && command -v trash-put >/dev/null && trash-put -- "$tmp" 2>/dev/null; true
}
trap cleanup EXIT

# 1. Renode starts headless and runs monitor commands
# (output to files, not $(...): a Renode child keeping the pipe open would block the test)
if "$R" run timeout 120 renode --console --disable-gui --plain -e 'mach create "smoke"; machine LoadPlatformDescription @platforms/cpus/stm32f412.repl; peripherals; quit' >"$tmp/renode.log" 2>&1 </dev/null \
   && grep -q usart1 "$tmp/renode.log"; then ok "renode headless: stm32f412 platform loads"
else bad "renode headless"; tail -5 "$tmp/renode.log" | sed 's/^/      /'; fi

# 2. toolchains compile for the user's cores
printf 'int main(void){return 0;}\n' >"$tmp/t.c"
for t in "arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb -mfloat-abi=hard -mfpu=fpv4-sp-d16" \
         "arm-none-eabi-gcc -mcpu=cortex-m7 -mthumb" "arm-none-eabi-gcc -mcpu=cortex-m33 -mthumb" \
         "riscv-none-elf-gcc -march=rv32ec_zicsr -mabi=ilp32e" "riscv-none-elf-gcc -march=rv32imac_zicsr -mabi=ilp32" \
         "riscv-none-elf-gcc -march=rv64imafdc_zicsr -mabi=lp64d"; do
  # shellcheck disable=SC2086  # $t is a command line
  if "$R" run $t --specs=nosys.specs -O2 "$tmp/t.c" -o "$tmp/t.elf" >/dev/null 2>&1; then ok "compile: $t"
  else bad "compile: $t"; fi
done

# 3. templates: board from the example DTS + robot test, against the H743 example firmware
"$R" examples build custom_board_dts >/dev/null 2>&1 || true
elf=$("$R" where | awk '$1=="build"{print $2}')/examples/custom_board_dts/weact_h743_hello.elf
if "$R" new board smokeboard --dir "$tmp" --dts "$HERE/examples/custom_board_dts/weact_h743.dts" >/dev/null 2>&1 \
   && "$R" new robot_test smoketest --dir "$tmp" >/dev/null 2>&1; then ok "new board (--dts) + new robot_test"
else bad "new templates"; fi
if [ -r "$elf" ] && timeout 300 "$R" robot "$tmp/smoketest/smoketest.robot" --variable "RESC:$tmp/smokeboard/smokeboard.resc" \
     --variable "ELF:$elf" --exclude skipped >"$tmp/robot.log" 2>&1 </dev/null && grep -q 'Tests finished successfully' "$tmp/robot.log"; then
  ok "robot_test template on the generated board (uart + virtual time)"
else bad "robot_test template run"; grep -E 'FAIL|failed|Exception' "$tmp/robot.log" 2>/dev/null | head -5 | sed 's/^/      /'; fi

# 4. the other templates: new + make + robot, each counted on its own
bash "$HERE/tests/test_templates.sh" >"$tmp/templates.log" 2>&1
while IFS= read -r line; do
  case "$line" in
    "ok    "*) ok "template ${line#ok    }" ;;
    "FAIL  "*) bad "template ${line#FAIL  }" ;;
    "      "*) printf '%s\n' "$line" ;;
  esac
done <"$tmp/templates.log"
grep -q '^templates: ' "$tmp/templates.log" || bad "tests/test_templates.sh did not finish"

echo "smoke: $pass ok, $failn failed"
[ "$failn" -eq 0 ]

#!/usr/bin/env bash
# about: Zig firmware (32_24_microzig's Zig, reached not copied) on the nRF52840 model: host unit test + Renode test
# Usage (via ./renode-box examples): build | run | test
# Needs 32_24_microzig (microzig-box): $BOX_MICROZIG or the sibling folder; exits 3 when missing.
# shellcheck source-path=SCRIPTDIR source=../fw/ex.sh
. "$(dirname "$0")/../fw/ex.sh"
ZIG_FLAGS=(-target thumb-freestanding-eabihf -mcpu cortex_m4 -O ReleaseSmall -fentry=Reset_Handler)
build() {
  local zb; zb=$(ex_sibling_launcher 32_24_microzig BOX_MICROZIG microzig-box)
  (cd "$EX_DIR" && "$zb" zig build-exe main.zig "${ZIG_FLAGS[@]}" -T nrf52840.ld \
     --cache-dir "$EX_OUT/zig-cache" -femit-bin="$EX_OUT/zig_nrf52840.elf")
  arm-none-eabi-size "$EX_OUT/zig_nrf52840.elf"
}
unit() {
  local zb; zb=$(ex_sibling_launcher 32_24_microzig BOX_MICROZIG microzig-box)
  (cd "$EX_DIR" && "$zb" zig test logic.zig --cache-dir "$EX_OUT/zig-cache")
}
case "${1:-run}" in
  build) build ;;
  run)   build >/dev/null; ex_renode "$EX_DIR/zig_nrf52840.resc" ;;
  test)  unit; build; ex_robot "$EX_DIR/test.robot" ;;
  *) echo "usage: example.sh build|run|test" >&2; exit 2 ;;
esac

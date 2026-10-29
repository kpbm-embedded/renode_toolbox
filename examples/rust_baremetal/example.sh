#!/usr/bin/env bash
# about: no_std Rust (32_17_embedded_rust toolchain, reached not copied) on BlackPill F411 and a CH32V203-like RV32IMAC board
# Usage (via ./renode-box examples): build | run [blackpill|ch32v203] | test
# Needs 32_17_embedded_rust (rust-box): $BOX_EMBEDDED_RUST or the sibling folder; exits 3 when missing.
# shellcheck source-path=SCRIPTDIR source=../fw/ex.sh
. "$(dirname "$0")/../fw/ex.sh"
build() {
  local rb; rb=$(ex_sibling_launcher 32_17_embedded_rust BOX_EMBEDDED_RUST rust-box)
  local t
  for t in thumbv7em-none-eabihf riscv32imac-unknown-none-elf; do
    # cargo reads .cargo/ and Cargo.lock from the crate dir; build output goes to $EX_OUT/target
    (cd "$EX_DIR" && "$rb" cargo build --release --offline --target "$t" --target-dir "$EX_OUT/target")
  done
}
case "${1:-run}" in
  build) build ;;
  run)   build >/dev/null; ex_renode "$EX_DIR/rust_${2:-blackpill}.resc" ;;
  test)  build; ex_robot "$EX_DIR/test.robot" ;;
  *) echo "usage: example.sh build|run [blackpill|ch32v203]|test" >&2; exit 2 ;;
esac

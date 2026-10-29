#!/usr/bin/env bash
# about: Armv8.1-M Helium (MVE int/float, tail predication) and low-overhead loops on the RA8M1 Cortex-M85 model, checked against plain C
# shellcheck disable=SC2119  # ex_make takes optional make arguments
# Usage (via ./renode-box examples): build | run | test
# shellcheck source-path=SCRIPTDIR source=../fw/ex.sh
. "$(dirname "$0")/../fw/ex.sh"
check_asm() { # the compiler really emitted MVE and LOB instructions
  local lst=$EX_OUT/helium_demo.lst n
  for n in vmlaldava vqadd.s32 vfma.f32 vctp.16 'le	lr|letp	lr|wls	lr|dls	lr|wlstp|dlstp'; do
    if grep -qE "$n" "$lst"; then echo "ok    $n in the listing"; else echo "FAIL  no $n in $lst"; return 1; fi
  done
}
case "${1:-run}" in
  build) ex_make ;;
  run)   ex_make >/dev/null; ex_renode "$EX_DIR/helium.resc" ;;
  test)  ex_make; check_asm; ex_robot test.robot ;;
  *) echo "usage: example.sh build|run|test" >&2; exit 2 ;;
esac

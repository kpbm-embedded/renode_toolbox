#!/usr/bin/env bash
# about: snapshots on the BlackPill F411 model: Save, run on, Load, the RAM counter resumes (RAM/CPU state checked)
# Usage (via ./renode-box examples): build | run | test
# shellcheck disable=SC2119  # ex_make takes optional make arguments
# shellcheck source-path=SCRIPTDIR source=../fw/ex.sh
. "$(dirname "$0")/../fw/ex.sh"
build() { ex_make; }
case "${1:-run}" in
  build) build ;;
  run)   build >/dev/null; ex_renode "$EX_DIR/snapshot.resc" ;;
  test)  build; ex_robot "$EX_DIR/test.robot" ;;
  *) echo "usage: example.sh build|run|test" >&2; exit 2 ;;
esac

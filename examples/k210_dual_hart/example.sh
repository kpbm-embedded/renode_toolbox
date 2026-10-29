#!/usr/bin/env bash
# about: K210 dual hart (rv64): both harts run, hart 1 computes, amoadd atomics keep a shared counter exact
# Usage (via ./renode-box examples): build | run | test
# shellcheck disable=SC2119  # ex_make takes optional make arguments
# shellcheck source-path=SCRIPTDIR source=../fw/ex.sh
. "$(dirname "$0")/../fw/ex.sh"
build() { ex_make; }
case "${1:-run}" in
  build) build ;;
  run)   build >/dev/null; ex_renode "$EX_DIR/k210_dual.resc" ;;
  test)  build; ex_robot "$EX_DIR/test.robot" ;;
  *) echo "usage: example.sh build|run|test" >&2; exit 2 ;;
esac

#!/usr/bin/env bash
# about: prebuilt Linux, offline: K210 NOMMU Linux (rv64) and Zynq-7000 Cortex-A9 buildroot (login + uname)
# shellcheck disable=SC2119  # ex_make takes optional make arguments
# Usage (via ./renode-box examples): build | run [k210|zynq] | test
# shellcheck source-path=SCRIPTDIR source=../fw/ex.sh
. "$(dirname "$0")/../fw/ex.sh"
need() { [ -r "$RENODE_BOX_DEMOS/$1" ] || { echo "missing cached image $1: run ./renode-box install" >&2; exit 1; }; }
check() {
  need kendryte-k210--vmlinux-s_2206416-2c1f2b2c2f2fc0c48a7b12a3f3c65809b81f452e
  need zynq-interface-tests-vmlinux-s_14142952-ab5cd7445f31414fcbf8c79d49d737c669034ef2
  need zynq--interface-tests-rootfs.ext2-s_16777216-191638e3b3832a81bebd21d555f67bf3a4d7882a
  need zynq-interface-tests-gem0.dtb-s_11724-f0dec8ffadea47891dfe2441215401f09f7242fa
}
case "${1:-run}" in
  build) check; echo "nothing to build: prebuilt images are cached in $RENODE_BOX_DEMOS" ;;
  run)   check; ex_renode "$EX_DIR/${2:-k210}_linux.resc" ;;
  test)  check; ex_robot "$EX_DIR/test.robot" ;;
  *) echo "usage: example.sh build|run [k210|zynq]|test" >&2; exit 2 ;;
esac

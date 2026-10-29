#!/usr/bin/env bash
# @NAME@ self-test: analyze the prebuilt Zephyr shell for nRF52840 (renode-box demo cache, offline) on Renode's
# nrf52840.repl and check that its UART accesses are found and every access lands in a girdl-typed peripheral.
# Run: ./renode-box run bash <dir>/@NAME@/test.sh   (exit 3 = optional add-ons missing)
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd -P)
: "${RENODE_BOX_DEMOS:?run through ./renode-box run}"
elf=$(find "$RENODE_BOX_DEMOS" -maxdepth 1 -name 'zephyr_shell_nrf52840.elf-*' | head -1)
[ -n "$elf" ] || { echo "skip: the cached Zephyr shell demo is missing (./renode-box install)" >&2; exit 3; }
bash "$here/analyze.sh" "$elf" platforms/cpus/nrf52840.repl "$here/build"
refs=$here/build/refs.tsv
n=$(wc -l <"$refs"); untyped=$(awk -F'\t' '$4 == "-"' "$refs" | wc -l)
uart=$(awk -F'\t' '$4 ~ /^uart0\+/' "$refs" | wc -l)
echo "accesses: $n, to uart0: $uart, outside any typed peripheral: $untyped"
[ "$n" -gt 0 ] && [ "$uart" -gt 0 ] || { echo "FAIL: no UART accesses found"; exit 1; }
echo "@NAME@: girdl + Ghidra analysis test passed"

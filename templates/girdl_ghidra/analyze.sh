#!/usr/bin/env bash
# @NAME@: firmware ELF + Renode platform -> peripheral map (`peripherals export`) + the Renode RDL files of its models
# -> girdl: DWARF with every peripheral (for gdb) and a headless Ghidra 12.2 analysis with typed, labelled
# peripherals; writes refs.tsv (function, address, peripheral+offset, RDL type) for each code access to 0x40000000-0x5FFFFFFF.
# Run: ./renode-box run bash <dir>/@NAME@/analyze.sh <firmware.elf> <platform.repl> [out-dir]
# Needs the optional add-ons: ./renode-box extras install girdl renode-rdl (exit 3 = missing). Offline at run time.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd -P)
: "${RENODE_BOX_ROOT:?run through ./renode-box run}" "${RENODE:?}"
elf=$(realpath "${1:?usage: analyze.sh <firmware.elf> <platform.repl> [out-dir]}")
repl=${2:?usage: analyze.sh <firmware.elf> <platform.repl> [out-dir]}
case "$repl" in /*|platforms/*) ;; *) repl=$(realpath "$repl") ;; esac   # platforms/... = bundled with Renode
out=$(mkdir -p "${3:-$here/build}" && cd "${3:-$here/build}" && pwd -P)
R=$RENODE_BOX_ROOT/renode-box
rdl=$RENODE_BOX_ROOT/install/renode-rdl
if [ -z "$(ls "$RENODE_BOX_ROOT"/install/girdl/dist/girdl/lib/girdl.jar 2>/dev/null)" ] || [ ! -d "$rdl" ]; then
  echo "skip: optional add-ons missing: ./renode-box extras install girdl renode-rdl" >&2; exit 3
fi
mkdir -p "$out/rdl"
timeout 120 "$RENODE" --console --disable-gui --plain -e "mach create \"@NAME@\"; machine LoadPlatformDescription @$repl; \
  peripherals export @$out/map.json; quit" >"$out/renode.log" 2>&1 </dev/null || { tail -5 "$out/renode.log"; exit 1; }
python - "$out/map.json" "$rdl" "$out/rdl" <<'PY'
import json, os, shutil, sys
m, src, dst = sys.argv[1:]
def walk(n):
    yield n["Name"]
    for c in n["Children"]:
        yield from walk(c)
types = sorted(set(walk(json.load(open(m))["Root"])))
got = [t for t in types if os.path.exists(os.path.join(src, t + ".rdl"))]
for t in got:
    shutil.copy(os.path.join(src, t + ".rdl"), dst)
print(f"@NAME@: {len(types)} model types in the map, {len(got)} with a Renode RDL file")
PY
"$R" girdl -q -i "$out/rdl" -i "$out/map.json" -o "$out/peripherals.dwarf" >"$out/girdl.log" 2>&1
echo "@NAME@: $out/peripherals.dwarf (gdb: add-symbol-file it, then e.g. ptype/x <peripheral>)"
mkdir -p "$out/ghidra"
timeout 900 "$R" ghidra "$out/ghidra" fw -import "$elf" -overwrite -deleteProject -scriptPath "$here" \
  -preScript SetGirdlOptions.java "$out/rdl" "$out/map.json" -postScript ListPeripheralRefs.java "$out/refs.tsv" \
  >"$out/ghidra.log" 2>&1 </dev/null || { echo "analyzeHeadless failed (log: $out/ghidra.log)" >&2; exit 1; }
echo "@NAME@: $(wc -l <"$out/refs.tsv") peripheral accesses -> $out/refs.tsv"

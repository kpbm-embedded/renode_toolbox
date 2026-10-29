#!/usr/bin/env bash
# about: girdl + headless Ghidra 12.2: Renode `peripherals export` map + Renode RDL -> peripheral types and labels in the analysis of the BlackPill F411 firmware built here; girdl standalone -> DWARF
# Usage (via ./renode-box examples): build | run | test. Needs the optional add-ons (./renode-box extras install girdl
# renode-rdl: JDK 25, Gradle, Ghidra 12.2, girdl built from source); exits 3 (skip) without them. No network at run time:
# girdl's "Use Renode RDL" download is off, both data sources are local files.
# shellcheck source-path=SCRIPTDIR source=../fw/ex.sh
. "$(dirname "$0")/../fw/ex.sh"
R=$RENODE_BOX_ROOT/renode-box
BP_OUT=$(dirname "$EX_OUT")/stm32f4_blackpill
ELF=$BP_OUT/blackpill_hello.elf
RDL=$RENODE_BOX_ROOT/install/renode-rdl
need() {
  [ -n "$(ls "$RENODE_BOX_ROOT"/install/girdl/dist/girdl/lib/girdl.jar 2>/dev/null)" ] && [ -d "$RDL" ] || {
    echo "skip: optional add-ons missing: ./renode-box extras install girdl renode-rdl" >&2; exit 3; }
}
build() { # firmware, the peripheral map Renode exports for its platform, and the RDL files of the models in that map
  make --no-print-directory -C "$EX_DIR/../stm32f4_blackpill" -j"${BOXT_JOBS:-4}" FW="$FW_DIR" OUT="$BP_OUT"
  mkdir -p "$EX_OUT/rdl"
  timeout 120 "$RENODE_DIR/renode" --config "$RENODE_CONFIG" --console --disable-gui --plain -e "mach create \"bp\"; \
    machine LoadPlatformDescription @$EX_DIR/../stm32f4_blackpill/blackpill_f411.repl; peripherals export @$EX_OUT/map.json; quit" \
    >"$EX_OUT/renode.log" 2>&1 </dev/null
  python - "$EX_OUT/map.json" "$RDL" "$EX_OUT/rdl" <<'PY'
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
print(f"map: {len(types)} model types, {len(got)} with a Renode RDL file -> {dst}")
PY
}
check() {
  local o=$EX_OUT rc=0
  # 1. girdl standalone: RDL + map -> DWARF (host gdb: add-symbol-file, then `ptype usart1`)
  "$R" girdl -q -i "$o/rdl" -i "$o/map.json" -o "$o/peripherals.dwarf" >"$o/girdl.log" 2>&1
  python - "$o/peripherals.dwarf" <<'PY' || rc=1
import sys
from elftools.elf.elffile import ELFFile
want = {"usart1": 0x40011000, "gpioPortC": 0x40020800, "rcc": 0x40023800}
seen, members = {}, {}
dw = ELFFile(open(sys.argv[1], "rb")).get_dwarf_info()
for cu in dw.iter_CUs():
    for die in cu.iter_DIEs():
        n = die.attributes.get("DW_AT_name")
        if die.tag == "DW_TAG_variable" and n and "DW_AT_location" in die.attributes:
            loc = die.attributes["DW_AT_location"].value
            if isinstance(loc, list) and loc and loc[0] == 3:   # DW_OP_addr
                seen[n.value.decode()] = int.from_bytes(bytes(loc[1:]), "little")
        if die.tag == "DW_TAG_structure_type" and n and n.value == b"STM32_UART":
            for c in die.iter_children():
                if c.tag == "DW_TAG_member":
                    members[c.attributes["DW_AT_name"].value.decode()] = c.attributes["DW_AT_data_member_location"].value
ok = True
for k, a in want.items():
    good = seen.get(k) == a
    ok &= good
    print(("ok   " if good else "FAIL ") + f" dwarf: {k} at {seen.get(k, 0):#x} (want {a:#x})")
good = members.get("Data") == 4 and members.get("BaudRate") == 8
ok &= good
print(("ok   " if good else "FAIL ") + f" dwarf: STM32_UART members {dict(list(members.items())[:4])}")
print(f"dwarf: {len(seen)} peripherals")
sys.exit(0 if ok else 1)
PY
  # 2. headless Ghidra: import the ELF, girdl analyzer with the same two sources, list code references into
  #    peripheral space (function, peripheral+offset, girdl type) and compare with what main.c does
  mkdir -p "$o/ghidra"   # -deleteProject: the temporary project is gone afterwards
  timeout 600 "$R" ghidra "$o/ghidra" fw -import "$ELF" -overwrite -deleteProject -scriptPath "$EX_DIR" \
    -preScript SetGirdlOptions.java "$o/rdl" "$o/map.json" -postScript ListPeripheralRefs.java "$o/refs.tsv" \
    >"$o/ghidra.log" 2>&1 </dev/null || { echo "FAIL: analyzeHeadless (log: $o/ghidra.log)"; return 1; }
  grep -E 'GirdlAnalyzer|ListPeripheralRefs:' "$o/ghidra.log" | sed 's/^INFO  //; s/ (Ghidra.*//; s/ (Girdl.*//'
  cut -f1,4,5 "$o/refs.tsv" | LC_ALL=C sort -u >"$o/refs.got"
  if diff -u "$EX_DIR/refs_expected.tsv" "$o/refs.got"; then echo "ok    ghidra: $(wc -l <"$o/refs.got") distinct (function, register, type) references, all labelled by girdl"
  else echo "FAIL  ghidra: references differ from refs_expected.tsv"; rc=1; fi
  return $rc
}
case "${1:-run}" in
  build) need; build ;;
  run)   need; build; check; column -t "$EX_OUT/refs.tsv" ;;
  test)  need; build; check ;;
  *) echo "usage: example.sh build|run|test" >&2; exit 2 ;;
esac

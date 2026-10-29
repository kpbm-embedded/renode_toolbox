# @NAME@: girdl + headless Ghidra on your firmware (from `./renode-box new girdl_ghidra`)

[girdl](https://github.com/antmicro/girdl) (Antmicro, Apache-2.0) is a Ghidra plugin that imports peripheral
register definitions (Renode RDL, SVD, JSON) and binds them with a peripheral map. Renode provides both halves:
`peripherals export @map.json` writes the map of the platform you load, and the pinned `renode-rdl` add-on holds
the SystemRDL descriptions of Renode's models. `analyze.sh` puts them together for any ELF + `.repl`:

- `peripherals.dwarf`: girdl standalone, every peripheral as a typed variable at its address (for gdb);
- headless Ghidra 12.2 with girdl: peripherals become typed, labelled memory blocks in the analysis, and
  `refs.tsv` lists each code access into 0x40000000-0x5FFFFFFF as function, address, peripheral+offset, RDL type.

| File | What |
|---|---|
| `analyze.sh` | map export, RDL selection, girdl DWARF, Ghidra headless run |
| `SetGirdlOptions.java` | pre-script: girdl's analyzer options (local sources, no "Use Renode RDL" download) |
| `ListPeripheralRefs.java` | post-script: writes `refs.tsv` |
| `test.sh` | runs it on the cached Zephyr shell for nRF52840 and checks the UART accesses |

```sh
./renode-box extras install girdl renode-rdl         # JDK 25, Gradle, Ghidra 12.2, girdl built from source
./renode-box run bash <dir>/@NAME@/test.sh
./renode-box run bash <dir>/@NAME@/analyze.sh fw.elf board.repl out/   # your firmware and platform
```
Accesses shown as `-` go to addresses without a Renode model (or a model without an RDL file); an SVD from the
vendor, passed as Data Source 1 instead of the RDL folder, covers those (absolute addresses, no map needed).

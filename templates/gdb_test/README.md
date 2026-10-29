# @NAME@: gdb against Renode inside a Robot test (from `./renode-box new gdb_test`)

The test starts Renode's GDB server (`machine StartGdbServer <port> true`) and runs `gdb -batch` with
the Process library while Renode keeps running: breakpoints, backtraces, registers, memory. The
default ELF is the prebuilt Zephyr shell for nRF52840 (offline cache); gdb comes from the renode-box
env (`arm-none-eabi-gdb`, `riscv-none-elf-gdb`).

```sh
./renode-box robot <dir>/@NAME@/@NAME@.robot
./renode-box robot <dir>/@NAME@/@NAME@.robot --variable ELF:fw.elf --variable BREAK:app_init \
    --variable PLATFORM:platforms/cpus/kendryte_k210.repl --variable GDB:riscv-none-elf-gdb
```
Interactive: `./renode-box renode` then `machine StartGdbServer 3333`, and in another shell
`./renode-box run arm-none-eabi-gdb fw.elf -ex 'target remote :3333'` (see the `gdb_debug` example).

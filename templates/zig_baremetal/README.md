# @NAME@: Zig firmware for Renode (from `./renode-box new zig_baremetal`)

Freestanding Zig for the nRF52840 (nice!nano): own startup and vector table, legacy UART0 line commands
(`crc <text>`, `led`), LED P0.15. Board-independent code lives in `logic.zig` and is unit-tested on the PC
before the firmware is built. The Zig compiler is not copied here: `make` calls 32_24_microzig's
`microzig-box zig` (`$BOX_MICROZIG`, else the folder next to 32_06_renode); without it, make says "skip".

```sh
./renode-box run make -C <dir>/@NAME@        # zig test logic.zig, then build/@NAME@.elf
./renode-box robot <dir>/@NAME@/@NAME@.robot
```
For MicroZig's HALs (RP2040, STM32, nRF5x register definitions) use 32_24_microzig's `firmware` template and keep
the `.repl`/`.resc`/`.robot` from here for the Renode side.

# examples/fw: shared bare-metal support for the 32_06_renode examples

Not an example itself (no `example.sh`). Minimal, dependency-free startup code, linker
scripts and a tiny print library used by the example firmware. Built with this ID's own
xPack toolchains (`install/arm-gcc`, `install/riscv-gcc`), never another ID's.

| File | What |
|---|---|
| `cortexm/startup.c` | Cortex-M vector table, `.data`/`.bss` init, weak handlers (FreeRTOS hooks map onto them) |
| `cortexm/stm32f4.ld` | STM32F4 (BlackPill F411: 512 KiB flash @0x08000000, 128 KiB SRAM @0x20000000) |
| `cortexm/stm32h743.ld` | STM32H743 (2 MiB flash @0x08000000, 512 KiB AXI SRAM @0x24000000) |
| `cortexm/nrf52840.ld` | nRF52840 (1 MiB flash @0x0, 256 KiB RAM @0x20000000) |
| `riscv/start.S` | RV32/RV64 entry: hart 0 runs, other harts park in `wfi`; stack, `.bss`, `main` |
| `riscv/k210.ld` | Kendryte K210 (SRAM @0x80000000) |
| `riscv/litex.ld` | LiteX/VexRiscv (main RAM @0x40000000) |
| `include/bm.h` | `bm_puts`/`bm_hex`/`bm_dec` on a board-supplied `bm_putc` |
| `rules.mk` | shared make rules (`CROSS`, `ARCHFLAGS`, `LDSCRIPT`, `SRCS` -> `$(OUT)/<name>.elf` + `.bin` + `.lst`) |

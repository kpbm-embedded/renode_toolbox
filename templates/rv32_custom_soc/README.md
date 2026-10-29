# @NAME@: your own RISC-V platform (from `./renode-box new rv32_custom_soc`)

For chips Renode 1.17 does not model (CH32V003/203/307, BL616/702, ESP32-C3): describe the memory
map and borrow peripheral models with the same register layout. The default is a CH32V003.

| File | What |
|---|---|
| `@NAME@.repl` | the platform: RV32EC core, flash, SRAM, USART1, GPIOD + LED, RCC stub |
| `@NAME@.ld`, `start.S` | the same memory map for the linker; startup with .data copy |
| `main.c`, `print.h` | banner + LED blink |
| `@NAME@.resc` / `.robot` | machine script and tests |

```sh
./renode-box run make -C <dir>/@NAME@
./renode-box robot <dir>/@NAME@/@NAME@.robot
./renode-box platforms uart                       # find peripheral models to reuse
```
Limits: no interrupt controller (PFIC/CLIC) or SysTick in the default; add one before using IRQs.

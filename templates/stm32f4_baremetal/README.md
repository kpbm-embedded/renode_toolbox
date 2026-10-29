# @NAME@: BlackPill F411 bare-metal project (from `./renode-box new stm32f4_baremetal`)

Register-level firmware (no HAL, no libc) plus everything Renode needs to run and test it.

| File | What |
|---|---|
| `main.c`, `print.h` | USART1 console, LED PC13, KEY PA0 |
| `startup.c`, `stm32f411.ld` | vector table and memory map of the F411CE |
| `@NAME@.repl` | platform: Renode's STM32F412 + LED and KEY (Renode has no F411 model) |
| `@NAME@.resc` | machine script (`$elf`, default `build/@NAME@.elf`) |
| `@NAME@.robot` | tests: banner, LED states, KEY press |

```sh
./renode-box run make -C <dir>/@NAME@                     # build/@NAME@.elf + .bin
./renode-box robot <dir>/@NAME@/@NAME@.robot              # headless tests
./renode-box renode <dir>/@NAME@/@NAME@.resc              # interactive (type `start`)
```
The same `.bin` runs on a real BlackPill (flash at 0x08000000, e.g. with 32_08_probe_tools).

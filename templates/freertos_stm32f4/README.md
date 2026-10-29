# @NAME@: FreeRTOS application for the BlackPill F411 (from `./renode-box new freertos_stm32f4`)

Uses this ID's FreeRTOS-Kernel (`install/freertos`, V11.3.2): `./renode-box run make` passes `FREERTOS_KERNEL`.

| File | What |
|---|---|
| `main.c` | sensor task -> queue -> logger task; mutex-shared counter; blink task (LED PC13) |
| `FreeRTOSConfig.h` | Cortex-M4F port, 1 kHz tick, heap_4 16 KiB, stack-overflow check 2 |
| `startup.c`, `stm32f411.ld`, `print.h` | startup (FreeRTOS handlers mapped onto SVC/PendSV/SysTick), memory map |
| `@NAME@.repl` / `.resc` / `.robot` | Renode platform, machine script, tests (queue, tick timing, blink timing) |

```sh
./renode-box run make -C <dir>/@NAME@
./renode-box robot <dir>/@NAME@/@NAME@.robot
```
`configCPU_CLOCK_HZ` only sets the SysTick reload: Renode runs it on virtual time. On a real board set
it to the clock you configure (16 MHz HSI unless you set up the PLL).

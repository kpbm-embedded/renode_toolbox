# @NAME@: nRF52840 bare-metal project (from `./renode-box new nrf52840_baremetal`)

| File | What |
|---|---|
| `main.c`, `print.h` | legacy UART0 (P0.06 TX, P0.08 RX) line commands, LED P0.15 |
| `startup.c`, `nrf52840.ld` | vector table, memory map (flash at 0) |
| `@NAME@.repl` / `.resc` / `.robot` | Renode platform, machine script, tests (echo, LED command) |

```sh
./renode-box run make -C <dir>/@NAME@
./renode-box robot <dir>/@NAME@/@NAME@.robot
```
On a real nice!nano the UF2 bootloader occupies the start of flash: link at 0x26000 (change `FLASH`
in `nrf52840.ld`) and convert the `.bin` to UF2, or flash at 0 over SWD.

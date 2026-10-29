# @NAME@: two boards talking over a UART (from `./renode-box new multi_node`)

Two machines in one Renode emulation, connected by a UART hub (`emulation CreateUARTHub`). Renode keeps
their virtual time in step, so the test is deterministic. On real boards: PA2 (TX) of one to PA3 (RX) of
the other and back, common GND.

| File | What |
|---|---|
| `main.c` | one source; `-DROLE_PING` sends "ping N" and waits, `-DROLE_PONG` answers "pong N" |
| `Makefile` | builds both roles into `build/ping/`, `build/pong/` |
| `@NAME@.resc` | two machines + hub; `$ping_elf`, `$pong_elf` |
| `@NAME@.robot` | one terminal tester per machine (`machine=`, `testerId=`), link break test |

```sh
./renode-box run make -C <dir>/@NAME@
./renode-box robot <dir>/@NAME@/@NAME@.robot
```
More nodes: `mach create` again and `connector Connect sysbus.usart2 link`. Radio links (BLE, 802.15.4)
use `emulation CreateIEEE802_15_4Medium` / `CreateBLEMedium` the same way.

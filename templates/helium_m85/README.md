# @NAME@: Helium (MVE) on the Cortex-M85 (from `./renode-box new helium_m85`)

Armv8.1-M firmware for Renode 1.17's Renesas RA8M1 model (Cortex-M85: Helium/MVE integer and float, FPv5,
low-overhead loops). Three kernels run twice, once with MVE intrinsics (`arm_mve.h`) and once in plain C; the UART
prints both results and the test checks they match. Use it to try a vector kernel before you have the board.

| File | What |
|---|---|
| `main.c`, `bm.h` | q15 dot product with tail predication, saturating int32 add, float FMA; MVE and C versions |
| `startup.c`, `ra8m1.ld` | vector table, code flash 0x02000000, SRAM 0x22000000 |
| `@NAME@.repl`, `@NAME@.resc` | RA8M1 + a debug UART at 0x5F000000 (simulation only), machine script |
| `@NAME@.robot` | results match, no "Unsupported opcode" in the log |

```sh
./renode-box run make -C <dir>/@NAME@        # build + check-asm: MVE/LOB instructions really in the listing
./renode-box robot <dir>/@NAME@/@NAME@.robot
```
Results are functional only: Renode does not model cycle timing, so measure speed-ups on the hardware.

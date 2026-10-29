# @NAME@: Kendryte K210 bare-metal project (from `./renode-box new k210_baremetal`)

| File | What |
|---|---|
| `main.c`, `print.h` | UARTHS console, misa/mhartid, a loop |
| `start.S`, `k210.ld` | entry for both harts (hart 1 parks), SRAM at 0x80000000 |
| `@NAME@.resc` / `.robot` | Renode's `kendryte_k210.repl`, tests |

```sh
./renode-box run make -C <dir>/@NAME@
./renode-box robot <dir>/@NAME@/@NAME@.robot
```
To use hart 1 too, see the `k210_dual_hart` example (`./renode-box examples run k210_dual_hart`).

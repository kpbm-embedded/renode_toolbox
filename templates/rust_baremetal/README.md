# @NAME@: no_std Rust firmware for Renode (from `./renode-box new rust_baremetal`)

A dependency-free `no_std` crate (own startup, vector table, panic handler, `core::fmt` over a UART) for two
boards: the BlackPill F411 (`thumbv7em-none-eabihf`) and a CH32V203-like RV32IMAC board
(`riscv32imac-unknown-none-elf`). The toolchain is not copied here: `make` calls 32_17_embedded_rust's
`rust-box cargo` (`$BOX_EMBEDDED_RUST`, else the folder next to 32_06_renode); without it, make says "skip".

| File | What |
|---|---|
| `src/main.rs` | both boards (`cfg(target_arch)`): USART, LED/KEY on the BlackPill, panic with message and location |
| `Cargo.toml`, `build.rs` | no dependencies (builds `--offline`); `build.rs` picks `blackpill.ld` or `ch32v203.ld` |
| `@NAME@_blackpill.repl/.resc`, `@NAME@_ch32v203.repl/.resc` | Renode platforms and machine scripts |
| `@NAME@.robot` | banner, `.data`/`.bss`, LED, panic on KEY, RISC-V run |

```sh
./renode-box run make -C <dir>/@NAME@                 # build/target/<triple>/release/@NAME@
./renode-box robot <dir>/@NAME@/@NAME@.robot
```
To use crates (embassy, cortex-m-rt, defmt), start from 32_17_embedded_rust's own templates instead and keep the
`.repl`/`.resc`/`.robot` from here for the Renode side.

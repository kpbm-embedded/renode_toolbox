# 32_06_renode - Renode (embedded system simulator)

Renode 1.17.0 (Antmicro, portable build) with its own Arm and RISC-V GCC, FreeRTOS-Kernel and a small
Python env for Robot Framework tests. Use it to run and test firmware on simulated boards (STM32, nRF52840,
K210, LiteX, Zynq) without hardware, including Linux boots and UART/LED/button checks in CI. Everything is
pinned, checksum-verified and kept inside this folder: no sudo, no system packages.

Status: **ready** (doctor 19 ok; examples 18/18; templates 12/12 built and tested; smoke 21/21; dry run 30/30;
2026-10-29). Nothing ran on real hardware: everything is simulated. Launcher: `./renode-box`.

## What's included

| Component | Version | Notes |
|---|---|---|
| Renode | 1.17.0 (2026-09-07) | portable, .NET bundled; sha256 in `config/pins.tsv` |
| Arm GCC | xPack arm-none-eabi-gcc 15.2.1-1.1 | newlib, nano; 1.1 GB |
| RISC-V GCC | xPack riscv-none-elf-gcc 15.2.0-1 | all multilibs incl. rv32e/rv64; 1.6 GB |
| FreeRTOS-Kernel | V11.3.2 | its `task.h` still says "V11.1.0+" |
| pixi | 0.81.0 | sha256 pinned in `renode-box` |
| Python env | 3.12, robotframework 6.1, retryfailed 0.2.0, psutil, pyyaml, telnetlib3, construct, pyelftools, GNU make 4.4 | `pixi.toml` / `pixi.lock`; versions from Renode's `tests/requirements.txt` |
| dts2repl | main @ c94a6ad (2026-10-19) | DTS to Renode `.repl` converter |
| Demo images | Zephyr shell (nRF52840), K210 NOMMU Linux, Zynq-7000 buildroot Linux | cached in `cache/downloads`, work offline |

## Quick start

```sh
cd "$BOX_RENODE"                           # or: cd $BOX/30_39_tools/32_embedded/32_06_renode
./renode-box install && ./renode-box doctor   # first setup (downloads once), then health checks
./renode-box examples list                    # the 18 examples
./renode-box examples test stm32f4_blackpill  # build + run one example headless with its Robot test
./renode-box examples run stm32f4_blackpill   # GUI monitor + UART analyzer (console if no display)
```

With the Box shell set up once (`box shell install --apply`), the `renode-box` shim works from any folder,
and `box test|doctor|status renode` run this launcher (`box clean renode` is a dry run until `--apply`).
Standalone (no Box, or `BOX_INTEGRATION=0`), `./renode-box` keeps its output in this folder.

## Commands

Global option: `--dry-run` / `-n` prints what a command would do. Exit codes: 0 ok, 1 failure, 2 usage error (unknown command or option, or arguments given to `where`, `status`, `doctor`, `bootstrap` or `relocate`), 3 not applicable. `help` ends with this tool's own examples and variables (`tool examples`, `tool environment`).

| Command | What it does | Example |
|---|---|---|
| `bootstrap` | pinned pixi + env + core downloads (sha-checked) | `./renode-box bootstrap` |
| `install [--no-demos]` | bootstrap + demo downloads + example firmware build | `./renode-box install` |
| `update [--check\|--env]` | `--check` (default): compare pins with newest upstream; `--env`: re-solve the pixi env | `./renode-box update --check` |
| `clean [--all] [--yes]` | move build/log output (`--all`: also install/, .pixi, native/, downloads) to the Trash; dry run unless `--yes` | `./renode-box --dry-run clean --all` |
| `status`, `where`, `doctor` | versions and sizes, paths, health checks (exit 1 on failure) | `./renode-box doctor` |
| `shell [-- cmd ...]` | bash (or a command) with the tools on PATH | `./renode-box shell` |
| `run <cmd> [args]` | one command inside the environment | `./renode-box run arm-none-eabi-gcc --version` |
| `renode [args]` | Renode itself (GUI monitor; `--console` or `--disable-gui` for headless) | `./renode-box renode --console my.resc` |
| `robot <file.robot> [args]` | `renode-test` (Robot Framework) on a test file | `./renode-box robot tests/my.robot` |
| `repl <zephyr.dts> [-o F]` | dts2repl: Renode platform (`.repl`) from a flattened DTS | `./renode-box repl build/zephyr/zephyr.dts -o board.repl` |
| `platforms [filter]` | list the bundled platform `.repl` files (cpus/ and boards/) | `./renode-box platforms stm32` |
| `test [--all]` | `tests/test_smoke.sh`; `--all` adds the dry-run test and the examples test | `./renode-box test` |
| `new <kind> <name> [--dir D] [--force]` | create a project from `templates/` (14 kinds, below) | `./renode-box new stm32f4_baremetal fw` |
| `examples list \| run <ex> [args] \| build [ex...] \| test [ex...]` | list, run, build or test the examples | `./renode-box examples test` |
| `native [--print]` | write `native/{native.zsh,native.bash,bin/}` | `./renode-box native` |
| `relocate` | after moving the folder: re-create the pixi env, rewrite `native/` | `./renode-box relocate` |
| `pack [--with-cache] [--out F]` | tarball of this folder (minus envs/build) for another machine | `./renode-box pack --out /tmp/r.tgz` |
| `help`, `-h`, `--help` | the command list | `./renode-box help` |

## Examples and templates

Examples (`examples/<name>/example.sh build|run|test`; shared startup code, linker scripts and make rules are in
`examples/fw/`). `examples test` takes about 3 min for all 18.

| Example | Board | What is checked |
|---|---|---|
| `stm32f4_blackpill` | BlackPill F411 (Renode has no F411: STM32F412 + board `.repl`, LED PC13, KEY PA0) | USART1 banner, LED follows firmware, KEY press seen |
| `stm32f4_freertos` | BlackPill F411 | FreeRTOS: scheduler, queue, 1 s timer at tick 2000, LED blinks every 250 ms |
| `nrf52840_nicenano` | nice!nano / nRF52840 | bare-metal UART echo + LED P0.15, plus prebuilt Zephyr shell (`demo ping` gives `pong`) |
| `riscv_k210_litex` | Kendryte K210 (rv64) and LiteX VexRiscv (rv32) | one source, two RISC-V platforms; ISA read from `misa` |
| `linux_k210_zynq` | K210 NOMMU Linux; Zynq-7000 Cortex-A9 | boot to shell, login, `uname -m` (riscv64 / armv7l); about 17 s for Zynq |
| `custom_board_dts` | WeAct MiniSTM32H743 | DTS, dts2repl, `.repl`, H743 firmware, then UART and LED checks |
| `gdb_debug` | BlackPill F411 | Renode GDB server + `arm-none-eabi-gdb -batch`: breakpoint, read `g_state`, write `g_gain`, check the effect |
| `uart_hub_two_nodes` | 2 x BlackPill F411 | two machines, USART2 <-> USART2 through a UART hub: ping/pong, link disconnect -> timeout |
| `snapshot_save_load` | BlackPill F411 | `Save` at tick 5, run on, `Load`: RAM counter and UART output resume at 6; load twice |
| `trace_coverage` | BlackPill F411 | PC trace (`CreateExecutionTracing`) -> function coverage from the ELF (pyelftools): used vs never-called handlers |
| `python_peripheral` | BlackPill F411 + sensor in Python | `PythonPeripheral` in the `.repl`; firmware polls it, the test changes its value |
| `csharp_peripheral` | BlackPill F411 + CRC-32 block in C# | `include @Crc32Accel.cs` compiled at run time; firmware and monitor results match zlib's CRC-32 |
| `ch32v003_custom_soc` | CH32V003-like (RV32EC) | platform written from scratch (`.repl`: core, memories, STM32F1-style USART/GPIO reused), `.data`/`misa`/LED checks |
| `nrf52840_timer_irq` | nice!nano / nRF52840 | TIMER0 compare IRQ (LED blink at 2 Hz on virtual time), GPIOTE button IRQ, vector table in RAM (VTOR) |
| `k210_dual_hart` | Kendryte K210 | both rv64 harts run; hart 1 counts primes, `amoadd` keeps a shared counter exact; per-hart state in the monitor |
| `fault_log_checks` | BlackPill F411 | failure paths: HardFault handler + CFSR + `FindSymbolAt`, unmapped access via Log Tester, expected-failure keywords |
| `uart_socket_host` | nice!nano / nRF52840 | UART on a TCP server socket; a host Python client talks to the firmware (works the same against a TCP serial bridge) |
| `i2c_sensor_stm32` | BlackPill F411 + TMP103 | register-level I2C1 driver, sensor model value set from the test (incl. negative), NACK on an empty address |

Templates (`./renode-box new <kind> <name> [--dir D]`; each has a README). Firmware templates build with
`./renode-box run make -C <dir>/<name>` (output in `<dir>/<name>/build/`); every template's test runs with
`./renode-box robot <dir>/<name>/<name>.robot`. The robot-only ones default to the cached Zephyr shell for nRF52840,
so they run offline without a build; pass `--variable ELF:...` for your firmware.

| Kind | What you get |
|---|---|
| `board` | `<name>.repl`, `.resc` (`$ORIGIN`, `$elf`), `.robot` (banner); `--dts zephyr.dts` generates the `.repl` with dts2repl |
| `robot_test` | Robot skeleton: UART, LED/button, virtual time, Linux login (variables `RESC`, `ELF`, `UART`) |
| `stm32f4_baremetal` | BlackPill F411 firmware project (startup, linker script, USART1/LED/KEY) + `.repl`/`.resc`/`.robot` |
| `nrf52840_baremetal` | nice!nano firmware project: UART line commands with echo, LED P0.15, tests |
| `k210_baremetal` | K210 rv64 firmware project (UARTHS, hart 1 parked) + tests |
| `rv32_custom_soc` | your own RISC-V platform: hand-written `.repl` (CH32V003 map, RV32EC), matching linker script, firmware, tests |
| `freertos_stm32f4` | FreeRTOS V11 app (queue, mutex, three tasks) on the BlackPill model; tests tick and blink timing |
| `multi_node` | two boards in one emulation on a UART hub (ping/pong roles from one source), one tester per machine |
| `python_peripheral` | register model in Python inside a `.repl` + monitor-driven test bench (no firmware) |
| `csharp_peripheral` | C# peripheral (`BasicDoubleWordPeripheral`, register DSL, W1C, IRQ) compiled at run time + test bench |
| `linux_boot_test` | boot Linux (vmlinux/dtb/rootfs variables; default the cached Zynq buildroot), log in, run commands |
| `zephyr_snapshot_test` | boot once, `Save`, every test starts from `Load` (fast suites) |
| `trace_coverage` | PC trace + `coverage.py` (function coverage, expected hit/miss lists) |
| `gdb_test` | gdb in batch mode against Renode's GDB server from a Robot test (breakpoint, registers, memory) |

Which of your boards Renode 1.17 can model:

| Board | Renode model | Notes |
|---|---|---|
| BlackPill F411, F401, F103 | `stm32f412.repl` / `stm32f4.repl`, `stm32f103` scripts | F411 = F412 model + `blackpill_f411.repl` |
| STM32H743 / H723 | `stm32h743.repl` or a dts2repl `.repl` | `custom_board_dts` |
| STM32G431, H562 | no SoC model | generate from a Zephyr `zephyr.dts` with `repl` |
| nRF52840 boards | `nrf52840.repl` | `nrf52840_nicenano` |
| K210 | `kendryte_k210.repl` | bare metal and Linux |
| CH32V003/203/307, BL616/702, ESP32-C3 | no SoC models; RV32 cores exist (`litex_vexriscv`, `murax`, generic `RiscV32`) | write a `.repl` |
| RP2040/RP2350, ESP32-S3 | none in 1.17 | - |
| Cortex-A Linux (H3, H616, T113, RK3506, STM32MP13) | Zynq/Cortex-A9, `cortex-a53` platforms | `linux_k210_zynq` shows the flow |

## Configuration and environment variables

| Variable | Default | Meaning |
|---|---|---|
| `BOXT_OUT` | same ID path on idisk03, else the ID folder | output root (`build/`, `log/`); also settable in `config/local.env` |
| `BOXT_JOBS` | 8 (also the maximum) | parallel jobs |
| `BOXT_MIN_FREE_GB` | 8 | pause builds while less RAM is free |
| `BOXT_RAM_WAIT_MAX` | 3600 | give up waiting for RAM after this many seconds |
| `BOXT_NET_TIMEOUT` | 3600 | seconds for one download |
| `BOXT_PLATFORM` | detected (`linux-x64`) | override the platform |
| `GITHUB_TOKEN` | unset | optional; lifts the GitHub API limit for `update --check` |
| `BOX_INTEGRATION` | 1 | `0` = standalone: ignore `$BOX`/`$BOX_V3`, keep output in this folder |
| `NO_COLOR` | unset | set to print plain text (colour is only used on a terminal anyway) |
| `BOX_RENODE` | set by `box_env.sh` | path of this ID, used by the native snippet |

Pins are in `config/pins.tsv`; `update` never edits them.

## Where files go

| What | Where |
|---|---|
| Source, launcher, examples, templates | this ID |
| Tools | `install/` (2.8 GB: renode-1.17.0 184 MB, arm-gcc 1.1 GB, riscv-gcc 1.6 GB, freertos 24 MB), `.pixi/` (196 MB), `.bin/` (110 MB pinned pixi) |
| Cache | `cache/` (0.9 GB: downloads incl. demo images, pixi cache, Renode config; `CACHEDIR.TAG`) |
| Build output and Robot results | `$BOX_V3/30_39_tools/32_embedded/32_06_renode/{build,log}` (25 MB; `build/examples/<ex>/`, `log/robot`) |

Renode's config and cache are redirected into `cache/`, so nothing goes to `~/.config/renode`.

## Native mode

`./renode-box native` writes `native/bin/{renode,renode-test,dts2repl}` and `native/native.{zsh,bash}`. Only
`native/bin` goes on PATH (paths are relative, so it survives a move); `renode-test` and `dts2repl` run through the
launcher because they need the env's Python. Load it in every shell (zsh, bash, fish) with `box native enable renode
--apply`: it runs `./renode-box native` when the files are missing and rebuilds `box_env.d/native.*` (without
`--apply` it only shows the plan; `box native disable renode --apply` undoes it). `BOX_NATIVE_OFF_RENODE=1` skips it
for one shell (the old `RENODEBOX_NATIVE_OFF` still works for now). Without Box, source `native/native.zsh` or
`native/native.bash` from your shell rc.

## Tests

```sh
./renode-box test --all          # smoke + dry-run + examples
tests/test_dry_run.sh            # every launcher command in --dry-run, read-only ones for real, shellcheck
tests/test_smoke.sh              # Renode headless, renode-test, both GCCs, FreeRTOS, dts2repl, every template
tests/test_templates.sh [kind]   # new + make + robot for each template (part of the smoke test)
```

Last known (2026-10-29): doctor 19 ok; `examples test` 18/18; `test_dry_run.sh` 30/30 (shellcheck clean);
`test_smoke.sh` 21/21 (9 tool checks + 12 templates). A fresh clone passed bootstrap, install, doctor and `test --all`.

## Troubleshooting

| Symptom | Fix |
|---|---|
| Temp files vanish while Renode runs | Renode deletes stale `/tmp/renode-*` at start: do not use that prefix for your own files |
| `renode-test` leaves `robot_output.xml`, `log.html` in the source tree | it writes to the cwd; use `./renode-box robot` or `examples test`, which run it from the results dir |
| `$(...)` around `renode-test` hangs | a Renode child keeps the pipe open: write to a file instead |
| Unaligned `sw` loops back to `_start` (RISC-V) | `.bss` must be 8-aligned |
| K210 `.resc` fails on `SetSerialExecution` | `machine SetSerialExecution True` must come after `mach create` |
| FreeRTOS build error on tick config | do not set both `configUSE_16_BIT_TICKS` and `configTICK_TYPE_WIDTH_IN_BITS` |
| k210 and litex objects mix | the Makefile uses `override OUT`; keep it |
| dts2repl writes `output.repl` in the cwd | pass `-o FILE` |
| Renode exits at once in a background script | `--console` reads stdin and quits on EOF: use `--disable-gui` without `--console` (`ex_renode_bg`) |
| `MappedMemory` fails: "size has to be aligned to guest page size" | memories are multiples of 4 KiB; keep the real size in the linker script |
| nRF52840 TIMER: SHORTS / BITMODE "unhandled" | Renode 1.17's model has neither: step `CC[0]` in the ISR (`nrf52840_timer_irq`) |
| `Write Line To Uart` times out | it waits for the echo by default: echo input in the firmware or pass `waitForEcho=false` |
| A trace file becomes `trace.txt.1` | Renode renames an existing output file; move the old one away first |
| `update --check` hits an API limit | export `GITHUB_TOKEN` |
| Folder was moved, env broken | `./renode-box relocate` |

## Git

This folder is its own git repository (`renode-box`). Only sources are committed; `.gitignore` keeps out
everything `bootstrap`/`install` downloads and everything the examples and tests produce. A fresh clone:

```sh
./renode-box install && ./renode-box doctor && ./renode-box test --all
```

## Limitations / needs you

- Linux x64 is tested. Linux arm64 is pinned but untested. Windows: use Git Bash or MSYS2. macOS: Renode ships only a
  `.dmg`, which the launcher does not unpack (copy `Renode.app` to `install/renode-1.17.0/` or `brew install renode`).
- No exact SoC models for several of your boards (see the table above); `custom_board_dts` shows the dts2repl route.
- Hardware-only steps (flashing, probes) are not part of this ID: the examples and templates are checked in Renode only.
  The `.bin` files are built for the real memory maps; flash them with 32_08_probe_tools.
- No sudo, licence or hardware needed. No open items for this ID in `$BOX/00_09_meta/02_logs/2026_10_25_open_items.md`.

## Scripts

Each script has a `[scripts.*]` descriptor in `.box.toml` (`box scripts show 32_06`; `box scripts check 32_06` must stay clean).

- `examples/custom_board_dts/example.sh`: custom board from a devicetree: weact_h743.dts -> dts2repl -> .repl -> STM32H743 firmware + test
- `examples/<ex>/example.sh` for the 12 examples added on 2026-10-29 (`./renode-box examples list` prints each `# about:` line);
  `examples/trace_coverage/coverage.py` and `examples/uart_socket_host/host_client.py` are their host-side Python helpers
- `examples/fw/ex.sh`: helpers sourced by examples/*/example.sh (run through ./renode-box examples ..., which puts Renode and the toolchains on PATH and sets EX_DIR, EX_OUT, RENODE_DIR)
- `examples/linux_k210_zynq/example.sh`: prebuilt Linux, offline: K210 NOMMU Linux (rv64) and Zynq-7000 Cortex-A9 buildroot (login + uname)
- `examples/nrf52840_nicenano/example.sh`: nRF52840 nice!nano: bare-metal UART echo + LED P0.15, and the prebuilt Zephyr shell (offline)
- `examples/riscv_k210_litex/example.sh`: RISC-V bare-metal on Kendryte K210 (rv64, owned board) and LiteX VexRiscv (rv32)
- `examples/stm32f4_blackpill/example.sh`: BlackPill F411 (STM32F412 model) bare-metal: USART1 banner, LED PC13 blink, KEY PA0
- `examples/stm32f4_freertos/example.sh`: FreeRTOS V11.3.2 on the BlackPill F411 model: tasks + queue + timer, LED timing checked
- `lib/boxtool.bash`: shared launcher framework (boxtool 3: bootstrap, pinned downloads, pixi env, every common command); byte-identical copy of `$BOX/00_09_meta/05_policy/templates/tool/lib/boxtool.bash` (edit there, then sync)
- `lib/renode.bash`: this tool's part of the launcher: TOOL_* settings, hook_* functions and extra commands (`./renode-box help`)
- `renode-box`: the launcher (POSIX sh): bootstraps the pinned pixi, keeps caches inside this folder, then runs lib/; `./renode-box help` lists the commands
- `tests/test_dry_run.sh`: every launcher command in --dry-run mode, the read-only commands for real, plus shellcheck (no downloads or builds)
- `tests/test_smoke.sh`: Smoke test of the installed tools: Renode headless, renode-test, both GCCs, FreeRTOS, dts2repl, `new` templates (board from a DTS + robot test) on freshly built firmware, plus tests/test_templates.sh
- `tests/test_templates.sh`: every other template: `new` into a temp dir, `make`, then its Robot test in Renode
- `native/`: written by `./renode-box native` (wrappers in native/bin, native.zsh / native.bash); regenerate, do not edit

## Links

- Renode: <https://github.com/renode/renode/releases/tag/v1.17.0>; dts2repl: <https://github.com/antmicro/dts2repl>
- xPack GCC: <https://github.com/xpack-dev-tools/arm-none-eabi-gcc-xpack/releases/tag/v15.2.1-1.1>, <https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases/tag/v15.2.0-1>
- FreeRTOS-Kernel: <https://github.com/FreeRTOS/FreeRTOS-Kernel/releases/tag/V11.3.2>; pixi: <https://github.com/prefix-dev/pixi/releases/tag/v0.81.0>
- History: `NOTES.md`. Reports: `$BOX/00_09_meta/02_logs/2026_10_25_readability_embedded_tools_verification_report.md`.
- Sibling tools: `32_10_qemu` (fast CPU-level emulation), `32_07_kenning` (uses its own Renode copy).

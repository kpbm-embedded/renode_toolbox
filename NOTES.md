# 32_06_renode notes

## 2026-10-24
- Created the ID with the `renode-box` launcher, which pins pixi 0.81.0 by sha256 (same pins as `31_04_gazebo/gz-box`, plus Windows).
  The generic part lives in `lib/boxtool.bash`; the IDs 32_06..32_10 each keep an identical copy.
- Pins: Renode 1.17.0 portable, xPack Arm GCC 15.2.1-1.1, xPack RISC-V GCC 15.2.0-1, FreeRTOS-Kernel V11.3.2.
  The Antmicro demo images are pinned by the sha1 in their names.
- Renode has no STM32F411 model, so the BlackPill is the STM32F412 plus an LED/button `.repl`. The K210, nRF52840, H743 and LiteX models were used as they are.
- FreeRTOS V11.3.2: `configUSE_16_BIT_TICKS` and `configTICK_TYPE_WIDTH_IN_BITS` must not both be set. The version macro in
  the release still reads "V11.1.0+", so the test accepts `V11.*`.
- RISC-V: `.bss` must be 8-aligned; an unaligned `sw` loop trapped and looped back to `_start`. The Makefile uses
  `override OUT` so that the k210 and litex objects don't mix (command-line `OUT` beats a plain assignment).
- K210 resc: `machine SetSerialExecution True` must come after `mach create`.
- `renode-test` writes robot_output.xml, log.html and snapshots to the **cwd**: `ex_robot` and `renode-box robot` run it from
  the results dir. Files that ended up in the source tree were moved to the Trash (logged).
- dts2repl writes `output.repl` to the cwd unless `-o` is given.

## 2026-10-25
- Renode clears stale `/tmp/renode-*` folders at start. The smoke test's temp dir is now `rbox-smoke.*` (it had been vanishing).
  A `$(...)` around `renode-test` could also hang when a Renode child kept the pipe open, so the tests write to files.
- Synced `boxtool.bash` into 32_07..32_10. Fixes: the `cmd_new` chmod/`rest` options, quiet curl off a tty, and `BUILD` kept
  across conda compiler activation (found in 32_09).
- Results: doctor 19 ok; `examples test` 6/6; `tests/test_dry_run.sh` 28/28 (shellcheck clean); `tests/test_smoke.sh` 9/9.

## 2026-10-25: readability pass 2 (script_style.md, scripts/README)
- lib/boxtool.bash (reference `00_09_meta/05_policy/templates/tool/lib/boxtool.bash`, synced to all 24 copies):
  `where`/`status`/`doctor`/`bootstrap`/`relocate` reject extra arguments (exit 2); colour only on a terminal
  and never with `NO_COLOR`; help lists `NO_COLOR`.
- `help` now ends with `tool examples` / `tool environment` (hook_help in lib/renode.bash).
- README: exit codes, `BOX_INTEGRATION` and `NO_COLOR` rows. Backups:
  `00_09_meta/02_logs/config_backups/2026_10_25_readability2_embedded_tools/`.

## 2026-10-29: 12 examples, 12 templates, own git repo
- New examples (all simulated, no board): `gdb_debug`, `uart_hub_two_nodes`, `snapshot_save_load`, `trace_coverage`,
  `python_peripheral`, `csharp_peripheral`, `ch32v003_custom_soc`, `nrf52840_timer_irq`, `k210_dual_hart`,
  `fault_log_checks`, `uart_socket_host`, `i2c_sensor_stm32`. `examples/fw/ex.sh` gained `ex_renode_bg`,
  `ex_renode_stop`, `ex_free_port`, `ex_wait_port` for host-side clients (gdb, sockets).
- New templates: `stm32f4_baremetal`, `nrf52840_baremetal`, `k210_baremetal`, `rv32_custom_soc`, `freertos_stm32f4`,
  `multi_node`, `python_peripheral`, `csharp_peripheral`, `linux_boot_test`, `zephyr_snapshot_test`, `trace_coverage`,
  `gdb_test`. Firmware templates are standalone (own startup, linker script, `print.h`); the robot-only ones default to
  the cached Zephyr shell for nRF52840. `tests/test_templates.sh` instantiates, builds and runs each; `test_smoke.sh` calls it.
- Problems found:
  - `renode --console` with stdin from /dev/null quits at EOF before a gdb or socket client connects. Background runs
    use `--disable-gui` without `--console`.
  - `MappedMemory` sizes must be multiples of 4 KiB: the CH32V003's 2 KiB SRAM is mapped as 4 KiB, the linker script keeps 2 KiB.
  - nRF52840 TIMER model: SHORTS and BITMODE are not implemented ("unhandled write"). The ISR steps `CC[0]` on a 16-bit timer.
  - `stm32f412.repl` already has I2C1-3 (from `stm32f4.repl`) and a `crc` peripheral: names in added `.repl` lines must not clash.
  - The K210 CPUs are named `cpu1`/`cpu2` (hart ids 0/1); RISC-V `GetRegister "mhartid"` does not exist, `HartId` does.
  - The prebuilt Zephyr shell image needs the legacy UART (`easyDMA: false`); with Renode's plain `nrf52840.repl` it prints nothing.
  - `Write Line To Uart` waits for the echo; regex results are `${line.Groups[n]}`; `exit=0` as an argument is read
    as a named argument (escape or reword).
  - Execution traces: about 10 bytes per instruction; Renode renames an existing output file to `.1`, `.2`.
  - The gdb breakpoint on `main` in the Zephyr image has two locations ("Breakpoint 1.2, main").
- Git: `git init -b main`; strict `.gitignore` (no install/, cache/, .pixi/, .bin/, native/, build/log output, traces,
  snapshots, firmware binaries).
- Results: doctor 19 ok; `examples test` 18/18; `test_templates.sh` 12/12; `test_smoke.sh` 21/21; `test_dry_run.sh` 30/30
  (shellcheck clean, 25 files). Fresh clone (`clone_check`, cache symlinked): install, doctor and `test --all` passed.

## 2026-10-29: Rust, Zig and BEAM (addendum to the brief)
- Rust: `rust_baremetal` example and template. A `no_std` crate without dependencies (own startup and vector table,
  `core::fmt` UART, panic handler with location) for the BlackPill F411 and a CH32V203-like RV32IMAC board
  (`ch32v203.repl`). Built by 32_17_embedded_rust's `rust-box cargo --offline`; nothing copied.
- Zig: `zig_baremetal` example and template for the nRF52840. Freestanding Zig built by 32_24_microzig's `microzig-box zig`,
  with `logic.zig` unit-tested on the host first.
- Not added: 32_22_rust_next (ESP32-S3 has no Renode model; Ariel OS needs laze and network crates) and BEAM/AtomVM
  (images only for Pico and ESP32-S3, neither modelled by Renode 1.17; the STM32 port is not built by 32_29).
- `examples/fw/ex.sh`: `ex_sibling_launcher` finds another ID's launcher (`$BOX_<NAME>`, else the sibling folder) and
  exits 3 with a "skip: needs ..." line when it is missing. `examples test` lists such an example as FAIL, because
  `lib/boxtool.bash` does not tell exit 3 apart (reported; the shared file was not changed). `test_templates.sh`
  prints "skip" for templates whose `make` says "skip: needs".
- Problems: Zig 0.17 dropped the `**` array repeat (use `@splat`); `zig build-exe` sets entry `_start` unless
  `-fentry=Reset_Handler`; a robot argument like `data=7` is read as a named argument (the firmware prints `data 7`).
- Results: `examples test` 20/20; templates 14/14; `test_smoke.sh` 23/23; `test_dry_run.sh` 30/30 (shellcheck clean).

## 2026-10-29: server mode, UI, coverage, girdl (follow-up)
- Server mode: `server` command (`renode --server-mode`, WebSocket API, protocol 1.5.0), `lib/ws_client.py`, a doctor
  check that starts a server on a free port and asks it for `status`. 1.17 binds 0.0.0.0 with no option (README warns).
- UI: Renode 1.17.0's portable package does ship `platform-lib/linux-x64/renode-ui` (an earlier note said it did not:
  `find` was run on the `install/renode` symlink without `-L`). `ui` runs `renode --ui`; with `--ui` the port is
  always 21234 (`--server-mode-port` is refused). Tested on a private `kwin_wayland --virtual` display: the UI starts
  and holds a WebSocket connection. Stopping Renode with a signal makes .NET abort (core dump); renode-ui aborts if
  the server goes away under it: the example stops the UI first, then sends `quit` over the API.
- Coverage: `retrace` and `covflow` commands (`lib/covflow.py`: retracer -> LCOV, info-process merge/pack, summary
  checks, standalone Coverview page). info-process pinned in the pixi env; Coverview as an optional add-on.
  Retracer 1.17 bug: with DWARF<5 line tables it maps directory 0 (compile dir) to the last include dir, so sources
  compiled as plain `main.c` are "not found"; the `coverage_lcov` template compiles by absolute path.
- Zephyr: `zephyr_coverage` (32_03's ztest-basic on riscv32_virtual, trace vs 32_03's gcov: 98.5 % vs 98 % of the
  test's lines) and `west_renode_gen` (west-renode-gen in a throwaway workspace with a shared clone of 32_03's zephyr;
  its patch 0002 does not apply to Zephyr v4.4.2, so trace -> .info is done by covflow). 32_03 not changed.
- girdl: Ghidra 12.2 needs Java >= 25 and Gradle >= 9.1, so the pins moved from JDK 21 / Gradle 8.14 to Temurin
  25.0.5+8 / Gradle 9.8.2 (old installs trashed, logged). girdl is built from source (f28fc4a); `ghidra` installs it as
  a user extension in `cache/xdg-config/<user>-ghidra/ghidra_12.2_PUBLIC/Extensions`. An empty "Data Source 2" made
  girdl scan the current directory: pass the map as source 2. Headless, the map + RDL give typed, labelled
  peripherals; the BlackPill firmware's 18 peripheral accesses all resolve (usart1, rcc, gpioPortA/C).
- Other 2025-2026 features with one example each: external control API in C, Helium/MVE on the RA8M1 Cortex-M85,
  Zephyr dashboard artifacts (incl. i.MX 8M Plus M7, Pico; ESP32-S3 needs the pinned nightly).
- New examples (9): server_mode_api, renode_ui, external_control_api, coverage_lcov, zephyr_coverage, west_renode_gen,
  zephyr_dashboard, helium_mve_m85, girdl_ghidra. New templates (4): server_client, coverage_lcov, helium_m85,
  girdl_ghidra. `test_templates.sh` runs a template's `test.sh` when it has one (exit 3 = skip).
- Still open (shared file, reported): `lib/boxtool.bash` `examples test` counts exit 3 as FAIL.
- Results (add-ons installed): doctor 24 ok; `examples test` 29/29; `test_smoke.sh` 27/27 (18 templates);
  `test_dry_run.sh` 39/39 (shellcheck clean, templates' shell scripts included).
- Fresh clone: `install` (which runs `examples build`) failed on girdl_ghidra and west_renode_gen before the add-ons
  were installed (exit 3 counted as FAIL); their `build` is now a no-op with a "skip" line, `test` still exits 3.

# @NAME@: line coverage from Renode traces (from `./renode-box new coverage_lcov`)

BlackPill F411 firmware built at `-O0 -g3` plus a Robot suite that records one execution trace per test case.
`test.sh` turns the traces into LCOV (renode-retracer), merges them (info-process; `merged.desc` says which test hit
each line), checks lines that must and must not be hit, and packs a Coverview archive. No gcov, no instrumented build:
the same ELF you flash is the one measured.

| File | What |
|---|---|
| `main.c`, `print.h`, `startup.c`, `stm32f411.ld` | command parser on USART1: `l` LED, `c` counter, `r` reset, anything else "unknown" |
| `@NAME@.repl`, `@NAME@.resc` | Renode's STM32F412 + LED/KEY, machine script |
| `@NAME@.robot` | two test cases, `cpu CreateExecutionTracing ... PCAndOpcode` each |
| `test.sh` | robot -> `covflow info` -> `covflow merge` -> `covflow summary --hit/--miss` -> `covflow pack/html` |

```sh
./renode-box run make -C <dir>/@NAME@
./renode-box run bash <dir>/@NAME@/test.sh          # output: <dir>/@NAME@/build/cov/
./renode-box extras install coverview                # optional: coverage.html opens offline in a browser
```
`cmd_reset` stays uncovered on purpose; add a test case that sends `r` and move its check from `--miss` to `--hit`.

# @NAME@: snapshot-based test suite (from `./renode-box new zephyr_snapshot_test`)

`renode-test` resets the emulation between tests, so each test normally boots again. Here the first test
boots once and saves the emulation (`Save @file`); every later test starts with `Load @file`. The default
image is the prebuilt Zephyr shell for nRF52840 from renode-box's cache (offline); pass your own with
`--variable ELF:` (and `PLATFORM`, `UART`, `PROMPT`).

```sh
./renode-box robot <dir>/@NAME@/@NAME@.robot
./renode-box robot <dir>/@NAME@/@NAME@.robot --variable ELF:build/zephyr/zephyr.elf --variable PLATFORM:platforms/cpus/nrf52840.repl
```
Keep `Snapshot Should Be Written` first: tests run in file order. Snapshots are tied to the Renode version.

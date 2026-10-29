# @NAME@: Renode board (from `./renode-box new board`)

| File | What |
|---|---|
| `@NAME@.repl` | platform: generated from your DTS (`--dts`), or a `using` of a bundled CPU .repl plus LED/button stubs to edit |
| `@NAME@.resc` | machine script: loads the platform and `$elf`, opens the UART analyzer |
| `@NAME@.robot` | Robot Framework test: banner on the UART (edit `${UART}` / `${BANNER}`) |

```sh
./renode-box renode -e '$elf=@/path/fw.elf; include @<dir>/@NAME@/@NAME@.resc; start'
./renode-box robot <dir>/@NAME@/@NAME@.robot --variable ELF:/path/fw.elf --variable BANNER:Hello
./renode-box repl build/zephyr/zephyr.dts -o <dir>/@NAME@/@NAME@.repl   # regenerate from a Zephyr build
./renode-box platforms stm32                                             # bundled CPU/board .repl files
```

Platform sources: a Zephyr build's `build/zephyr/zephyr.dts` is the best input for dts2repl
(it is already flattened). Without a DTS, start from the closest bundled CPU description
(`./renode-box platforms <filter>`) and add board parts (LEDs, buttons, sensors) as in
`examples/stm32f4_blackpill/blackpill_f411.repl`.

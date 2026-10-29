# @NAME@: Renode Robot Framework test (from `./renode-box new robot_test`)

`@NAME@.robot` shows the usual keywords (Renode's `tests/renode-keywords.robot`):
UART line/prompt waits and writes, LED state and blink timing, button presses, monitor
commands, virtual-time checks and a Linux login. Delete what you do not need.

```sh
./renode-box robot <dir>/@NAME@/@NAME@.robot --variable RESC:/path/board.resc --variable ELF:/path/fw.elf --variable UART:sysbus.usart1
```
Results (log.html, report.html, robot_output.xml, failure snapshots) go to the ID's log/robot/.

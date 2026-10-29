# @NAME@: peripheral model in Python (from `./renode-box new python_peripheral`)

Model a register block before (or without) writing C#: the script runs in Renode's IronPython for each
access (`request.IsInit/IsRead/IsWrite`, `request.Offset`, `request.Value`; `self.InfoLog(...)`).

| File | What |
|---|---|
| `@NAME@.repl` | the platform (`using` a CPU .repl) plus the Python peripheral at 0x40080000 |
| `@NAME@.robot` | a register-level test bench from the monitor: no firmware needed |

```sh
./renode-box robot <dir>/@NAME@/@NAME@.robot
```
Use it from firmware as in the `python_peripheral` example (`./renode-box examples test python_peripheral`).
Keep the script small: state lives in the script's variables and is reset with the machine.

# @NAME@: peripheral model in C# (from `./renode-box new csharp_peripheral`)

A Renode peripheral class compiled at run time (no Renode rebuild): `include @@NAME@.cs`, then map it with
`machine LoadPlatformDescriptionFromString "dut: Miscellaneous.@NAME@ @ sysbus 0x40081000 { IRQ -> nvic@60 }"`
or put the same line in your `.repl` (after the `include` in your `.resc`).

| File | What |
|---|---|
| `@NAME@.cs` | `BasicDoubleWordPeripheral` with the register DSL: CTRL/STATUS(W1C)/INPUT/VALUE and an IRQ line |
| `@NAME@.robot` | register-level test bench from the monitor (compute, W1C, IRQ follows DONE) |

```sh
./renode-box robot <dir>/@NAME@/@NAME@.robot
```
The class name is the template name, so keep it a valid C# identifier. Compile errors show in the Robot log.
For firmware using a C# model, see the `csharp_peripheral` example.

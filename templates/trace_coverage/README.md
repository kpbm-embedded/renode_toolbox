# @NAME@: function coverage from an execution trace (from `./renode-box new trace_coverage`)

Renode writes every executed PC to a file (`cpu CreateExecutionTracing "tracer" @file PC`); `coverage.py`
(pyelftools, in the renode-box env) maps the PCs onto the ELF's functions and checks expectations.
Default firmware: the prebuilt Zephyr shell for nRF52840 (offline cache).

```sh
./renode-box robot <dir>/@NAME@/@NAME@.robot
./renode-box robot <dir>/@NAME@/@NAME@.robot --variable ELF:fw.elf --variable EXPECT_HIT:main,my_isr --variable EXPECT_MISS:panic
./renode-box run python <dir>/@NAME@/coverage.py fw.elf trace.txt      # report only
```
Traces grow with every executed instruction (about 10 bytes each): trace short windows, and prefer
firmware that sleeps (`wfi`) when idle.

# Batch gdb session against Renode's GDB server: breakpoint, read and write target memory.
set pagination off
set confirm off
break filter_step
continue
printf "first=%u\n", g_state.steps
continue
continue
printf "third=%u\n", g_state.steps
set var g_gain = 100
printf "before=%d\n", g_state.acc
printf "in=%d\n", in
delete
finish
printf "after=%d gain=%d\n", g_state.acc, g_gain
detach

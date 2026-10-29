/* start.S (K210, rv64): hart 0 sets up gp/sp, zeroes .bss, calls main; hart 1 parks in wfi. */
    .section .text.start, "ax"
    .globl _start
_start:
    csrr  t0, mhartid
    bnez  t0, park
    .option push
    .option norelax
    la    gp, __global_pointer$
    .option pop
    la    sp, _stack_top
    la    t0, _sbss
    la    t1, _ebss
1:  bgeu  t0, t1, 2f
    sd    zero, 0(t0)
    addi  t0, t0, 8
    j     1b
2:  call  main
park:
    wfi
    j     park

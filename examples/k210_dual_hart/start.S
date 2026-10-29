/* start.S (K210, rv64): both harts start here. Each gets its own 8 KiB stack; hart 0
 * zeroes .bss and calls main, hart 1 waits for `hart1_go` (in .data) and calls hart1_main. */
    .section .text.start, "ax"
    .globl _start
_start:
    .option push
    .option norelax
    la    gp, __global_pointer$
    .option pop
    csrr  t0, mhartid
    la    sp, _stack_top
    slli  t1, t0, 13
    sub   sp, sp, t1
    bnez  t0, other
    la    t0, _sbss
    la    t1, _ebss
1:  bgeu  t0, t1, 2f
    sd    zero, 0(t0)
    addi  t0, t0, 8
    j     1b
2:  call  main
3:  j     3b
other:
    la    t0, hart1_go
4:  lw    t1, 0(t0)
    beqz  t1, 4b
    fence
    call  hart1_main
5:  wfi
    j     5b

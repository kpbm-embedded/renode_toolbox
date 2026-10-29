/* start.S: RV32/RV64 bare-metal entry. Hart 0 sets up the stack, zeroes .bss and calls
 * main; other harts (K210 has two) park in wfi. */
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
    sw    zero, 0(t0)
    addi  t0, t0, 4
    j     1b
2:  call  main
park:
    wfi
    j     park

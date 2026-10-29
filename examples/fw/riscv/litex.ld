/* litex.ld: everything in RAM @0x40000000 (16M); the ELF is loaded by Renode (sysbus LoadELF) */
ENTRY(_start)
MEMORY { RAM (rwx) : ORIGIN = 0x40000000, LENGTH = 16M }
SECTIONS
{
    .text : { *(.text.start) *(.text*) } > RAM
    .rodata : { *(.rodata*) *(.srodata*) } > RAM
    .data : { *(.data*) *(.sdata*) } > RAM
    PROVIDE(__global_pointer$ = . + 0x800);
    .bss (NOLOAD) : { . = ALIGN(8); _sbss = .; *(.sbss*) *(.bss*) *(COMMON) . = ALIGN(8); _ebss = .; } > RAM
    . = ALIGN(16);
    . += 0x4000;
    _stack_top = .;
}

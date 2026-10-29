/* ch32v003.ld: 16K flash @0x00000000, 2K SRAM @0x20000000 */
ENTRY(_start)
MEMORY
{
    FLASH (rx)  : ORIGIN = 0x00000000, LENGTH = 16K
    RAM   (rwx) : ORIGIN = 0x20000000, LENGTH = 2K
}
_estack = ORIGIN(RAM) + LENGTH(RAM);
SECTIONS
{
    .text : { *(.text.start) *(.text*) *(.rodata*) *(.srodata*) . = ALIGN(4); } > FLASH
    _sidata = LOADADDR(.data);
    .data : { _sdata = .; *(.data*) *(.sdata*) . = ALIGN(4); _edata = .; } > RAM AT > FLASH
    PROVIDE(__global_pointer$ = _sdata + 0x800);
    .bss (NOLOAD) : { _sbss = .; *(.sbss*) *(.bss*) *(COMMON) . = ALIGN(4); _ebss = .; } > RAM
}

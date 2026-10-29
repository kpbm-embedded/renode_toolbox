/* startup.c: Cortex-M vector table, .data copy, .bss zero, then main. Handlers are weak:
 * define e.g. `void SysTick_Handler(void)` in your code to override one. External IRQ n
 * is vector 16+n (32 entries here; extend for more). */
#include <stdint.h>
extern uint32_t _sidata, _sdata, _edata, _sbss, _ebss, _estack;
int main(void);
void Default_Handler(void) { for (;;) ; }
void Reset_Handler(void)
{
    uint32_t *s = &_sidata, *d = &_sdata;
    while (d < &_edata) *d++ = *s++;
    for (d = &_sbss; d < &_ebss;) *d++ = 0;
#if defined(__ARM_FP)
    *(volatile uint32_t *)0xE000ED88 |= (0xFu << 20); /* FPU on */
    __asm volatile("dsb\n isb");
#endif
    main();
    for (;;) ;
}
#define WEAK __attribute__((weak, alias("Default_Handler")))
void NMI_Handler(void) WEAK;
void HardFault_Handler(void) WEAK;
void SVC_Handler(void) WEAK;
void PendSV_Handler(void) WEAK;
void SysTick_Handler(void) WEAK;
__attribute__((section(".isr_vector"), used))
void (*const vectors[16 + 32])(void) = {
    (void (*)(void))(&_estack), Reset_Handler, NMI_Handler, HardFault_Handler,
    Default_Handler, Default_Handler, Default_Handler, 0, 0, 0, 0, SVC_Handler,
    Default_Handler, 0, PendSV_Handler, SysTick_Handler,
    [16 ... 47] = Default_Handler,
};

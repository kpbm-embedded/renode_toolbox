/* startup.c: minimal Cortex-M startup (vector table, .data copy, .bss zero, main).
 * Handlers are weak aliases of Default_Handler; FreeRTOS maps its port handlers onto
 * SVC_Handler / PendSV_Handler / SysTick_Handler through FreeRTOSConfig.h. */
#include <stdint.h>

extern uint32_t _sidata, _sdata, _edata, _sbss, _ebss, _estack;
int main(void);

void Default_Handler(void)
{
    for (;;)
        ;
}

void Reset_Handler(void)
{
    uint32_t *s = &_sidata, *d = &_sdata;
    while (d < &_edata)
        *d++ = *s++;
    for (d = &_sbss; d < &_ebss;)
        *d++ = 0;
#if defined(__ARM_FP)
    /* enable CP10/CP11 (FPU) before any float code runs */
    *(volatile uint32_t *)0xE000ED88 |= (0xFu << 20);
    __asm volatile("dsb\n isb");
#endif
    main();
    for (;;)
        ;
}

#define WEAK __attribute__((weak, alias("Default_Handler")))
void NMI_Handler(void) WEAK;
void HardFault_Handler(void) WEAK;
void MemManage_Handler(void) WEAK;
void BusFault_Handler(void) WEAK;
void UsageFault_Handler(void) WEAK;
void SVC_Handler(void) WEAK;
void DebugMon_Handler(void) WEAK;
void PendSV_Handler(void) WEAK;
void SysTick_Handler(void) WEAK;

__attribute__((section(".isr_vector"), used))
void (*const vectors[16 + 32])(void) = {
    (void (*)(void))(&_estack),
    Reset_Handler, NMI_Handler, HardFault_Handler, MemManage_Handler, BusFault_Handler,
    UsageFault_Handler, 0, 0, 0, 0, SVC_Handler, DebugMon_Handler, 0, PendSV_Handler,
    SysTick_Handler,
    /* external IRQs 0..31: unused by the examples */
    [16 ... 47] = Default_Handler,
};

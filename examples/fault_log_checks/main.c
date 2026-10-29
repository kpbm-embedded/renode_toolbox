/* Failure paths on the BlackPill F411 model: commands on USART1 trigger an undefined
 * instruction (HardFault, handler prints the stacked PC), an access to unmapped memory
 * (Renode logs it), or a bad assert. The test checks that each failure is caught. */
#include <stdint.h>
#include "bm.h"

#define RCC_AHB1ENR  REG32(0x40023830)
#define RCC_APB2ENR  REG32(0x40023844)
#define GPIOA_MODER  REG32(0x40020000)
#define GPIOA_AFRH   REG32(0x40020024)
#define USART1_SR    REG32(0x40011000)
#define USART1_DR    REG32(0x40011004)
#define USART1_BRR   REG32(0x40011008)
#define USART1_CR1   REG32(0x4001100C)
#define SCB_CFSR     REG32(0xE000ED28)

void bm_putc(char c)
{
    while (!(USART1_SR & (1u << 7)))
        ;
    USART1_DR = (uint8_t)c;
}

/* overrides the weak alias in startup.c; r0 = stacked frame (MSP) */
__attribute__((naked)) void HardFault_Handler(void)
{
    __asm volatile("mrs r0, msp\n b hardfault_report");
}

__attribute__((used)) void hardfault_report(uint32_t *frame)
{
    bm_puts("HARDFAULT pc=");
    bm_hex(frame[6]);
    bm_puts(" cfsr=");
    bm_hex(SCB_CFSR);
    bm_puts("\n");
    for (;;)
        ;
}

__attribute__((noinline)) void do_undefined(void) { __asm volatile("udf #42"); }

#define ASSERT(c) do { if (!(c)) { bm_puts("ASSERT failed: " #c "\n"); } } while (0)

int main(void)
{
    RCC_AHB1ENR |= 1u;
    RCC_APB2ENR |= 1u << 4;
    GPIOA_MODER = (GPIOA_MODER & ~(0xFu << 18)) | (0xAu << 18);
    GPIOA_AFRH = (GPIOA_AFRH & ~0xFF0u) | (0x77u << 4);
    USART1_BRR = 0x8B;
    USART1_CR1 = (1u << 13) | (1u << 3) | (1u << 2);
    bm_puts("fault demo: u=undefined insn, m=unmapped read, a=assert\n");
    for (;;) {
        if (!(USART1_SR & (1u << 5)))
            continue;
        char c = (char)USART1_DR;
        if (c == 'u') {
            do_undefined();
        } else if (c == 'm') {
            uint32_t v = REG32(0x30000000); /* nothing mapped there in the model */
            bm_puts("unmapped read gave ");
            bm_hex(v);
            bm_puts("\n");
        } else if (c == 'a') {
            uint32_t two = 2;
            ASSERT(two + two == 5);
        }
    }
}

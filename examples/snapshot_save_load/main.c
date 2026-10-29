/* Snapshot demo (BlackPill F411 model): a counter that only lives in RAM, printed as
 * "tick N". After Renode loads a snapshot the count continues from the saved value. */
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

volatile uint32_t g_ticks;

void bm_putc(char c)
{
    while (!(USART1_SR & (1u << 7)))
        ;
    USART1_DR = (uint8_t)c;
}

int main(void)
{
    RCC_AHB1ENR |= 1u;
    RCC_APB2ENR |= 1u << 4;
    GPIOA_MODER = (GPIOA_MODER & ~(0xFu << 18)) | (0xAu << 18);
    GPIOA_AFRH = (GPIOA_AFRH & ~0xFF0u) | (0x77u << 4);
    USART1_BRR = 0x8B;
    USART1_CR1 = (1u << 13) | (1u << 3) | (1u << 2);
    bm_puts("snapshot demo boot\n");
    for (;;) {
        for (volatile uint32_t d = 0; d < 200000; d++)
            ;
        bm_puts("tick ");
        bm_dec(++g_ticks);
        bm_puts("\n");
    }
}

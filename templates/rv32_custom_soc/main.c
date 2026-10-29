/* @NAME@: firmware for the hand-written platform: USART1 banner, LED PD0. */
#include <stdint.h>
#include "print.h"

#define RCC_APB2PCENR  REG32(0x40021018)
#define GPIOD_CFGLR    REG32(0x40011400)
#define GPIOD_BSHR     REG32(0x40011410)
#define USART1_STATR   REG32(0x40013800)
#define USART1_DATAR   REG32(0x40013804)
#define USART1_BRR     REG32(0x40013808)
#define USART1_CTLR1   REG32(0x4001380C)

void putc_console(char c)
{
    while (!(USART1_STATR & (1u << 7)))
        ;
    USART1_DATAR = (uint8_t)c;
}

int main(void)
{
    RCC_APB2PCENR |= (1u << 5) | (1u << 14);
    GPIOD_CFGLR = (GPIOD_CFGLR & ~0xF00000Fu) | 0xB000001u;
    USART1_BRR = 0x34;
    USART1_CTLR1 = (1u << 13) | (1u << 3) | (1u << 2);
    puts_console("@NAME@ up\n");
    for (uint32_t n = 0;; n++) {
        GPIOD_BSHR = (n & 1) ? (1u << 16) : 1u;
        puts_console((n & 1) ? "led on\n" : "led off\n");
        for (volatile uint32_t d = 0; d < 30000; d++)
            ;
    }
}

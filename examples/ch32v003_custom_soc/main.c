/* CH32V003-like bare metal on a hand-written Renode platform: USART1 (PD5 TX) banner,
 * LED PD0 blink, and a .data/.bss check (flash -> RAM copy). Register names follow the
 * CH32V003 reference manual; the layout is STM32F1-compatible. */
#include <stdint.h>
#include "bm.h"

#define RCC_APB2PCENR  REG32(0x40021018)
#define GPIOD_CFGLR    REG32(0x40011400)
#define GPIOD_BSHR     REG32(0x40011410)
#define USART1_STATR   REG32(0x40013800)
#define USART1_DATAR   REG32(0x40013804)
#define USART1_BRR     REG32(0x40013808)
#define USART1_CTLR1   REG32(0x4001380C)

static uint32_t magic = 0xC0FFEE03u; /* .data: must arrive from flash */
static uint32_t zeroed;              /* .bss */

void bm_putc(char c)
{
    while (!(USART1_STATR & (1u << 7)))
        ;
    USART1_DATAR = (uint8_t)c;
}

int main(void)
{
    RCC_APB2PCENR |= (1u << 5) | (1u << 14); /* IOPD, USART1 */
    GPIOD_CFGLR = (GPIOD_CFGLR & ~0xF00000Fu) | 0xB000001u; /* PD0 out, PD5 AF push-pull */
    USART1_BRR = 0x34;                                /* 6 MHz HSI/... 115200 (approx.) */
    USART1_CTLR1 = (1u << 13) | (1u << 3) | (1u << 2);
    bm_puts("CH32V003-like RV32EC up\n");
    bm_puts(magic == 0xC0FFEE03u && zeroed == 0 ? "data/bss ok\n" : "data/bss BROKEN\n");
    uint32_t misa;
    __asm volatile("csrr %0, misa" : "=r"(misa));
    bm_puts("misa ");
    bm_hex(misa);
    bm_puts((misa & (1u << 4)) ? " (E)\n" : " (no E)\n");
    for (uint32_t n = 0;; n++) {
        GPIOD_BSHR = (n & 1) ? (1u << 16) : 1u; /* PD0 low = LED on */
        bm_puts((n & 1) ? "led on\n" : "led off\n");
        for (volatile uint32_t d = 0; d < 30000; d++)
            ;
    }
}

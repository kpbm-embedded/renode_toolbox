/* Trace/coverage demo (BlackPill F411 model): a small command parser. The test feeds it
 * only some commands, so some handlers never run; the PC trace shows which ones. */
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

void bm_putc(char c)
{
    while (!(USART1_SR & (1u << 7)))
        ;
    USART1_DR = (uint8_t)c;
}

__attribute__((noinline)) void cmd_led(void) { bm_puts("led toggled\n"); }
__attribute__((noinline)) void cmd_status(void) { bm_puts("status ok\n"); }
__attribute__((noinline)) void cmd_reset(void) { bm_puts("reset requested\n"); }
__attribute__((noinline)) void cmd_unknown(char c)
{
    bm_puts("unknown command ");
    bm_putc(c);
    bm_puts("\n");
}

static void dispatch(char c)
{
    switch (c) {
    case 'l': cmd_led(); break;
    case 's': cmd_status(); break;
    case 'r': cmd_reset(); break;
    default: cmd_unknown(c); break;
    }
}

int main(void)
{
    RCC_AHB1ENR |= 1u;
    RCC_APB2ENR |= 1u << 4;
    GPIOA_MODER = (GPIOA_MODER & ~(0xFu << 18)) | (0xAu << 18);
    GPIOA_AFRH = (GPIOA_AFRH & ~0xFF0u) | (0x77u << 4);
    USART1_BRR = 0x8B;
    USART1_CR1 = (1u << 13) | (1u << 3) | (1u << 2);
    bm_puts("cmd> ");
    for (;;) {
        if (USART1_SR & (1u << 5)) {
            char c = (char)USART1_DR;
            if (c == '\r' || c == '\n')
                continue;
            dispatch(c);
            bm_puts("cmd> ");
        }
    }
}

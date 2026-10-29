/* @NAME@: command parser on the BlackPill F411 (USART1 at 115200 on the 16 MHz HSI, LED PC13 active low).
 * Built at -O0 so every source line has its own code: line coverage from a Renode trace (no gcov). */
#include <stdint.h>
#include "print.h"

#define RCC_AHB1ENR  REG32(0x40023830)
#define RCC_APB2ENR  REG32(0x40023844)
#define GPIOA_MODER  REG32(0x40020000)
#define GPIOA_AFRH   REG32(0x40020024)
#define GPIOC_MODER  REG32(0x40020800)
#define GPIOC_ODR    REG32(0x40020814)
#define USART1_SR    REG32(0x40011000)
#define USART1_DR    REG32(0x40011004)
#define USART1_BRR   REG32(0x40011008)
#define USART1_CR1   REG32(0x4001100C)

void putc_console(char c)
{
    while (!(USART1_SR & (1u << 7)))
        ;
    USART1_DR = (uint8_t)c;
}

static void cmd_led(void)
{
    GPIOC_ODR ^= 1u << 13;
    puts_console("led toggled\n");
}

static void cmd_count(uint32_t *n)
{
    *n += 1;
    puts_console("count ");
    put_dec(*n);
    puts_console("\n");
}

static void cmd_reset(void)
{
    puts_console("reset requested\n");
}

static void cmd_unknown(char c)
{
    puts_console("unknown command ");
    putc_console(c);
    puts_console("\n");
}

int main(void)
{
    uint32_t count = 0;
    RCC_AHB1ENR |= (1u << 0) | (1u << 2);
    RCC_APB2ENR |= 1u << 4;
    GPIOA_MODER = (GPIOA_MODER & ~(0xFu << 18)) | (0xAu << 18);
    GPIOA_AFRH = (GPIOA_AFRH & ~0xFF0u) | (0x77u << 4);
    GPIOC_MODER = (GPIOC_MODER & ~(3u << 26)) | (1u << 26);
    USART1_BRR = 0x8B;
    USART1_CR1 = (1u << 13) | (1u << 3) | (1u << 2);
    puts_console("@NAME@ ready\ncmd> ");
    for (;;) {
        if (!(USART1_SR & (1u << 5)))
            continue;
        char c = (char)USART1_DR;
        if (c == '\r' || c == '\n')
            continue;
        switch (c) {
        case 'l': cmd_led(); break;
        case 'c': cmd_count(&count); break;
        case 'r': cmd_reset(); break;
        default: cmd_unknown(c); break;
        }
        puts_console("cmd> ");
    }
}

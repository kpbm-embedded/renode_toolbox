/* @NAME@: BlackPill F411 bare metal. USART1 (PA9/PA10) console at 115200 on the 16 MHz HSI,
 * LED PC13 (active low), KEY PA0 (active low). Register-level, no HAL. */
#include <stdint.h>
#include "print.h"

#define RCC_AHB1ENR  REG32(0x40023830)
#define RCC_APB2ENR  REG32(0x40023844)
#define GPIOA_MODER  REG32(0x40020000)
#define GPIOA_PUPDR  REG32(0x4002000C)
#define GPIOA_IDR    REG32(0x40020010)
#define GPIOA_AFRH   REG32(0x40020024)
#define GPIOC_MODER  REG32(0x40020800)
#define GPIOC_BSRR   REG32(0x40020818)
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

int main(void)
{
    RCC_AHB1ENR |= (1u << 0) | (1u << 2);
    RCC_APB2ENR |= 1u << 4;
    GPIOA_MODER = (GPIOA_MODER & ~(0xFu << 18)) | (0xAu << 18);
    GPIOA_AFRH = (GPIOA_AFRH & ~0xFF0u) | (0x77u << 4);
    GPIOA_PUPDR |= 1u;
    GPIOC_MODER = (GPIOC_MODER & ~(3u << 26)) | (1u << 26);
    USART1_BRR = 0x8B;
    USART1_CR1 = (1u << 13) | (1u << 3) | (1u << 2);
    puts_console("@NAME@ on BlackPill F411\n");
    int was = 0;
    for (uint32_t n = 0;; n++) {
        GPIOC_BSRR = (n & 1) ? (1u << (13 + 16)) : (1u << 13);
        puts_console((n & 1) ? "led on\n" : "led off\n");
        for (int i = 0; i < 20; i++) {
            int key = !(GPIOA_IDR & 1u);
            if (key && !was)
                puts_console("key pressed\n");
            was = key;
            for (volatile uint32_t d = 0; d < 10000; d++)
                ;
        }
    }
}

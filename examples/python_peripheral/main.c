/* Python peripheral demo (BlackPill F411 model + a sensor written in Python in the .repl).
 * Registers at 0x40080000: ID (RO), TEMP (centi-degC, RO), CTRL (write 1 = new sample),
 * COUNT (samples taken). The test changes the temperature from the monitor. */
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
#define SENS_ID      REG32(0x40080000)
#define SENS_TEMP    REG32(0x40080004)
#define SENS_CTRL    REG32(0x40080008)
#define SENS_COUNT   REG32(0x4008000C)

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
    bm_puts("sensor id ");
    bm_hex(SENS_ID);
    bm_puts("\n");
    if (SENS_ID != 0x5E450001u) {
        bm_puts("sensor missing\n");
        for (;;)
            ;
    }
    uint32_t last = 0xffffffffu;
    for (;;) {
        SENS_CTRL = 1;
        uint32_t t = SENS_TEMP;
        if (t != last) {
            bm_puts("temp ");
            bm_dec(t / 100);
            bm_putc('.');
            bm_dec((t / 10) % 10);
            bm_dec(t % 10);
            bm_puts(" C after ");
            bm_dec(SENS_COUNT);
            bm_puts(" samples\n");
            last = t;
        }
        for (volatile uint32_t d = 0; d < 20000; d++)
            ;
    }
}

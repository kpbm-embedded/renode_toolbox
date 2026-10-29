/* C# peripheral demo (BlackPill F411 model + Crc32Accel.cs at 0x40081000): the firmware
 * computes CRC-32 in software and on the "accelerator" and compares both. */
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
#define CRC_DATA     REG32(0x40081000)
#define CRC_RESULT   REG32(0x40081004)
#define CRC_CTRL     REG32(0x40081008)
#define CRC_COUNT    REG32(0x4008100C)

void bm_putc(char c)
{
    while (!(USART1_SR & (1u << 7)))
        ;
    USART1_DR = (uint8_t)c;
}

static uint32_t crc32_sw(const uint8_t *p, uint32_t n)
{
    uint32_t c = 0xFFFFFFFFu;
    while (n--) {
        c ^= *p++;
        for (int k = 0; k < 8; k++)
            c = (c & 1) ? (c >> 1) ^ 0xEDB88320u : c >> 1;
    }
    return ~c;
}

static const char msg[] = "123456789\0\0\0"; /* standard check string, padded to words */

int main(void)
{
    RCC_AHB1ENR |= 1u;
    RCC_APB2ENR |= 1u << 4;
    GPIOA_MODER = (GPIOA_MODER & ~(0xFu << 18)) | (0xAu << 18);
    GPIOA_AFRH = (GPIOA_AFRH & ~0xFF0u) | (0x77u << 4);
    USART1_BRR = 0x8B;
    USART1_CR1 = (1u << 13) | (1u << 3) | (1u << 2);

    /* 8 bytes = 2 words through the accelerator vs. software */
    CRC_CTRL = 1;
    const uint32_t *w = (const uint32_t *)(const void *)msg;
    CRC_DATA = w[0];
    CRC_DATA = w[1];
    uint32_t hw = CRC_RESULT, sw = crc32_sw((const uint8_t *)msg, 8);
    bm_puts("crc sw ");
    bm_hex(sw);
    bm_puts(" hw ");
    bm_hex(hw);
    bm_puts(" bytes ");
    bm_dec(CRC_COUNT);
    bm_puts(hw == sw ? " MATCH\n" : " MISMATCH\n");
    bm_puts("crc32(\"12345678\") check done\n");
    for (;;)
        ;
}

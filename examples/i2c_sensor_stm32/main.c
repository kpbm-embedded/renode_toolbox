/* I2C sensor on the BlackPill F411 model: register-level I2C1 master (PB6 SCL / PB7 SDA)
 * reads a TMP103 at 0x70 (register 0: temperature, signed degC) once per loop and
 * prints it on USART1. A missing device (NACK) is reported, not hung on. */
#include <stdint.h>
#include "bm.h"

#define RCC_AHB1ENR  REG32(0x40023830)
#define RCC_APB1ENR  REG32(0x40023840)
#define RCC_APB2ENR  REG32(0x40023844)
#define GPIOA_MODER  REG32(0x40020000)
#define GPIOA_AFRH   REG32(0x40020024)
#define GPIOB_MODER  REG32(0x40020400)
#define GPIOB_OTYPER REG32(0x40020404)
#define GPIOB_AFRL   REG32(0x40020420)
#define USART1_SR    REG32(0x40011000)
#define USART1_DR    REG32(0x40011004)
#define USART1_BRR   REG32(0x40011008)
#define USART1_CR1   REG32(0x4001100C)
#define I2C1_CR1     REG32(0x40005400)
#define I2C1_CR2     REG32(0x40005404)
#define I2C1_DR      REG32(0x40005410)
#define I2C1_SR1     REG32(0x40005414)
#define I2C1_SR2     REG32(0x40005418)
#define I2C1_CCR     REG32(0x4000541C)
#define I2C1_TRISE   REG32(0x40005420)
#define SR1_SB   (1u << 0)
#define SR1_ADDR (1u << 1)
#define SR1_BTF  (1u << 2)
#define SR1_RXNE (1u << 6)
#define SR1_TXE  (1u << 7)
#define SR1_AF   (1u << 10)
#define CR1_PE    (1u << 0)
#define CR1_START (1u << 8)
#define CR1_STOP  (1u << 9)
#define CR1_ACK   (1u << 10)

void bm_putc(char c)
{
    while (!(USART1_SR & (1u << 7)))
        ;
    USART1_DR = (uint8_t)c;
}

static int wait_sr1(uint32_t bits)
{
    for (uint32_t i = 0; i < 100000; i++) {
        uint32_t s = I2C1_SR1;
        if (s & SR1_AF) {
            I2C1_SR1 = ~SR1_AF;
            I2C1_CR1 |= CR1_STOP;
            return -1;
        }
        if (s & bits)
            return 0;
    }
    return -2;
}

/* read one register byte; returns 0..255, or <0 on NACK/timeout */
static int i2c_read_reg(uint8_t addr, uint8_t reg)
{
    I2C1_CR1 |= CR1_START | CR1_ACK;
    if (wait_sr1(SR1_SB)) return -2;
    I2C1_DR = (uint32_t)addr << 1;
    if (wait_sr1(SR1_ADDR)) return -1;
    (void)I2C1_SR2;
    I2C1_DR = reg;
    if (wait_sr1(SR1_TXE | SR1_BTF)) return -3;
    I2C1_CR1 |= CR1_START;
    if (wait_sr1(SR1_SB)) return -2;
    I2C1_DR = ((uint32_t)addr << 1) | 1u;
    if (wait_sr1(SR1_ADDR)) return -1;
    I2C1_CR1 &= ~CR1_ACK;
    (void)I2C1_SR2;
    I2C1_CR1 |= CR1_STOP;
    if (wait_sr1(SR1_RXNE)) return -3;
    return (int)(I2C1_DR & 0xFF);
}

int main(void)
{
    RCC_AHB1ENR |= 1u | (1u << 1); /* GPIOA, GPIOB */
    RCC_APB1ENR |= 1u << 21;       /* I2C1 */
    RCC_APB2ENR |= 1u << 4;        /* USART1 */
    GPIOA_MODER = (GPIOA_MODER & ~(0xFu << 18)) | (0xAu << 18);
    GPIOA_AFRH = (GPIOA_AFRH & ~0xFF0u) | (0x77u << 4);
    GPIOB_MODER = (GPIOB_MODER & ~(0xFu << 12)) | (0xAu << 12); /* PB6/PB7 AF */
    GPIOB_OTYPER |= 3u << 6;                                     /* open drain */
    GPIOB_AFRL = (GPIOB_AFRL & ~0xFF000000u) | 0x44000000u;      /* AF4 = I2C1 */
    USART1_BRR = 0x8B;
    USART1_CR1 = (1u << 13) | (1u << 3) | (1u << 2);
    I2C1_CR2 = 16;     /* APB1 16 MHz */
    I2C1_CCR = 80;     /* 100 kHz */
    I2C1_TRISE = 17;
    I2C1_CR1 = CR1_PE;
    bm_puts("i2c sensor demo\n");
    int missing = i2c_read_reg(0x48, 0);
    bm_puts(missing < 0 ? "no device at 0x48 (NACK)\n" : "unexpected device at 0x48\n");
    for (;;) {
        int t = i2c_read_reg(0x70, 0);
        if (t < 0) {
            bm_puts("tmp103 read error\n");
        } else {
            int8_t c = (int8_t)t;
            bm_puts("tmp103 ");
            if (c < 0) {
                bm_putc('-');
                c = (int8_t)-c;
            }
            bm_dec((uint32_t)c);
            bm_puts(" C\n");
        }
        for (volatile uint32_t d = 0; d < 100000; d++)
            ;
    }
}

/* BlackPill F411 bare-metal demo for Renode: USART1 console, LED PC13 (active low),
 * KEY button PA0 (active low). Register-level, no HAL. On real hardware the clock stays
 * on the 16 MHz HSI; USART1 BRR is set for 115200 baud at 16 MHz. */
#include <stdint.h>
#include "bm.h"

#define RCC_AHB1ENR  REG32(0x40023830)
#define RCC_APB2ENR  REG32(0x40023844)
#define GPIOA_BASE   0x40020000u
#define GPIOC_BASE   0x40020800u
#define GPIO_MODER(b) REG32((b) + 0x00)
#define GPIO_PUPDR(b) REG32((b) + 0x0C)
#define GPIO_IDR(b)   REG32((b) + 0x10)
#define GPIO_BSRR(b)  REG32((b) + 0x18)
#define GPIO_AFRH(b)  REG32((b) + 0x24)
#define USART1_SR    REG32(0x40011000)
#define USART1_DR    REG32(0x40011004)
#define USART1_BRR   REG32(0x40011008)
#define USART1_CR1   REG32(0x4001100C)

void bm_putc(char c)
{
    while (!(USART1_SR & (1u << 7))) /* TXE */
        ;
    USART1_DR = (uint8_t)c;
}

static void led(int on) /* PC13, active low */
{
    GPIO_BSRR(GPIOC_BASE) = on ? (1u << (13 + 16)) : (1u << 13);
}

static int key_pressed(void) /* PA0, active low with pull-up */
{
    return !(GPIO_IDR(GPIOA_BASE) & 1u);
}

static void delay(volatile uint32_t n)
{
    while (n--)
        ;
}

int main(void)
{
    RCC_AHB1ENR |= (1u << 0) | (1u << 2); /* GPIOA, GPIOC */
    RCC_APB2ENR |= (1u << 4);             /* USART1 */
    /* PA9/PA10 alternate function 7 (USART1) */
    GPIO_MODER(GPIOA_BASE) = (GPIO_MODER(GPIOA_BASE) & ~(0xFu << 18)) | (0xAu << 18);
    GPIO_AFRH(GPIOA_BASE) = (GPIO_AFRH(GPIOA_BASE) & ~0xFF0u) | (0x77u << 4);
    GPIO_PUPDR(GPIOA_BASE) |= 1u; /* PA0 pull-up */
    GPIO_MODER(GPIOC_BASE) = (GPIO_MODER(GPIOC_BASE) & ~(3u << 26)) | (1u << 26);
    USART1_BRR = 0x8B;                                  /* 16 MHz / 115200 */
    USART1_CR1 = (1u << 13) | (1u << 3) | (1u << 2);    /* UE | TE | RE */

    bm_puts("Hello from BlackPill F411 (Renode, 32_06_renode)\n");
    uint32_t n = 0;
    int was = 0;
    for (;;) {
        int on = (int)(n & 1);
        led(on);
        bm_puts("blink ");
        bm_dec(n++);
        bm_puts(on ? " led=on\n" : " led=off\n");
        for (int i = 0; i < 20; i++) {
            int k = key_pressed();
            if (k && !was)
                bm_puts("KEY pressed\n");
            was = k;
            delay(20000);
        }
    }
}

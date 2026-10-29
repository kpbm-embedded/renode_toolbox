/* nRF52840 (nice!nano) interrupts: TIMER0 compare IRQ toggles the LED every 250 ms,
 * GPIOTE IN[0] IRQ counts presses of a button on P0.11. Vector table moved to RAM (VTOR)
 * so the shared startup code stays untouched. Main only prints what the ISRs did. */
#include <stdint.h>
#include "bm.h"

#define UART0           0x40002000u
#define UART_STARTTX    REG32(UART0 + 0x008)
#define UART_TXDRDY     REG32(UART0 + 0x11C)
#define UART_ENABLE     REG32(UART0 + 0x500)
#define UART_PSELTXD    REG32(UART0 + 0x50C)
#define UART_TXD        REG32(UART0 + 0x51C)
#define UART_BAUDRATE   REG32(UART0 + 0x524)
#define TIMER0          0x40008000u
#define T_START         REG32(TIMER0 + 0x000)
#define T_COMPARE0      REG32(TIMER0 + 0x140)
#define T_INTENSET      REG32(TIMER0 + 0x304)
#define T_MODE          REG32(TIMER0 + 0x504)
#define T_BITMODE       REG32(TIMER0 + 0x508)
#define T_PRESCALER     REG32(TIMER0 + 0x510)
#define T_CC0           REG32(TIMER0 + 0x540)
#define GPIOTE          0x40006000u
#define GT_IN0          REG32(GPIOTE + 0x100)
#define GT_INTENSET     REG32(GPIOTE + 0x304)
#define GT_CONFIG0      REG32(GPIOTE + 0x510)
#define P0_OUTSET       REG32(0x50000508)
#define P0_OUTCLR       REG32(0x5000050C)
#define P0_DIRSET       REG32(0x50000518)
#define NVIC_ISER0      REG32(0xE000E100)
#define SCB_VTOR        REG32(0xE000ED08)
#define IRQ_GPIOTE      6
#define IRQ_TIMER0      8
#define PERIOD          7812 /* 31250 Hz * 0.25 s */

extern void (*const vectors[48])(void);
static void (*ram_vectors[48])(void) __attribute__((aligned(256)));
static volatile uint32_t ticks, presses;

void bm_putc(char c)
{
    UART_TXDRDY = 0;
    UART_TXD = (uint8_t)c;
    while (!UART_TXDRDY)
        ;
}

static void timer0_isr(void)
{
    T_COMPARE0 = 0;
    T_CC0 = (T_CC0 + PERIOD) & 0xFFFF; /* next compare; Renode 1.17's timer has no SHORTS */
    if (++ticks & 1)
        P0_OUTSET = 1u << 15;
    else
        P0_OUTCLR = 1u << 15;
}

static void gpiote_isr(void)
{
    GT_IN0 = 0;
    presses++;
}

int main(void)
{
    for (int i = 0; i < 48; i++)
        ram_vectors[i] = vectors[i];
    ram_vectors[16 + IRQ_TIMER0] = timer0_isr;
    ram_vectors[16 + IRQ_GPIOTE] = gpiote_isr;
    SCB_VTOR = (uint32_t)(uintptr_t)ram_vectors;

    P0_DIRSET = 1u << 15;
    UART_PSELTXD = 6;
    UART_BAUDRATE = 0x01D7E000;
    UART_ENABLE = 4;
    UART_STARTTX = 1;
    bm_puts("nrf52840 irq demo\n");

    T_MODE = 0;          /* timer */
    T_BITMODE = 0;       /* 16 bit */
    T_PRESCALER = 9;     /* 16 MHz / 2^9 = 31250 Hz */
    T_CC0 = PERIOD;      /* 250 ms */
    T_INTENSET = 1u << 16;
    GT_CONFIG0 = 1u | (11u << 8) | (1u << 16); /* event mode, P0.11, rising edge */
    GT_INTENSET = 1u;
    NVIC_ISER0 = (1u << IRQ_TIMER0) | (1u << IRQ_GPIOTE);
    T_START = 1;

    uint32_t seen_t = 0, seen_p = 0;
    for (;;) {
        __asm volatile("wfi");
        if (ticks != seen_t && ticks % 4 == 0) {
            bm_puts("ticks ");
            bm_dec(ticks);
            bm_puts("\n");
        }
        seen_t = ticks;
        if (presses != seen_p) {
            seen_p = presses;
            bm_puts("button presses ");
            bm_dec(seen_p);
            bm_puts("\n");
        }
    }
}

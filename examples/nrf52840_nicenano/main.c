/* nRF52840 (nice!nano v2 / Pro Micro clone) bare-metal demo: legacy UART0 console on
 * P0.06 (TX) / P0.08 (RX), blue LED P0.15 (active high), echo of received characters. */
#include <stdint.h>
#include "bm.h"

#define UART0           0x40002000u
#define UART_STARTRX    REG32(UART0 + 0x000)
#define UART_STARTTX    REG32(UART0 + 0x008)
#define UART_RXDRDY     REG32(UART0 + 0x108)
#define UART_TXDRDY     REG32(UART0 + 0x11C)
#define UART_ENABLE     REG32(UART0 + 0x500)
#define UART_PSELTXD    REG32(UART0 + 0x50C)
#define UART_PSELRXD    REG32(UART0 + 0x514)
#define UART_RXD        REG32(UART0 + 0x518)
#define UART_TXD        REG32(UART0 + 0x51C)
#define UART_BAUDRATE   REG32(UART0 + 0x524)
#define P0_OUTSET       REG32(0x50000508)
#define P0_OUTCLR       REG32(0x5000050C)
#define P0_DIRSET       REG32(0x50000518)

void bm_putc(char c)
{
    UART_TXDRDY = 0;
    UART_TXD = (uint8_t)c;
    while (!UART_TXDRDY)
        ;
}

int main(void)
{
    P0_DIRSET = 1u << 15;
    UART_PSELTXD = 6;
    UART_PSELRXD = 8;
    UART_BAUDRATE = 0x01D7E000; /* 115200 */
    UART_ENABLE = 4;            /* legacy UART (not UARTE/EasyDMA) */
    UART_STARTTX = 1;
    UART_STARTRX = 1;
    bm_puts("Hello from nRF52840 nice!nano (Renode, 32_06_renode)\n> ");
    uint32_t n = 0;
    for (;;) {
        if (UART_RXDRDY) {
            UART_RXDRDY = 0;
            char c = (char)UART_RXD;
            if (c == '\r' || c == '\n') {
                bm_puts("\nled toggles so far: ");
                bm_dec(n);
                bm_puts("\n> ");
            } else {
                bm_putc(c);
            }
        }
        static uint32_t t;
        if (++t == 200000) {
            t = 0;
            if (n++ & 1)
                P0_OUTCLR = 1u << 15;
            else
                P0_OUTSET = 1u << 15;
        }
    }
}

/* @NAME@: nRF52840 bare metal. Legacy UART0 on P0.06 (TX) / P0.08 (RX), LED P0.15,
 * line commands with echo: "led" toggles the LED, any other line is answered with "echo: <line>". */
#include <stdint.h>
#include "print.h"

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
#define P0_OUT          REG32(0x50000504)
#define P0_DIRSET       REG32(0x50000518)

void putc_console(char c)
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
    UART_ENABLE = 4;
    UART_STARTTX = 1;
    UART_STARTRX = 1;
    puts_console("@NAME@ on nRF52840\n> ");
    char line[32];
    unsigned n = 0;
    for (;;) {
        if (!UART_RXDRDY)
            continue;
        UART_RXDRDY = 0;
        char c = (char)UART_RXD;
        if (c != '\r' && c != '\n') {
            putc_console(c); /* echo, like a terminal (Renode's Write Line To Uart waits for it) */
            if (n < sizeof line - 1)
                line[n++] = c;
            continue;
        }
        line[n] = 0;
        if (n == 3 && line[0] == 'l' && line[1] == 'e' && line[2] == 'd') {
            P0_OUT ^= 1u << 15;
            puts_console((P0_OUT & (1u << 15)) ? "\nled is on\n> " : "\nled is off\n> ");
        } else if (n) {
            puts_console("\necho: ");
            puts_console(line);
            puts_console("\n> ");
        }
        n = 0;
    }
}

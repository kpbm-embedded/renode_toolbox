/* @NAME@: two BlackPill F411 nodes linked USART2 <-> USART2 (Renode: a UART hub; boards: PA2/PA3 crossed).
 * ROLE_PING sends "ping N" every few ms and prints the replies; ROLE_PONG answers each
 * line. Both print on USART1 (the console). Same source, two builds (-DROLE_PING/-DROLE_PONG). */
#include <stdint.h>
#include "print.h"

#define RCC_AHB1ENR  REG32(0x40023830)
#define RCC_APB1ENR  REG32(0x40023840)
#define RCC_APB2ENR  REG32(0x40023844)
#define GPIOA_MODER  REG32(0x40020000)
#define GPIOA_AFRL   REG32(0x40020020)
#define GPIOA_AFRH   REG32(0x40020024)
#define USART_SR(b)  REG32((b) + 0x00)
#define USART_DR(b)  REG32((b) + 0x04)
#define USART_BRR(b) REG32((b) + 0x08)
#define USART_CR1(b) REG32((b) + 0x0C)
#define USART1 0x40011000u
#define USART2 0x40004400u

static void putc_on(uint32_t u, char c)
{
    while (!(USART_SR(u) & (1u << 7)))
        ;
    USART_DR(u) = (uint8_t)c;
}
static void puts_on(uint32_t u, const char *s)
{
    while (*s)
        putc_on(u, *s++);
}
void putc_console(char c) { putc_on(USART1, c); }

/* one line from USART2 into buf; returns its length, or -1 after `spins` empty polls */
static int link_getline(char *buf, int max, uint32_t spins)
{
    int n = 0;
    while (spins--) {
        if (USART_SR(USART2) & (1u << 5)) { /* RXNE */
            char c = (char)USART_DR(USART2);
            if (c == '\n') {
                buf[n] = 0;
                return n;
            }
            if (n < max - 1)
                buf[n++] = c;
        }
    }
    return -1;
}

static void dec_to(char *p, uint32_t v)
{
    char t[11];
    int i = 0;
    do t[i++] = (char)('0' + v % 10); while (v /= 10);
    while (i) *p++ = t[--i];
    *p = 0;
}

int main(void)
{
    RCC_AHB1ENR |= 1u;
    RCC_APB1ENR |= 1u << 17; /* USART2 */
    RCC_APB2ENR |= 1u << 4;  /* USART1 */
    /* PA2/PA3 AF7 (USART2), PA9/PA10 AF7 (USART1) */
    GPIOA_MODER = (GPIOA_MODER & ~((0xFu << 4) | (0xFu << 18))) | (0xAu << 4) | (0xAu << 18);
    GPIOA_AFRL = (GPIOA_AFRL & ~0xFF00u) | 0x7700u;
    GPIOA_AFRH = (GPIOA_AFRH & ~0xFF0u) | 0x770u;
    USART_BRR(USART1) = USART_BRR(USART2) = 0x8B;
    USART_CR1(USART1) = USART_CR1(USART2) = (1u << 13) | (1u << 3) | (1u << 2);
    char line[32];
#ifdef ROLE_PING
    puts_console("node ping up\n");
    for (uint32_t n = 1;; n++) {
        char msg[24] = "ping ";
        dec_to(msg + 5, n);
        puts_on(USART2, msg);
        putc_on(USART2, '\n');
        if (link_getline(line, sizeof line, 2000000) >= 0) {
            puts_console("got: ");
            puts_console(line);
            puts_console("\n");
        } else {
            puts_console("timeout waiting for pong\n");
        }
    }
#else
    puts_console("node pong up\n");
    for (;;) {
        if (link_getline(line, sizeof line, 0xffffffffu) < 0)
            continue;
        puts_console("rx: ");
        puts_console(line);
        puts_console("\n");
        if (line[0] == 'p' && line[1] == 'i') {
            line[1] = 'o'; /* ping N -> pong N */
            puts_on(USART2, line);
            putc_on(USART2, '\n');
        }
    }
#endif
}

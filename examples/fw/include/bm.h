/* bm.h: tiny print helpers for bare-metal examples (no libc). The board provides bm_putc. */
#ifndef BM_H
#define BM_H
#include <stdint.h>

void bm_putc(char c);

static inline void bm_puts(const char *s)
{
    while (*s) {
        if (*s == '\n')
            bm_putc('\r');
        bm_putc(*s++);
    }
}

static inline void bm_hex(uint32_t v)
{
    static const char d[] = "0123456789abcdef";
    bm_puts("0x");
    for (int i = 28; i >= 0; i -= 4)
        bm_putc(d[(v >> i) & 0xf]);
}

static inline void bm_dec(uint32_t v)
{
    char b[11];
    int i = 0;
    do {
        b[i++] = (char)('0' + v % 10);
        v /= 10;
    } while (v);
    while (i)
        bm_putc(b[--i]);
}

#define REG32(a) (*(volatile uint32_t *)(uintptr_t)(a))

#endif

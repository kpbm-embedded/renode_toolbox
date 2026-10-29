/* print.h: tiny output helpers (no libc). The board code provides putc_console. */
#ifndef PRINT_H
#define PRINT_H
#include <stdint.h>
#define REG32(a) (*(volatile uint32_t *)(uintptr_t)(a))
void putc_console(char c);
static inline void puts_console(const char *s)
{
    while (*s) {
        if (*s == '\n')
            putc_console('\r');
        putc_console(*s++);
    }
}
static inline void put_dec(uint32_t v)
{
    char b[11];
    int i = 0;
    do b[i++] = (char)('0' + v % 10); while (v /= 10);
    while (i) putc_console(b[--i]);
}
#endif

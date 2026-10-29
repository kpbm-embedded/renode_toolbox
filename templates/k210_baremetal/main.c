/* @NAME@: K210 bare metal on UARTHS (SiFive UART @0x38000000): banner, misa, cycle counter. */
#include <stdint.h>
#include "print.h"

#define UART_TX    REG32(0x38000000)
#define UART_TXCTL REG32(0x38000008)

void putc_console(char c)
{
    while (UART_TX & 0x80000000u)
        ;
    UART_TX = (uint8_t)c;
}

int main(void)
{
    UART_TXCTL = 1;
    unsigned long misa, hart;
    __asm volatile("csrr %0, misa" : "=r"(misa));
    __asm volatile("csrr %0, mhartid" : "=r"(hart));
    puts_console("@NAME@ on K210, hart ");
    put_dec((uint32_t)hart);
    puts_console((misa >> 62) == 2 ? ", rv64\n" : ", not rv64\n");
    for (uint32_t n = 1;; n++) {
        unsigned long c;
        __asm volatile("rdcycle %0" : "=r"(c));
        puts_console("loop ");
        put_dec(n);
        puts_console("\n");
        for (volatile uint32_t d = 0; d < 100000; d++)
            ;
    }
}

/* K210 dual-core demo: hart 1 counts primes while hart 0 keeps printing; both add to one
 * counter with atomic AMOs (amoadd.w via __atomic_fetch_add). Hart 0 reports the result. */
#include <stdint.h>
#include "bm.h"

#define UART_TX    REG32(0x38000000)
#define UART_TXCTL REG32(0x38000008)
#define ROUNDS     5000

volatile uint32_t hart1_go = 0;   /* .data: set by hart 0 after .bss is zeroed */
volatile uint32_t shared_count;   /* both harts add ROUNDS each */
volatile uint32_t hart1_done, hart1_primes, hart1_id;

void bm_putc(char c)
{
    while (UART_TX & 0x80000000u)
        ;
    UART_TX = (uint8_t)c;
}

static uint32_t count_primes(uint32_t below)
{
    uint32_t n = 0;
    for (uint32_t i = 2; i < below; i++) {
        uint32_t d = 2;
        while (d * d <= i && i % d)
            d++;
        if (d * d > i)
            n++;
    }
    return n;
}

void hart1_main(void)
{
    unsigned long id;
    __asm volatile("csrr %0, mhartid" : "=r"(id));
    hart1_id = (uint32_t)id;
    for (int i = 0; i < ROUNDS; i++)
        __atomic_fetch_add(&shared_count, 1, __ATOMIC_RELAXED);
    hart1_primes = count_primes(20000);
    __atomic_store_n(&hart1_done, 1, __ATOMIC_RELEASE);
}

int main(void)
{
    UART_TXCTL = 1;
    bm_puts("K210 dual hart demo: hart 0 up\n");
    __atomic_store_n(&hart1_go, 1, __ATOMIC_RELEASE);
    for (int i = 0; i < ROUNDS; i++)
        __atomic_fetch_add(&shared_count, 1, __ATOMIC_RELAXED);
    uint32_t polls = 0;
    while (!__atomic_load_n(&hart1_done, __ATOMIC_ACQUIRE))
        polls++;
    bm_puts("hart ");
    bm_dec(hart1_id);
    bm_puts(" found ");
    bm_dec(hart1_primes);
    bm_puts(" primes below 20000\n");
    bm_puts("shared count ");
    bm_dec(shared_count);
    bm_puts(shared_count == 2 * ROUNDS ? " (atomic ok)\n" : " (LOST UPDATES)\n");
    bm_puts(polls ? "hart 0 ran in parallel\n" : "hart 0 did not run in parallel\n");
    for (;;)
        __asm volatile("wfi");
}

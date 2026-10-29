/* RISC-V bare-metal demo, one source for two Renode platforms:
 *   BOARD_K210  Kendryte K210 (rv64, UARTHS = SiFive UART @0x38000000) - the user's CanMV/Maix boards
 *   BOARD_LITEX LiteX SoC with VexRiscv (rv32im, LiteX UART CSRs @0xE0001800) - the RV32 class
 *               of CH32V / BL616-style cores; also what `litex_sim`/LiteX boards run.
 * Prints the ISA from misa and a running cycle count. */
#include <stdint.h>
#include "bm.h"

#if defined(BOARD_K210)
#define BOARD "Kendryte K210"
#define UART_TX    REG32(0x38000000) /* txdata: bit31 = full */
#define UART_TXCTL REG32(0x38000008)
void bm_putc(char c)
{
    while (UART_TX & 0x80000000u)
        ;
    UART_TX = (uint8_t)c;
}
static void uart_init(void) { UART_TXCTL = 1; }
#elif defined(BOARD_LITEX)
#define BOARD "LiteX VexRiscv"
#define UART_RXTX  REG32(0xE0001800)
#define UART_TXFULL REG32(0xE0001804)
void bm_putc(char c)
{
    while (UART_TXFULL & 1)
        ;
    UART_RXTX = (uint8_t)c;
}
static void uart_init(void) {}
#else
#error "define BOARD_K210 or BOARD_LITEX"
#endif

static unsigned long csr_misa(void)
{
    unsigned long v;
    __asm volatile("csrr %0, misa" : "=r"(v));
    return v;
}

int main(void)
{
    uart_init();
    unsigned long misa = csr_misa();
    bm_puts("Hello from " BOARD " (Renode, 32_06_renode)\nISA: rv");
    bm_dec((misa >> (sizeof(long) * 8 - 2)) == 2 ? 64 : 32);
    for (int i = 0; i < 26; i++)
        if (misa & (1ul << i))
            bm_putc((char)('a' + i));
    bm_puts("\n");
    for (uint32_t n = 1; n <= 3; n++) {
        bm_puts("count ");
        bm_dec(n);
        bm_puts("\n");
    }
    bm_puts("done\n");
    return 0;
}

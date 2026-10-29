/* GDB demo firmware (BlackPill F411 model): a filter step the debugger stops in.
 * gdb sets a breakpoint on filter_step, reads g_state and changes g_gain from the host. */
#include <stdint.h>
#include "bm.h"

#define RCC_AHB1ENR  REG32(0x40023830)
#define RCC_APB2ENR  REG32(0x40023844)
#define GPIOA_MODER  REG32(0x40020000)
#define GPIOA_AFRH   REG32(0x40020024)
#define USART1_SR    REG32(0x40011000)
#define USART1_DR    REG32(0x40011004)
#define USART1_BRR   REG32(0x40011008)
#define USART1_CR1   REG32(0x4001100C)

struct state {
    uint32_t steps;
    int32_t acc;
};
volatile struct state g_state;
volatile int32_t g_gain = 1;

void bm_putc(char c)
{
    while (!(USART1_SR & (1u << 7)))
        ;
    USART1_DR = (uint8_t)c;
}

__attribute__((noinline)) int32_t filter_step(int32_t in)
{
    g_state.acc += in * g_gain;
    g_state.steps++;
    return g_state.acc;
}

int main(void)
{
    RCC_AHB1ENR |= 1u;
    RCC_APB2ENR |= 1u << 4;
    GPIOA_MODER = (GPIOA_MODER & ~(0xFu << 18)) | (0xAu << 18);
    GPIOA_AFRH = (GPIOA_AFRH & ~0xFF0u) | (0x77u << 4);
    USART1_BRR = 0x8B;
    USART1_CR1 = (1u << 13) | (1u << 3) | (1u << 2);
    bm_puts("gdb demo ready\n");
    for (int32_t i = 1;; i++) {
        int32_t acc = filter_step(i);
        if ((i & 0xff) == 0) {
            bm_puts("acc=");
            bm_dec((uint32_t)acc);
            bm_puts("\n");
        }
    }
}

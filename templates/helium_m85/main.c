/* @NAME@: Helium (MVE) kernels on the Cortex-M85 of the RA8M1 model (Renode 1.17: Armv8.1-M MVE, FPv5, LOB).
 * Each kernel runs twice, once with MVE intrinsics and once in plain C, and prints both results;
 * the test checks they match. -O2 also lets GCC use low-overhead loops (wls/dls/le) in the scalar code. */
#include <arm_mve.h>
#include <stdint.h>
#include "bm.h"

#define UART_SR REG32(0x5F000000)
#define UART_DR REG32(0x5F000004)
#define UART_CR1 REG32(0x5F00000C)

void bm_putc(char c)
{
    while (!(UART_SR & (1u << 7)))
        ;
    UART_DR = (uint8_t)c;
}

#define N 64
static int16_t a16[N], b16[N];
static int32_t a32[N], b32[N], sum_mve[N], sum_c[N];
static float fx[N], fy[N], f_mve[N], f_c[N];

__attribute__((noinline)) static int64_t dot_q15_mve(const int16_t *a, const int16_t *b, int n)
{
    int64_t acc = 0;
    for (int i = 0; i < n; i += 8) {           /* 8 x int16 per 128-bit vector */
        mve_pred16_t p = vctp16q(n - i);
        acc = vmlaldavaq_p_s16(acc, vld1q_z_s16(a + i, p), vld1q_z_s16(b + i, p), p);
    }
    return acc;
}
__attribute__((noinline)) static int64_t dot_q15_c(const int16_t *a, const int16_t *b, int n)
{
    int64_t acc = 0;
    for (int i = 0; i < n; i++)
        acc += (int32_t)a[i] * b[i];
    return acc;
}
__attribute__((noinline)) static void add_s32_mve(const int32_t *a, const int32_t *b, int32_t *o, int n)
{
    for (int i = 0; i < n; i += 4)
        vst1q_s32(o + i, vqaddq_s32(vld1q_s32(a + i), vld1q_s32(b + i)));   /* saturating add */
}
__attribute__((noinline)) static void add_s32_c(const int32_t *a, const int32_t *b, int32_t *o, int n)
{
    for (int i = 0; i < n; i++) {
        int64_t s = (int64_t)a[i] + b[i];
        o[i] = s > INT32_MAX ? INT32_MAX : s < INT32_MIN ? INT32_MIN : (int32_t)s;
    }
}
__attribute__((noinline)) static void axpy_f32_mve(float k, const float *x, const float *y, float *o, int n)
{
    for (int i = 0; i < n; i += 4)
        vst1q_f32(o + i, vfmaq_n_f32(vld1q_f32(y + i), vld1q_f32(x + i), k));
}
__attribute__((noinline)) static void axpy_f32_c(float k, const float *x, const float *y, float *o, int n)
{
    for (int i = 0; i < n; i++)
        o[i] = __builtin_fmaf(x[i], k, y[i]);
}
static uint32_t crc_words(const void *p, int nbytes)
{
    const uint8_t *b = p;
    uint32_t c = 0xFFFFFFFFu;
    for (int i = 0; i < nbytes; i++) {
        c ^= b[i];
        for (int k = 0; k < 8; k++)
            c = (c >> 1) ^ (0xEDB88320u & -(c & 1u));
    }
    return ~c;
}
static void report(const char *what, uint32_t mve, uint32_t c)
{
    bm_puts(what);
    bm_puts(" mve=");
    bm_hex(mve);
    bm_puts(" c=");
    bm_hex(c);
    bm_puts(mve == c ? " MATCH\n" : " DIFF\n");
}

int main(void)
{
    UART_CR1 = (1u << 13) | (1u << 3);
    bm_puts("@NAME@: Helium MVE on Cortex-M85 (RA8M1 model)\n");
    for (int i = 0; i < N; i++) {
        a16[i] = (int16_t)(i * 517 - 9000);
        b16[i] = (int16_t)(12000 - i * 333);
        a32[i] = (i & 1) ? INT32_MAX - i : i * 100000;
        b32[i] = (i & 3) ? 1000 + i : -7;
        fx[i] = (float)i * 0.25f - 3.0f;
        fy[i] = 1.5f - (float)i * 0.125f;
    }
    int64_t d1 = dot_q15_mve(a16, b16, N - 3), d2 = dot_q15_c(a16, b16, N - 3);   /* tail predication */
    report("dot_q15 (61 lanes, vctp tail)", (uint32_t)d1 ^ (uint32_t)(d1 >> 32), (uint32_t)d2 ^ (uint32_t)(d2 >> 32));
    add_s32_mve(a32, b32, sum_mve, N);
    add_s32_c(a32, b32, sum_c, N);
    report("vqadd_s32 (saturating)", crc_words(sum_mve, sizeof sum_mve), crc_words(sum_c, sizeof sum_c));
    axpy_f32_mve(2.5f, fx, fy, f_mve, N);
    axpy_f32_c(2.5f, fx, fy, f_c, N);
    report("vfma_f32 (MVE-F)", crc_words(f_mve, sizeof f_mve), crc_words(f_c, sizeof f_c));
    bm_puts("done\n");
    for (;;)
        ;
}

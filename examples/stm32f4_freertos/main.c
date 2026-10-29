/* FreeRTOS on a BlackPill F411 (Renode STM32F412 model): a producer task, a 1 s software
 * timer and a consumer task share one queue; a blink task toggles LED PC13 every 250 ms.
 * Only the consumer writes to USART1, so output never interleaves. */
#include <stdint.h>
#include "FreeRTOS.h"
#include "queue.h"
#include "task.h"
#include "timers.h"
#include "bm.h"

#define RCC_AHB1ENR  REG32(0x40023830)
#define RCC_APB2ENR  REG32(0x40023844)
#define GPIOA_MODER  REG32(0x40020000)
#define GPIOA_AFRH   REG32(0x40020024)
#define GPIOC_MODER  REG32(0x40020800)
#define GPIOC_BSRR   REG32(0x40020818)
#define USART1_SR    REG32(0x40011000)
#define USART1_DR    REG32(0x40011004)
#define USART1_BRR   REG32(0x40011008)
#define USART1_CR1   REG32(0x4001100C)

static QueueHandle_t q;

void bm_putc(char c)
{
    while (!(USART1_SR & (1u << 7)))
        ;
    USART1_DR = (uint8_t)c;
}

static void producer(void *arg)
{
    (void)arg;
    int32_t n = 0;
    for (;;) {
        xQueueSend(q, &n, portMAX_DELAY);
        n++;
        vTaskDelay(pdMS_TO_TICKS(100));
    }
}

static void consumer(void *arg)
{
    (void)arg;
    int32_t v;
    for (;;) {
        if (xQueueReceive(q, &v, portMAX_DELAY) != pdPASS)
            continue;
        if (v >= 0) {
            bm_puts("rx ");
            bm_dec((uint32_t)v);
        } else {
            bm_puts("timer ");
            bm_dec((uint32_t)-v);
            bm_puts(" s, tick ");
            bm_dec(xTaskGetTickCount());
        }
        bm_puts("\n");
    }
}

static void blink(void *arg)
{
    (void)arg;
    TickType_t last = xTaskGetTickCount();
    int on = 0;
    for (;;) {
        on = !on;
        GPIOC_BSRR = on ? (1u << (13 + 16)) : (1u << 13); /* active low */
        vTaskDelayUntil(&last, pdMS_TO_TICKS(250));
    }
}

static void every_second(TimerHandle_t t)
{
    static int32_t s;
    int32_t v = -(++s);
    (void)t;
    xQueueSend(q, &v, 0);
}

void vApplicationMallocFailedHook(void) { configASSERT(0); }
void vApplicationStackOverflowHook(TaskHandle_t t, char *name) { (void)t; (void)name; configASSERT(0); }

int main(void)
{
    RCC_AHB1ENR |= (1u << 0) | (1u << 2);
    RCC_APB2ENR |= (1u << 4);
    GPIOA_MODER = (GPIOA_MODER & ~(0xFu << 18)) | (0xAu << 18);
    GPIOA_AFRH = (GPIOA_AFRH & ~0xFF0u) | (0x77u << 4);
    GPIOC_MODER = (GPIOC_MODER & ~(3u << 26)) | (1u << 26);
    USART1_BRR = 0x8B;
    USART1_CR1 = (1u << 13) | (1u << 3) | (1u << 2);

    bm_puts("FreeRTOS " tskKERNEL_VERSION_NUMBER " on BlackPill F411 (Renode)\n");
    q = xQueueCreate(8, sizeof(int32_t));
    xTaskCreate(consumer, "consumer", 256, NULL, 2, NULL);
    xTaskCreate(producer, "producer", 256, NULL, 1, NULL);
    xTaskCreate(blink, "blink", 128, NULL, 1, NULL);
    xTimerStart(xTimerCreate("1s", pdMS_TO_TICKS(1000), pdTRUE, NULL, every_second), 0);
    vTaskStartScheduler();
    for (;;)
        ;
}

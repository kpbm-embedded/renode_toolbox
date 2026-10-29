/* @NAME@: FreeRTOS on the BlackPill F411. A sensor task sends samples through a queue to
 * a logger task (the only one writing to USART1); a mutex-protected counter is shared with a
 * blink task that toggles LED PC13 every 500 ms. */
#include <stdint.h>
#include "FreeRTOS.h"
#include "queue.h"
#include "semphr.h"
#include "task.h"
#include "print.h"

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

static QueueHandle_t samples;
static SemaphoreHandle_t lock;
static uint32_t blinks;

void putc_console(char c)
{
    while (!(USART1_SR & (1u << 7)))
        ;
    USART1_DR = (uint8_t)c;
}

static void sensor_task(void *arg)
{
    uint32_t v = 0;
    for (;;) {
        v += 7;
        xQueueSend(samples, &v, portMAX_DELAY);
        vTaskDelay(pdMS_TO_TICKS(200));
    }
}

static void logger_task(void *arg)
{
    uint32_t v;
    for (;;) {
        if (xQueueReceive(samples, &v, portMAX_DELAY) != pdPASS)
            continue;
        xSemaphoreTake(lock, portMAX_DELAY);
        uint32_t b = blinks;
        xSemaphoreGive(lock);
        puts_console("sample ");
        put_dec(v);
        puts_console(" blinks ");
        put_dec(b);
        puts_console(" tick ");
        put_dec(xTaskGetTickCount());
        puts_console("\n");
    }
}

static void blink_task(void *arg)
{
    TickType_t last = xTaskGetTickCount();
    for (;;) {
        xSemaphoreTake(lock, portMAX_DELAY);
        uint32_t b = ++blinks;
        xSemaphoreGive(lock);
        GPIOC_BSRR = (b & 1) ? (1u << (13 + 16)) : (1u << 13);
        vTaskDelayUntil(&last, pdMS_TO_TICKS(500));
    }
}

void vApplicationMallocFailedHook(void) { configASSERT(0); }
void vApplicationStackOverflowHook(TaskHandle_t t, char *name) { configASSERT(0); }

int main(void)
{
    RCC_AHB1ENR |= (1u << 0) | (1u << 2);
    RCC_APB2ENR |= 1u << 4;
    GPIOA_MODER = (GPIOA_MODER & ~(0xFu << 18)) | (0xAu << 18);
    GPIOA_AFRH = (GPIOA_AFRH & ~0xFF0u) | (0x77u << 4);
    GPIOC_MODER = (GPIOC_MODER & ~(3u << 26)) | (1u << 26);
    USART1_BRR = 0x8B;
    USART1_CR1 = (1u << 13) | (1u << 3) | (1u << 2);
    puts_console("@NAME@: FreeRTOS " tskKERNEL_VERSION_NUMBER "\n");
    samples = xQueueCreate(4, sizeof(uint32_t));
    lock = xSemaphoreCreateMutex();
    xTaskCreate(logger_task, "logger", 256, NULL, 2, NULL);
    xTaskCreate(sensor_task, "sensor", 256, NULL, 1, NULL);
    xTaskCreate(blink_task, "blink", 128, NULL, 1, NULL);
    vTaskStartScheduler();
    for (;;)
        ;
}

/* FreeRTOSConfig.h for the BlackPill F411 FreeRTOS example (FreeRTOS-Kernel V11.3.2).
 * CPU_HZ is the SysTick clock: Renode's STM32F4 model ticks SysTick at 72 MHz; on a real
 * BlackPill running from the 16 MHz HSI build with `make CPU_HZ=16000000`. */
#ifndef FREERTOS_CONFIG_H
#define FREERTOS_CONFIG_H

#ifndef CPU_HZ
#define CPU_HZ 72000000u
#endif

#define configUSE_PREEMPTION                    1
#define configUSE_PORT_OPTIMISED_TASK_SELECTION 1
#define configCPU_CLOCK_HZ                      (CPU_HZ)
#define configTICK_RATE_HZ                      1000
#define configMAX_PRIORITIES                    5
#define configMINIMAL_STACK_SIZE                128
#define configTOTAL_HEAP_SIZE                   (16 * 1024)
#define configMAX_TASK_NAME_LEN                 12
#define configTICK_TYPE_WIDTH_IN_BITS           TICK_TYPE_WIDTH_32_BITS
#define configUSE_MUTEXES                       1
#define configUSE_TIMERS                        1
#define configTIMER_TASK_PRIORITY               3
#define configTIMER_QUEUE_LENGTH                4
#define configTIMER_TASK_STACK_DEPTH            256
#define configUSE_IDLE_HOOK                     0
#define configUSE_TICK_HOOK                     0
#define configCHECK_FOR_STACK_OVERFLOW          2
#define configUSE_MALLOC_FAILED_HOOK            1
#define configSUPPORT_DYNAMIC_ALLOCATION        1
#define configSUPPORT_STATIC_ALLOCATION         0
#define configKERNEL_PROVIDED_STATIC_MEMORY     0

/* Cortex-M4: 4 priority bits */
#define configPRIO_BITS                         4
#define configKERNEL_INTERRUPT_PRIORITY         (15 << (8 - configPRIO_BITS))
#define configMAX_SYSCALL_INTERRUPT_PRIORITY    (5 << (8 - configPRIO_BITS))

#define INCLUDE_vTaskDelay                      1
#define INCLUDE_vTaskDelayUntil                 1
#define INCLUDE_xTaskGetTickCount               1

#define configASSERT(x) do { if (!(x)) { __asm volatile("cpsid i"); for (;;) {} } } while (0)

/* map the port's handlers onto the names in fw/cortexm/startup.c */
#define vPortSVCHandler     SVC_Handler
#define xPortPendSVHandler  PendSV_Handler
#define xPortSysTickHandler SysTick_Handler

#endif

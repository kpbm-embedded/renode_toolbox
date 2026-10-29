# FreeRTOS V11 demo for the BlackPill F411. Needs FREERTOS_KERNEL (set by ./renode-box).
NAME      := blackpill_freertos
FW        ?= ../fw
FREERTOS_KERNEL ?= $(error FREERTOS_KERNEL not set: run through ./renode-box)
CPU_HZ    ?= 72000000u
CROSS     := arm-none-eabi-
ARCHFLAGS := -mcpu=cortex-m4 -mthumb -mfloat-abi=hard -mfpu=fpv4-sp-d16
LDSCRIPT  := $(FW)/cortexm/stm32f4.ld
K         := $(FREERTOS_KERNEL)
SRCS      := main.c $(FW)/cortexm/startup.c $(K)/tasks.c $(K)/queue.c $(K)/list.c $(K)/timers.c \
             $(K)/portable/GCC/ARM_CM4F/port.c $(K)/portable/MemMang/heap_4.c
CFLAGS    += -I. -I$(K)/include -I$(K)/portable/GCC/ARM_CM4F -DCPU_HZ=$(CPU_HZ) -Wno-unused-parameter
include $(FW)/rules.mk

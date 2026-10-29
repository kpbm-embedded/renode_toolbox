# nRF52840 TIMER0 + GPIOTE interrupt demo. make OUT=<dir> FW=<examples/fw>
NAME      := nrf_irq
FW        ?= ../fw
CROSS     := arm-none-eabi-
ARCHFLAGS := -mcpu=cortex-m4 -mthumb -mfloat-abi=hard -mfpu=fpv4-sp-d16
LDSCRIPT  := $(FW)/cortexm/nrf52840.ld
SRCS      := main.c $(FW)/cortexm/startup.c
include $(FW)/rules.mk

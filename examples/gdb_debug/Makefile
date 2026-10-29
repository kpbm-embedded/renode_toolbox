# GDB demo firmware for the BlackPill F411 model. make OUT=<dir> FW=<examples/fw>
NAME      := gdb_demo
FW        ?= ../fw
CROSS     := arm-none-eabi-
ARCHFLAGS := -mcpu=cortex-m4 -mthumb -mfloat-abi=hard -mfpu=fpv4-sp-d16
LDSCRIPT  := $(FW)/cortexm/stm32f4.ld
SRCS      := main.c $(FW)/cortexm/startup.c
include $(FW)/rules.mk

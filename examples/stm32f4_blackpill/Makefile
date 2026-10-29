# BlackPill F411 bare-metal demo (USART1 + LED PC13 + KEY PA0). make OUT=<dir> FW=<examples/fw>
NAME      := blackpill_hello
FW        ?= ../fw
CROSS     := arm-none-eabi-
ARCHFLAGS := -mcpu=cortex-m4 -mthumb -mfloat-abi=hard -mfpu=fpv4-sp-d16
LDSCRIPT  := $(FW)/cortexm/stm32f4.ld
SRCS      := main.c $(FW)/cortexm/startup.c
include $(FW)/rules.mk

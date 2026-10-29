# WeAct MiniSTM32H743 bare-metal demo (USART1 + LED PE3). make OUT=<dir> FW=<examples/fw>
NAME      := weact_h743_hello
FW        ?= ../fw
CROSS     := arm-none-eabi-
ARCHFLAGS := -mcpu=cortex-m7 -mthumb -mfloat-abi=hard -mfpu=fpv5-d16
LDSCRIPT  := $(FW)/cortexm/stm32h743.ld
SRCS      := main.c $(FW)/cortexm/startup.c
include $(FW)/rules.mk

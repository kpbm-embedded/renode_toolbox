# nRF52840 nice!nano bare-metal demo (legacy UART0 + LED P0.15). make OUT=<dir> FW=<examples/fw>
NAME      := nicenano_hello
FW        ?= ../fw
CROSS     := arm-none-eabi-
ARCHFLAGS := -mcpu=cortex-m4 -mthumb -mfloat-abi=hard -mfpu=fpv4-sp-d16
LDSCRIPT  := $(FW)/cortexm/nrf52840.ld
SRCS      := main.c $(FW)/cortexm/startup.c
include $(FW)/rules.mk

# Two-node UART hub demo: make ROLE=ping|pong OUT=<dir> FW=<examples/fw>
ROLE      ?= ping
NAME      := node_$(ROLE)
FW        ?= ../fw
CROSS     := arm-none-eabi-
ARCHFLAGS := -mcpu=cortex-m4 -mthumb -mfloat-abi=hard -mfpu=fpv4-sp-d16
CFLAGS    += -DROLE_$(shell echo $(ROLE) | tr a-z A-Z)
OUT       ?= build
override OUT := $(OUT)/$(ROLE)
LDSCRIPT  := $(FW)/cortexm/stm32f4.ld
SRCS      := main.c $(FW)/cortexm/startup.c
include $(FW)/rules.mk

# Helium/MVE demo for the Cortex-M85 (Renesas RA8M1 model). make OUT=<dir> FW=<examples/fw>
NAME      := helium_demo
FW        ?= ../fw
CROSS     := arm-none-eabi-
ARCHFLAGS := -mcpu=cortex-m85 -mthumb -mfloat-abi=hard
LDSCRIPT  := ra8m1.ld
SRCS      := main.c $(FW)/cortexm/startup.c
include $(FW)/rules.mk
CFLAGS    += -O2

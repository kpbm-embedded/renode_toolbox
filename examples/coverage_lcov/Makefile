# Line-coverage demo: the trace_coverage command parser built at -O0 -g3 (one PC per source line, as the
# retracer docs recommend). make OUT=<dir> FW=<examples/fw>
NAME      := cov_demo
FW        ?= ../fw
CROSS     := arm-none-eabi-
ARCHFLAGS := -mcpu=cortex-m4 -mthumb -mfloat-abi=hard -mfpu=fpv4-sp-d16
LDSCRIPT  := $(FW)/cortexm/stm32f4.ld
SRCS      := ../trace_coverage/main.c $(FW)/cortexm/startup.c
include $(FW)/rules.mk
CFLAGS    += -O0

# RISC-V bare-metal demo for two boards: make BOARD=k210|litex OUT=<dir> FW=<examples/fw>
BOARD     ?= k210
FW        ?= ../fw
CROSS     := riscv-none-elf-
ifeq ($(BOARD),k210)
NAME      := k210_hello
ARCHFLAGS := -march=rv64imac_zicsr -mabi=lp64 -mcmodel=medany -DBOARD_K210
LDSCRIPT  := $(FW)/riscv/k210.ld
else
NAME      := litex_hello
ARCHFLAGS := -march=rv32im_zicsr -mabi=ilp32 -DBOARD_LITEX
LDSCRIPT  := $(FW)/riscv/litex.ld
endif
OUT       ?= build
override OUT := $(OUT)/$(BOARD)
SRCS      := main.c $(FW)/riscv/start.S
LDLIBS    := -lgcc
include $(FW)/rules.mk

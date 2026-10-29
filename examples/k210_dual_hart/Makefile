# K210 dual-hart demo (rv64imac, both harts). make OUT=<dir> FW=<examples/fw>
NAME      := k210_dual
FW        ?= ../fw
CROSS     := riscv-none-elf-
ARCHFLAGS := -march=rv64imac_zicsr -mabi=lp64 -mcmodel=medany
LDSCRIPT  := $(FW)/riscv/k210.ld
SRCS      := main.c start.S
LDLIBS    := -lgcc
include $(FW)/rules.mk

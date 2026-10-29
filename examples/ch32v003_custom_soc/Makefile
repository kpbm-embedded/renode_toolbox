# CH32V003-like RV32EC bare-metal demo. make OUT=<dir> FW=<examples/fw>
NAME      := ch32v003_hello
FW        ?= ../fw
CROSS     := riscv-none-elf-
ARCHFLAGS := -march=rv32ec_zicsr -mabi=ilp32e
LDSCRIPT  := ch32v003.ld
SRCS      := main.c start.S
LDLIBS    := -lgcc
include $(FW)/rules.mk

# @NAME@: firmware for a hand-written RV32 platform (@NAME@.repl): CH32V003-like by default.
# Build: ./renode-box run make -C <dir>/@NAME@   (change ARCHFLAGS for rv32imac parts: CH32V203/307, BL616, ESP32-C3)
NAME      := @NAME@
CROSS     := riscv-none-elf-
ARCHFLAGS := -march=rv32ec_zicsr -mabi=ilp32e
LDSCRIPT  := @NAME@.ld
SRCS      := main.c start.S
LDLIBS    := -lgcc
OUT     ?= build
CC      := $(CROSS)gcc
OBJCOPY := $(CROSS)objcopy
SIZE    := $(CROSS)size
CFLAGS  += $(ARCHFLAGS) -Os -g3 -Wall -Wextra -ffreestanding -ffunction-sections -fdata-sections
LDFLAGS += $(ARCHFLAGS) -nostartfiles -Wl,--gc-sections -Wl,-Map=$(OUT)/$(NAME).map -T$(LDSCRIPT)
OBJS    := $(addprefix $(OUT)/obj/,$(addsuffix .o,$(basename $(notdir $(SRCS)))))
vpath %.c $(sort $(dir $(SRCS)))
vpath %.S $(sort $(dir $(SRCS)))

all: $(OUT)/$(NAME).elf $(OUT)/$(NAME).bin

$(OUT)/obj/%.o: %.c | $(OUT)/obj
	$(CC) $(CFLAGS) -c $< -o $@
$(OUT)/obj/%.o: %.S | $(OUT)/obj
	$(CC) $(CFLAGS) -c $< -o $@
$(OUT)/$(NAME).elf: $(OBJS) $(LDSCRIPT)
	$(CC) $(LDFLAGS) $(OBJS) $(LDLIBS) -o $@
	$(SIZE) $@
$(OUT)/$(NAME).bin: $(OUT)/$(NAME).elf
	$(OBJCOPY) -O binary $< $@
$(OUT)/obj:
	mkdir -p $@

.PHONY: all

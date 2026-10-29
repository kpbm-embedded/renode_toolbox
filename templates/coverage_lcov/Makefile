# @NAME@: BlackPill F411 firmware for line coverage from Renode traces (-O0 -g3: one PC per source line).
# Build: ./renode-box run make -C <dir>/@NAME@   (arm-none-eabi-gcc from the renode-box env)
NAME      := @NAME@
# Sources are compiled by absolute path: renode-retracer 1.17 maps DWARF<5 directory index 0 (the compile dir) to the
# last include directory, so files given as plain "main.c" would not be found.
CROSS     := arm-none-eabi-
ARCHFLAGS := -mcpu=cortex-m4 -mthumb -mfloat-abi=hard -mfpu=fpv4-sp-d16
LDSCRIPT  := stm32f411.ld
SRCS      := main.c startup.c
OUT     ?= build
CC      := $(CROSS)gcc
OBJCOPY := $(CROSS)objcopy
SIZE    := $(CROSS)size
CFLAGS  += $(ARCHFLAGS) -O0 -g3 -Wall -Wextra -ffreestanding -ffunction-sections -fdata-sections
LDFLAGS += $(ARCHFLAGS) -nostartfiles -Wl,--gc-sections -Wl,-Map=$(OUT)/$(NAME).map -T$(LDSCRIPT)
OBJS    := $(addprefix $(OUT)/obj/,$(addsuffix .o,$(basename $(notdir $(SRCS)))))
vpath %.c $(sort $(dir $(SRCS)))
vpath %.S $(sort $(dir $(SRCS)))

all: $(OUT)/$(NAME).elf $(OUT)/$(NAME).bin

$(OUT)/obj/%.o: %.c | $(OUT)/obj
	$(CC) $(CFLAGS) -c $(abspath $<) -o $@
$(OUT)/obj/%.o: %.S | $(OUT)/obj
	$(CC) $(CFLAGS) -c $(abspath $<) -o $@
$(OUT)/$(NAME).elf: $(OBJS) $(LDSCRIPT)
	$(CC) $(LDFLAGS) $(OBJS) $(LDLIBS) -o $@
	$(SIZE) $@
$(OUT)/$(NAME).bin: $(OUT)/$(NAME).elf
	$(OBJCOPY) -O binary $< $@
$(OUT)/obj:
	mkdir -p $@

.PHONY: all

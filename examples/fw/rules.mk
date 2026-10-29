# rules.mk: shared rules for the bare-metal examples. The including Makefile sets
#   NAME, CROSS (arm-none-eabi- | riscv-none-elf-), ARCHFLAGS, LDSCRIPT, SRCS, OUT
# and gets $(OUT)/$(NAME).elf, .bin and .lst. Tools come from PATH (./renode-box shell).
FW      ?= $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
OUT     ?= build
CC      := $(CROSS)gcc
OBJCOPY := $(CROSS)objcopy
OBJDUMP := $(CROSS)objdump
SIZE    := $(CROSS)size
CFLAGS  += $(ARCHFLAGS) -Os -g3 -Wall -Wextra -ffreestanding -ffunction-sections -fdata-sections -I$(FW)/include
LDFLAGS += $(ARCHFLAGS) -nostartfiles -Wl,--gc-sections -Wl,-Map=$(OUT)/$(NAME).map -T$(LDSCRIPT)
OBJS    := $(addprefix $(OUT)/obj/,$(notdir $(addsuffix .o,$(basename $(SRCS)))))
vpath %.c $(sort $(dir $(SRCS)))
vpath %.S $(sort $(dir $(SRCS)))

all: $(OUT)/$(NAME).elf $(OUT)/$(NAME).bin $(OUT)/$(NAME).lst

$(OUT)/obj/%.o: %.c | $(OUT)/obj
	$(CC) $(CFLAGS) -c $< -o $@
$(OUT)/obj/%.o: %.S | $(OUT)/obj
	$(CC) $(CFLAGS) -c $< -o $@
$(OUT)/$(NAME).elf: $(OBJS) $(LDSCRIPT)
	$(CC) $(LDFLAGS) $(OBJS) $(LDLIBS) -o $@
	$(SIZE) $@
$(OUT)/$(NAME).bin: $(OUT)/$(NAME).elf
	$(OBJCOPY) -O binary $< $@
$(OUT)/$(NAME).lst: $(OUT)/$(NAME).elf
	$(OBJDUMP) -d -S $< > $@
$(OUT)/obj:
	mkdir -p $@

.PHONY: all

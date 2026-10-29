# @NAME@: one source, two firmware roles for two BlackPill F411 boards (ping and pong).
# Build both: ./renode-box run make -C <dir>/@NAME@   -> build/ping/@NAME@_ping.elf, build/pong/@NAME@_pong.elf
ROLES     := ping pong
ifeq ($(ROLE),)
all:
	@for r in $(ROLES); do $(MAKE) --no-print-directory ROLE=$$r || exit 1; done
.PHONY: all
else
NAME      := @NAME@_$(ROLE)
CROSS     := arm-none-eabi-
ARCHFLAGS := -mcpu=cortex-m4 -mthumb -mfloat-abi=hard -mfpu=fpv4-sp-d16
CFLAGS    += -DROLE_$(shell echo $(ROLE) | tr a-z A-Z)
LDSCRIPT  := stm32f411.ld
SRCS      := main.c startup.c
OUT       := build/$(ROLE)
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
endif

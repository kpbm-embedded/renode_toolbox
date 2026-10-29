# @NAME@: Cortex-M85 (RA8M1) firmware with Helium/MVE kernels; `make check-asm` greps the listing for MVE/LOB.
# Build: ./renode-box run make -C <dir>/@NAME@   (arm-none-eabi-gcc from the renode-box env)
NAME      := @NAME@
CROSS     := arm-none-eabi-
ARCHFLAGS := -mcpu=cortex-m85 -mthumb -mfloat-abi=hard
LDSCRIPT  := ra8m1.ld
SRCS      := main.c startup.c
OUT     ?= build
CC      := $(CROSS)gcc
OBJCOPY := $(CROSS)objcopy
SIZE    := $(CROSS)size
OBJDUMP := $(CROSS)objdump
CFLAGS  += $(ARCHFLAGS) -O2 -g3 -Wall -Wextra -ffreestanding -ffunction-sections -fdata-sections
LDFLAGS += $(ARCHFLAGS) -nostartfiles -Wl,--gc-sections -Wl,-Map=$(OUT)/$(NAME).map -T$(LDSCRIPT)
OBJS    := $(addprefix $(OUT)/obj/,$(addsuffix .o,$(basename $(notdir $(SRCS)))))
vpath %.c $(sort $(dir $(SRCS)))
vpath %.S $(sort $(dir $(SRCS)))

all: $(OUT)/$(NAME).elf $(OUT)/$(NAME).bin check-asm

# the compiler really emitted Helium (vmlaldava or its alias vmlalva, vqadd, vfma, tail predication vctp) and low-overhead loops
check-asm: $(OUT)/$(NAME).lst
	@for n in 'vmlaldava|vmlalva' vqadd.s32 vfma.f32 vctp.16 'le\slr|letp\slr|wls\slr|dls\slr|wlstp|dlstp'; do \
	  grep -qE "$$n" $< && echo "ok    $$n in the listing" || { echo "FAIL  no $$n in $<"; exit 1; }; done
$(OUT)/$(NAME).lst: $(OUT)/$(NAME).elf
	$(OBJDUMP) -d $< > $@

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

.PHONY: all check-asm

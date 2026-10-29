# @NAME@: Zig firmware for the nRF52840 with the Zig of 32_24_microzig (microzig-box: $BOX_MICROZIG, else the
# folder next to 32_06_renode). Run: ./renode-box run make -C <dir>/@NAME@   (host unit tests first, then the ELF)
ZIG_ID     ?= $(or $(BOX_MICROZIG),$(RENODE_BOX_ROOT)/../32_24_microzig)
ZIG_BOX    := $(ZIG_ID)/microzig-box
ZIG_FLAGS  := -target thumb-freestanding-eabihf -mcpu cortex_m4 -O ReleaseSmall -fentry=Reset_Handler

all: build/@NAME@.elf

check-zig:
	@[ -x "$(ZIG_BOX)" ] || { echo "skip: needs 32_24_microzig (microzig-box): set BOX_MICROZIG"; exit 3; }

test: check-zig
	"$(ZIG_BOX)" zig test logic.zig --cache-dir build/zig-cache

build/@NAME@.elf: main.zig logic.zig nrf52840.ld | test
	"$(ZIG_BOX)" zig build-exe main.zig $(ZIG_FLAGS) -T nrf52840.ld --cache-dir build/zig-cache -femit-bin=$@

.PHONY: all test check-zig

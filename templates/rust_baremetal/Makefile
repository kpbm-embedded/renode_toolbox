# @NAME@: builds the no_std Rust firmware for both boards with the pinned toolchain of 32_17_embedded_rust
# (rust-box: $BOX_EMBEDDED_RUST, else the folder next to 32_06_renode). Run: ./renode-box run make -C <dir>/@NAME@
RUST_ID  ?= $(or $(BOX_EMBEDDED_RUST),$(RENODE_BOX_ROOT)/../32_17_embedded_rust)
RUST_BOX := $(RUST_ID)/rust-box
TARGETS  := thumbv7em-none-eabihf riscv32imac-unknown-none-elf

all:
	@[ -x "$(RUST_BOX)" ] || { echo "skip: needs 32_17_embedded_rust (rust-box): set BOX_EMBEDDED_RUST"; exit 3; }
	@for t in $(TARGETS); do "$(RUST_BOX)" cargo build --release --offline --target $$t --target-dir "$(CURDIR)/build/target" || exit 1; done

.PHONY: all

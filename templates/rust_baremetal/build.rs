// Picks the linker script for the target: blackpill.ld (Arm) or ch32v203.ld (RISC-V).
use std::env;

fn main() {
    let dir = env::var("CARGO_MANIFEST_DIR").unwrap();
    let target = env::var("TARGET").unwrap();
    let ld = if target.starts_with("thumb") { "blackpill.ld" } else { "ch32v203.ld" };
    println!("cargo:rustc-link-search={dir}");
    println!("cargo:rustc-link-arg=-T{ld}");
    println!("cargo:rerun-if-changed={dir}/{ld}");
}

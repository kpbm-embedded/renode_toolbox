//! no_std, no-dependency Rust firmware for Renode, one source for two boards:
//! - BlackPill F411 (thumbv7em-none-eabihf): USART1 console, LED PC13, KEY PA0 -> panic
//! - CH32V203-like (riscv32imac-unknown-none-elf): USART1 console (same STM32-style USART)
//! Shows: own startup (.data/.bss), core::fmt over a UART, a panic handler that reports
//! its message and location, and plain MMIO with volatile reads/writes.
#![no_std]
#![no_main]

use core::fmt::Write;
use core::panic::PanicInfo;
use core::ptr::{read_volatile, write_volatile};

fn rd(a: usize) -> u32 {
    unsafe { read_volatile(a as *const u32) }
}
fn wr(a: usize, v: u32) {
    unsafe { write_volatile(a as *mut u32, v) }
}

/// STM32-style USART (STM32F4 and the WCH CH32V parts share this register layout).
struct Usart(usize);
impl Usart {
    fn init(&self) {
        wr(self.0 + 0x08, 0x8B); // BRR: 115200 at 16 MHz
        wr(self.0 + 0x0C, (1 << 13) | (1 << 3) | (1 << 2)); // UE | TE | RE
    }
    fn putc(&self, c: u8) {
        while rd(self.0) & (1 << 7) == 0 {}
        wr(self.0 + 0x04, c as u32);
    }
}
impl Write for Usart {
    fn write_str(&mut self, s: &str) -> core::fmt::Result {
        for b in s.bytes() {
            if b == b'\n' {
                self.putc(b'\r');
            }
            self.putc(b);
        }
        Ok(())
    }
}

static mut BOOTS: u32 = 7; // .data: proves the flash -> RAM copy
static mut ZEROED: u32 = 0; // .bss

fn fib(n: u32) -> u32 {
    (0..n).fold((0u32, 1u32), |(a, b), _| (b, a.wrapping_add(b))).0
}

#[cfg(target_arch = "arm")]
mod board {
    use super::*;
    pub const NAME: &str = "BlackPill F411 (thumbv7em)";
    pub const CONSOLE: Usart = Usart(0x4001_1000);
    pub fn init() {
        wr(0x4002_3830, rd(0x4002_3830) | 1 | (1 << 2)); // RCC_AHB1ENR: GPIOA, GPIOC
        wr(0x4002_3844, rd(0x4002_3844) | (1 << 4)); // RCC_APB2ENR: USART1
        let moder = rd(0x4002_0000) & !(0xF << 18);
        wr(0x4002_0000, moder | (0xA << 18)); // PA9/PA10 AF
        wr(0x4002_0024, (rd(0x4002_0024) & !0xFF0) | (0x77 << 4)); // AF7
        wr(0x4002_000C, rd(0x4002_000C) | 1); // PA0 pull-up
        wr(0x4002_0800, (rd(0x4002_0800) & !(3 << 26)) | (1 << 26)); // PC13 output
    }
    pub fn led(on: bool) {
        wr(0x4002_0818, if on { 1 << (13 + 16) } else { 1 << 13 }); // active low
    }
    pub fn key() -> bool {
        rd(0x4002_0010) & 1 == 0
    }

    unsafe extern "C" {
        static mut _sidata: u32;
        static mut _sdata: u32;
        static mut _edata: u32;
        static mut _sbss: u32;
        static mut _ebss: u32;
    }
    #[unsafe(no_mangle)]
    pub unsafe extern "C" fn reset() -> ! {
        unsafe {
            let (mut s, mut d) = (&raw const _sidata, &raw mut _sdata);
            while d < &raw mut _edata {
                write_volatile(d, read_volatile(s));
                d = d.add(1);
                s = s.add(1);
            }
            let mut b = &raw mut _sbss;
            while b < &raw mut _ebss {
                write_volatile(b, 0);
                b = b.add(1);
            }
            wr(0xE000_ED88, rd(0xE000_ED88) | (0xF << 20)); // FPU on (hard-float ABI)
        }
        super::main()
    }
    unsafe extern "C" fn default_handler() -> ! {
        loop {}
    }
    #[unsafe(link_section = ".vectors")]
    #[used]
    static VECTORS: [unsafe extern "C" fn() -> !; 15] = {
        let mut v: [unsafe extern "C" fn() -> !; 15] = [default_handler; 15];
        v[0] = reset;
        v
    };
}

#[cfg(target_arch = "riscv32")]
mod board {
    use super::*;
    pub const NAME: &str = "CH32V203-like (riscv32imac)";
    pub const CONSOLE: Usart = Usart(0x4001_3800);
    pub fn init() {}
    pub fn led(_on: bool) {}
    pub fn key() -> bool {
        false
    }

    core::arch::global_asm!(
        ".section .text.start, \"ax\"",
        ".globl _start",
        "_start:",
        "    la sp, _estack",
        "    la a0, _sidata",
        "    la a1, _sdata",
        "    la a2, _edata",
        "1:  bgeu a1, a2, 2f",
        "    lw t0, 0(a0)",
        "    sw t0, 0(a1)",
        "    addi a0, a0, 4",
        "    addi a1, a1, 4",
        "    j 1b",
        "2:  la a0, _sbss",
        "    la a1, _ebss",
        "3:  bgeu a0, a1, 4f",
        "    sw zero, 0(a0)",
        "    addi a0, a0, 4",
        "    j 3b",
        "4:  call {main}",
        "5:  j 5b",
        main = sym super::main,
    );
}

fn main() -> ! {
    board::init();
    let mut con = board::CONSOLE;
    con.init();
    let (boots, zeroed) = unsafe { (read_volatile(&raw const BOOTS), read_volatile(&raw const ZEROED)) };
    let _ = writeln!(con, "Hello from Rust on {}", board::NAME);
    let _ = writeln!(con, "data {} bss {}", boots, zeroed);
    for n in 0u32.. {
        board::led(n % 2 == 0);
        let _ = writeln!(con, "fib({}) = {}", n, fib(n));
        for _ in 0..20 {
            if board::key() {
                panic!("KEY pressed at n={}", n);
            }
            for _ in 0..5_000 {
                unsafe { core::arch::asm!("nop") };
            }
        }
    }
    unreachable!()
}

#[panic_handler]
fn panic(info: &PanicInfo) -> ! {
    let mut con = board::CONSOLE;
    let _ = write!(con, "PANIC: {}", info.message());
    if let Some(l) = info.location() {
        let _ = write!(con, " at {}:{}", l.file(), l.line());
    }
    let _ = writeln!(con);
    loop {}
}

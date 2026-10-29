//! Zig firmware for the nRF52840 (nice!nano) in Renode: own startup and vector table, legacy
//! UART0 console, LED P0.15, line commands ("crc <text>" prints CRC-8 of <text>, "led" toggles).
//! Built with the Zig of 32_24_microzig (freestanding, no MicroZig HAL needed).
const logic = @import("logic.zig");

fn reg(comptime a: usize) *volatile u32 {
    return @ptrFromInt(a);
}
const UART0 = 0x40002000;
const uart_startrx = reg(UART0 + 0x000);
const uart_starttx = reg(UART0 + 0x008);
const uart_rxdrdy = reg(UART0 + 0x108);
const uart_txdrdy = reg(UART0 + 0x11C);
const uart_enable = reg(UART0 + 0x500);
const uart_pseltxd = reg(UART0 + 0x50C);
const uart_pselrxd = reg(UART0 + 0x514);
const uart_rxd = reg(UART0 + 0x518);
const uart_txd = reg(UART0 + 0x51C);
const uart_baudrate = reg(UART0 + 0x524);
const p0_out = reg(0x50000504);
const p0_dirset = reg(0x50000518);

fn putc(c: u8) void {
    uart_txdrdy.* = 0;
    uart_txd.* = c;
    while (uart_txdrdy.* == 0) {}
}
fn puts(s: []const u8) void {
    for (s) |c| {
        if (c == '\n') putc('\r');
        putc(c);
    }
}

var boot_magic: u32 = 0x5A16; // .data
var line_buf: [64]u8 = undefined; // .bss

fn main() noreturn {
    p0_dirset.* = 1 << 15;
    uart_pseltxd.* = 6;
    uart_pselrxd.* = 8;
    uart_baudrate.* = 0x01D7E000;
    uart_enable.* = 4;
    uart_starttx.* = 1;
    uart_startrx.* = 1;
    puts("Hello from Zig on nRF52840\n");
    puts(if (boot_magic == 0x5A16) "data ok\n> " else "data BROKEN\n> ");
    var n: usize = 0;
    while (true) {
        if (uart_rxdrdy.* == 0) continue;
        uart_rxdrdy.* = 0;
        const c: u8 = @truncate(uart_rxd.*);
        if (c != '\r' and c != '\n') {
            putc(c); // echo
            if (n < line_buf.len) {
                line_buf[n] = c;
                n += 1;
            }
            continue;
        }
        const line = line_buf[0..n];
        n = 0;
        puts("\n");
        if (line.len >= 4 and std_eql(line[0..4], "crc ")) {
            var d: [10]u8 = undefined;
            puts("crc8 ");
            puts(logic.fmtDec(&d, logic.crc8(line[4..])));
            puts("\n");
            boot_magic +%= 1; // written at run time: keeps it a real .data variable
        } else if (std_eql(line, "led")) {
            p0_out.* ^= 1 << 15;
            puts(if (p0_out.* & (1 << 15) != 0) "led on\n" else "led off\n");
        } else if (line.len > 0) {
            puts("unknown command\n");
        }
        puts("> ");
    }
}

fn std_eql(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;
    for (a, b) |x, y| if (x != y) return false;
    return true;
}

// ---- startup: .data copy, .bss zero, then main; the table is placed after the initial SP ----
extern var _sidata: u32;
extern var _sdata: u32;
extern var _edata: u32;
extern var _sbss: u32;
extern var _ebss: u32;

export fn Reset_Handler() callconv(.c) noreturn {
    const data_len = @intFromPtr(&_edata) - @intFromPtr(&_sdata);
    const src: [*]const u8 = @ptrCast(&_sidata);
    const dst: [*]u8 = @ptrCast(&_sdata);
    @memcpy(dst[0..data_len], src[0..data_len]);
    const bss_len = @intFromPtr(&_ebss) - @intFromPtr(&_sbss);
    const bss: [*]u8 = @ptrCast(&_sbss);
    @memset(bss[0..bss_len], 0);
    main();
}

fn defaultHandler() callconv(.c) noreturn {
    while (true) {}
}

const Handler = *const fn () callconv(.c) noreturn;
export const vectors linksection(".vectors") = blk: {
    var v: [15]Handler = @splat(defaultHandler);
    v[0] = Reset_Handler;
    break :blk v;
};

pub fn panic(msg: []const u8, _: ?*@import("std").builtin.StackTrace, _: ?usize) noreturn {
    puts("PANIC: ");
    puts(msg);
    puts("\n");
    while (true) {}
}

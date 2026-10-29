//! Board-independent logic, unit-tested on the host (`zig test logic.zig`) and used by the firmware.

/// CRC-8 (polynomial 0x07, init 0), as used by many sensors (SMBus PEC).
pub fn crc8(data: []const u8) u8 {
    var crc: u8 = 0;
    for (data) |b| {
        crc ^= b;
        var i: u4 = 0;
        while (i < 8) : (i += 1) {
            crc = if (crc & 0x80 != 0) (crc << 1) ^ 0x07 else crc << 1;
        }
    }
    return crc;
}

/// Writes `v` in decimal into `buf`; returns the used part.
pub fn fmtDec(buf: []u8, v: u32) []const u8 {
    var i: usize = buf.len;
    var x = v;
    while (true) {
        i -= 1;
        buf[i] = @intCast('0' + x % 10);
        x /= 10;
        if (x == 0) break;
    }
    return buf[i..];
}

const std = @import("std");

test "crc8 check value" {
    try std.testing.expectEqual(@as(u8, 0xF4), crc8("123456789"));
    try std.testing.expectEqual(@as(u8, 0), crc8(""));
}

test "fmtDec" {
    var b: [10]u8 = undefined;
    try std.testing.expectEqualStrings("0", fmtDec(&b, 0));
    try std.testing.expectEqualStrings("4294967295", fmtDec(&b, 4294967295));
}

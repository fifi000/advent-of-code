const std = @import("std");
const File = std.fs.File;
const Reader = std.io.Reader;
const print = std.debug.print;
const assert = std.debug.assert;
const String = []const u8;

pub fn main() !void {
    const file = try std.fs.cwd().openFile("./2023/day1/input.txt", .{ .mode = .read_only });
    defer file.close();

    var buffer: [2 << 16]u8 = undefined;
    const bytes_read = try file.read(&buffer);

    assert(bytes_read < buffer.len);

    var it = std.mem.splitSequence(u8, buffer[0..bytes_read], "\n");

    var sum: u32 = 0;

    while (it.next()) |line| {
        sum += getLineCalibrationValue(line);
    }

    print("{any}\n", .{sum});
}

fn getLineCalibrationValue(line: String) u32 {
    var first: ?u8 = null;
    var last: ?u8 = null;

    for (line) |char| {
        switch (char) {
            '0'...'9' => {
                if (first == null) {
                    first = char - '0';
                }

                last = char - '0';
            },
            else => continue,
        }
    }

    if (first == null or last == null) unreachable;

    return concat(u8, first.?, last.?);
}

test getLineCalibrationValue {
    try std.testing.expectEqual(getLineCalibrationValue("1abc2"), 12);
    try std.testing.expectEqual(getLineCalibrationValue("pqr3stu8vwx"), 38);
    try std.testing.expectEqual(getLineCalibrationValue("a1b2c3d4e5f"), 15);
    try std.testing.expectEqual(getLineCalibrationValue("treb7uchet"), 77);
}

fn concat(comptime T: type, left: T, right: T) T {
    const right_len = if (right == 0) 1 else std.math.log10_int(right) + 1;

    // std.debug.print("left: {0}, right: {1}, len: {2}\n", .{ left, right, right_len });
    return left * std.math.pow(T, 10, right_len) + right;
}

test concat {
    try std.testing.expectEqual(11, concat(u8, 1, 1));
    try std.testing.expectEqual(123, concat(u8, 12, 3));
    try std.testing.expectEqual(123, concat(u8, 1, 23));
    try std.testing.expectEqual(123, concat(u32, 0, 123));
    try std.testing.expectEqual(1230, concat(u32, 123, 0));
    try std.testing.expectEqual(0, concat(u32, 0, 0));
}

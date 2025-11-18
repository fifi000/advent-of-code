const std = @import("std");
const File = std.fs.File;
const Reader = std.io.Reader;
const print = std.debug.print;
const assert = std.debug.assert;
const String = []const u8;

const FileLinesIterator = struct {};

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

    for (line, 0..) |_, i| {
        var j: usize = 0;
        while (i + j < line.len and j <= 5) : (j += 1) {
            switch (parseNumber(line[i..(i + j + 1)])) {
                .number => |number| {
                    if (first == null) {
                        first = number;
                    }

                    last = number;
                    break;
                },
                .canBeNumber => |canBe| {
                    if (!canBe) {
                        break;
                    }
                },
            }
        }
    }

    if (first == null or last == null) unreachable;

    return concat(u8, first.?, last.?);
}

const MaybeNumber = union(enum) { number: u8, canBeNumber: bool };

fn parseNumber(text: String) MaybeNumber {
    // is a number 0-9
    if (text.len == 1 and '0' <= text[0] and text[0] <= '9') {
        return MaybeNumber{ .number = text[0] - '0' };
    }

    const numbers = [_]String{
        "zero",
        "one",
        "two",
        "three",
        "four",
        "five",
        "six",
        "seven",
        "eight",
        "nine",
    };

    // is a number "zero" - "nine"
    for (numbers, 0..) |number, idx| {
        if (std.mem.eql(u8, text, number)) {
            return MaybeNumber{ .number = @intCast(idx) };
        }
    }

    // can be a number "zero" - "nine"
    for (numbers) |number| {
        if (std.mem.startsWith(u8, number, text)) {
            return MaybeNumber{ .canBeNumber = true };
        }
    }

    // will not (and is not) a number
    return MaybeNumber{ .canBeNumber = false };
}

test getLineCalibrationValue {
    try std.testing.expectEqual(getLineCalibrationValue("1abc2"), 12);
    try std.testing.expectEqual(getLineCalibrationValue("pqr3stu8vwx"), 38);
    try std.testing.expectEqual(getLineCalibrationValue("a1b2c3d4e5f"), 15);
    try std.testing.expectEqual(getLineCalibrationValue("treb7uchet"), 77);

    try std.testing.expectEqual(getLineCalibrationValue("two1nine"), 29);
    try std.testing.expectEqual(getLineCalibrationValue("eightwothree"), 83);
    try std.testing.expectEqual(getLineCalibrationValue("abcone2threexyz"), 13);
    try std.testing.expectEqual(getLineCalibrationValue("xtwone3four"), 24);
    try std.testing.expectEqual(getLineCalibrationValue("4nineeightseven2"), 42);
    try std.testing.expectEqual(getLineCalibrationValue("zoneight234"), 14);
    try std.testing.expectEqual(getLineCalibrationValue("7pqrstsixteen"), 76);
}

fn concat(comptime T: type, left: T, right: T) T {
    const right_len = if (right == 0) 1 else std.math.log10_int(right) + 1;

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

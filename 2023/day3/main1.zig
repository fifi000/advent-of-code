const std = @import("std");
const math = std.math;

const File = std.fs.File;
const Reader = std.io.Reader;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const print = std.debug.print;
const assert = std.debug.assert;

const String = []const u8;
const Int = u32;

fn getInput(filename: String) !String {
    const file = try std.fs.cwd().openFile(filename, .{ .mode = .read_only });
    defer file.close();

    var buffer: [2 << 16]u8 = undefined;
    const bytes_read = try file.read(&buffer);

    assert(bytes_read < buffer.len);

    return buffer[0..bytes_read];
}

fn getLines(gpa: Allocator, text: String) !ArrayList(String) {
    var list = ArrayList(String).empty;

    var it = std.mem.tokenizeAny(u8, text, "\r\n");

    while (it.next()) |line| {
        try list.append(gpa, line);
    }

    return list;
}

fn Number(comptime T: type) type {
    const ti = @typeInfo(T);
    if (ti != .int or ti.int.signedness != .unsigned) {
        @compileError("T must be an unsigned int.");
    }

    return struct {
        value: T,

        const Self = @This();

        pub fn reset(self: *Self) void {
            self.value = null;
        }

        pub fn addDigit(self: *Self, char: u8) void {
            assert(std.ascii.isDigit(char));

            self.value = concat(self.value, char - '0');
        }

        fn concat(left: T, right: T) T {
            const right_len = if (right == 0) 1 else std.math.log10_int(right) + 1;

            return left * std.math.pow(T, 10, right_len) + right;
        }
    };
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    const allocator = gpa.allocator();

    const input = try getInput("./2023/day3/input.txt");
    // const input = try getInput("./input.txt");
    var list = try getLines(allocator, input);
    defer list.deinit(allocator);

    const array = list.items;
    var sum: Int = 0;

    for (array, 0..) |row, row_idx| {
        var number: ?Number(Int) = null;
        var start_idx: usize = 0;

        for (row, 0..) |char, column_idx| {
            if (std.ascii.isDigit(char)) {
                if (number == null) {
                    start_idx = column_idx;
                    number = .{ .value = char - '0' };
                } else {
                    number.?.addDigit(char);
                }
            } else if (number != null) {
                if (isPartNumber(usize, array, row_idx, start_idx, column_idx - 1)) {
                    print("adding: {}\n", .{number.?.value});
                    sum += number.?.value;
                }

                number = null;
            }
        }

        // we have reached the end of a line but still did not sum the number
        if (number != null and isPartNumber(usize, array, row_idx, start_idx, row.len - 1)) {
            print("adding: {}\n", .{number.?.value});
            sum += number.?.value;
        }
    }

    print("the sum is: '{0}'\n", .{sum});
}

fn isPartNumber(comptime T: type, array: []String, row_idx: T, start_idx: T, end_idx: T) bool {
    // left
    left: {
        const left_idx = math.sub(T, start_idx, 1) catch break :left;

        if (left_idx >= 0 and isSymbol(array[row_idx][left_idx])) {
            return true;
        }
    }

    // right
    right: {
        const right_idx = math.add(T, end_idx, 1) catch break :right;
        if (right_idx < array[row_idx].len and isSymbol(array[row_idx][right_idx])) {
            return true;
        }
    }

    // up
    up: {
        const up_idx = math.sub(T, row_idx, 1) catch break :up;
        if (up_idx >= 0) {
            const left_idx = if (start_idx == 0) 0 else start_idx - 1;
            const right_idx = @min(end_idx + 2, array[up_idx].len);

            for (array[up_idx][left_idx..right_idx]) |c| {
                if (isSymbol(c)) {
                    return true;
                }
            }
        }
    }

    // down
    down: {
        const down_idx = math.add(T, row_idx, 1) catch break :down;
        if (down_idx < array.len) {
            const left_idx = if (start_idx == 0) 0 else start_idx - 1;
            const right_idx = @min(end_idx + 2, array[down_idx].len);

            for (array[down_idx][left_idx..right_idx]) |c| {
                if (isSymbol(c)) {
                    return true;
                }
            }
        }
    }

    // apparently it is not a number
    return false;
}

fn isSymbol(c: u8) bool {
    return switch (c) {
        '1'...'9', '.' => false,
        else => true,
    };
}

test "split" {
    const ss = "aaa\r\nbbb\r\nccc\r\n";

    var it = std.mem.tokenizeAny(u8, ss, "\r\n");

    try std.testing.expectEqualStrings("aaa", it.next().?);
    try std.testing.expectEqualStrings("bbb", it.next().?);
    try std.testing.expectEqualStrings("ccc", it.next().?);
    try std.testing.expect(it.next() == null);
}

test "split2" {
    const ss = "aaa\n\rbbb\nccc\r\n";

    var it = std.mem.tokenizeAny(u8, ss, "\r\n");

    try std.testing.expectEqualStrings("aaa", it.next().?);
    try std.testing.expectEqualStrings("bbb", it.next().?);
    try std.testing.expectEqualStrings("ccc", it.next().?);
    try std.testing.expect(it.next() == null);
}

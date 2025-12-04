const std = @import("std");
const math = std.math;
const debug = std.debug;

const File = std.fs.File;
const Reader = std.io.Reader;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const AutoArrayHashMap = std.AutoArrayHashMap;

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

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const input = try getInput("./2025/day3/input.txt");

    const list = try getLines(allocator, input);

    const result = solve(list.items);

    print("result: '{any}'\n", .{result});
}

fn solve(banks: []const String) Int {
    var sum: Int = 0;

    for (banks) |bank| {
        sum += getLargestJoltage(bank);
    }

    return sum;
}

fn getLargestJoltage(bank: String) Int {
    assert(bank.len > 0);

    var left_idx: usize = 0;
    var left: u8 = toDigit(bank[left_idx]);
    var idx: usize = left_idx + 1;

    var battery: u8 = undefined;

    while (idx < bank.len - 1) : (idx += 1) {
        battery = toDigit(bank[idx]);
        if (battery > left) {
            left = battery;
            left_idx = idx;
        }
    }

    var right_idx: usize = left_idx + 1;
    var right: u8 = toDigit(bank[right_idx]);
    idx = right_idx + 1;

    while (idx < bank.len) : (idx += 1) {
        battery = toDigit(bank[idx]);
        if (battery > right) {
            right = battery;
            right_idx = idx;
        }
    }

    return concat(Int, left, right);
}

fn toDigit(c: u8) u8 {
    return switch (c) {
        '0'...'9' => c - '0',
        else => @panic("not a digit"),
    };
}

fn concat(comptime T: type, left: T, right: T) T {
    const right_len = if (right == 0) 1 else std.math.log10_int(right) + 1;

    return left * std.math.pow(T, 10, right_len) + right;
}

test concat {
    try std.testing.expectEqual(10, concat(u32, 1, 0));
    try std.testing.expectEqual(99, concat(u32, 9, 9));
    try std.testing.expectEqual(1122, concat(u32, 11, 22));
    try std.testing.expectEqual(123456, concat(u32, 1234, 56));
}

test getLargestJoltage {
    try std.testing.expectEqual(99, getLargestJoltage("99111111"));
    try std.testing.expectEqual(98, getLargestJoltage("987654321111111"));
    try std.testing.expectEqual(89, getLargestJoltage("811111111111119"));
    try std.testing.expectEqual(78, getLargestJoltage("234234234234278"));
    try std.testing.expectEqual(92, getLargestJoltage("818181911112111"));
}

test solve {
    const banks = [_]String{
        "987654321111111",
        "811111111111119",
        "234234234234278",
        "818181911112111",
    };

    try std.testing.expectEqual(357, solve(&banks));
}

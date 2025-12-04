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
const Int = u128;

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

const joltage_digits = 12;
var joltage_buffer: [joltage_digits]u8 = undefined;

fn getLargestJoltage(bank: String) Int {
    assert(bank.len >= joltage_digits);

    var counter: usize = joltage_digits;
    var battery: u8 = undefined;
    var number_idx: ?usize = null;

    while (counter > 0) : (counter -= 1) {
        var idx = if (number_idx == null) 0 else number_idx.? + 1;
        number_idx = idx;
        var number = toDigit(bank[number_idx.?]);

        while (idx <= bank.len - counter) : (idx += 1) {
            battery = toDigit(bank[idx]);

            if (battery > number) {
                number = battery;
                number_idx = idx;
            }
        }

        joltage_buffer[joltage_digits - counter] = number;
    }

    var result: Int = joltage_buffer[0];

    for (joltage_buffer[1..]) |n| {
        result = concat(Int, result, n);
    }

    return result;
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
    try std.testing.expectEqual(97, getLargestJoltage("90657"));
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

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
const Int = i128;

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

    const input = try getInput("./2025/day2/input.txt");

    const list = try getLines(allocator, input);
    assert(list.items.len == 1);

    const ranges = try getRanges(allocator, list.items[0]);

    const result = solve(ranges);

    print("result: '{any}'\n", .{result});
}

fn getRanges(gpa: Allocator, text: String) ![]const String {
    var list = ArrayList(String).empty;

    var it = std.mem.tokenizeScalar(u8, text, ',');

    while (it.next()) |line| {
        try list.append(gpa, line);
    }

    return list.items;
}

fn Range(comptime T: type) type {
    const ti = @typeInfo(T);
    if (ti != .int or ti.int.signedness != .unsigned) {
        @compileError("T must be an unsigned int.");
    }

    return struct {
        start: T,
        end: T,

        const Self = @This();

        pub fn create(start: T, end: T) Self {
            assert(start >= end);

            return .{ .start = start, .end = end };
        }

        pub fn parse(text: String) Self {
            const idx = std.mem.indexOfScalar(u8, text, '-') orelse {
                debug.panic("Invalid range format: '{s}'", .{text});
            };
            assert(text.len >= 3);
            assert(idx > 0);
            assert(idx < text.len - 2);

            const start = std.fmt.parseInt(T, text[0..idx], 10) catch {
                debug.panic("Invalid range start: {s}\n", .{text[0..idx]});
            };
            const end = std.fmt.parseInt(T, text[idx + 1 ..], 10) catch {
                debug.panic("Invalid range end: {s}\n", .{text[idx + 1 ..]});
            };

            return .{ .start = start, .end = end };
        }
    };
}

fn solve(ranges: []const String) Int {
    var sum: Int = 0;

    for (ranges) |rangeString| {
        const range = Range(usize).parse(rangeString);

        for (range.start..range.end + 1) |id| {
            if (!isIdValid(usize, id)) {
                print("invalid id {}\n", .{id});
                sum += @intCast(id);
            }
        }
    }

    return sum;
}

fn isIdValid(comptime T: type, id: T) bool {
    const number = splitNumber(T, id) catch |err| switch (err) {
        error.OddLength => {
            return true;
        },
    };

    return number.left != number.right;
}

fn splitNumber(comptime T: type, number: T) error{OddLength}!struct { left: T, right: T } {
    const length = getNumberLength(T, number);

    if (@mod(length, 2) != 0) {
        return error.OddLength;
    }

    const denominator = math.pow(T, 10, length / 2);
    const left = @divFloor(number, denominator);
    const right = @mod(number, denominator);

    return .{ .left = left, .right = right };
}

fn getNumberLength(comptime T: type, number: T) T {
    assert(number >= 0);

    return if (number == 0) 1 else math.log10_int(number) + 1;
}

fn concat(comptime T: type, left: T, right: T) T {
    const right_len = if (right == 0) 1 else std.math.log10_int(right) + 1;

    // std.debug.print("left: {0}, right: {1}, len: {2}\n", .{ left, right, right_len });
    return left * std.math.pow(T, 10, right_len) + right;
}

test getNumberLength {
    for (0..10) |i| {
        try std.testing.expect(getNumberLength(usize, i) == 1);
    }

    for (10..100) |i| {
        try std.testing.expect(getNumberLength(usize, i) == 2);
    }

    for (100..1000) |i| {
        try std.testing.expect(getNumberLength(usize, i) == 3);
    }

    try std.testing.expect(getNumberLength(usize, 123456) == 6);
    try std.testing.expect(getNumberLength(usize, 1112111) == 7);
    try std.testing.expect(getNumberLength(usize, 9999999999) == 10);
}

test solve {
    try std.testing.expectEqual(33, solve(&[_]String{"11-22"}));
    try std.testing.expectEqual(99, solve(&[_]String{"95-115"}));
    try std.testing.expectEqual(1010, solve(&[_]String{"998-1012"}));
}

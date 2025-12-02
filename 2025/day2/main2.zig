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
            if (isIdInvalid(usize, id)) {
                print("invalid id: {}\n", .{id});
                sum += @intCast(id);
            }
        }
    }

    return sum;
}

fn isIdInvalid(comptime T: type, id: T) bool {
    const length = getNumberLength(T, id);

    for (1..length) |splitLength| {
        if (splitLength > @divFloor(length, 2)) break;

        const parts = split(T, id, @intCast(splitLength)) catch |err| switch (err) {
            error.ImpossibleEvenSplit => {
                continue;
            },
        };

        assert(parts.len >= 2);

        if (allEqual(T, parts)) {
            return true;
        }
    }

    return false;
}

fn allEqual(comptime T: type, slice: []const T) bool {
    assert(slice.len >= 1);

    for (slice) |part| {
        if (slice[0] != part) {
            return false;
        }
    }

    return true;
}

// '20' - usize max value length
var split_buffer: [20]usize = undefined;

fn split(comptime T: type, number: T, splitLength: u8) error{ImpossibleEvenSplit}![]const T {
    assert(splitLength >= 1);

    const length = getNumberLength(T, number);

    if (@mod(length, splitLength) != 0) {
        return error.ImpossibleEvenSplit;
    }

    assert(splitLength <= length);

    var denominator = math.pow(T, 10, length - splitLength);
    const moduloDenominator = math.pow(T, 10, splitLength);
    var idx: usize = 0;
    while (denominator > 0) {
        split_buffer[idx] = @mod(@divFloor(number, denominator), moduloDenominator);

        denominator /= moduloDenominator;
        idx += 1;
    }

    return split_buffer[0..idx];
}

fn getNumberLength(comptime T: type, number: T) T {
    assert(number >= 0);

    return if (number == 0) 1 else math.log10_int(number) + 1;
}

test isIdInvalid {
    try std.testing.expect(isIdInvalid(usize, 11));
    try std.testing.expect(isIdInvalid(usize, 22));
    try std.testing.expect(isIdInvalid(usize, 99));
    try std.testing.expect(isIdInvalid(usize, 111));
    try std.testing.expect(isIdInvalid(usize, 999));
    try std.testing.expect(isIdInvalid(usize, 1010));
    try std.testing.expect(isIdInvalid(usize, 1188511885));
    try std.testing.expect(isIdInvalid(usize, 222222));
    try std.testing.expect(isIdInvalid(usize, 446446));
    try std.testing.expect(isIdInvalid(usize, 565656));
}

test solve {
    try std.testing.expectEqual(243, solve(&[_]String{ "11-22", "95-115" }));
    try std.testing.expectEqual(33, solve(&[_]String{"11-22"}));
    try std.testing.expectEqual(210, solve(&[_]String{"95-115"}));
    try std.testing.expectEqual(2009, solve(&[_]String{"998-1012"}));
}

test split {
    const number: usize = 123123;

    try std.testing.expectEqualSlices(usize, &[_]usize{ 1, 2, 3, 1, 2, 3 }, try split(usize, number, 1));
    try std.testing.expectEqualSlices(usize, &[_]usize{ 12, 31, 23 }, try split(usize, number, 2));
    try std.testing.expectEqualSlices(usize, &[_]usize{ 123, 123 }, try split(usize, number, 3));
    try std.testing.expectError(error.ImpossibleEvenSplit, split(usize, number, 4));
    try std.testing.expectError(error.ImpossibleEvenSplit, split(usize, number, 5));
    try std.testing.expectEqualSlices(usize, &[_]usize{123123}, try split(usize, number, 6));
}

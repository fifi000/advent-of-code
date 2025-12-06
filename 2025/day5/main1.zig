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
const Int = u64;

fn getInput(allocator: Allocator, filename: String) !String {
    const file = try std.fs.cwd().openFile(filename, .{ .mode = .read_only });
    defer file.close();

    const file_size = try file.getEndPos();
    return file.readToEndAlloc(allocator, file_size);
}

fn getLines(allocator: Allocator, text: String) ![]String {
    var list = ArrayList(String).empty;
    defer list.deinit(allocator);

    var it = std.mem.tokenizeAny(u8, text, "\r\n");

    while (it.next()) |line| {
        try list.append(allocator, line);
    }

    return list.toOwnedSlice(allocator) catch @panic("getLines");
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    var input = try getInput(allocator, "./2025/day5/input.txt");
    defer allocator.free(input);

    // fuck windows :)
    input = try std.mem.replaceOwned(u8, allocator, input, "\r", "");
    defer allocator.free(input);

    const count = std.mem.count(u8, input, "\n\n");
    if (count != 1) {
        debug.panic("unexpected count: {}\n", .{count});
    }
    var it = std.mem.tokenizeSequence(u8, input, "\n\n");

    const rangesText = it.next() orelse unreachable;
    const idsText = it.next() orelse unreachable;
    assert(it.next() == null);

    const ranges = try getLines(allocator, rangesText);
    defer allocator.free(ranges);

    const ids = try getLines(allocator, idsText);
    defer allocator.free(ids);

    const result = solve(allocator, ranges, ids);
    print("result: '{any}'\n", .{result});
}

fn Range(comptime T: type) type {
    return struct {
        start: T,
        end: T,

        const Self = @This();

        pub fn contains(self: Self, needle: T) bool {
            return self.start <= needle and needle <= self.end;
        }

        pub fn parse(text: String) Self {
            const idx = std.mem.indexOfScalar(u8, text, '-') orelse @panic("'text' does not have '-'");

            assert(idx > 0);
            assert(idx < text.len - 1);

            return .{
                .start = std.fmt.parseInt(T, text[0..idx], 10) catch @panic("could not parse 'start'"),
                .end = std.fmt.parseInt(T, text[idx + 1 ..], 10) catch @panic("could not parse 'end'"),
            };
        }

        pub fn create(start: T, end: T) Self {
            assert(start <= end);

            return .{ .start = start, .end = end };
        }
    };
}

fn solve(allocator: Allocator, rangesText: []const String, idsText: []const String) Int {
    var counter: Int = 0;

    const ranges = createRanges(Int, allocator, rangesText);
    defer allocator.free(ranges);

    for (idsText) |idText| {
        const id = std.fmt.parseInt(Int, idText, 10) catch @panic("could not parse id");

        for (ranges) |range| {
            if (range.contains(id)) {
                counter += 1;
                break;
            }
        }
    }

    return counter;
}

fn createRanges(comptime T: type, allocator: Allocator, ranges: []const String) []Range(T) {
    var list = ArrayList(Range(T)).initCapacity(allocator, ranges.len) catch @panic("could not create a list of ranges");
    defer list.deinit(allocator);

    for (ranges) |text| {
        const range = Range(T).parse(text);
        list.appendAssumeCapacity(range);
    }

    return list.toOwnedSlice(allocator) catch @panic("create ranges - to owned slice");
}

test "rangeParse" {
    const range3_5 = Range(Int).parse("3-5");
    try std.testing.expectEqual(3, range3_5.start);
    try std.testing.expectEqual(5, range3_5.end);

    const range10_14 = Range(Int).parse("10-14");
    try std.testing.expectEqual(10, range10_14.start);
    try std.testing.expectEqual(14, range10_14.end);

    const range16_20 = Range(Int).parse("16-20");
    try std.testing.expectEqual(16, range16_20.start);
    try std.testing.expectEqual(20, range16_20.end);
}

test solve {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const rangesText = [_]String{
        "3-5",
        "10-14",
        "16-20",
        "12-18",
    };

    const idsText = [_]String{
        "1",
        "5",
        "8",
        "11",
        "17",
        "32",
    };

    try std.testing.expectEqual(3, solve(allocator, &rangesText, &idsText));
}

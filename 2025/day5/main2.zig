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
    _ = it.next() orelse unreachable;
    assert(it.next() == null);

    const ranges = try getLines(allocator, rangesText);
    defer allocator.free(ranges);

    const result = solve(allocator, ranges);
    print("result: '{any}'\n", .{result});
}

fn RangeCollection(comptime T: type) type {
    return struct {
        ranges: ArrayList(Range(T)),

        const Self = @This();

        pub fn create() Self {
            return .{
                .ranges = ArrayList(Range(T)).empty,
            };
        }

        pub fn count(self: Self) T {
            var counter: T = 0;

            for (self.ranges.items) |range| {
                counter += range.length();
            }

            return counter;
        }

        pub fn deinit(self: *Self, allocator: Allocator) void {
            self.ranges.deinit(allocator);
        }

        pub fn add(self: *Self, allocator: Allocator, new_range: Range(T)) void {
            // asserts ranges are sorted and disjoined
            if (self.ranges.items.len > 0) {
                for (0..self.ranges.items.len - 1) |idx| {
                    assert(self.ranges.items[idx].end < self.ranges.items[idx + 1].start);
                }
            }

            const current_count = self.count();
            defer assert(self.count() >= current_count);

            // initial value
            if (self.ranges.items.len == 0) {
                self.ranges.append(allocator, new_range) catch unreachable;
                return;
            }

            // new range is already an inner range
            if (self.contains(new_range)) {
                return;
            }

            // insert at front
            if (new_range.end < self.ranges.items[0].start) {
                self.ranges.insert(allocator, 0, new_range) catch unreachable;
                return;
            }

            // append to the end
            if (self.ranges.items[self.ranges.items.len - 1].end < new_range.start) {
                self.ranges.append(allocator, new_range) catch unreachable;
                return;
            }

            var indexes_to_remove = ArrayList(usize).empty;
            defer indexes_to_remove.deinit(allocator);

            // can extend other range
            for (self.ranges.items, 0..) |range, i| {
                var merged = range.merge(new_range) catch {
                    if (new_range.end < range.start) {
                        self.ranges.insert(allocator, i, new_range) catch unreachable;
                        break;
                    }

                    continue;
                };
                var idx = i + 1;

                while (idx < self.ranges.items.len) : (idx += 1) {
                    merged = self.ranges.items[idx].merge(merged) catch |err| switch (err) {
                        error.DisjointRanges => break,
                    };

                    indexes_to_remove.append(allocator, idx) catch unreachable;
                }

                self.ranges.items[i] = merged;
                break;
            }

            self.ranges.orderedRemoveMany(indexes_to_remove.items);
        }

        fn contains(self: Self, needle: Range(T)) bool {
            for (self.ranges.items) |range| {
                if (range.containsRange(needle)) {
                    return true;
                }
            }

            return false;
        }
    };
}

const RangeRelation = enum {
    equal,
    superset,
    subset,
    disjoined,
    adjacent,
    intersected,
};

fn Range(comptime T: type) type {
    return struct {
        start: T,
        end: T,

        const Self = @This();

        pub fn length(self: Self) T {
            return self.end - self.start + 1;
        }

        pub fn contains(self: Self, needle: T) bool {
            return self.start <= needle and needle <= self.end;
        }

        pub fn getRelation(self: Self, other: Self) RangeRelation {
            // equal sets
            if (self.start == other.start and self.end == other.end) {
                return .equal;
            }

            // other is superset of self
            if (other.start <= self.start and self.end <= other.end) {
                return .superset;
            }

            // other is subset of self
            if (self.start <= other.start and other.end <= self.end) {
                return .subset;
            }

            // one is continuation of the other one
            if (self.end + 1 == other.start or other.end + 1 == self.start) {
                return .adjacent;
            }

            // disjoined sets
            if (self.end < other.start or other.end < self.start) {
                return .disjoined;
            }

            // sets are intersected
            if ((other.start <= self.end and self.end <= other.end) or (self.start <= other.end and other.end <= self.end)) {
                return .intersected;
            }

            debug.panic("Unsupported range relation: Range({}, {}), Range({}, {})\n", .{ self.start, self.end, other.start, other.end });
        }

        pub fn containsRange(self: Self, range: Self) bool {
            return switch (self.getRelation(range)) {
                .equal, .subset => true,
                else => false,
            };
        }

        pub fn merge(self: Self, other: Self) error{DisjointRanges}!Self {
            const left: Self, const right: Self = if (self.start < other.start)
                .{ self, other }
            else
                .{ other, self };

            // disjoint - (    )  [    ]
            if (left.getRelation(right) == .disjoined) {
                return error.DisjointRanges;
            }

            return Self{
                .start = @min(left.start, right.start), // actually, this always will be `left.start`
                .end = @max(left.end, right.end),
            };
        }

        pub fn parse(text: String) Self {
            const idx = std.mem.indexOfScalar(u8, text, '-') orelse @panic("'text' does not have '-'");

            assert(idx > 0);
            assert(idx < text.len - 1);

            const start = std.fmt.parseInt(T, text[0..idx], 10) catch @panic("could not parse 'start'");
            const end = std.fmt.parseInt(T, text[idx + 1 ..], 10) catch @panic("could not parse 'end'");

            return create(start, end);
        }

        pub fn create(start: T, end: T) Self {
            assert(start <= end);

            return .{ .start = start, .end = end };
        }

        pub fn lessThan(context: void, lhs: Self, rhs: Self) bool {
            _ = context;
            return lhs.start < rhs.end;
        }
    };
}

fn solve(allocator: Allocator, rangesText: []const String) Int {
    var collection = RangeCollection(Int).create();
    defer collection.deinit(allocator);

    for (rangesText) |text| {
        collection.add(allocator, Range(Int).parse(text));
    }

    for (rangesText) |text| {
        if (!collection.contains(Range(Int).parse(text))) {
            debug.panic("this range is not included: Range({s})\n", .{text});
        }
        assert(collection.contains(Range(Int).parse(text)));
    }

    return collection.count();
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

test "rangeLength" {
    const range3_5 = Range(Int).parse("3-5");
    try std.testing.expectEqual(3, range3_5.length());

    const range10_14 = Range(Int).parse("10-14");
    try std.testing.expectEqual(5, range10_14.length());

    const range16_20 = Range(Int).parse("16-100");
    try std.testing.expectEqual(85, range16_20.length());

    const range1000_1000 = Range(Int).parse("1000-1000");
    try std.testing.expectEqual(1, range1000_1000.length());
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

    try std.testing.expectEqual(14, solve(allocator, &rangesText));
}

test RangeCollection {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var collection = RangeCollection(Int).create();
    var range: Range(Int) = undefined;

    try std.testing.expectEqual(0, collection.ranges.items.len);

    //   5 - 10
    range = Range(Int).parse("5-10");
    collection.add(allocator, range);
    try std.testing.expectEqual(1, collection.ranges.items.len);
    try std.testing.expectEqual(5, collection.ranges.items[0].start);
    try std.testing.expectEqual(10, collection.ranges.items[0].end);

    //    5 - 10
    //   12 - 15
    range = Range(Int).parse("12-15");
    collection.add(allocator, range);
    try std.testing.expectEqual(2, collection.ranges.items.len);
    try std.testing.expectEqual(5, collection.ranges.items[0].start);
    try std.testing.expectEqual(10, collection.ranges.items[0].end);
    try std.testing.expectEqual(12, collection.ranges.items[1].start);
    try std.testing.expectEqual(15, collection.ranges.items[1].end);

    //    5 - 10
    //   12 - 20
    range = Range(Int).parse("13-20");
    collection.add(allocator, range);
    try std.testing.expectEqual(2, collection.ranges.items.len);
    try std.testing.expectEqual(5, collection.ranges.items[0].start);
    try std.testing.expectEqual(10, collection.ranges.items[0].end);
    try std.testing.expectEqual(12, collection.ranges.items[1].start);
    try std.testing.expectEqual(20, collection.ranges.items[1].end);

    //   1 - 20
    range = Range(Int).parse("1-13");
    collection.add(allocator, range);
    try std.testing.expectEqual(1, collection.ranges.items.len);
    try std.testing.expectEqual(1, collection.ranges.items[0].start);
    try std.testing.expectEqual(20, collection.ranges.items[0].end);

    //   1 - 20
    range = Range(Int).parse("2-19");
    collection.add(allocator, range);
    try std.testing.expectEqual(1, collection.ranges.items.len);
    try std.testing.expectEqual(1, collection.ranges.items[0].start);
    try std.testing.expectEqual(20, collection.ranges.items[0].end);

    //   1 - 20
    //  30 - 40
    range = Range(Int).parse("30-40");
    collection.add(allocator, range);
    try std.testing.expectEqual(2, collection.ranges.items.len);
    try std.testing.expectEqual(1, collection.ranges.items[0].start);
    try std.testing.expectEqual(20, collection.ranges.items[0].end);
    try std.testing.expectEqual(30, collection.ranges.items[1].start);
    try std.testing.expectEqual(40, collection.ranges.items[1].end);

    //   1 - 20
    //  30 - 40
    //  50 - 60
    range = Range(Int).parse("50-60");
    collection.add(allocator, range);
    try std.testing.expectEqual(3, collection.ranges.items.len);
    try std.testing.expectEqual(1, collection.ranges.items[0].start);
    try std.testing.expectEqual(20, collection.ranges.items[0].end);
    try std.testing.expectEqual(30, collection.ranges.items[1].start);
    try std.testing.expectEqual(40, collection.ranges.items[1].end);
    try std.testing.expectEqual(50, collection.ranges.items[2].start);
    try std.testing.expectEqual(60, collection.ranges.items[2].end);

    //   1 - 20
    //  30 - 60
    range = Range(Int).parse("41-49");
    collection.add(allocator, range);
    try std.testing.expectEqual(2, collection.ranges.items.len);
    try std.testing.expectEqual(1, collection.ranges.items[0].start);
    try std.testing.expectEqual(20, collection.ranges.items[0].end);
    try std.testing.expectEqual(30, collection.ranges.items[1].start);
    try std.testing.expectEqual(60, collection.ranges.items[1].end);
}

test "123" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var collection = RangeCollection(Int).create();

    collection.add(allocator, Range(Int).parse("4-7"));
    collection.add(allocator, Range(Int).parse("11-19"));
    collection.add(allocator, Range(Int).parse("82-85"));
    collection.add(allocator, Range(Int).parse("85-88"));
    collection.add(allocator, Range(Int).parse("116-118"));
    collection.add(allocator, Range(Int).parse("161-162"));
    collection.add(allocator, Range(Int).parse("218-220"));
    collection.add(allocator, Range(Int).parse("408-410"));
    collection.add(allocator, Range(Int).parse("554-562"));

    try std.testing.expectEqual(8, collection.ranges.items.len);

    const range = Range(Int).parse("155-156");
    try std.testing.expect(!collection.contains(range));

    collection.add(allocator, range);
    try std.testing.expectEqual(9, collection.ranges.items.len);
}

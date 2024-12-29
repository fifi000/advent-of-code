const std = @import("std");
const AutoArrayHashMap = std.AutoArrayHashMap;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const Timer = std.time.Timer;

const print = std.debug.print;

const Point = struct {
    x: isize,
    y: isize,
};

fn Set(comptime T: type) type {
    return struct {
        const Self = @This();

        hashmap: AutoArrayHashMap(T, void),

        pub fn init(allocator: Allocator) Self {
            return .{
                .hashmap = AutoArrayHashMap(T, void).init(allocator),
            };
        }

        pub fn add(self: *Self, value: T) !void {
            try self.hashmap.put(value, {});
        }

        pub fn count(self: *Self) usize {
            return self.hashmap.count();
        }

        pub fn deinit(self: *Self) void {
            self.hashmap.deinit();
        }
    };
}

fn Combinations(comptime T: type) type {
    return struct {
        const Self = @This();

        allocator: Allocator,
        list: ArrayList([]const T),
        iterables: []const T,
        r: u8,

        pub fn items(self: Self) []const []const T {
            return self.list.items;
        }

        pub fn create(allocator: Allocator, iterables: []const T, comptime r: u8) !Self {
            var result = Self{
                .allocator = allocator,
                .list = ArrayList([]const T).init(allocator),
                .iterables = iterables,
                .r = r,
            };

            if (iterables.len >= r) {
                try result.generate_all();
            }

            return result;
        }

        pub fn destroy(self: *Self) void {
            for (self.list.items) |item| {
                self.allocator.free(item);
            }
            self.list.deinit();
        }

        fn generate_all(self: *Self) !void {
            var array = try self.allocator.alloc(u32, self.r);
            defer self.allocator.free(array);

            const n = self.iterables.len;
            var i: u8 = 0;

            // init first combination
            while (i < self.r) : (i += 1) {
                array[i] = i;
            }

            i = self.r - 1;

            while (array[0] < n - self.r + 1) {
                while (i > 0 and array[i] == n - self.r + i) {
                    i -= 1;
                }

                var temp = try self.allocator.alloc(T, array.len);
                for (0..array.len) |idx| {
                    temp[idx] = self.iterables[array[idx]];
                }
                try self.list.append(temp);

                array[i] += 1;

                while (i < self.r - 1) : (i += 1) {
                    array[i + 1] = array[i] + 1;
                }
            }
        }
    };
}

pub fn main() !void {
    var timer = try Timer.start();
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    // get input array
    const array = try getInputLines(arena.allocator());
    defer arena.allocator().free(array);

    var antennas = AutoArrayHashMap(u8, ArrayList(Point)).init(arena.allocator());
    defer antennas.deinit();

    // find all antennas
    for (array, 0..) |row, i| {
        for (row, 0..) |cell, j| {
            if (!isAntenna(cell)) {
                continue;
            }

            const entry = try antennas.getOrPutValue(cell, ArrayList(Point).init(arena.allocator()));
            try entry.value_ptr.append(.{
                .x = @as(isize, @intCast(i)),
                .y = @as(isize, @intCast(j)),
            });
        }
    }

    var antinodes = Set(Point).init(arena.allocator());
    defer antinodes.deinit();

    for (antennas.values()) |locations| {
        var combs = try Combinations(Point).create(arena.allocator(), locations.items, 2);
        defer combs.destroy();

        for (combs.items()) |item| {
            const points = calcAntinodes(item[0], item[1]);
            for (points) |point| {
                if (isValidLocation(array, point)) {
                    try antinodes.add(point);
                }
            }
        }
    }

    print("antinodes: {d}\n", .{antinodes.count()});

    print("Found in: {d:.6} s\n", .{@as(f64, @floatFromInt(timer.lap())) / std.time.ns_per_s});
}

fn isValidLocation(array: []const []const u8, point: Point) bool {
    if (point.x < 0 or array.len <= point.x) {
        return false;
    }

    if (point.y < 0 or array[@as(usize, @intCast(point.x))].len <= point.y) {
        return false;
    }

    return true;
}

fn isAntenna(letter: u8) bool {
    return std.ascii.isAlphanumeric(letter);
}

fn getLineEndpoint(start: Point, middle: Point) Point {
    return .{
        .x = 2 * middle.x - start.x,
        .y = 2 * middle.y - start.y,
    };
}

fn calcAntinodes(point1: Point, point2: Point) [2]Point {
    return .{
        getLineEndpoint(point1, point2),
        getLineEndpoint(point2, point1),
    };
}

fn getInputLines(allocator: Allocator) ![]const []const u8 {
    const file = try std.fs.cwd().openFile("2024/day8/input.txt", .{});
    defer file.close();

    const content = try file.readToEndAlloc(allocator, std.math.maxInt(usize));

    // split into lines
    var lines_iter = std.mem.tokenizeAny(u8, content, "\n\r");
    var lines = ArrayList([]const u8).init(allocator);

    while (lines_iter.next()) |line| {
        try lines.append(line);
    }

    return try lines.toOwnedSlice();
}

fn getArray() []const []const u8 {
    const string = [_][]const u8{
        "..........",
        "...#......",
        "..........",
        "....a.....",
        "..........",
        ".....a....",
        "..........",
        "......#...",
        "..........",
        "..........",
    };

    return string[0..];
}

test "file" {
    const lines = try getInputLines(std.testing.allocator);
    defer {
        for (lines.items) |line| {
            std.testing.allocator.free(line);
        }
        lines.deinit();
    }

    for (lines.items) |line| {
        print("{s}\n", .{line});
    }
}

test "combinations empty" {
    var combs = try Combinations(u8).create(std.testing.allocator, "012", 5);
    defer combs.destroy();

    try std.testing.expectEqual(0, combs.items().len);
}

test "combinations simple" {
    var combs = try Combinations(u8).create(std.testing.allocator, "012", 1);
    defer combs.destroy();

    const expected = [_][1]u8{
        [_]u8{'0'},
        [_]u8{'1'},
        [_]u8{'2'},
    };

    try std.testing.expectEqual(expected.len, combs.items().len);
    for (expected, combs.items()) |exp_row, val_row| {
        try std.testing.expectEqual(exp_row.len, val_row.len);
        for (exp_row, val_row) |exp_col, val_col| {
            try std.testing.expectEqual(exp_col, val_col);
        }
    }
}

test "combinations proper" {
    var combs = try Combinations(u8).create(std.testing.allocator, "012", 2);
    defer combs.destroy();

    const expected = [_][2]u8{
        [_]u8{ '0', '1' },
        [_]u8{ '0', '2' },
        [_]u8{ '1', '2' },
    };

    try std.testing.expectEqual(expected.len, combs.items().len);
    for (expected, combs.items()) |exp_row, val_row| {
        try std.testing.expectEqual(exp_row.len, val_row.len);
        for (exp_row, val_row) |exp_col, val_col| {
            try std.testing.expectEqual(exp_col, val_col);
        }
    }
}

test "123" {}

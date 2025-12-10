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
const Int = i64;
const Float = f64;

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

    const input = try getInput(allocator, "./2025/day9/input.txt");
    defer allocator.free(input);

    const lines = try getLines(allocator, input);
    defer allocator.free(lines);

    const result = solve(allocator, lines);

    print("result: '{any}'\n", .{result});
}

fn solve(allocator: Allocator, lines: []const String) Int {
    const points = createPoints(allocator, lines);
    defer allocator.free(points);

    var maxArea: Int = 0;

    for (points, 0..) |point1, idx| {
        for (points[idx + 1 ..]) |point2| {
            // print("({}, {}) * ({}, {}) = {}\n", .{ point1.x, point1.y, point2.x, point2.y, point1.area(point2) });
            maxArea = @max(maxArea, point1.area(point2));
        }
    }

    return maxArea;
}

fn createPoints(allocator: Allocator, lines: []const String) []const Point {
    var points = ArrayList(Point).initCapacity(allocator, lines.len) catch unreachable;
    defer points.deinit(allocator);

    for (lines) |line| {
        points.appendAssumeCapacity(Point.parse(line));
    }

    return points.toOwnedSlice(allocator) catch unreachable;
}

const Point = struct {
    x: Int,
    y: Int,

    const Self = @This();

    pub fn area(self: Self, other: Self) Int {
        const a = @abs(self.x - other.x) + 1;
        const b = @abs(self.y - other.y) + 1;

        return @intCast(a * b);
    }

    pub fn parse(text: String) Point {
        const idx = std.mem.indexOfScalar(u8, text, ',') orelse debug.panic("could not parse text: {s}\n", .{text});

        assert(idx != 0);
        assert(idx < text.len - 1);

        return .{
            .x = std.fmt.parseInt(Int, text[0..idx], 10) catch unreachable,
            .y = std.fmt.parseInt(Int, text[idx + 1 ..], 10) catch unreachable,
        };
    }
};

test solve {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    // const allocator = std.testing.allocator;

    const lines = [_]String{
        "7,1",
        "11,1",
        "11,7",
        "9,7",
        "9,5",
        "2,5",
        "2,3",
        "7,3",
    };

    try std.testing.expectEqual(50, solve(allocator, &lines));
}

test "speed" {
    var x: usize = 0;

    for (0..9617724875) |i| {
        x = i + 1;
    }
}

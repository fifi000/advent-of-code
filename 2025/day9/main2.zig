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
const Int = usize;
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

fn solve(allocator: Allocator, input: []const String) Int {
    const points = createPoints(allocator, input);
    defer allocator.free(points);

    var row_count: Int = 0;
    var column_count: Int = 0;
    for (points) |point| {
        row_count = @max(point.x + 1, row_count);
        column_count = @max(point.y + 1, column_count);
    }

    print("creating floor of size: {} x {}\n", .{ row_count, column_count });
    var floor = createFloor(allocator, row_count, column_count);
    defer allocator.free(floor);

    print("initial floor:\n", .{});

    print("marking rim\n", .{});
    markRim(&floor, points);

    print("calculating max area\n", .{});
    var max_area: Int = 0;

    var counter: Int = 0;
    for (points, 0..) |point1, idx| {
        print("processing point {}/{}:\r", .{ counter, points.len });
        counter += 1;
        for (points[idx + 1 ..]) |point2| {
            const rectangle = Rectangle.create(point1, point2);

            if (isInside(floor, rectangle.a) and
                isInside(floor, rectangle.b) and
                isInside(floor, rectangle.c) and
                isInside(floor, rectangle.d))
            {
                max_area = @max(max_area, rectangle.area());
            }
        }
    }

    return max_area;
}

// raycasting approach
// should check in all directions
fn isInside(array: []const []const u8, point: Point) bool {
    if (array[point.x][point.y] != '.') {
        return true;
    }

    // left
    {
        var wall_counter: Int = 0;
        var outside = true;

        var idx: Int = 0;
        while (idx < point.y) : (idx += 1) {
            if (outside and array[point.x][idx] != '.') {
                outside = false;
                wall_counter += 1;
            } else if (!outside and array[point.x][idx] == '.') {
                outside = true;
                wall_counter += 1;
            }
        }

        if (wall_counter == 0 or @mod(wall_counter, 2) == 1) {
            return false;
        }
    }

    // right
    {
        var wall_counter: Int = 0;
        var outside = true;

        var idx: Int = array[point.x].len - 1;
        while (idx > point.y) : (idx -= 1) {
            if (outside and array[point.x][idx] != '.') {
                outside = false;
                wall_counter += 1;
            } else if (!outside and array[point.x][idx] == '.') {
                outside = true;
                wall_counter += 1;
            }
        }

        if (wall_counter == 0 or @mod(wall_counter, 2) == 1) {
            return false;
        }
    }

    // top
    {
        var wall_counter: Int = 0;
        var outside = true;

        var idx: Int = 0;
        while (idx < point.x) : (idx += 1) {
            if (outside and array[idx][point.y] != '.') {
                outside = false;
                wall_counter += 1;
            } else if (!outside and array[idx][point.y] == '.') {
                outside = true;
                wall_counter += 1;
            }
        }

        if (wall_counter == 0 or @mod(wall_counter, 2) == 1) {
            return false;
        }
    }

    // bottom
    {
        var wall_counter: Int = 0;
        var outside = true;

        var idx: Int = array.len - 1;
        while (idx > point.x) : (idx -= 1) {
            if (outside and array[idx][point.y] != '.') {
                outside = false;
                wall_counter += 1;
            } else if (!outside and array[idx][point.y] == '.') {
                outside = true;
                wall_counter += 1;
            }
        }

        if (wall_counter == 0 or @mod(wall_counter, 2) == 1) {
            return false;
        }
    }

    return true;
}

fn createFloor(allocator: Allocator, row_count: usize, column_count: usize) [][]u8 {
    var rows = ArrayList([]u8).initCapacity(allocator, row_count) catch unreachable;
    defer rows.deinit(allocator);

    for (0..row_count) |_| {
        var row = allocator.alloc(u8, column_count) catch unreachable;

        for (0..row.len) |idx| {
            row[idx] = '.';
        }

        rows.appendAssumeCapacity(row);
    }

    return rows.toOwnedSlice(allocator) catch unreachable;
}

fn printArray(array: []const []const u8) void {
    for (array) |row| {
        print("{s}\n", .{row});
    }
}

fn markFloor(allocator: Allocator, array: *[][]u8) void {
    // find first point that is inside
    const first: Point = blk: for (array.*, 0..) |row, row_idx| {
        for (row[0 .. row.len - 1], 0..) |cell, column_idx| {
            if (cell == 'X' and row[column_idx + 1] == '.') {
                break :blk Point{ .x = row_idx, .y = column_idx + 1 };
            }
        }
    } else {
        debug.panic("could not find starting point for marking floor\n", .{});
    };

    print("found starting point for marking floor: ({}, {})\n", .{ first.x, first.y });

    // mark whole inner area
    var stack = ArrayList(Point).empty;
    stack.append(allocator, first) catch unreachable;

    while (stack.pop()) |point| {
        if (array.*[point.x][point.y] != '.') continue;
        array.*[point.x][point.y] = 'X';

        left: {
            if (point.y == 0) break :left;
            const left: Point = .{ .x = point.x, .y = point.y - 1 };
            if (array.*[left.x][left.y] != '.') break :left;

            stack.append(allocator, left) catch unreachable;
        }

        right: {
            if (point.y == array.*[point.x].len - 1) break :right;
            const right: Point = .{ .x = point.x, .y = point.y + 1 };
            if (array.*[right.x][right.y] != '.') break :right;

            stack.append(allocator, right) catch unreachable;
        }

        top: {
            if (point.x == 0) break :top;
            const top: Point = .{ .x = point.x - 1, .y = point.y };
            if (array.*[top.x][top.y] != '.') break :top;

            stack.append(allocator, top) catch unreachable;
        }

        bottom: {
            if (point.x == array.len - 1) break :bottom;
            const bottom: Point = .{ .x = point.x + 1, .y = point.y };
            if (array.*[bottom.x][bottom.y] != '.') break :bottom;

            stack.append(allocator, bottom) catch unreachable;
        }
    }
}

fn markRim(array: *[][]u8, points: []const Point) void {
    for (0..points.len) |idx| {
        markLine(array, points[idx], points[@mod(idx + 1, points.len)]);
    }
}

fn markLine(array: *[][]u8, p1: Point, p2: Point) void {
    array.*[p1.x][p1.y] = '#';
    array.*[p2.x][p2.y] = '#';

    if (p1.y == p2.y) {
        // vertical line
        const top, const bottom = if (p1.x < p2.x)
            .{ p1, p2 }
        else
            .{ p2, p1 };

        // print("marking vertical line: ({}, {}) to ({}, {})\n", .{ top.x, top.y, bottom.x, bottom.y });
        // print("from {} to {}\n", .{ top.x + 1, bottom.x });
        for (top.x + 1..bottom.x) |idx| {
            array.*[idx][bottom.y] = 'X';
        }
    } else if (p1.x == p2.x) {
        // horizontal line
        const left, const right = if (p1.y < p2.y)
            .{ p1, p2 }
        else
            .{ p2, p1 };

        // print("marking horizontal line: ({}, {}) to ({}, {})\n", .{ left.x, left.y, right.x, right.y });
        // print("from {} to {}\n", .{ left.y + 1, right.y });
        for (left.y + 1..right.y) |idx| {
            array.*[left.x][idx] = 'X';
        }
    } else {
        debug.panic("neither horizontal not vertical points: ({}), ({})\n", .{ p1, p2 });
    }
}

fn createLines(allocator: Allocator, points: []const Point) []const Line {
    var lines = ArrayList(Line).initCapacity(allocator, points.len) catch unreachable;
    defer lines.deinit(allocator);

    for (points, 0..) |_, idx| {
        lines.appendAssumeCapacity(Line.create(points[idx], points[@mod(idx + 1, points.len)]));
    }

    return lines.toOwnedSlice(allocator) catch unreachable;
}

fn createPoints(allocator: Allocator, lines: []const String) []const Point {
    var points = ArrayList(Point).initCapacity(allocator, lines.len) catch unreachable;
    defer points.deinit(allocator);

    for (lines) |line| {
        points.appendAssumeCapacity(Point.parse(line));
    }

    return points.toOwnedSlice(allocator) catch unreachable;
}

const Rectangle = struct {
    a: Point,
    b: Point,
    c: Point,
    d: Point,

    const Self = @This();

    pub fn create(a: Point, b: Point) Self {
        if (a.eql(b)) {
            debug.panic("cannot create rectangle with equal points\n", .{});
        }

        return .{
            .a = a,
            .b = Point{ .x = a.x, .y = b.y },
            .c = b,
            .d = Point{ .x = b.x, .y = a.y },
        };
    }

    pub fn area(self: Self) Int {
        return self.a.area(self.c);
    }
};

const Corner = enum { leftBottom, leftTop, rightTop, rightBottom };

const Alignment = enum { horizontal, vertical, diagonal };

const Line = struct {
    a: Point,
    b: Point,

    const Self = @This();

    pub fn create(a: Point, b: Point) Self {
        if (a.eql(b)) {
            debug.panic("cannot create line with equal points\n", .{});
        }

        switch (a.getAlignment(b)) {
            .horizontal => {
                const left, const right = if (a.y < b.y)
                    .{ a, b }
                else
                    .{ b, a };
                return .{ .a = left, .b = right };
            },
            .vertical => {
                const top, const bottom = if (a.x < b.x)
                    .{ a, b }
                else
                    .{ b, a };
                return .{ .a = top, .b = bottom };
            },
            .diagonal => {
                debug.print("cannot create diagonal line\n", .{});
            },
        }
    }

    pub fn isPerpendicularIntersected(self: Self, other: Self) bool {
        if (self.a.getAlignment(self.b) == other.a.getAlignment(other.b)) {
            return false;
        }

        const horizontal = if (self.a.getAlignment(self.b) == .horizontal) self else other;
        const vertical = if (self.a.getAlignment(self.b) == .vertical) self else other;

        return horizontal.a.x <= vertical.a.x and vertical.a.x <= horizontal.b.x and
            vertical.a.y <= horizontal.a.y and horizontal.a.y <= vertical.b.y;
    }

    pub fn contains(self: Self, needle: Point) bool {
        switch (self.a.getAlignment(self.b)) {
            .horizontal => {
                return self.a.y <= needle.y and needle.y <= self.b.y;
            },
            .vertical => {
                return self.a.x <= needle.x and needle.x <= self.b.x;
            },
            else => unreachable,
        }
    }
};

const Point = struct {
    x: Int,
    y: Int,

    const Self = @This();

    pub fn area(self: Self, other: Self) Int {
        const a = @abs(if (self.x > other.x) self.x - other.x else other.x - self.x) + 1;
        const b = @abs(if (self.y > other.y) self.y - other.y else other.y - self.y) + 1;

        return @intCast(a * b);
    }

    pub fn copy(self: Self) Self {
        return .{ .x = self.x, .y = self.y };
    }

    pub fn parse(text: String) Point {
        const idx = std.mem.indexOfScalar(u8, text, ',') orelse debug.panic("could not parse text: {s}\n", .{text});

        assert(idx != 0);
        assert(idx < text.len - 1);

        return .{
            .y = std.fmt.parseInt(Int, text[0..idx], 10) catch unreachable,
            .x = std.fmt.parseInt(Int, text[idx + 1 ..], 10) catch unreachable,
        };
    }

    pub fn eql(self: Self, other: Self) bool {
        return self.x == other.x and self.y == other.y;
    }

    pub fn getAlignment(self: Self, other: Self) Alignment {
        if (self.x == other.x) {
            return .horizontal;
        }
        if (self.y == other.y) {
            return .vertical;
        }

        unreachable;
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

    try std.testing.expectEqual(24, solve(allocator, &lines));
}

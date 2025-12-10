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

    const input = try getInput(allocator, "./2025/day8/input.txt");
    defer allocator.free(input);

    const lines = try getLines(allocator, input);
    defer allocator.free(lines);

    const result = solve(allocator, lines, 1000);

    print("result: '{any}'\n", .{result});
}

const Tuple = struct { p1: Point(Int), p2: Point(Int) };

fn solve(allocator: Allocator, lines: []const String, count: usize) usize {
    const points = parsePoints(Int, allocator, lines);
    defer allocator.free(points);

    var circuits = ArrayList(Circuit(Int)).initCapacity(allocator, points.len) catch unreachable;
    defer {
        for (circuits.items) |*circuit| {
            circuit.deinit(allocator);
        }
        circuits.deinit(allocator);
    }

    for (points) |*point| {
        circuits.appendAssumeCapacity(Circuit(Int).init(allocator, point));
    }

    //
    //
    //

    var stack = ArrayList(Tuple).empty;
    defer stack.deinit(allocator);

    for (points, 0..) |p1, i| {
        for (points[i + 1 ..]) |p2| {
            if (p1.eq(p2)) continue;

            stack.append(allocator, .{ .p1 = p1, .p2 = p2 }) catch unreachable;
        }
    }
    std.mem.sort(Tuple, stack.items, {}, struct {
        pub fn lessThan(_: @TypeOf({}), t1: Tuple, t2: Tuple) bool {
            return t1.p1.distance(Float, t1.p2) > t2.p1.distance(Float, t2.p2);
        }
    }.lessThan);

    var counter: usize = 0;
    while (counter < count) : (counter += 1) {
        const tuple = stack.pop() orelse unreachable;
        const circuit1_idx = findCircuit(Int, circuits.items, tuple.p1);
        const circuit2_idx = findCircuit(Int, circuits.items, tuple.p2);

        if (circuit1_idx != circuit2_idx) {
            for (circuits.items[circuit2_idx].points.items) |item| {
                circuits.items[circuit1_idx].add(allocator, item);
            }
            _ = circuits.orderedRemove(circuit2_idx);
        }
    }

    assert(circuits.items.len >= 3);

    std.mem.sort(Circuit(Int), circuits.items, {}, struct {
        pub fn lessThan(_: @TypeOf({}), lhs: Circuit(Int), rhs: Circuit(Int)) bool {
            return lhs.count() > rhs.count();
        }
    }.lessThan);

    return circuits.items[0].count() * circuits.items[1].count() * circuits.items[2].count();
}

fn findCircuit(comptime T: type, circuits: []Circuit(T), needle: Point(T)) usize {
    for (circuits, 0..) |item, idx| {
        for (item.points.items) |point| {
            if (needle.eq(point.*)) {
                return idx;
            }
        }
    }

    for (circuits) |circuit| {
        circuit.print();
    }

    debug.panic("could not find: {}\n", .{needle});
    unreachable;
}

fn parsePoints(comptime T: type, allocator: Allocator, lines: []const String) []const Point(T) {
    var points = ArrayList(Point(T)).initCapacity(allocator, lines.len) catch unreachable;
    defer points.deinit(allocator);

    for (lines) |line| {
        points.appendAssumeCapacity(Point(T).parse(line));
    }

    return points.toOwnedSlice(allocator) catch unreachable;
}

fn Circuit(comptime T: type) type {
    return struct {
        points: ArrayList(*const Point(T)),

        const Self = @This();

        pub fn init(allocator: Allocator, point: *const Point(T)) Self {
            var self = Self{ .points = ArrayList(*const Point(T)).empty };
            self.points.append(allocator, point) catch unreachable;
            return self;
        }

        pub fn deinit(self: *Self, allocator: Allocator) void {
            self.points.deinit(allocator);
        }

        pub fn count(self: Self) usize {
            return self.points.items.len;
        }

        pub fn contains(self: Self, needle: *const Point(T)) bool {
            for (self.points.items) |item| {
                if (item.eq(needle.*)) {
                    return true;
                }
            }

            return false;
        }

        pub fn add(self: *Self, allocator: Allocator, point: *const Point(T)) void {
            if (self.contains(point)) debug.panic("circuit already contains point {any}\n", .{point});

            self.points.append(allocator, point) catch unreachable;
        }

        pub fn distance(self: Self, comptime F: type, other: Self) F {
            var d: F = math.floatMax(F);

            for (self.points.items) |point1| {
                for (other.points.items) |point2| {
                    if (point1.distance(F, point2.*) < d) {
                        d = point1.distance(F, point2.*);
                    }
                }
            }

            assert(d != math.floatMax(F));
            return d;
        }

        pub fn print(self: Self) void {
            debug.print("[", .{});
            for (self.points.items) |point| {
                debug.print("({}, {}, {}), ", .{ point.x, point.y, point.z });
            }
            debug.print("]\n", .{});
        }
    };
}

fn Point(comptime T: type) type {
    return struct {
        x: T,
        y: T,
        z: T,

        const Self = @This();

        pub fn eq(self: Self, other: Self) bool {
            return self.x == other.x and self.y == other.y and self.z == other.z;
        }

        pub fn distance(self: Self, comptime F: type, other: Self) F {
            const sum = math.pow(T, (self.x - other.x), 2) + math.pow(T, (self.y - other.y), 2) + math.pow(T, (self.z - other.z), 2);
            const sumF: F = @floatFromInt(sum);
            return math.sqrt(sumF);
        }

        pub fn parse(text: String) Self {
            if (text.len == 0) debug.panic("cannot parse empty string\n", .{});
            if (std.mem.count(u8, text, ",") != 2) debug.panic("invalid point string '{s}'\n", .{text});

            var it = std.mem.tokenizeScalar(u8, text, ',');

            const x = std.fmt.parseInt(T, it.next().?, 10) catch unreachable;
            const y = std.fmt.parseInt(T, it.next().?, 10) catch unreachable;
            const z = std.fmt.parseInt(T, it.next().?, 10) catch unreachable;

            assert(it.next() == null);

            return .{ .x = x, .y = y, .z = z };
        }
    };
}

test solve {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    // const allocator = std.testing.allocator;

    const lines = [_]String{
        "162,817,812",
        "57,618,57",
        "906,360,560",
        "592,479,940",
        "352,342,300",
        "466,668,158",
        "542,29,236",
        "431,825,988",
        "739,650,466",
        "52,470,668",
        "216,146,977",
        "819,987,18",
        "117,168,530",
        "805,96,715",
        "346,949,466",
        "970,615,88",
        "941,993,340",
        "862,61,35",
        "984,92,344",
        "425,690,689",
    };

    try std.testing.expectEqual(40, solve(allocator, &lines, 10));
}

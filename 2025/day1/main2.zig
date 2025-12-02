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
const Int = i32;

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

    const input = try getInput("./2025/day1/input.txt");

    const list = try getLines(allocator, input);

    const result = try solveNaive(list.items, 50, 99);

    print("result: '{any}'\n", .{result});
}

const Direction = enum { left, right };

const Rotation = struct {
    direction: Direction,
    distance: Int,

    const Self = @This();

    pub fn parse(text: String) Self {
        assert(text.len >= 2);

        const direction = switch (text[0]) {
            'R' => Direction.right,
            'L' => Direction.left,
            else => {
                debug.panic("Invalid direction: {}\n", .{text[0]});
            },
        };

        const number = std.fmt.parseUnsigned(Int, text[1..], 10) catch {
            debug.panic("Invalid distance: {any}\n", .{text[1..]});
        };

        return .{ .direction = direction, .distance = number };
    }
};

fn solve(operations: []const String, current: Int, max: Int) !Int {
    var counter: Int = 0;
    var number = current;

    print("solve fn\n", .{});
    for (operations) |operation| {
        const rotation = Rotation.parse(operation);

        switch (rotation.direction) {
            .right => {
                counter += try math.divFloor(Int, number + rotation.distance, max + 1);
                number = try math.mod(Int, number + rotation.distance, max + 1);
            },
            .left => {
                counter += @intCast(@abs(try math.divFloor(Int, number - rotation.distance, max + 1)));
                number = try math.mod(Int, number - rotation.distance, max + 1);
            },
        }

        print("operation: {s}, counter: {}, number: {}\n", .{ operation, counter, number });
    }

    return counter;
}

fn solveNaive(operations: []const String, current: Int, max: Int) !Int {
    var counter: Int = 0;
    var number = current;

    print("solveNaive fn\n", .{});
    for (operations) |operation| {
        const rotation = Rotation.parse(operation);

        switch (rotation.direction) {
            .right => {
                for (0..@intCast(rotation.distance)) |_| {
                    number += 1;

                    if (number > max) number = 0;

                    if (number == 0) counter += 1;
                }
            },
            .left => {
                for (0..@intCast(rotation.distance)) |_| {
                    number -= 1;

                    if (number < 0) number = max;

                    if (number == 0) counter += 1;
                }
            },
        }

        print("operation: {s}, counter: {}, number: {}\n", .{ operation, counter, number });
    }

    return counter;
}

test "solveNaive1" {
    const operations = [_]String{
        "L40",
        "L72",
        "L4",
        "R54",
        "R94",
        "L8",
        "R94",
        "L6",
        "L62",
        "R64",
    };

    try std.testing.expectEqual(try solveNaive(&operations, 50, 99), try solve(&operations, 50, 99));
}

test "solve1" {
    const operations = [_]String{
        "L68",
        "L30",
        "R48",
        "L5",
        "R60",
        "L55",
        "L1",
        "L99",
        "R14",
        "L82",
    };

    try std.testing.expectEqual(6, try solve(&operations, 50, 99));
    try std.testing.expectEqual(6, try solveNaive(&operations, 50, 99));
}

test "solve2" {
    const operations = [_]String{"R1000"};

    try std.testing.expectEqual(10, try solve(&operations, 50, 99));
    try std.testing.expectEqual(10, try solveNaive(&operations, 50, 99));
}

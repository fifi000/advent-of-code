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

    const result = try solve(list.items, 50, 99);

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

    for (operations) |operation| {
        const rotation = Rotation.parse(operation);

        switch (rotation.direction) {
            .right => {
                number = try math.mod(Int, number + rotation.distance, max + 1);
            },
            .left => {
                number = try math.mod(Int, number - rotation.distance, max + 1);
            },
        }

        if (number == 0) counter += 1;
    }

    return counter;
}

test solve {
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

    try std.testing.expectEqual(3, try solve(&operations, 50, 99));
}

test "addition" {
    // const min = 0;
    const max: Int = 15;

    var current: Int = 14;

    for (0..20) |_| {
        current = try math.mod(Int, current + 1, max + 1);
    }

    assert(true);
}

test "subtraction" {
    // const min = 0;
    const max: Int = 15;

    var current: Int = 12;

    for (0..20) |_| {
        current = try math.mod(Int, current - 1, max + 1);
    }

    assert(true);
}

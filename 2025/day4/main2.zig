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
const Int = u32;

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

    const input = try getInput("./2025/day4/input.txt");

    const list = try getLines(allocator, input);

    const result = solve(list.items);

    print("result: '{any}'\n", .{result});
}

fn solve(diagram: []const String) Int {
    var counter: Int = 0;

    for (diagram, 0..) |row, i| {
        for (row, 0..) |cell, j| {
            if (!isPaperRoll(cell)) {
                continue;
            }

            const papers = countAdjacentPapers(diagram, i, j);
            if (papers < 4) {
                counter += 1;
                // print("Position({}, {})\n", .{ i, j });
            }
        }
    }

    return counter;
}

fn countAdjacentPapers(diagram: []const String, row_idx: usize, column_idx: usize) u8 {
    var counter: u8 = 0;

    left: {
        const left_idx = math.sub(usize, column_idx, 1) catch break :left;

        if (left_idx >= 0 and isPaperRoll(diagram[row_idx][left_idx])) {
            counter += 1;
        }
    }

    right: {
        const right_idx = math.add(usize, column_idx, 1) catch break :right;

        if (right_idx < diagram[row_idx].len and isPaperRoll(diagram[row_idx][right_idx])) {
            counter += 1;
        }
    }

    up: {
        if (row_idx == 0) {
            break :up;
        }

        const up_idx = row_idx - 1;

        // left up
        if (column_idx >= 1 and isPaperRoll(diagram[up_idx][column_idx - 1])) {
            counter += 1;
        }

        // center up
        if (isPaperRoll(diagram[up_idx][column_idx])) {
            counter += 1;
        }

        // right up
        if (column_idx + 1 < diagram[up_idx].len and isPaperRoll(diagram[up_idx][column_idx + 1])) {
            counter += 1;
        }
    }

    down: {
        if (row_idx == diagram.len - 1) {
            break :down;
        }

        const down_idx = row_idx + 1;

        // left down
        if (column_idx >= 1 and isPaperRoll(diagram[down_idx][column_idx - 1])) {
            counter += 1;
        }

        // center down
        if (isPaperRoll(diagram[down_idx][column_idx])) {
            counter += 1;
        }

        // right down
        if (column_idx + 1 < diagram[down_idx].len and isPaperRoll(diagram[down_idx][column_idx + 1])) {
            counter += 1;
        }
    }

    return counter;
}

fn isPaperRoll(c: u8) bool {
    return c == '@';
}

test countAdjacentPapers {
    const diagram = [_]String{
        "@.@",
        ".@@",
        "@.@",
    };

    // top
    try std.testing.expectEqual(1, countAdjacentPapers(&diagram, 0, 0));
    try std.testing.expectEqual(4, countAdjacentPapers(&diagram, 0, 1));
    try std.testing.expectEqual(2, countAdjacentPapers(&diagram, 0, 2));

    // center
    try std.testing.expectEqual(3, countAdjacentPapers(&diagram, 1, 0));
    try std.testing.expectEqual(5, countAdjacentPapers(&diagram, 1, 1));
    try std.testing.expectEqual(3, countAdjacentPapers(&diagram, 1, 2));

    // bottom
    try std.testing.expectEqual(1, countAdjacentPapers(&diagram, 2, 0));
    try std.testing.expectEqual(4, countAdjacentPapers(&diagram, 2, 1));
    try std.testing.expectEqual(2, countAdjacentPapers(&diagram, 2, 2));
}

test solve {
    const diagram = [_]String{
        "..@@.@@@@.",
        "@@@.@.@.@@",
        "@@@@@.@.@@",
        "@.@@@@..@.",
        "@@.@@@@.@@",
        ".@@@@@@@.@",
        ".@.@.@.@@@",
        "@.@@@.@@@@",
        ".@@@@@@@@.",
        "@.@.@@@.@.",
    };

    try std.testing.expectEqual(13, solve(&diagram));
}

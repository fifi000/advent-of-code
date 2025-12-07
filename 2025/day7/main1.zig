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

    const input = try getInput(allocator, "./2025/day7/input.txt");
    defer allocator.free(input);

    const lines = try getLines(allocator, input);
    defer allocator.free(lines);

    const result = solve(allocator, lines);

    print("result: '{any}'\n", .{result});
}

fn solve(allocator: Allocator, lines: []const String) Int {
    // assert lines are rectangle
    assert(lines.len > 0);
    for (lines, 0..) |line, idx| {
        if (line.len != lines[0].len) {
            debug.panic("different line length '{}'\n", .{idx});
        }
    }

    var result: Int = 0;

    // list of indexes
    var tachyonBeams = allocator.alloc(bool, lines[0].len) catch unreachable;
    defer allocator.free(tachyonBeams);

    for (tachyonBeams) |beam| assert(!beam);

    // find 'S' - start index
    const start_idx = std.mem.indexOfScalar(u8, lines[0], 'S') orelse debug.panic("could not find 'S' in first line\n", .{});
    tachyonBeams[start_idx] = true;

    for (lines[1..]) |line| {
        for (line, 0..) |cell, column_idx| {
            if (cell == '^' and tachyonBeams[column_idx]) {
                tachyonBeams[column_idx] = false;
                if (column_idx >= 1) {
                    tachyonBeams[column_idx - 1] = true;
                }
                if (column_idx < tachyonBeams.len - 1) {
                    tachyonBeams[column_idx + 1] = true;
                }
                result += 1;
            }
        }
    }

    return result;
}

test solve {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var lines = [_]String{
        ".......S.......",
        "...............",
        ".......^.......",
        "...............",
        "......^.^......",
        "...............",
        ".....^.^.^.....",
        "...............",
        "....^.^...^....",
        "...............",
        "...^.^...^.^...",
        "...............",
        "..^...^.....^..",
        "...............",
        ".^.^.^.^.^...^.",
        "...............",
    };

    try std.testing.expectEqual(21, solve(allocator, &lines));
}

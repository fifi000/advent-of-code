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

    const input = try getInput(allocator, "./2025/day6/input.txt");
    defer allocator.free(input);

    const lines = try getLines(allocator, input);
    defer allocator.free(lines);

    const result = solve(allocator, lines);

    print("result: '{any}'\n", .{result});
}

fn solve(allocator: Allocator, lines: []const String) Int {
    var result: Int = 0;
    const array = normalizeEquation(allocator, lines);
    defer allocator.free(array);

    for (array) |row| {
        const operation = blk: {
            const last = row[row.len - 1];
            if (last.len != 1) {
                debug.panic("Unexpected operation '{s}'\n", .{last});
            }
            break :blk last[0];
        };

        var inner_result = std.fmt.parseInt(Int, row[0], 10) catch {
            debug.panic("Could not parse number: '{s}'\n", .{row[0]});
        };

        for (row[1 .. row.len - 1]) |text| {
            const number = std.fmt.parseInt(Int, text, 10) catch {
                debug.panic("Could not parse number: '{s}'\n", .{text});
            };
            inner_result = execute(Int, inner_result, number, operation);
        }

        result += inner_result;
    }

    return result;
}

fn normalizeEquation(allocator: Allocator, lines: []const String) []const []const String {
    // assert is rectangle
    for (lines, 0..) |line, idx| {
        if (line.len != lines[0].len) {
            debug.panic("is not rectangle - idx = {}\n", .{idx});
        }
    }

    var equations = ArrayList([]const String).empty;
    defer equations.deinit(allocator);

    var column_idx = lines[0].len - 1;
    while (column_idx >= 0) {
        var currentEquation = ArrayList(String).empty;
        defer currentEquation.deinit(allocator);

        while (column_idx >= 0) {
            var currentNumber = ArrayList(u8).empty;
            defer currentNumber.deinit(allocator);

            // find first non empty char
            var row_idx: usize = 0;
            while (row_idx < lines.len and lines[row_idx][column_idx] == ' ') {
                row_idx += 1;
            }
            // did not find any digit --> empty column
            if (row_idx >= lines.len - 1) {
                break;
            }

            // create a number
            while (isDigit(lines[row_idx][column_idx])) : (row_idx += 1) {
                currentNumber.append(allocator, lines[row_idx][column_idx]) catch unreachable;
            }

            const slice = currentNumber.toOwnedSlice(allocator) catch unreachable;
            currentEquation.append(allocator, slice) catch unreachable;

            if (column_idx == 0) {
                break;
            } else {
                column_idx -= 1;
            }
        }

        // add operation symbol
        const operatorText = allocator.alloc(u8, 1) catch unreachable;
        operatorText[0] = lines[lines.len - 1][if (column_idx == 0) 0 else column_idx + 1];

        currentEquation.append(allocator, operatorText) catch unreachable;

        const slice = currentEquation.toOwnedSlice(allocator) catch unreachable;
        equations.append(allocator, slice) catch unreachable;

        if (column_idx == 0) {
            break;
        } else {
            column_idx -= 1;
        }
    }

    const array = allocator.alloc([]const String, equations.items.len) catch unreachable;
    for (equations.items, 0..) |item, idx| {
        array[idx] = item;
    }
    return array;
}

fn isDigit(c: u8) bool {
    return switch (c) {
        '0'...'9' => true,
        else => false,
    };
}

fn execute(comptime T: type, a: T, b: T, operation: u8) T {
    return switch (operation) {
        '+' => a + b,
        '*' => a * b,
        else => debug.panic("Unexpected operation: '{}'\n", .{operation}),
    };
}

fn printArray(array: []const []const String) void {
    for (array) |row| {
        for (row) |el| {
            print("{s:5}", .{el});
        }
        print("\n", .{});
    }
}

test normalizeEquation {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const allocator = arena.allocator();
    var lines = [_]String{
        "123 328  51 64 ",
        " 45 64  387 23 ",
        "  6 98  215 314",
        "*   +   *   +  ",
    };

    const array = normalizeEquation(allocator, &lines);
    _ = array;
}

test solve {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var lines = [_]String{
        "123 328  51 64 ",
        " 45 64  387 23 ",
        "  6 98  215 314",
        "*   +   *   +  ",
    };

    try std.testing.expectEqual(3263827, solve(allocator, &lines));
}

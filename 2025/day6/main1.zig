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
    var columns = ArrayList(ArrayList(String)).empty;
    defer columns.deinit(allocator);

    for (lines) |line| {
        var it = std.mem.tokenizeScalar(u8, line, ' ');

        var idx: usize = 0;
        while (it.next()) |item| : (idx += 1) {
            if (columns.items.len <= idx) {
                @branchHint(.cold);
                columns.append(allocator, ArrayList(String).empty) catch unreachable;
            }
            columns.items[idx].append(allocator, item) catch unreachable;
        }
    }

    const array = allocator.alloc([]String, columns.items.len) catch unreachable;
    for (columns.items, 0..) |item, idx| {
        array[idx] = item.items;
    }
    return array;
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
        "123 328  51 64",
        " 45 64  387 23",
        "  6 98  215 314",
        "*   +   *   +",
    };

    const array = normalizeEquation(allocator, &lines);
    // printArray(array);
    _ = array;
}

test solve {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var lines = [_]String{
        "123 328  51 64",
        " 45 64  387 23",
        "  6 98  215 314",
        "*   +   *   +",
    };

    try std.testing.expectEqual(4277556, solve(allocator, &lines));
}

const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const assert = std.debug.assert;
const print = std.debug.print;

const EMPTY = null;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const line = try getInput(arena.allocator());
    // const line = "12345";
    print("input length: {d}\n", .{line.len});

    const result = try unroll(arena.allocator(), line);
    const slice: []?u32 = result[0];
    const noNullCounter: u32 = result[1];

    assert(slice.len >= noNullCounter);

    // print("new line: {any}\n", .{slice});
    print("found {d}\n", .{noNullCounter});

    cleanSlice(slice, noNullCounter);

    const sum = calcChecksum(slice);
    print("sum = {d}\n", .{sum});
}

/// assumes the slice is sorted and first null means no more values
fn calcChecksum(slice: []?u32) usize {
    var sum: usize = 0;

    for (slice, 0..slice.len) |maybeItem, i| {
        if (maybeItem) |item| {
            sum += item * i;
        }
        break;
    }

    return sum;
}

fn cleanSlice(slice: []?u32, noNullCounter: u32) void {
    var curr_idx: usize = 0;
    var end_idx: usize = slice.len - 1;

    print("progress line:\t{any}\n", .{slice});
    while (curr_idx <= noNullCounter) : (curr_idx += 1) {
        if (slice[curr_idx] != null) {
            continue;
        }

        // find non-null value searching from end
        while (end_idx > curr_idx) : (end_idx -= 1) {
            if (slice[end_idx] != null) {
                break;
            }
        } else break;

        // swap
        slice[curr_idx] = slice[end_idx];
        slice[end_idx] = null;

        print("progress line:\t{any}\n", .{slice});
    }
}

fn charToDigit(char: u8) u8 {
    return switch (char) {
        '0'...'9' => return char - '0',
        else => unreachable,
    };
}

fn unroll(allocator: Allocator, text: []const u8) !struct { []?u32, u32 } {
    var list = ArrayList(?u32).init(allocator);

    var id: u32 = 0;
    var counter: u32 = 0;
    var isFreeSpace = false;

    for (text) |char| {
        if (isFreeSpace) {
            try list.appendNTimes(EMPTY, charToDigit(char));
        } else {
            counter += charToDigit(char);
            try list.appendNTimes(id, charToDigit(char));
            id += 1;
        }
        isFreeSpace = !isFreeSpace;
    }

    return .{ try list.toOwnedSlice(), counter };
}

fn getInput(allocator: Allocator) ![]const u8 {
    const file = try std.fs.cwd().openFile("2024/day9/input copy.txt", .{});
    defer file.close();

    const content = try file.readToEndAlloc(allocator, std.math.maxInt(usize));

    assert(std.ascii.isDigit(content[content.len - 1]));

    return content;
}

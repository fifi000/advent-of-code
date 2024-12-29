const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Timer = std.time.Timer;

const assert = std.debug.assert;
const print = std.debug.print;

const EMPTY = null;

const Block = struct {
    value: u32,
    start_idx: usize,
    end_idx: usize,

    pub fn count(self: Block) usize {
        return self.end_idx - self.start_idx + 1;
    }
};

const FreeBlock = struct {
    start_idx: usize,
    end_idx: usize,

    pub fn count(self: FreeBlock) usize {
        return self.end_idx - self.start_idx + 1;
    }
};

pub fn main() !void {
    var timer = try Timer.start();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    var allocator = arena.allocator();
    defer arena.deinit();

    const line = try getInput(allocator);
    defer allocator.free(line);

    const slice = try unroll(allocator, line);
    defer allocator.free(slice);

    try cleanSlice(arena.allocator(), slice);

    const sum = calcChecksum(slice);
    print("sum = {d}\n", .{sum}); // 6321896265143

    print("main done in: {d:.6} s\n", .{@as(f64, @floatFromInt(timer.lap())) / std.time.ns_per_s});
}

/// assumes the slice is sorted and first null means no more values
fn calcChecksum(slice: []?u32) usize {
    var sum: usize = 0;

    for (slice, 0..slice.len) |maybeItem, i| {
        if (maybeItem) |item| {
            sum += item * i;
        }
    }

    return sum;
}

fn getBlocks(allocator: Allocator, slice: []?u32) !ArrayList(Block) {
    var blocks = ArrayList(Block).init(allocator);

    var curr_block: ?Block = null;

    for (slice, 0..) |maybe_item, i| {
        if (maybe_item == null) {
            continue;
        }

        if (curr_block == null or curr_block.?.value != maybe_item.?) {
            if (curr_block != null) {
                try blocks.append(curr_block.?);
            }

            curr_block = Block{
                .value = maybe_item.?,
                .start_idx = i,
                .end_idx = i,
            };
            continue;
        }

        curr_block.?.end_idx = i;
    }

    if (curr_block) |block| {
        try blocks.append(block);
    }

    return blocks;
}

fn getFreeBlocks(allocator: Allocator, slice: []?u32, blocks: ArrayList(Block)) !ArrayList(FreeBlock) {
    var free_blocks = ArrayList(FreeBlock).init(allocator);

    if (slice[0] == EMPTY) {
        try free_blocks.append(.{ .start_idx = 0, .end_idx = blocks.items[0].start_idx - 1 });
    }

    var i: usize = 0;
    while (i < blocks.items.len - 1) : (i += 1) {
        const block1 = blocks.items[i];
        const block2 = blocks.items[i + 1];

        const start_idx = block1.end_idx + 1;
        const end_idx = block2.start_idx - 1;

        if (end_idx + 1 <= start_idx) {
            continue;
        }

        try free_blocks.append(.{ .start_idx = start_idx, .end_idx = end_idx });
    }

    if (slice[slice.len - 1] == EMPTY) {
        try free_blocks.append(.{ .start_idx = blocks.getLast().end_idx + 1, .end_idx = slice.len - 1 });
    }

    return free_blocks;
}

fn getFreeSpace(free_blocks: *ArrayList(FreeBlock), size: usize, max_idx: usize) ?usize {
    for (free_blocks.items, 0..) |block, i| {
        if (block.end_idx > max_idx) {
            break;
        }
        if (block.count() >= size) {
            return i;
        }
    }
    return null;
}

fn insertFreeSpace(free_blocks: *ArrayList(FreeBlock), new_block: FreeBlock) !void {
    const idx: usize = for (free_blocks.items, 0..) |block, i| {
        if (new_block.end_idx < block.start_idx) {
            break i;
        }
    } else undefined;

    if (idx == undefined) {
        // insert at the end
        var block_to_add = new_block;
        if (free_blocks.getLast().end_idx + 1 == new_block.start_idx) {
            block_to_add = free_blocks.pop();
            block_to_add.end_idx = new_block.end_idx;
        }
        try free_blocks.append(block_to_add);
        return;
    }

    // can join one before and one after
    if (free_blocks.items[idx - 1].end_idx + 1 == new_block.start_idx and new_block.end_idx + 1 == free_blocks.items[idx + 1].start_idx) {
        // remove one after
        const after = free_blocks.orderedRemove(idx);

        // update the one before
        var before = free_blocks.items[idx - 1];
        before.end_idx = after.end_idx;
        return;
    }

    // can join one before
    if (free_blocks.items[idx - 1].end_idx + 1 == new_block.start_idx) {
        var before = free_blocks.items[idx - 1];
        before.end_idx = new_block.end_idx;
        return;
    }

    // can join one after
    if (new_block.end_idx + 1 == free_blocks.items[idx + 1].start_idx) {
        var after = free_blocks.items[idx + 1];
        after.start_idx = new_block.start_idx;
        return;
    }
}

fn pprint(slice: []?u32) void {
    for (slice) |item| {
        if (item == null) {
            print(".", .{});
        } else {
            print("{any}", .{item});
        }
    }
    print("\n", .{});
}

fn cleanSlice(allocator: Allocator, slice: []?u32) !void {
    var blocks = try getBlocks(allocator, slice);
    defer blocks.deinit();

    var free_blocks = try getFreeBlocks(allocator, slice, blocks);
    defer free_blocks.deinit();

    while (blocks.popOrNull()) |block| {
        const space_idx = getFreeSpace(&free_blocks, block.count(), block.start_idx) orelse continue;
        var free_block = free_blocks.items[space_idx];

        assert(free_block.start_idx <= block.start_idx);

        // move block to free memory
        for (0..block.count()) |i| {
            slice[free_block.start_idx + i] = slice[block.start_idx + i];
            slice[block.start_idx + i] = null;
        }
        free_block.start_idx += block.count();

        // remove free block
        if (free_block.start_idx > free_block.end_idx) {
            _ = free_blocks.orderedRemove(space_idx);
        } else {
            try free_blocks.append(free_block);
            _ = free_blocks.swapRemove(space_idx);
        }

        try insertFreeSpace(&free_blocks, .{ .start_idx = block.start_idx, .end_idx = block.end_idx });
    }
}

fn charToDigit(char: u8) u8 {
    return switch (char) {
        '0'...'9' => return char - '0',
        else => unreachable,
    };
}

fn unroll(allocator: Allocator, text: []const u8) ![]?u32 {
    var list = ArrayList(?u32).init(allocator);

    var id: u32 = 0;
    var isFreeSpace = false;

    for (text) |char| {
        if (isFreeSpace) {
            try list.appendNTimes(EMPTY, charToDigit(char));
        } else {
            try list.appendNTimes(id, charToDigit(char));
            id += 1;
        }
        isFreeSpace = !isFreeSpace;
    }

    return try list.toOwnedSlice();
}

fn getInput(allocator: Allocator) ![]const u8 {
    const file = try std.fs.cwd().openFile("2024/day9/input.txt", .{});
    defer file.close();

    const content = try file.readToEndAlloc(allocator, std.math.maxInt(usize));

    assert(std.ascii.isDigit(content[content.len - 1]));

    return content;
}

test calcChecksum {
    const test_slice = "00992111777.44.333....5555.6666.....8888..";

    var slice: [test_slice.len]?u32 = undefined;

    for (test_slice, 0..) |val, i| {
        if (val == '.') {
            slice[i] = null;
        } else {
            slice[i] = charToDigit(val);
        }
    }

    // print("type:\t{any}\n", .{@TypeOf(slice)});
    // print("test line:\t{any}\n", .{slice});

    const result = calcChecksum(slice[0..]);

    try std.testing.expectEqual(2858, result);
}

test cleanSlice {
    // const test_slice = "00992111777.44.333....5555.6666.....8888..";
    const test_slice = "00...111...2...333.44.5555.6666.777.888899";

    var slice: [test_slice.len]?u32 = undefined;
    for (test_slice, 0..) |val, i| {
        if (val == '.') {
            slice[i] = null;
        } else {
            slice[i] = charToDigit(val);
        }
    }

    try cleanSlice(std.testing.allocator, slice[0..]);

    const exp_slice = "00992111777.44.333....5555.6666.....8888..";

    for (exp_slice, slice[0..]) |exp, act| {
        if (exp == '.') {
            try std.testing.expectEqual(EMPTY, act);
        } else {
            try std.testing.expectEqual(charToDigit(exp), act);
        }
    }
}

test ArrayList {
    var list = ArrayList(FreeBlock).init(std.testing.allocator);
    defer list.deinit();

    try list.append(.{ .start_idx = 0, .end_idx = 0 });
    try list.append(.{ .start_idx = 1, .end_idx = 1 });
    try list.append(.{ .start_idx = 2, .end_idx = 2 });
    try list.append(.{ .start_idx = 3, .end_idx = 3 });
    try list.append(.{ .start_idx = 4, .end_idx = 4 });
    try list.append(.{ .start_idx = 5, .end_idx = 5 });
    try list.append(.{ .start_idx = 6, .end_idx = 6 });

    print("before:\t", .{});
    for (list.items) |item| print("[{d}...{d}], ", .{ item.start_idx, item.end_idx });
    print("\n", .{});
    list.items[0].start_idx = 10;
    print("after:\t", .{});
    for (list.items) |item| print("[{d}...{d}], ", .{ item.start_idx, item.end_idx });
    print("\n", .{});
}

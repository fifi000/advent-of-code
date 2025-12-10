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

    print("creating tree...\n", .{});
    var node = createTree(allocator, lines);
    defer node.deinit(allocator);
    print("tree created\n", .{});

    print("counting...\n", .{});
    return node.count();
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

    try std.testing.expectEqual(40, solve(allocator, &lines));
}

test "solve2" {
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
    };

    try std.testing.expectEqual(40, solve(allocator, &lines));
}

test createTree {
    const allocator = std.testing.allocator;
    // var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    // defer arena.deinit();
    // const allocator = arena.allocator();

    var lines: [8]String = undefined;
    var node: Node = undefined;

    lines = [_]String{
        ".......S.......",
        "...............",
        ".......^.......",
        "...............",
        "......^........",
        "...............",
        ".....^.........",
        "...............",
    };
    node = createTree(allocator, &lines);
    try std.testing.expectEqual(4, node.count());

    lines = [_]String{
        "...............",
        "...............",
        ".......5.......",
        "...............",
        "......3.2......",
        "...............",
        ".....2.........",
        "...............",
    };
    node = createTree(allocator, &lines);
    try std.testing.expectEqual(5, node.count());
}

fn isSplit(c: u8) bool {
    return switch (c) {
        '0'...'9' => true,
        '^' => true,
        else => false,
    };
}

fn createTree(allocator: Allocator, lines: []const String) Node {
    const start_row_idx, const start_column_idx = blk: {
        for (lines, 0..) |line, row_idx| {
            for (line, 0..) |cell, column_idx| {
                if (isSplit(cell)) {
                    break :blk .{ row_idx, column_idx };
                }
            }
        }

        unreachable;
    };

    var root = Node.create(start_row_idx, start_column_idx);
    var nodesToCheck = ArrayList(*Node).empty;
    defer nodesToCheck.deinit(allocator);

    nodesToCheck.append(allocator, &root) catch unreachable;

    var seen = AutoArrayHashMap(Position, *Node).init(allocator);
    defer seen.deinit();

    var counter: usize = 0;
    while (nodesToCheck.pop()) |node| {
        if (seen.get(node.position)) |seen_node| {
            node.left = seen_node.left;
            node.right = seen_node.right;
            continue;
        }
        seen.put(node.position, node) catch unreachable;
        print("#{} to check: {}\n", .{ counter, nodesToCheck.items.len });
        counter += 1;

        // left
        if (node.position.column > 0 and node.position.row < lines.len - 1) {
            var idx: usize = node.position.row;
            while (idx < lines.len) : (idx += 1) {
                if (isSplit(lines[idx][node.position.column - 1])) {
                    const tempNode = allocator.create(Node) catch unreachable;
                    tempNode.* = Node.create(idx, node.position.column - 1);
                    node.left = tempNode;
                    nodesToCheck.append(allocator, node.left.?) catch unreachable;
                    break;
                }
            }
        }

        // right
        if (node.position.column < lines[node.position.row].len - 1 and node.position.row < lines.len - 1) {
            var idx: usize = node.position.row;
            while (idx < lines.len) : (idx += 1) {
                if (isSplit(lines[idx][node.position.column + 1])) {
                    const tempNode = allocator.create(Node) catch unreachable;
                    tempNode.* = Node.create(idx, node.position.column + 1);
                    node.right = tempNode;
                    nodesToCheck.append(allocator, node.right.?) catch unreachable;
                    break;
                }
            }
        }
    }

    return root;
}

const Position = struct {
    row: usize,
    column: usize,
};

const Node = struct {
    left: ?*Self = null,
    right: ?*Self = null,

    position: Position,
    cached_counter: ?Int = null,

    const Self = @This();

    pub fn count(self: *Self) Int {
        if (self.cached_counter != null) {
            return self.cached_counter.?;
        }
        var counter: Int = 0;

        counter += if (self.left != null) self.left.?.count() else 1;
        counter += if (self.right != null) self.right.?.count() else 1;

        self.cached_counter = counter;
        return counter;
    }

    pub fn create(row_idx: usize, column_idx: usize) Self {
        return Self{ .position = .{ .row = row_idx, .column = column_idx } };
    }

    pub fn deinit(self: *Self, allocator: Allocator) void {
        if (self.left != null) self.left.?.deinit(allocator);
        if (self.right != null) self.right.?.deinit(allocator);

        allocator.free(self);
    }
};

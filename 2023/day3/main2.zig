const std = @import("std");
const math = std.math;

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

const Position = struct {
    row_idx: usize,
    column_idx: usize,
};

fn NumberWithPostion(comptime T: type) type {
    return struct {
        position: Position,
        number: T,
    };
}

fn Number(comptime T: type) type {
    const ti = @typeInfo(T);
    if (ti != .int or ti.int.signedness != .unsigned) {
        @compileError("T must be an unsigned int.");
    }

    return struct {
        value: T,

        const Self = @This();

        pub fn reset(self: *Self) void {
            self.value = null;
        }

        pub fn addDigit(self: *Self, char: u8) void {
            assert(std.ascii.isDigit(char));

            self.value = concat(self.value, char - '0');
        }

        fn concat(left: T, right: T) T {
            const right_len = if (right == 0) 1 else std.math.log10_int(right) + 1;

            return left * std.math.pow(T, 10, right_len) + right;
        }
    };
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    // var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    const allocator = arena.allocator();

    const input = try getInput("./2023/day3/input.txt");

    const list = try getLines(allocator, input);
    defer list.deinit(allocator);

    const array = list.items;

    var hashMap = AutoArrayHashMap(Position, ArrayList(NumberWithPostion(usize))).init(allocator);
    defer hashMap.deinit();

    for (array, 0..) |row, row_idx| {
        var number: ?Number(Int) = null;
        var start_idx: usize = 0;

        for (row, 0..) |char, column_idx| {
            if (std.ascii.isDigit(char)) {
                if (number == null) {
                    start_idx = column_idx;
                    number = .{ .value = char - '0' };
                } else {
                    number.?.addDigit(char);
                }
            } else if (number != null) {
                const gears = try getAdjecentGears(usize, allocator, array, row_idx, start_idx, column_idx - 1);
                for (gears) |gear| {
                    var result = try hashMap.getOrPutValue(gear, ArrayList(NumberWithPostion(usize)).empty);
                    try result.value_ptr.append(allocator, .{ .number = number.?.value, .position = .{ .row_idx = row_idx, .column_idx = column_idx - 1 } });
                }

                number = null;
            }
        }

        // we have reached the end of a line
        if (number != null) {
            const gears = try getAdjecentGears(usize, allocator, array, row_idx, start_idx, row.len - 1);
            for (gears) |gear| {
                var result = try hashMap.getOrPutValue(gear, ArrayList(NumberWithPostion(usize)).empty);
                try result.value_ptr.append(allocator, .{ .number = number.?.value, .position = .{ .row_idx = row_idx, .column_idx = row.len - 1 } });
            }

            number = null;
        }
    }

    var sum: usize = 0;
    var it = hashMap.iterator();

    while (it.next()) |pair| {
        if (pair.value_ptr.items.len == 2) {
            // print("summing: '{any}'\n", .{pair.key_ptr});
            sum += pair.value_ptr.items[0].number * pair.value_ptr.items[1].number;
        } else {
            // print("skipping: '{any}'\n", .{pair.key_ptr});
        }
    }

    print("the sum is: '{0}'\n", .{sum});
}

fn getAdjecentGears(comptime T: type, gpa: Allocator, array: []String, row_idx: T, start_idx: T, end_idx: T) ![]Position {
    var gearList = ArrayList(Position).empty;

    // left
    left: {
        const left_idx = math.sub(T, start_idx, 1) catch break :left;

        if (left_idx >= 0 and isGear(array[row_idx][left_idx])) {
            try gearList.append(gpa, .{ .row_idx = row_idx, .column_idx = left_idx });
        }
    }

    // right
    right: {
        const right_idx = math.add(T, end_idx, 1) catch break :right;
        if (right_idx < array[row_idx].len and isGear(array[row_idx][right_idx])) {
            try gearList.append(gpa, .{ .row_idx = row_idx, .column_idx = right_idx });
        }
    }

    // up
    up: {
        const up_idx = math.sub(T, row_idx, 1) catch break :up;
        if (up_idx >= 0) {
            const left_idx = if (start_idx == 0) 0 else start_idx - 1;
            const right_idx = @min(end_idx + 2, array[up_idx].len);

            for (array[up_idx][left_idx..right_idx], left_idx..) |c, idx| {
                if (isGear(c)) {
                    try gearList.append(gpa, .{ .row_idx = up_idx, .column_idx = idx });
                }
            }
        }
    }

    // down
    down: {
        const down_idx = math.add(T, row_idx, 1) catch break :down;
        if (down_idx < array.len) {
            const left_idx = if (start_idx == 0) 0 else start_idx - 1;
            const right_idx = @min(end_idx + 2, array[down_idx].len);

            for (array[down_idx][left_idx..right_idx], left_idx..) |c, idx| {
                if (isGear(c)) {
                    try gearList.append(gpa, .{ .row_idx = down_idx, .column_idx = idx });
                }
            }
        }
    }

    return gearList.toOwnedSlice(gpa);
}

fn isGear(c: u8) bool {
    return c == '*';
}

test "split" {
    const ss = "aaa\r\nbbb\r\nccc\r\n";

    var it = std.mem.tokenizeAny(u8, ss, "\r\n");

    try std.testing.expectEqualStrings("aaa", it.next().?);
    try std.testing.expectEqualStrings("bbb", it.next().?);
    try std.testing.expectEqualStrings("ccc", it.next().?);
    try std.testing.expect(it.next() == null);
}

test "split2" {
    const ss = "aaa\n\rbbb\nccc\r\n";

    var it = std.mem.tokenizeAny(u8, ss, "\r\n");

    try std.testing.expectEqualStrings("aaa", it.next().?);
    try std.testing.expectEqualStrings("bbb", it.next().?);
    try std.testing.expectEqualStrings("ccc", it.next().?);
    try std.testing.expect(it.next() == null);
}

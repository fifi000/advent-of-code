// --- Day 7: Bridge Repair ---
// The Historians take you to a familiar rope bridge over a river in the middle of a jungle. The Chief isn't on this side of the bridge, though; maybe he's on the other side?

// When you go to cross the bridge, you notice a group of engineers trying to repair it. (Apparently, it breaks pretty frequently.) You won't be able to cross until it's fixed.

// You ask how long it'll take; the engineers tell you that it only needs final calibrations, but some young elephants were playing nearby and stole all the operators from their calibration equations! They could finish the calibrations if only someone could determine which test values could possibly be produced by placing any combination of operators into their calibration equations (your puzzle input).

// For example:

// 190: 10 19
// 3267: 81 40 27
// 83: 17 5
// 156: 15 6
// 7290: 6 8 6 15
// 161011: 16 10 13
// 192: 17 8 14
// 21037: 9 7 18 13
// 292: 11 6 16 20
// Each line represents a single equation. The test value appears before the colon on each line; it is your job to determine whether the remaining numbers can be combined with operators to produce the test value.

// Operators are always evaluated left-to-right, not according to precedence rules. Furthermore, numbers in the equations cannot be rearranged. Glancing into the jungle, you can see elephants holding two different types of operators: add (+) and multiply (*).

// Only three of the above equations can be made true by inserting operators:

// 190: 10 19 has only one position that accepts an operator: between 10 and 19. Choosing + would give 29, but choosing * would give the test value (10 * 19 = 190).
// 3267: 81 40 27 has two positions for operators. Of the four possible configurations of the operators, two cause the right side to match the test value: 81 + 40 * 27 and 81 * 40 + 27 both equal 3267 (when evaluated left-to-right)!
// 292: 11 6 16 20 can be solved in exactly one way: 11 + 6 * 16 + 20.
// The engineers just need the total calibration result, which is the sum of the test values from just the equations that could possibly be true. In the above example, the sum of the test values for the three equations listed above is 3749.

// Determine which equa=tions could possibly be true. What is their total calibration result?
const std = @import("std");
const print = std.debug.print;

const Product = struct {
    a: u8,
    b: u8,
    len: u32,
    flags: u32 = 0,
    overflow: u1 = 0,

    fn create(a: u8, b: u8, len: u32) Product {
        return .{
            .a = a,
            .b = b,
            .len = len,
            .flags = (std.math.pow(u32, 2, len) - 1),
        };
    }

    fn next(self: *Product, buffer: *[]u8) !void {
        std.debug.assert(self.len <= @typeInfo(@TypeOf(self.flags)).Int.bits);

        if (self.overflow == 1) return error.IteratorExhausted;

        var i: u5 = 0;
        while (i < self.len) : (i += 1) {
            if ((self.flags & (@as(u32, 1) << i)) != 0) {
                buffer.*[i] = self.a;
            } else {
                buffer.*[i] = self.b;
            }
        }

        const result = @subWithOverflow(self.flags, 1);
        self.flags = result[0];
        self.overflow = result[1];
    }
};

pub fn main() !void {
    var timer = try std.time.Timer.start();

    // input file
    const input_file = try getInputFile("2024", "day7", "input.txt");
    defer input_file.close();

    // get filtered lines
    var buf_reader = std.io.bufferedReader(input_file.reader());
    var in_stream = buf_reader.reader();
    var buffer: [1024]u8 = undefined;

    var sum: u64 = 0;

    while (try in_stream.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        const result = try isLineValid(line);
        if (result == null) {
            continue;
        }
        sum += result.?;
        print("line: {s}\n", .{line});
    }

    print("\nresult: {d}\n", .{sum});

    print("\nDone in: {d:.6} s\n", .{@as(f64, @floatFromInt(timer.lap())) / std.time.ns_per_s});
}

fn getInputFile(year: []const u8, day: []const u8, file_name: []const u8) !std.fs.File {
    const cwd = std.fs.cwd();

    var year_dir = try cwd.openDir(year, .{});
    defer year_dir.close();

    var day_dir = try year_dir.openDir(day, .{});
    defer day_dir.close();

    const file = try day_dir.openFile(file_name, .{});

    return file;
}

fn isLineValid(line: []const u8) !?u64 {
    var it = std.mem.tokenize(u8, line, ": \n\r");
    var sum: ?u64 = null;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var nums = std.ArrayList(u64).init(arena.allocator());
    defer nums.deinit();

    while (it.next()) |word| {
        const num = std.fmt.parseInt(u64, word, 10) catch |err| {
            print("Problematic line: {s}\n", .{line});
            return err;
        };
        if (sum == null) {
            sum = num;
            continue;
        }
        try nums.append(num);
    }

    const len: u32 = @intCast(nums.items.len - 1);
    var op_it = Product.create('*', '+', len);
    var allocator = arena.allocator();
    var buffer = try allocator.alloc(u8, len);
    defer allocator.free(buffer);

    while (true) {
        op_it.next(&buffer) catch |err| {
            if (err == error.IteratorExhausted) break;
            return err;
        };
        const testSum = try calcEquation(nums.items, buffer);
        if (testSum == sum) return sum.?;
    }

    return null;
}

fn calcEquation(nums: []u64, operations: []u8) !u64 {
    if (nums.len - 1 != operations.len) return error.WrongLenghts;

    var sum: u64 = nums[0];

    for (0..operations.len) |i| {
        sum = try calc(sum, nums[i + 1], operations[i]);
    }

    return sum;
}

fn calc(a: u64, b: u64, operation: u8) !u64 {
    return switch (operation) {
        '+' => a + b,
        '*' => a * b,
        else => error.InvalidOperation,
    };
}

// ========================================================================================
// tests

test "aaa" {
    var i: u32 = 0;
    i -%= 1;
    print("{d}\n", .{i});
    print("{d}\n", .{590877201219});
}

test "test calc" {
    try std.testing.expectEqual(10, try calc(10, 1, '*'));
    try std.testing.expectEqual(0, try calc(0, 1111, '*'));
    try std.testing.expectEqual(10, try calc(5, 5, '+'));
    try std.testing.expectEqual(88, try calc(11, 8, '*'));
}

test "test calculations" {
    var nums = [_]u64{ 1, 2, 3, 4 };
    var operations = [_]u8{ '+', '+', '+' };
    try std.testing.expectEqual(10, calcEquation(nums[0..], operations[0..]));
    // try std.testing.expectEqual(190, calcNums(([_]u32{ 10, 19 })[0..], ([_]u8{'*'})[0..]));
}

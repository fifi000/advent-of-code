const std = @import("std");
const File = std.fs.File;
const Reader = std.io.Reader;
const print = std.debug.print;
const assert = std.debug.assert;
const String = []const u8;

fn getLineIterator(filename: String) !std.mem.SplitIterator(u8, .sequence) {
    const file = try std.fs.cwd().openFile(filename, .{ .mode = .read_only });
    defer file.close();

    var buffer: [2 << 16]u8 = undefined;
    const bytes_read = try file.read(&buffer);

    assert(bytes_read < buffer.len);

    return std.mem.splitSequence(u8, buffer[0..bytes_read], "\n");
}

fn CubeSet(comptime T: type) type {
    const ti = @typeInfo(T);
    if (ti != .int or ti.int.signedness != .unsigned) {
        @compileError("T must be an unsigned int.");
    }

    return struct {
        blue: T = 0,
        red: T = 0,
        green: T = 0,

        const Self = @This();

        pub fn canFit(self: *Self, other: *Self) bool {
            return other.blue <= self.blue and other.red <= self.red and other.green <= self.green;
        }
    };
}

const Int = u32;

var maxSet = CubeSet(Int){
    .blue = 14,
    .red = 12,
    .green = 13,
};

const Color = enum { blue, red, green };

pub fn main() !void {
    var line_it = try getLineIterator("./2023/day2/input.txt");

    var sum: Int = 0;

    while (line_it.next()) |line| {
        const game_idx = std.mem.indexOf(u8, line, ":") orelse @panic("Could not find ':' inside a line.");

        const gameMinCubeSet = getGameMinCubeSet(line[game_idx + 2 ..]);

        sum += gameMinCubeSet.blue * gameMinCubeSet.red * gameMinCubeSet.green;
    }

    print("the sum is: '{0}'\n", .{sum});
}

fn getGameMinCubeSet(game: String) CubeSet(Int) {
    var set_it = std.mem.splitSequence(u8, game, "; ");

    var minSet = CubeSet(Int){};

    while (set_it.next()) |set| {
        var color_it = std.mem.splitSequence(u8, set, ", ");
        while (color_it.next()) |color| {
            const tuple = getColorTuple(color);

            switch (tuple.color) {
                .blue => minSet.blue = @max(minSet.blue, tuple.count),
                .red => minSet.red = @max(minSet.red, tuple.count),
                .green => minSet.green = @max(minSet.green, tuple.count),
            }
        }
    }

    return minSet;
}

fn getColorTuple(text: String) struct { count: Int, color: Color } {
    var it = std.mem.splitSequence(u8, text, " ");

    // count
    const count_string = it.next() orelse @panic("Color tuple iterator is empty.");
    const count = std.fmt.parseInt(Int, count_string, 10) catch @panic("Could not parse value to int.");

    // color
    var color_string = it.next() orelse @panic("Color tuple iterator does not have second element.");
    color_string = std.mem.trimEnd(u8, color_string, "\n\r ");
    var color: Color = undefined;

    if (std.mem.eql(u8, color_string, "blue")) {
        color = .blue;
    } else if (std.mem.eql(u8, color_string, "red")) {
        color = .red;
    } else if (std.mem.eql(u8, color_string, "green")) {
        color = .green;
    } else {
        @panic("Unsupported color type.");
    }

    return .{ .count = count, .color = color };
}

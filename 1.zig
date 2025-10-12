const std = @import("std");
const input = @import("input.zig");
const timed = @import("timed.zig");

fn part1(allocator: std.mem.Allocator) !void {
    var cols = try input.readTwoColumnsAlloc(allocator, "1.txt", u32);
    defer {
        allocator.free(cols.left);
        allocator.free(cols.right);
    }

    std.sort.block(u32, cols.left, {}, comptime std.sort.asc(u32));
    std.sort.block(u32, cols.right, {}, comptime std.sort.asc(u32));

    var result: u64 = 0;

    for (cols.left, 0..) |_, i| {
        const a = cols.left[i];
        const b = cols.right[i];
        result += if (a > b) a - b else b - a;
    }

    std.debug.print("{}\n", .{result});
}

pub fn solveDay1part1(allocator: std.mem.Allocator) !void {
    try timed.timed("day1/part1", part1, allocator);
}

fn part2(allocator: std.mem.Allocator) !void {
    var cols = try input.readTwoColumnsAlloc(allocator, "1.txt", u32);
    const left = cols.left;
    const right = cols.right;
    defer {
        allocator.free(cols.left);
        allocator.free(cols.right);
    }

    std.sort.block(u32, cols.left, {}, comptime std.sort.asc(u32));
    std.sort.block(u32, cols.right, {}, comptime std.sort.asc(u32));

    var result: u64 = 0;

    var i: usize = 0;
    var j: usize = 0;

    while (i < left.len) {
        var countL: usize = 1;
        var countR: usize = 0;
        while (i < left.len - 1 and left[i] == left[i + 1]) {
            countL += 1;
            i += 1;
        }

        while (j < right.len - 1 and right[j] <= left[i]) {
            if (right[j] == left[i]) countR += 1;
            j += 1;
        }

        result += countL * left[i] * countR;

        i += 1;
        std.debug.print("{}\n", .{result});
    }

    std.debug.print("{}\n", .{result});
}

pub fn solveDay1part2(allocator: std.mem.Allocator) !void {
    try timed.timed("day1/part2", part2, allocator);
}

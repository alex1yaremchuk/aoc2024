const std = @import("std");
const timed = @import("timed.zig");
const print = std.debug.print;
const inp = @import("input/index.zig");

fn part1(_: std.mem.Allocator) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const alloc = arena.allocator();

    const input = try inp.readFile(&arena, "25.txt");

    var keys: std.ArrayList([5]u8) = .empty;
    var locks: std.ArrayList([5]u8) = .empty;

    var it_group = input.groups();

    var counter: [5]u8 = .{ 0, 0, 0, 0, 0 };
    var isKey: ?bool = null;

    while (it_group.next()) |group| {
        var it_lines = inp.groupLines(group);
        while (it_lines.next()) |line| {
            if (isKey == null) isKey = !std.mem.eql(u8, line, "#####");

            for (line, 0..) |ch, ind| {
                if (ch == '#') counter[ind] += 1;
            }
        }
        if (isKey == true) try keys.append(alloc, counter) else try locks.append(alloc, counter);
        // print("{any}\n", .{counter});
        counter = .{ 0, 0, 0, 0, 0 };
        isKey = null;
    }

    var fitCount: usize = 0;

    for (locks.items) |lock| {
        keys: for (keys.items) |key| {
            for (0..5) |ind| {
                if (key[ind] + lock[ind] > 7) continue :keys;
            }
            fitCount += 1;
        }
    }
    // print("locks len {d} keys len {d}", .{ locks.items.len, keys.items.len });

    print("final answer of 2024 is: {d}", .{fitCount});
}

pub fn solvepart1(allocator: std.mem.Allocator) !void {
    try timed.timed("part1", part1, allocator);
}

pub fn solvepart2(allocator: std.mem.Allocator) !void {
    try timed.timed("part2", part2, allocator);
}

fn part2(_: std.mem.Allocator) !void {}

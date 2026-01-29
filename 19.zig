const std = @import("std");
const timed = @import("timed.zig");
const print = std.debug.print;
const inp = @import("input/index.zig");
const maxInt = std.math.maxInt;

fn part1(_: std.mem.Allocator) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    // const alloc = arena.alloc();

    const input = try inp.readFile(&arena, "19.txt");

    var gr_it = input.groups();

    const patterns_buffer = gr_it.next() orelse unreachable;

    const towels_buffer = gr_it.next() orelse unreachable;

    const patterns = try inp.stringsAnyTrim(&arena, patterns_buffer, ",", " \n\r");

    const towels = try inp.stringsAnyTrim(&arena, towels_buffer, "\n", " \r");

    var count: usize = 0;

    for (towels) |towel| {
        if (match(patterns, towel, 0)) count += 1;
    }

    print("there are {d} correct towels", .{count});
}

fn match(patterns: [][]const u8, towel: []const u8, towel_ind: usize) bool {
    if (towel.len == towel_ind) return true;

    for (patterns) |pattern| {
        if (pattern_ok(pattern, towel[towel_ind..])) {
            if (match(patterns, towel, towel_ind + pattern.len)) return true else continue;
        }
    }
    return false;
}

fn pattern_ok(pattern: []const u8, towel: []const u8) bool {
    if (pattern.len > towel.len) return false;
    return std.mem.eql(u8, pattern, towel[0..pattern.len]);
}

fn part2(_: std.mem.Allocator) !void {}

pub fn solvepart1(allocator: std.mem.Allocator) !void {
    try timed.timed("part1", part1, allocator);
}

pub fn solvepart2(allocator: std.mem.Allocator) !void {
    try timed.timed("part2", part2, allocator);
}

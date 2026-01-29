const std = @import("std");
const timed = @import("timed.zig");
const print = std.debug.print;
const inp = @import("input/index.zig");
const maxInt = std.math.maxInt;

fn part1(_: std.mem.Allocator) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const alloc = arena.allocator();

    const input = try inp.readFile(&arena, "19.txt");

    var gr_it = input.groups();

    const patterns_buffer = gr_it.next() orelse unreachable;

    const towels_buffer = gr_it.next() orelse unreachable;

    const patterns = try inp.stringsAnyTrim(&arena, patterns_buffer, ",", " \n\r");

    const towels = try inp.stringsAnyTrim(&arena, towels_buffer, "\n", " \r");

    var count: usize = 0;

    for (towels) |towel| {
        const memo = try alloc.alloc(?usize, towel.len + 1);
        std.mem.set(?usize, memo, null);
        if (count_ways(patterns, towel, 0, memo) > 0) count += 1;
    }

    print("there are {d} correct towels", .{count});
}

fn count_ways(patterns: [][]const u8, towel: []const u8, towel_ind: usize, memo: []?usize) usize {
    if (memo[towel_ind]) |cached| return cached;
    if (towel.len == towel_ind) {
        memo[towel_ind] = 1;
        return 1;
    }

    var total: usize = 0;
    for (patterns) |pattern| {
        if (pattern_ok(pattern, towel[towel_ind..])) {
            total += count_ways(patterns, towel, towel_ind + pattern.len, memo);
        }
    }
    memo[towel_ind] = total;
    return total;
}

fn pattern_ok(pattern: []const u8, towel: []const u8) bool {
    if (pattern.len > towel.len) return false;
    return std.mem.eql(u8, pattern, towel[0..pattern.len]);
}

fn part2(_: std.mem.Allocator) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const alloc = arena.allocator();

    const input = try inp.readFile(&arena, "19.txt");

    var gr_it = input.groups();

    const patterns_buffer = gr_it.next() orelse unreachable;

    const towels_buffer = gr_it.next() orelse unreachable;

    const patterns = try inp.stringsAnyTrim(&arena, patterns_buffer, ",", " \n\r");

    const towels = try inp.stringsAnyTrim(&arena, towels_buffer, "\n", " \r");

    var count: usize = 0;

    for (towels) |towel| {
        const memo = try alloc.alloc(?usize, towel.len + 1);
        @memset(memo, null);
        count += count_ways(patterns, towel, 0, memo);
    }

    print("there are {d} correct towels", .{count});
}

pub fn solvepart1(allocator: std.mem.Allocator) !void {
    try timed.timed("part1", part1, allocator);
}

pub fn solvepart2(allocator: std.mem.Allocator) !void {
    try timed.timed("part2", part2, allocator);
}

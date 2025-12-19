const std = @import("std");
const timed = @import("timed.zig");
const input = @import("input.zig");
const Grid = input.Grid;
const Dirs = input.Dirs;
const print = std.debug.print;

const Key = struct { stone: u64, depth: usize };

const DEPTH = 75;

fn part1(alloc: std.mem.Allocator) !void {
    var arena_state = std.heap.ArenaAllocator.init(alloc);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const nums = try input.readNumbers(arena, "11.txt", u64);

    var cache = std.AutoHashMap(Key, u64).init(arena);
    defer cache.deinit();

    var result: u64 = 0;

    result = 0;

    // _ = nums;

    // print("{any} \n", .{splitDivisor(21212231)});

    for (nums) |num| {
        result += try count(&cache, arena, num, DEPTH);
    }

    std.debug.print("result: {}\n", .{result});
}

fn count(
    cache: *std.AutoHashMap(Key, u64),
    alloc: std.mem.Allocator,
    stone: u64,
    depth: usize,
) !u64 {
    if (depth == 0) return 1;

    const key = Key{ .stone = stone, .depth = depth };
    const cached = cache.get(key);
    if (cached != null) return cached.?;

    const result: u64 = rules: {
        // rule 1
        if (stone == 0) break :rules try count(cache, alloc, 1, depth - 1);

        // rule 2 - even digits
        const divisor = splitDivisor(stone);
        if (divisor > 0) {
            const arr: [2]u64 = splitDigits(stone, divisor);
            break :rules try count(cache, alloc, arr[0], depth - 1) +
                try count(cache, alloc, arr[1], depth - 1);
        }

        break :rules try count(cache, alloc, stone * 2024, depth - 1);
    };

    try cache.put(key, result);

    return result;
}

fn splitDivisor(s: u64) u64 {
    var n: u64 = s;

    var digits: u8 = 0;

    while (n > 0) : (n /= 10) digits += 1;

    // print("{any} \n", .{digits});

    if (digits % 2 != 0) return 0;

    const half = digits / 2;
    var div: u64 = 1;
    var i: u8 = 0;
    while (i < half) : (i += 1) div *= 10;
    return div;
}

fn splitDigits(s: u64, divisor: u64) [2]u64 {
    return [2]u64{ s / divisor, s % divisor };
}

pub fn solvepart1(allocator: std.mem.Allocator) !void {
    try timed.timed("part1", part1, allocator);
}

fn part2(alloc: std.mem.Allocator) !void {
    var arena_state = std.heap.ArenaAllocator.init(alloc);
    defer arena_state.deinit();
    // const arena = arena_state.allocator();

    // std.debug.print("result: {}\n", .{11});
}

pub fn solvepart2(allocator: std.mem.Allocator) !void {
    try timed.timed("part2", part2, allocator);
}

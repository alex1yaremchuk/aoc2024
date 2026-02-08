const std = @import("std");
const timed = @import("timed.zig");
const print = std.debug.print;
const inp = @import("input/index.zig");

const iterations: usize = 2000;
const UNK: usize = std.math.maxInt(usize);

fn part1(_: std.mem.Allocator) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const input = try inp.readFile(&arena, "22.txt");

    var lines_it = input.lines();

    var result: usize = 0;

    while (lines_it.next()) |line| {
        const secret: usize = try std.fmt.parseInt(usize, line, 10);
        result += next(iterations, secret);
    }

    print("result is: {d}", .{result});
}

const MASK24: usize = (1 << 24) - 1;
inline fn prune(s: usize) usize {
    return s & MASK24;
}

inline fn mix(x: usize, s: usize) usize {
    return s ^ x;
}

fn next(iterations_count: usize, secret_in: usize) usize {
    if (iterations_count == 0) return secret_in;
    return next(iterations_count - 1, nextSecret(secret_in));
}

inline fn nextSecret(secret_in: usize) usize {
    var s = prune(secret_in);
    s = prune(mix(s << 6, s));

    s = prune(mix(s >> 5, s));

    s = prune(mix(s << 11, s));

    return s;
}

fn part2(_: std.mem.Allocator) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const input = try inp.readFile(&arena, "22.txt");

    var lines_it = input.lines();

    var totals: [PATTERN_COUNT]u32 = [_]u32{0} ** PATTERN_COUNT;
    var seen_stamp: [PATTERN_COUNT]u32 = [_]u32{0} ** PATTERN_COUNT;
    var epoch: u32 = 1;

    while (lines_it.next()) |line| : (epoch += 1) {
        var s: usize = try std.fmt.parseInt(usize, line, 10);

        var prev_price: i32 = @intCast(s % 10);
        var d0: i32 = 0;
        var d1: i32 = 0;
        var d2: i32 = 0;
        var d3: i32 = 0;
        var have: u32 = 0;

        var step: u32 = 0;
        while (step < 2000) : (step += 1) {
            s = nextSecret(s);
            const price: i32 = @intCast(s % 10);
            const d: i32 = price - prev_price;
            prev_price = price;

            d0 = d1;
            d1 = d2;
            d2 = d3;
            d3 = d;
            if (have < 4) {
                have += 1;
                continue;
            }

            const idx = patternIndex(d0, d1, d2, d3);

            if (seen_stamp[idx] != epoch) {
                seen_stamp[idx] = epoch;
                totals[idx] += @as(u32, @intCast(price));
            }
        }
    }

    var best: u32 = 0;
    for (totals) |v| {
        if (v > best) best = v;
    }

    print("result is: {d}", .{best});
}

pub fn solvepart1(allocator: std.mem.Allocator) !void {
    try timed.timed("part1", part1, allocator);
}

pub fn solvepart2(allocator: std.mem.Allocator) !void {
    try timed.timed("part2", part2, allocator);
}

const BASE: u32 = 19;

const PATTERN_COUNT: usize = 19 * 19 * 19 * 19;

inline fn deltaKey(d: i32) u32 {
    return @as(u32, @intCast(d + 9));
}

inline fn patternIndex(d0: i32, d1: i32, d2: i32, d3: i32) usize {
    const k0 = deltaKey(d0);
    const k1 = deltaKey(d1);
    const k2 = deltaKey(d2);
    const k3 = deltaKey(d3);

    return @as(usize, (((k0 * BASE + k1) * BASE + k2) * BASE + k3));
}

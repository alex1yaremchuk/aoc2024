const std = @import("std");
const input = @import("input.zig");
const timed = @import("timed.zig");
const app_io = @import("app_io.zig");

fn part1(alloc: std.mem.Allocator) !void {
    var arena_state = std.heap.ArenaAllocator.init(alloc);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const parsed = try readInts("07.txt", arena);

    var result: u128 = 0;

    const Shift = std.math.Log2Int(usize);

    for (parsed) |line| {
        const n_ops: usize = line.len - 2;
        const max: usize = @as(usize, 1) << @as(Shift, @intCast(n_ops));
        var mask: usize = 0;
        var res: u128 = undefined;

        std.debug.print("line {any} \n", .{line});

        while (mask < max) : (mask += 1) {
            res = line[1];
            // std.debug.print("mask {b} \n", .{mask});
            for (0..n_ops) |i| {
                if ((mask >> @as(Shift, @intCast(i))) & 1 == 0) {
                    // +
                    res += line[i + 2];
                } else {
                    // *
                    res *= line[i + 2];
                }
                if (res > line[0]) break;
                // std.debug.print("{} -> ", .{res});
            }
            // std.debug.print("\n", .{});
            if (res == line[0]) break;
        }
        result += if (res == line[0]) res else 0;
        // std.debug.print("\ntemp: {}\n", .{if (res == line[0]) res else 0});
    }

    std.debug.print("result: {}\n", .{result});
}

pub fn solvepart1(allocator: std.mem.Allocator) !void {
    try timed.timed("part1", part1, allocator);
}

fn part2(alloc: std.mem.Allocator) !void {
    var arena_state = std.heap.ArenaAllocator.init(alloc);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const parsed = try readInts("07.txt", arena);

    var result: u128 = 0;

    // const Shift = std.math.Log2Int(usize);

    const OpCount: usize = 3;

    var ops: [20]u8 = [_]u8{0} ** 20;

    for (parsed) |line| {
        const n_ops: usize = line.len - 2;
        const max: usize = std.math.pow(usize, OpCount, n_ops);
        var mask: usize = 0;
        var res: u128 = undefined;

        var pow_b = try arena.alloc(u128, n_ops);

        for (0..n_ops) |i| {
            const b = line[i + 2];
            pow_b[i] = pow10[digits_u128(b)];
        }

        // std.debug.print("line {any} \n", .{line});

        while (mask < max) : (mask += 1) {
            var tmp = mask;

            for (0..n_ops) |i| {
                ops[i] = @as(u8, @intCast(tmp % OpCount));
                tmp /= OpCount;
            }

            res = line[1];
            for (0..n_ops) |i| {
                switch (ops[i]) {
                    0 => res += line[i + 2],
                    1 => res *= line[i + 2],
                    2 => res = concat_fast(res, line[i + 2], pow_b[i]),
                    else => unreachable,
                }

                if (res > line[0]) break;
                // std.debug.print("{} -> ", .{res});
            }
            // std.debug.print("\n", .{});
            if (res == line[0]) break;
        }
        result += if (res == line[0]) res else 0;
        // std.debug.print("\ntemp: {}\n", .{if (res == line[0]) res else 0});
    }

    std.debug.print("result: {}\n", .{result});
}

pub fn solvepart2(allocator: std.mem.Allocator) !void {
    try timed.timed("part2", part2, allocator);
}

fn readInts(path: []const u8, allocator: std.mem.Allocator) ![][]u128 {
    var data = try std.Io.Dir.cwd().readFileAlloc(app_io.io, path, allocator, .unlimited);

    data = input.stripCR(data);

    var numbers = try allocator.alloc(u128, data.len / 2);

    var ind: usize = 0;
    var start_ind: usize = 0;

    var rows = std.ArrayList([]u128){};
    defer rows.deinit(allocator);

    var it = std.mem.splitAny(u8, data, "\n");
    while (it.next()) |line| {
        if (line.len == 0) continue;
        var it2 = std.mem.splitAny(u8, line, " \t");

        start_ind = ind;
        while (it2.next()) |num_raw| {
            if (num_raw.len == 0) continue;
            const num_raw2 = std.mem.trimEnd(u8, num_raw, ":");
            if (num_raw2.len == 0) continue;

            numbers[ind] = try input.parseInt(num_raw2, u128);
            ind += 1;
        }
        if (ind > start_ind) {
            try rows.append(allocator, numbers[start_ind..ind]);
        }
    }
    return rows.toOwnedSlice(allocator);
}

fn concat(a: u128, b: u128) !u128 {
    var pow: u128 = 1;
    var tmp = b;

    while (tmp >= 10) : (tmp /= 10) {
        pow *= 10;
    }
    pow *= 10;

    return a * pow + b;
}

fn pow10_table() [10]u128 {
    var t: [10]u128 = undefined;
    t[0] = 1;

    var i: usize = 1;
    while (i < t.len) : (i += 1) {
        t[i] = t[i - 1] * 10;
    }
    return t;
}
const pow10 = pow10_table();

inline fn concat_fast(a: u128, b: u128, pow10_b: u128) u128 {
    return a * pow10_b + b;
}

fn digits_u128(x: u128) u8 {
    var t = x;
    var n: u8 = 1;
    while (t >= 10) : (t /= 10) {
        n += 1;
    }
    return n;
}

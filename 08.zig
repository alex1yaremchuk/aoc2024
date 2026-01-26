const std = @import("std");
const input = @import("input.zig");
const timed = @import("timed.zig");
const app_io = @import("app_io.zig");

fn part1(alloc: std.mem.Allocator) !void {
    var arena_state = std.heap.ArenaAllocator.init(alloc);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const parsed = try readCharLines(arena, "08.txt");

    const lines = parsed.lines;
    const groups = parsed.groups;

    var antinodes = try std.bit_set.DynamicBitSetUnmanaged.initEmpty(arena, lines.len * (lines[0].len));

    for (groups) |group| {
        for (group, 0..) |p, i| {
            for (group, 0..) |q, j| {
                if (i <= j) continue;
                addAntinodes(&antinodes, p, q, lines.len, lines[0].len);
            }
        }
    }

    std.debug.print("result: {}\n", .{antinodes.count()});
}

pub fn solvepart1(allocator: std.mem.Allocator) !void {
    try timed.timed("part1", part1, allocator);
}

fn part2(alloc: std.mem.Allocator) !void {
    var arena_state = std.heap.ArenaAllocator.init(alloc);
    defer arena_state.deinit();
    // const arena = arena_state.allocator();

    // const parsed = try readInts("07.txt", arena);

    std.debug.print("result: {}\n", .{1});
}

pub fn solvepart2(allocator: std.mem.Allocator) !void {
    try timed.timed("part2", part2, allocator);
}

const Point = struct {
    i: usize,
    j: usize,
};

fn addAntinodes(nodes: *std.bit_set.DynamicBitSetUnmanaged, p: Point, q: Point, h: usize, w: usize) void {
    const pi = @as(isize, @intCast(p.i));
    const pj = @as(isize, @intCast(p.j));
    const qi = @as(isize, @intCast(q.i));
    const qj = @as(isize, @intCast(q.j));

    const di = qi - pi;
    const dj = qj - pj;

    var ind: isize = 0;
    while (true) : (ind += 1) {
        const ai = pi - ind * di;
        const aj = pj - ind * dj;
        if (!addIfInBounds(nodes, ai, aj, h, w)) break;
    }

    ind = 0;
    while (true) : (ind += 1) {
        const bi = qi + ind * di;
        const bj = qj + ind * dj;
        if (!addIfInBounds(nodes, bi, bj, h, w)) break;
    }
}

fn addIfInBounds(nodes: *std.bit_set.DynamicBitSetUnmanaged, i: isize, j: isize, h: usize, w: usize) bool {
    const H: isize = @intCast(h);
    const W: isize = @intCast(w);

    if (i >= 0 and j >= 0 and i < H and j < W) {
        const iu: usize = @intCast(i);
        const ju: usize = @intCast(j);
        nodes.set(iu * w + ju);
        return true;
    }
    return false;
}

pub fn readCharLines(
    allocator: std.mem.Allocator,
    path: []const u8,
) !struct { lines: [][]const u8, groups: [][]Point } {
    var data = try std.Io.Dir.cwd().readFileAlloc(app_io.io, path, allocator, .unlimited);
    errdefer allocator.free(data);

    data = input.stripCR(data);

    var map = std.AutoHashMap(u8, std.ArrayListUnmanaged(Point)).init(allocator);

    var linesAL = std.ArrayListUnmanaged([]const u8){};
    errdefer linesAL.deinit(allocator);

    var it = std.mem.splitScalar(u8, data, '\n');

    while (it.next()) |line| {
        if (line.len == 0) continue;
        try linesAL.append(allocator, line);
    }

    const lines = try linesAL.toOwnedSlice(allocator);

    for (lines, 0..) |row, i| {
        for (row, 0..) |ch, j| {
            if (ch == '.') continue;

            const g = try map.getOrPut(ch);

            if (!g.found_existing) {
                g.value_ptr.* = std.ArrayListUnmanaged(Point){};
            }
            try g.value_ptr.append(allocator, .{ .i = i, .j = j });
        }
    }

    var buckets = std.ArrayListUnmanaged([]Point){};
    var it2 = map.iterator();

    while (it2.next()) |entry| {
        try buckets.append(allocator, entry.value_ptr.items);
    }
    return .{ .lines = lines, .groups = try buckets.toOwnedSlice(allocator) };
}

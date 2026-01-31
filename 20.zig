const std = @import("std");
const timed = @import("timed.zig");
const print = std.debug.print;
const inp = @import("input/index.zig");
const maxInt = std.math.maxInt;

const G = inp.Grid(u8);

const cut_threshold = 40;

fn part1(_: std.mem.Allocator) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const input = try inp.readFile(&arena, "20_.txt");

    const gl = try input.gridLines(&arena);
    const vals = try inp.gridFlatten(&arena, gl);

    var grid = G{ .nrows = gl.nrows, .ncols = gl.ncols, .vals = vals };

    const s_idx = try grid.findOrError('S');
    const e_idx = try grid.findOrError('E');

    const alloc = arena.allocator();

    const distS = try inp.bfs4U8(alloc, &grid, '#', s_idx);

    print("found paths from Start \n", .{});

    const distE = try inp.bfs4U8(alloc, &grid, '#', e_idx);

    print("found paths from Finish \n", .{});

    var counter: usize = 0;

    for (0..vals.len) |p1| {
        var it = grid.neighbours_2stepsIndex(p1);
        while (it.next()) |p2| {
            const c1 = grid.coordsI(p1);
            const c2 = grid.coordsI(p2);
            const dr = std.math.absInt(c1[0] - c2[0]) catch unreachable;
            const dc = std.math.absInt(c1[1] - c2[1]) catch unreachable;
            const cheat_len: usize = @intCast(dr + dc);
            // если dist p1 - dist p2 > 102,
            if (distS[p1] < std.math.maxInt(usize) and
                distE[p2] < std.math.maxInt(usize) and
                distS[p1] + distE[p2] + cut_threshold + cheat_len <= distS[e_idx]) counter += 1;
        }
    }

    print("shortest path from S to E is {d}\n", .{distS[e_idx]});

    print("total number of cheats of {d} and more is: {d}\n", .{ cut_threshold, counter });
}

fn part2(_: std.mem.Allocator) !void {}

pub fn solvepart1(allocator: std.mem.Allocator) !void {
    try timed.timed("part1", part1, allocator);
}

pub fn solvepart2(allocator: std.mem.Allocator) !void {
    try timed.timed("part2", part2, allocator);
}

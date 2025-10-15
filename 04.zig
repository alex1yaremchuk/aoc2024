const std = @import("std");
const input = @import("input.zig");
const timed = @import("timed.zig");

const Coord = struct {
    i: i8,
    j: i8,
};

const dirs = [_]Coord{
    Coord{ .i = 1, .j = 0 },
    .{ .i = -1, .j = 0 },
    .{ .i = 0, .j = 1 },
    .{ .i = 0, .j = -1 },
    .{ .i = 1, .j = 1 },
    .{ .i = 1, .j = -1 },
    .{ .i = -1, .j = 1 },
    .{ .i = -1, .j = -1 },
};

fn part1(allocator: std.mem.Allocator) !void {
    const vals = try input.readCharsLineSlices(allocator, "04.txt");
    defer {
        allocator.free(vals.all);
        allocator.free(vals.rows);
    }
    const rows = vals.rows;
    var result: usize = 0;

    for (rows, 0..) |row, i| {
        for (row, 0..) |c, j| {
            if (c != 'X') continue;
            for (dirs) |dir|
                result += checkDir(vals.rows, i, j, dir);
        }
    }

    std.debug.print("{}\n", .{result});
}

pub fn solvepart1(allocator: std.mem.Allocator) !void {
    try timed.timed("part1", part1, allocator);
}

fn part2(allocator: std.mem.Allocator) !void {
    const vals = try input.readCharsLineSlices(allocator, "04.txt");
    defer {
        allocator.free(vals.all);
        allocator.free(vals.rows);
    }
    const rows = vals.rows;
    var result: usize = 0;

    for (rows, 0..) |row, i| {
        for (row, 0..) |c, j| {
            if (c != 'A') continue;
            result += checkMas(vals.rows, i, j);
        }
    }

    std.debug.print("{}\n", .{result});
}

pub fn solvepart2(allocator: std.mem.Allocator) !void {
    try timed.timed("part2", part2, allocator);
}

const lit = "MAS";
const mas: []const u8 = lit[0..3];
fn checkDir(rows: [][]const u8, i: usize, j: usize, dir: Coord) u8 {
    for (mas, 1..) |c, ind_u| {
        const ind: isize = @intCast(ind_u);

        const new_i = @as(isize, @intCast(i)) + @as(isize, dir.i) * ind;
        const new_j = @as(isize, @intCast(j)) + @as(isize, dir.j) * ind;

        if (new_i < 0 or new_i >= rows.len or
            new_j < 0 or new_j >= rows[0].len) return 0;

        const niu: usize = @intCast(new_i);
        const nju: usize = @intCast(new_j);

        if (rows[niu][nju] != c) return 0;
    }
    return 1;
}

fn checkMas(rows: [][]const u8, i: usize, j: usize) u8 {
    const i_1: usize = i -| 1;
    const i_2: usize = i + 1;
    const j1: usize = j -| 1;
    const j2: usize = j + 1;

    if (i == i_1 or i_2 >= rows.len or
        j == j1 or j2 >= rows[0].len) return 0;

    if (rows[i_1][j1] == 'M' and rows[i_2][j2] == 'S' and rows[i_1][j2] == 'M' and rows[i_2][j1] == 'S' or
        rows[i_1][j1] == 'M' and rows[i_2][j2] == 'S' and rows[i_1][j2] == 'S' and rows[i_2][j1] == 'M' or
        rows[i_1][j1] == 'S' and rows[i_2][j2] == 'M' and rows[i_1][j2] == 'M' and rows[i_2][j1] == 'S' or
        rows[i_1][j1] == 'S' and rows[i_2][j2] == 'M' and rows[i_1][j2] == 'S' and rows[i_2][j1] == 'M') return 1;

    return 0;
}

const std = @import("std");
const timed = @import("timed.zig");
const print = std.debug.print;
const inp = @import("input/index.zig");
const Dir = inp.Dir;

fn part1(_: std.mem.Allocator) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const input = try inp.readFile(&arena, "15.txt");

    var gi = input.groups();

    const field_group = gi.next() orelse return error.Format;
    const cmd_group = gi.next() orelse return error.Format;
    if (gi.next() != null) return error.Format; // если хочешь строго 2 группы

    const field_lines = try inp.gridLinesFromSlice(&arena, field_group);
    const G = inp.Grid(u8);

    const field_flat = try inp.gridFlatten(&arena, field_lines);

    var grid = G{ .nrows = field_lines.nrows, .ncols = field_lines.ncols, .vals = field_flat };

    var cmds = cmd_group;
    cmds = inp.stripByteInPlace(cmds, '\n');

    var r_cur: isize = 0;
    var c_cur: isize = 0;

    for (grid.vals, 0..) |val, idx| {
        if (val == '@') {
            const coords = grid.coordsI(idx);
            r_cur = coords[0];
            c_cur = coords[1];
            grid.setI(r_cur, c_cur, '.');
        }
    }

    for (cmds) |cmd| {
        const dir = switch (cmd) {
            '<' => Dir{ 0, -1 },
            '>' => Dir{ 0, 1 },
            '^' => Dir{ -1, 0 },
            'v' => Dir{ 1, 0 },
            else => return error.Internal,
        };
        move(G, &grid, &r_cur, &c_cur, dir[0], dir[1]);
    }

    print(" {d}", .{countPackages(G, &grid)});
}

fn countPackages(comptime G: type, grid: *const G) usize {
    var res: usize = 0;
    for (grid.vals, 0..) |val, idx| {
        if (val == 'O') {
            const coords = grid.coords(idx);
            res += coords[0] * 100 + coords[1];
        }
    }
    return res;
}

fn move(comptime G: type, grid: *G, r: *isize, c: *isize, rmove: isize, cmove: isize) void {
    if (canMove(G, grid, r.*, c.*, rmove, cmove)) {
        r.* += rmove;
        c.* += cmove;
        if (grid.getI(r.*, c.*) == 'O') {
            const r_first = r.*;
            const c_first = c.*;
            var r_last = r_first;
            var c_last = c_first;
            while (grid.getI(r_last, c_last) == 'O') {
                r_last += rmove;
                c_last += cmove;
            }
            grid.setI(r_first, c_first, '.');
            grid.setI(r_last, c_last, 'O');
        }
    }
}

fn canMove(comptime G: type, grid: *const G, r: isize, c: isize, rmove: isize, cmove: isize) bool {
    var cur_r = r + rmove;
    var cur_c = c + cmove;
    while (grid.inBounds(cur_r, cur_c)) {
        const idx = grid.idxI(cur_r, cur_c);
        if (grid.vals[idx] == '#') return false;
        if (grid.vals[idx] == '.') return true;

        cur_r += rmove;
        cur_c += cmove;
    }
    return false;
}

fn part2(_: std.mem.Allocator) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const input = try inp.readFile(&arena, "15.txt");

    var gi = input.groups();

    const field_group = gi.next() orelse return error.Format;
    const cmd_group = gi.next() orelse return error.Format;
    if (gi.next() != null) return error.Format; // если хочешь строго 2 группы

    const field_lines = try inp.gridLinesFromSlice(&arena, field_group);
    const G = inp.Grid(u8);

    const field_flat = try inp.gridFlatten(&arena, field_lines);

    const alloc = arena.allocator();

    const field_dbl = try alloc.alloc(u8, field_flat.len * 2);

    for (field_flat, 0..) |val, idx| {
        switch (val) {
            '.', '#' => {
                field_dbl[2 * idx] = field_flat[idx];
                field_dbl[2 * idx + 1] = field_flat[idx];
            },
            'O' => {
                field_dbl[2 * idx] = '[';
                field_dbl[2 * idx + 1] = ']';
            },
            '@' => {
                field_dbl[2 * idx] = '@';
                field_dbl[2 * idx + 1] = '.';
            },
            else => return error.Internal,
        }
    }

    var grid = G{ .nrows = field_lines.nrows, .ncols = 2 * field_lines.ncols, .vals = field_dbl };

    grid.print();

    var cmds = cmd_group;
    cmds = inp.stripByteInPlace(cmds, '\n');

    var r_cur: isize = 0;
    var c_cur: isize = 0;

    for (grid.vals, 0..) |val, idx| {
        if (val == '@') {
            const coords = grid.coordsI(idx);
            r_cur = coords[0];
            c_cur = coords[1];
            grid.setI(r_cur, c_cur, '.');
        }
    }

    for (cmds) |cmd| {
        const dir = switch (cmd) {
            '<' => Dir{ 0, -1 },
            '>' => Dir{ 0, 1 },
            '^' => Dir{ -1, 0 },
            'v' => Dir{ 1, 0 },
            else => return error.Internal,
        };
        try movePart2(G, &grid, &r_cur, &c_cur, dir[0], dir[1], alloc);
    }

    print("\n", .{});

    grid.print();

    print(" {d}", .{countPackagesPart2(G, &grid)});
}

fn countPackagesPart2(comptime G: type, grid: *const G) usize {
    var res: usize = 0;
    for (grid.vals, 0..) |val, idx| {
        if (val == '[') {
            const coords = grid.coords(idx);

            // const r = @min(coords[0], grid.nrows - 1 - coords[0]);
            // const c = @min(coords[1], grid.ncols - 2 - coords[1]);

            const r = coords[0];
            const c = coords[1];

            print("pack ({d} {d}) has {d} {d}\n", .{ coords[0], coords[1], r, c });

            res += r * 100 + c;
        }
    }
    return res;
}

fn movePart2(
    comptime G: type,
    grid: *G,
    r: *isize,
    c: *isize,
    rmove: isize,
    cmove: isize,
    alloc: std.mem.Allocator,
) !void {
    var visited = try std.DynamicBitSet.initEmpty(alloc, grid.ncols * grid.nrows);
    var toMove: std.ArrayList(usize) = .{};

    try toMove.append(alloc, grid.idxI(r.*, c.*));

    var i: usize = 0;

    while (i < toMove.items.len) : (i += 1) {
        const coords = grid.coordsI(toMove.items[i]);
        const rnext = coords[0] + rmove;
        const cnext = coords[1] + cmove;
        const next_tile = grid.getI(rnext, cnext);
        const next_idx = grid.idxI(rnext, cnext);

        if (visited.isSet(next_idx)) continue;
        if (next_tile == '#') return;

        visited.set(next_idx);

        if (next_tile == '[' or next_tile == ']') {
            try toMove.append(alloc, grid.idxI(rnext, cnext));
            const other = if (next_tile == '[')
                grid.idxI(rnext, cnext + 1)
            else
                grid.idxI(rnext, cnext - 1);
            try toMove.append(alloc, other);
            visited.set(other);
        }
    }

    r.* += rmove;
    c.* += cmove;

    i = toMove.items.len;
    while (i > 0) : (i -= 1) {
        const idx_tomove = toMove.items[i - 1];
        const coords = grid.coordsI(idx_tomove);
        grid.setI(
            coords[0] + rmove,
            coords[1] + cmove,
            grid.getI(coords[0], coords[1]),
        );
        grid.setI(coords[0], coords[1], '.');
    }
}

pub fn solvepart1(allocator: std.mem.Allocator) !void {
    try timed.timed("part1", part1, allocator);
}

pub fn solvepart2(allocator: std.mem.Allocator) !void {
    try timed.timed("part2", part2, allocator);
}

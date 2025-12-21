const std = @import("std");
const timed = @import("timed.zig");
const print = std.debug.print;
const inp = @import("input/index.zig");
const Dir = inp.Dir;

const G = inp.Grid(u8);

const Point = struct {
    grid: *const G,

    r: isize,
    c: isize,
    d: u2,

    cost: usize,

    pub fn next(self: Point, d: u2) !?Point {
        var row = self.r;
        var col = self.c;

        switch (d) {
            0 => col -= 1,
            1 => row -= 1,
            2 => col += 1,
            3 => row += 1,
        }

        if (col < 0 or row < 0 or col >= @as(isize, @intCast(self.grid.ncols)) or row >= @as(isize, @intCast(self.grid.nrows))) return null;

        if (self.grid.getI(row, col) == '#') return null;

        const cost = self.cost + 1 + self.rotation(d) * 1000;

        return Point{ .grid = self.grid, .r = row, .c = col, .d = d, .cost = cost };
    }

    pub fn rotation(self: Point, d: u2) usize {
        var diff: usize = (@as(usize, self.d) + 4 - @as(usize, d)) % 4;
        diff = @min(diff, 4 - diff);
        return diff;
    }

    pub fn forward(self: Point) !?Point {
        return try self.next(self.d);
    }

    pub fn left(self: Point) !?Point {
        return try self.next(self.d -% @as(u2, 1));
    }

    pub fn right(self: Point) !?Point {
        return try self.next(self.d +% @as(u2, 1));
    }

    pub fn back(self: Point) !?Point {
        return try self.next(self.d +% @as(u2, 2));
    }

    pub fn nexts(self: Point) ![4]?Point {
        return [4]?Point{ try self.forward(), try self.left(), try self.right(), try self.back() };
    }

    pub fn idxI(self: Point) usize {
        return @as(usize, @intCast(self.d)) * (self.grid.ncols * self.grid.nrows) + @as(usize, @intCast(self.r)) * self.grid.ncols + @as(usize, @intCast(self.c));
    }

    pub fn idxs(grid: G, r: isize, c: isize) [4]usize {
        return [4]usize{
            0 * (grid.ncols * grid.nrows) + @as(usize, @intCast(r)) * grid.ncols + @as(usize, @intCast(c)),
            1 * (grid.ncols * grid.nrows) + @as(usize, @intCast(r)) * grid.ncols + @as(usize, @intCast(c)),
            2 * (grid.ncols * grid.nrows) + @as(usize, @intCast(r)) * grid.ncols + @as(usize, @intCast(c)),
            3 * (grid.ncols * grid.nrows) + @as(usize, @intCast(r)) * grid.ncols + @as(usize, @intCast(c)),
        };
    }
};

fn lessThan(_: void, a: Point, b: Point) std.math.Order {
    if (a.cost < b.cost) return .gt;
    if (a.cost > b.cost) return .lt;
    return .eq;
}

fn part1(_: std.mem.Allocator) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const input = try inp.readFile(&arena, "16.txt");

    const gl = try input.gridLines(&arena);
    const vals = try inp.gridFlatten(&arena, gl);

    var grid = G{ .nrows = gl.nrows, .ncols = gl.ncols, .vals = vals };

    // найти S и E
    // завести массив dist
    // завести PriorityQueue queue

    // в цикле берем вершину из PriorityQueue (pop - удаляем)
    // проверяем трех соседей - вперед, влево-вперед, вправо-вперед
    // если путь до какого-то лучше сохраненного, то добавляем в dist и в queue

    const s_idx = grid.find('S') orelse return error.Internal;
    const e_idx = grid.find('E') orelse return error.Internal;

    const coords = grid.coordsI(s_idx);

    const alloc = arena.allocator();
    var dist = try alloc.alloc(usize, grid.ncols * grid.nrows * 4);
    for (dist) |*d| {
        d.* = std.math.maxInt(usize);
    }

    var pq = std.PriorityQueue(Point, void, lessThan).init(alloc, {});
    defer pq.deinit();

    const start = Point{
        .grid = &grid,
        .r = coords[0],
        .c = coords[1],
        .cost = 0,
        .d = 2,
    };

    try pq.add(start);

    dist[start.idxI()] = 0;

    while (pq.items.len > 0) {
        if (pq.removeOrNull()) |point| {
            for (try point.nexts()) |next_raw| {
                if (next_raw != null) {
                    var next = next_raw.?;
                    if (grid.idxI(next.r, next.c) == e_idx) {
                        next.d = 0; // reset
                    }

                    const idx = next.idxI();

                    if (dist[idx] > next.cost) {
                        dist[idx] = next.cost;
                        if (grid.idxI(next.r, next.c) != e_idx) {
                            try pq.add(next);
                        }
                    }
                }
            }
        }
    }

    print("cost to end: {d}\n", .{dist[e_idx]});
}

fn part2(_: std.mem.Allocator) !void {}

pub fn solvepart1(allocator: std.mem.Allocator) !void {
    try timed.timed("part1", part1, allocator);
}

pub fn solvepart2(allocator: std.mem.Allocator) !void {
    try timed.timed("part2", part2, allocator);
}

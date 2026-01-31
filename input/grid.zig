const std = @import("std");
const iter = @import("iter.zig");

pub const GridLines = struct {
    rows: [][]const u8,
    nrows: usize,
    ncols: usize,

    pub inline fn at(self: GridLines, r: usize, c: usize) u8 {
        return self.rows[r][c];
    }
};

pub fn gridFlatten(
    arena: *std.heap.ArenaAllocator,
    g: GridLines,
) ![]u8 {
    const alloc = arena.allocator();
    const out = try alloc.alloc(u8, g.nrows * g.ncols);
    var k: usize = 0;

    for (g.rows) |row| {
        @memcpy(out[k .. k + g.ncols], row);
        k += g.ncols;
    }

    return out;
}

pub fn gridDigits(
    arena: *std.heap.ArenaAllocator,
    g: GridLines,
) ![]u8 {
    const alloc = arena.allocator();
    const out = try alloc.alloc(u8, g.nrows * g.ncols);

    var k: usize = 0;
    for (g.rows) |row| {
        for (row) |ch| {
            if (ch < '0' and ch > '9') return error.NorADigit;
            out[k] = ch - '0';
            k += 1;
        }
    }
    return out;
}

pub fn Grid(comptime T: type) type {
    return struct {
        nrows: usize,
        ncols: usize,
        vals: []T,

        const Self = @This();

        pub inline fn idx(self: Self, r: usize, c: usize) usize {
            return r * self.ncols + c;
        }

        pub inline fn idxI(self: Self, r: isize, c: isize) usize {
            return @intCast(r * @as(isize, @intCast(self.ncols)) + c);
        }

        pub inline fn inBounds(self: Self, r: isize, c: isize) bool {
            return r >= 0 and c >= 0 and
                @as(usize, @intCast(r)) < self.nrows and
                @as(usize, @intCast(c)) < self.ncols;
        }

        pub inline fn get(self: Self, r: usize, c: usize) T {
            return self.vals[self.idx(r, c)];
        }

        pub inline fn getI(self: Self, r: isize, c: isize) T {
            return self.vals[self.idxI(r, c)];
        }

        pub inline fn ptr(self: Self, r: usize, c: usize) *T {
            return &self.vals[self.idx(r, c)];
        }

        pub inline fn set(self: Self, r: usize, c: usize, v: T) void {
            self.vals[self.idx(r, c)] = v;
        }

        pub inline fn setI(self: Self, r: isize, c: isize, v: T) void {
            self.vals[self.idxI(r, c)] = v;
        }

        pub inline fn coords(self: Self, ind: usize) [2]usize {
            return .{ ind / self.ncols, ind % self.ncols };
        }

        pub inline fn coordsI(self: Self, ind: usize) [2]isize {
            return .{ @intCast(ind / self.ncols), @intCast(ind % self.ncols) };
        }

        pub inline fn neighbours4(self: *const Self, r: usize, c: usize) Neigh4Iter(Self) {
            return Neigh4Iter(Self).init(self, r, c);
        }

        pub inline fn neighbours4Index(self: *const Self, ind: usize) Neigh4Iter(Self) {
            const rc = self.coords(ind);
            return Neigh4Iter(Self).init(self, rc[0], rc[1]);
        }

        pub inline fn neighbours_2stepsIndex(self: *const Self, ind: usize) Neigh2Steps(Self) {
            const rc = self.coords(ind);
            return Neigh2Steps(Self).init(self, rc[0], rc[1]);
        }

        pub fn print(self: Self) void {
            comptime if (T != u8) @compileError("print is for u8 only");

            for (0..self.nrows) |i| {
                std.debug.print("{s}\n", .{self.vals[i * self.ncols .. (i + 1) * self.ncols]});
            }
        }

        pub fn find(self: Self, to_find: u8) ?usize {
            comptime if (T != u8) @compileError("print is for u8 only");

            for (self.vals, 0..) |val, i| {
                if (val == to_find) return i;
            }
            return null;
        }

        pub fn findOrError(self: Self, to_find: u8) !usize {
            comptime if (T != u8) @compileError("print is for u8 only");
            return self.find(to_find) orelse error.NotFound;
        }
    };
}

pub fn Neigh4Iter(comptime G: type) type {
    return struct {
        g: *const G,
        r: usize,
        c: usize,
        i: u3 = 0,

        const Self = @This();
        const dirs = [_][2]isize{
            .{ -1, 0 },
            .{ 1, 0 },
            .{ 0, -1 },
            .{ 0, 1 },
        };

        pub inline fn init(g: *const G, r: usize, c: usize) Self {
            return .{ .g = g, .r = r, .c = c };
        }

        pub inline fn next(self: *Self) ?usize {
            while (self.i < 4) {
                const d = dirs[self.i];
                self.i += 1;

                const nr: isize = @as(isize, @intCast(self.r)) + d[0];
                const nc: isize = @as(isize, @intCast(self.c)) + d[1];

                if (self.g.inBounds(nr, nc)) {
                    const ur: usize = @intCast(nr);
                    const uc: usize = @intCast(nc);
                    return self.g.idx(ur, uc);
                }
            }
            return null;
        }
    };
}

pub fn Neigh2Steps(comptime G: type) type {
    return struct {
        g: *const G,
        r: usize,
        c: usize,
        i: u4 = 0,

        const Self = @This();
        const dirs = [_][2]isize{
            .{ -2, 0 },
            .{ -1, -1 },
            .{ -1, 1 },

            .{ 0, 2 },
            .{ 0, -2 },

            .{ 2, 0 },
            .{ 1, -1 },
            .{ 1, 1 },
        };

        pub inline fn init(g: *const G, r: usize, c: usize) Self {
            return .{ .g = g, .r = r, .c = c };
        }

        pub inline fn next(self: *Self) ?usize {
            while (self.i < dirs.len) {
                const d = dirs[self.i];
                self.i += 1;

                const nr: isize = @as(isize, @intCast(self.r)) + d[0];
                const nc: isize = @as(isize, @intCast(self.c)) + d[1];

                if (self.g.inBounds(nr, nc)) {
                    const ur: usize = @intCast(nr);
                    const uc: usize = @intCast(nc);
                    return self.g.idx(ur, uc);
                }
            }
            return null;
        }
    };
}

pub fn bfs4U8(
    allocator: std.mem.Allocator,
    g: *const Grid(u8),
    wall: u8,
    start: usize,
) ![]usize {
    var dist = try allocator.alloc(usize, g.vals.len);
    @memset(dist, std.math.maxInt(usize));

    var queue = try std.ArrayList(usize).initCapacity(allocator, g.vals.len);
    defer queue.deinit();

    var head: usize = 0;
    queue.appendAssumeCapacity(start);
    dist[start] = 0;

    while (head < queue.items.len) {
        const cur = queue.items[head];
        head += 1;
        var it = g.neighbours4Index(cur);
        while (it.next()) |next| {
            const rc = g.coordsI(next);
            if (g.getI(rc[0], rc[1]) == wall) continue;
            if (dist[next] > dist[cur] + 1) {
                dist[next] = dist[cur] + 1;
                queue.appendAssumeCapacity(next);
            }
        }
    }

    return dist;
}

pub fn gridLinesFromSlice(
    arena: *std.heap.ArenaAllocator,
    slice: []const u8,
) !GridLines {
    const alloc = arena.allocator();

    var nrows: usize = 0;
    var ncols: usize = 0;
    var it1 = iter.LinesIter.init(slice);
    while (it1.next()) |line| {
        if (ncols == 0) ncols = line.len;
        if (line.len != ncols) return error.NotRectangular;
        nrows += 1;
    }
    if (nrows == 0 or ncols == 0) return error.EmptyGrid;

    const rows = try alloc.alloc([]const u8, nrows);
    var it2 = iter.LinesIter.init(slice);
    var i: usize = 0;
    while (it2.next()) |line| : (i += 1) rows[i] = line;
    if (i != nrows) return error.Internal;

    return .{ .rows = rows, .nrows = nrows, .ncols = ncols };
}

const std = @import("std");
const iter = @import("iter.zig");
const grid = @import("grid.zig");
const util = @import("util.zig");
const app_io = @import("../app_io.zig");

pub const Input = struct {
    buf: []u8,

    pub inline fn bytes(self: Input) []const u8 {
        return self.buf;
    }

    pub inline fn lines(self: Input) iter.LinesIter {
        return iter.LinesIter.init(self.buf);
    }

    pub inline fn linesTrimmed(self: Input) iter.LinesIterTrim {
        return iter.LinesIterTrim.init(self.buf);
    }

    pub fn intsAny(
        self: Input,
        arena: *std.heap.ArenaAllocator,
        comptime T: type,
        delims: []const u8,
    ) ![]T {
        const alloc = arena.allocator();

        var count: usize = 0;
        var it1 = util.tokensAny(self.buf, delims);
        while (it1.next()) |_| count += 1;

        const out = try alloc.alloc(T, count);
        var i: usize = 0;
        var it2 = util.tokensAny(self.buf, delims);
        while (it2.next()) |tok| : (i += 1) {
            out[i] = try std.fmt.parseInt(T, tok, 10);
        }
        return out;
    }

    pub fn intRowsAny(
        self: Input,
        arena: *std.heap.ArenaAllocator,
        comptime T: type,
        delims: []const u8,
    ) !struct { all: []T, rows: [][]T } {
        const alloc = arena.allocator();

        var total: usize = 0;
        var row_count: usize = 0;

        var lines1 = self.linesTrimmed();
        while (lines1.next()) |line| {
            var tok1 = util.tokensAny(line, delims);
            var any: bool = false;
            while (tok1.next()) |_| {
                total += 1;
                any = true;
            }
            if (any) row_count += 1;
        }

        const all = try alloc.alloc(T, total);
        const rows = try alloc.alloc([]T, row_count);

        var idx: usize = 0;
        var r: usize = 0;

        var lines2 = self.linesTrimmed();
        while (lines2.next()) |line| {
            const start = idx;

            var tok2 = util.tokensAny(line, delims);
            while (tok2.next()) |t| : (idx += 1) {
                all[idx] = try std.fmt.parseInt(T, t, 10);
            }

            if (idx != start) {
                rows[r] = all[start..idx];
                r += 1;
            }
        }

        if (idx != total or r != row_count) return error.Internal;

        return .{ .all = all, .rows = rows };
    }

    pub inline fn groups(self: Input) iter.GroupsIter {
        return iter.GroupsIter.init(self.buf);
    }

    pub fn gridLines(self: Input, arena: *std.heap.ArenaAllocator) !grid.GridLines {
        const alloc = arena.allocator();

        var nrows: usize = 0;
        var ncols: usize = 0;

        var it1 = self.lines();
        while (it1.next()) |line| {
            if (ncols == 0) ncols = line.len;
            if (line.len != ncols) return error.NotRectangular;
            nrows += 1;
        }
        if (nrows == 0 or ncols == 0) return error.EmptyGrid;

        const rows = try alloc.alloc([]const u8, nrows);
        var i: usize = 0;

        var it2 = self.lines();
        while (it2.next()) |line| : (i += 1) {
            rows[i] = line;
        }
        if (i != nrows) return error.Internal;

        return .{ .rows = rows, .nrows = nrows, .ncols = ncols };
    }
};

pub fn readFile(arena: *std.heap.ArenaAllocator, path: []const u8) !Input {
    const alloc = arena.allocator();

    var data = try std.Io.Dir.cwd().readFileAlloc(app_io.io, path, alloc, .unlimited);

    var w: usize = 0;
    for (data) |c| {
        if (c != '\r') {
            data[w] = c;
            w += 1;
        }
    }
    data = data[0..w];

    return .{ .buf = data };
}

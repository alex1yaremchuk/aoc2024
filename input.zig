const std = @import("std");
const print = std.debug.print;
const app_io = @import("app_io.zig");

pub const Point = struct {
    row: isize,
    col: isize,

    pub fn add(self: *Point, p: *const Point) *Point {
        self.row += p.row;
        self.col += p.col;
        return self;
    }
};

pub const Dirs = [4]Point{
    Point{ .row = -1, .col = 0 },
    Point{ .row = 1, .col = 0 },
    Point{ .row = 0, .col = 1 },
    Point{ .row = 0, .col = -1 },
};

pub fn readChars(
    allocator: std.mem.Allocator,
    path: []const u8,
) ![]u8 {
    const data = try std.Io.Dir.cwd().readFileAlloc(app_io.io, path, allocator, .unlimited);
    errdefer allocator.free(data);

    return data;
}

pub fn readLinesUnmanaged(
    allocator: std.mem.Allocator,
    path: []const u8,
) !struct {
    lines: std.ArrayListUnmanaged([]const u8),
    buffer: []u8,
} {
    const data = try std.Io.Dir.cwd().readFileAlloc(app_io.io, path, allocator, .unlimited);
    errdefer allocator.free(data);

    var lines = std.ArrayListUnmanaged([]const u8){};
    errdefer lines.deinit(allocator);

    var it = std.mem.splitScalar(u8, data, '\n');

    while (it.next()) |line| {
        if (line.len == 0) continue;
        try lines.append(allocator, line);
    }
    return .{ .lines = lines, .buffer = data };
}

pub fn readTwoColumnsAlloc(
    allocator: std.mem.Allocator,
    path: []const u8,
    comptime T: type,
) !struct { left: []T, right: []T } {
    const data = try std.Io.Dir.cwd().readFileAlloc(app_io.io, path, allocator, .unlimited);
    defer allocator.free(data);

    var n: usize = 0;
    {
        var it = std.mem.splitAny(u8, data, "\n");
        while (it.next()) |raw| {
            const line = std.mem.trim(u8, raw, " \t\r");
            if (line.len != 0) n += 1;
        }
    }

    var left = try allocator.alloc(T, n);
    errdefer allocator.free(left);
    var right = try allocator.alloc(T, n);
    errdefer allocator.free(right);

    var idx: usize = 0;
    var it = std.mem.splitAny(u8, data, "\n");
    while (it.next()) |raw| {
        var line = std.mem.trim(u8, raw, " \t\r");
        if (line.len == 0) continue;

        var tok = std.mem.tokenizeAny(u8, line, " \t");
        const a_str = tok.next() orelse return error.Format;
        const b_str = tok.next() orelse return error.Format;

        left[idx] = try std.fmt.parseInt(T, a_str, 10);
        right[idx] = try std.fmt.parseInt(T, b_str, 10);

        if (tok.next() != null) return error.Format;

        idx += 1;
    }
    return .{ .left = left, .right = right };
}

pub fn readNumbersLineSlices(
    allocator: std.mem.Allocator,
    path: []const u8,
    comptime T: type,
) !struct { all: []T, rows: [][]T } {
    const data = try std.Io.Dir.cwd().readFileAlloc(app_io.io, path, allocator, .unlimited);
    defer allocator.free(data);

    var total_values: usize = 0;
    var line_count: usize = 0;
    {
        var it = std.mem.splitAny(u8, data, "\n");
        while (it.next()) |raw| {
            const line = std.mem.trim(u8, raw, " \t\r");
            if (line.len != 0) line_count += 1;
            var it_item = std.mem.splitAny(u8, line, " \t");
            while (it_item.next()) |item_raw| {
                const item = std.mem.trim(u8, item_raw, " \t\r");
                if (item.len != 0) total_values += 1;
            }
        }
    }

    var all = try allocator.alloc(T, total_values);
    errdefer allocator.free(all);
    var rows = try allocator.alloc([]T, line_count);
    errdefer allocator.free(rows);

    var idx: usize = 0;
    var row_i: usize = 0;

    var it2 = std.mem.splitAny(u8, data, "\n");
    while (it2.next()) |raw| {
        const line = std.mem.trim(u8, raw, " \t\r");
        if (line.len == 0) continue;

        const start_idx = idx;

        var tok = std.mem.tokenizeAny(u8, line, " \t");
        var parsed_any = false;

        while (tok.next()) |t| {
            all[idx] = try std.fmt.parseInt(T, t, 10);
            idx += 1;
            parsed_any = true;
        }

        if (parsed_any) {
            rows[row_i] = all[start_idx..idx];
            row_i += 1;
        }
    }

    if (idx != total_values or row_i != line_count)
        return error.Internal;
    return .{ .all = all, .rows = rows };
}

pub fn readCharsLineSlices(
    allocator: std.mem.Allocator,
    path: []const u8,
) !struct { all: []u8, rows: [][]const u8 } {
    var data = try std.Io.Dir.cwd().readFileAlloc(app_io.io, path, allocator, .unlimited);
    errdefer allocator.free(data);

    var w: usize = 0;
    for (data) |b| {
        if (b != '\r') {
            data[w] = b;
            w += 1;
        }
    }
    data = data[0..w];

    var line_count: usize = 0;
    var it1 = std.mem.splitScalar(u8, data, '\n');
    while (it1.next()) |line_raw| {
        if (line_raw.len != 0) line_count += 1;
    }

    var rows = try allocator.alloc([]const u8, line_count);
    errdefer allocator.free(rows);

    var i: usize = 0;
    var it2 = std.mem.splitScalar(u8, data, '\n');
    while (it2.next()) |line_raw| {
        if (line_raw.len == 0) continue;
        rows[i] = line_raw;
        i += 1;
    }
    return .{ .all = data, .rows = rows };
}

pub fn stripCR(data: []u8) []u8 {
    var w: usize = 0;
    for (data) |c| {
        if (c != '\r') {
            data[w] = c;
            w += 1;
        }
    }
    return data[0..w];
}

pub fn strip(data: []u8, skip: u8) []u8 {
    var w: usize = 0;
    for (data) |c| {
        if (c != skip) {
            data[w] = c;
            w += 1;
        }
    }
    return data[0..w];
}

pub fn parseInt(s: []const u8, T: type) !T {
    return std.fmt.parseUnsigned(T, s, 10);
}

pub fn readCharLines(
    allocator: std.mem.Allocator,
    path: []const u8,
) ![][]const u8 {
    const data = try std.Io.Dir.cwd().readFileAlloc(app_io.io, path, allocator, .unlimited);
    errdefer allocator.free(data);

    data = stripCR(data);

    var lines = std.ArrayListUnmanaged([]const u8){};
    errdefer lines.deinit(allocator);

    var it = std.mem.splitScalar(u8, data, '\n');

    while (it.next()) |line| {
        if (line.len == 0) continue;
        try lines.append(allocator, line);
    }
    return lines.toOwnedSlice(allocator);
}

// ============== 2D digits ========================

const NeighborIter = struct {
    g: *const Grid,
    row: usize,
    col: usize,
    i: u3 = 0, // 0..3

    const dirs = [_][2]i32{ .{ 1, 0 }, .{ -1, 0 }, .{ 0, 1 }, .{ 0, -1 } };

    pub inline fn init(g: *const Grid, r: usize, c: usize) NeighborIter {
        return .{ .g = g, .row = r, .col = c };
    }

    pub inline fn next(self: *NeighborIter) ?usize {
        while (self.i < 4) {
            // std.debug.print("self.i = {}\n", .{self.i});
            const d = dirs[self.i];
            const nr = @as(i32, @intCast(self.row)) + d[0];
            const nc = @as(i32, @intCast(self.col)) + d[1];
            self.i += 1;
            // std.debug.print("self.i after = {}\n", .{self.i});
            if (nc >= 0 and nr >= 0 and nc < self.g.cols and nr < self.g.rows) {
                return self.g.idx(@intCast(nr), @intCast(nc));
            }
        }
        return null;
    }
};

pub const Grid = struct {
    cols: usize,
    rows: usize,
    vals: []u8,

    pub inline fn coords(self: *const Grid, ind: usize) ![2]usize {
        if (ind >= self.cols * self.rows) return error.OutOfBounds;
        const row = ind / self.cols;
        const col = ind % self.cols;

        // print("ind {} rows {} cols {} row {} col {} \n", .{ ind, self.rows, self.cols, row, col });

        return [2]usize{ row, col };
    }

    pub inline fn idx(self: *const Grid, row: usize, col: usize) usize {
        return row * self.cols + col;
    }

    pub inline fn get(self: *const Grid, row: usize, col: usize) u8 {
        return self.vals[self.idx(row, col)];
    }

    pub inline fn neighbors(self: *const Grid, row: usize, col: usize) NeighborIter {
        return NeighborIter.init(self, row, col);
    }

    pub inline fn neighbors_ind(self: *const Grid, ind: usize) NeighborIter {
        const row = ind / self.cols;
        const col = ind % self.cols;
        return NeighborIter.init(self, row, col);
    }
};

pub fn read2D(
    allocator: std.mem.Allocator,
    path: []const u8,
    parseNums: bool,
) !Grid {
    const raw = try std.Io.Dir.cwd().readFileAlloc(app_io.io, path, allocator, .unlimited);
    errdefer allocator.free(raw);

    var data = stripCR(raw);

    const D = try findDimensions(data);

    data = strip(data, '\n');

    const expected = D.cols * D.rows;
    if (data.len != expected) return error.ShapeMismatched;

    if (parseNums) {
        var nums = try allocator.alloc(u8, data.len);

        for (data, 0..) |ch, i| {
            // std.debug.print("[ {} {} ] ", .{ ch, '0' });
            nums[i] = ch - '0';
        }

        return Grid{ .rows = D.rows, .cols = D.cols, .vals = nums };
    } else {
        return Grid{ .rows = D.rows, .cols = D.cols, .vals = data };
    }
}

const Dimensions = struct {
    rows: usize,
    cols: usize,
};

fn findDimensions(data: []u8) !Dimensions {
    var rows: usize = 0;
    var cols: usize = 0;

    var it = std.mem.splitScalar(u8, data, '\n');
    while (it.next()) |line| {
        if (line.len == 0) continue;
        if (cols == 0) cols = line.len;
        if (cols != 0 and cols != line.len) return error.NotRectangular;
        rows += 1;
    }

    return Dimensions{ .rows = rows, .cols = cols };
}
// ============== 2D digits ========================

pub fn readNumbers(
    allocator: std.mem.Allocator,
    path: []const u8,
    comptime T: type,
) ![]T {
    const raw = try std.Io.Dir.cwd().readFileAlloc(app_io.io, path, allocator, .unlimited);
    errdefer allocator.free(raw);
    var data = stripCR(raw);
    data = strip(data, '\n');

    var nums = std.ArrayListUnmanaged(T){};

    var it = std.mem.splitAny(u8, data, " \t");

    while (it.next()) |next| {
        const num = try std.fmt.parseInt(T, next, 10);
        try nums.append(allocator, num);
    }
    return nums.toOwnedSlice(allocator);
}

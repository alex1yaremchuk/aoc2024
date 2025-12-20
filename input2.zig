const std = @import("std");

pub const GridLines = struct {
    rows: [][]const u8,
    nrows: usize,
    ncols: usize,

    pub inline fn at(self: GridLines, r: usize, c: usize) u8 {
        return self.rows[r][c];
    }
};

pub const Input = struct {
    buf: []u8,

    pub inline fn bytes(self: Input) []const u8 {
        return self.buf;
    }

    pub inline fn lines(self: Input) LinesIter {
        return LinesIter.init(self.buf);
    }

    pub inline fn linesTrimmed(self: Input) LinesIterTrim {
        return LinesIterTrim.init(self.buf);
    }

    pub fn intsAny(
        _: Input,
        arena: *std.heap.ArenaAllocator,
        comptime T: type,
        delims: []const u8,
    ) ![]T {
        const alloc = arena.allocator();

        var count: usize = 0;
        var it1 = tokensAny(delims);
        while (it1.next()) |_| count += 1;

        const out = try alloc.alloc(T, count);
        var i: usize = 0;
        var it2 = tokensAny(delims);
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
            var tok1 = self.tokensAny(line, delims);
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

            var tok2 = tokensAny(line, delims);
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

    pub inline fn groups(self: Input) GroupsIter {
        return GroupsIter.init(self.buf);
    }

    pub fn gridLines(self: Input, arena: *std.heap.ArenaAllocator) !GridLines {
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

pub const LinesIter = struct {
    it: std.mem.SplitIterator(u8, .scalar),

    pub inline fn init(buf: []const u8) LinesIter {
        return .{ .it = std.mem.splitScalar(u8, buf, '\n') };
    }

    pub inline fn next(self: *LinesIter) ?[]const u8 {
        while (self.it.next()) |line| {
            if (line.len == 0) continue;
            return line;
        }
        return null;
    }
};

pub const LinesIterTrim = struct {
    base: LinesIter,

    pub inline fn init(buf: []const u8) LinesIterTrim {
        return .{ .base = LinesIter.init(buf) };
    }

    pub inline fn next(self: *LinesIterTrim) ?[]const u8 {
        while (self.base.next()) |line| {
            const t = std.mem.trim(u8, line, " \t");
            if (t.len == 0) continue;
            return t;
        }
        return null;
    }
};

pub const TokensIter = struct {
    it: std.mem.TokenIterator(u8, .any),

    pub inline fn init(buf: []const u8, delims: []const u8) TokensIter {
        return .{ .it = std.mem.tokenizeAny(u8, buf, delims) };
    }

    pub inline fn next(self: *TokensIter) ?[]const u8 {
        return self.it.next();
    }
};

pub const GroupsIter = struct {
    buf: []const u8,
    pos: usize = 0,

    pub inline fn init(buf: []const u8) GroupsIter {
        return .{ .buf = buf, .pos = 0 };
    }

    pub inline fn next(self: *GroupsIter) ?[]const u8 {
        const n = self.buf.len;

        while (self.pos < n and self.buf[self.pos] == '\n') self.pos += 1;
        if (self.pos >= n) return null;

        const start = self.pos;

        while (self.pos + 1 < n) : (self.pos += 1) {
            if (self.buf[self.pos] == '\n' and self.buf[self.pos + 1] == '\n') {
                const end = self.pos;
                while (self.pos < n and self.buf[self.pos] == '\n') self.pos += 1;
                return self.buf[start..end];
            }
        }
        self.pos = n;
        return self.buf[start..n];
    }
};

pub fn readFile(arena: *std.heap.ArenaAllocator, path: []const u8) !Input {
    const alloc = arena.allocator();

    var data = try std.fs.cwd().readFileAlloc(path, alloc, .unlimited);

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

pub inline fn tokensAny(buf: []const u8, delims: []const u8) TokensIter {
    return TokensIter.init(buf, delims);
}

pub inline fn groupLines(group: []const u8) LinesIter {
    return LinesIter.init(group);
}

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
            const rc = self.coods(ind);
            return Neigh4Iter(Self).init(self, rc[0], rc[1]);
        }

        pub fn print(self: Self) void {
            comptime if (T != u8) @compileError("print is for u8 only");

            for (0..self.nrows) |i| {
                std.debug.print("{s}\n", .{self.vals[i * self.ncols .. (i + 1) * self.ncols]});
            }
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

pub fn gridLinesFromSlice(
    arena: *std.heap.ArenaAllocator,
    slice: []const u8,
) !GridLines {
    const alloc = arena.allocator();

    // pass1: count rows/cols + validate rectangular
    var nrows: usize = 0;
    var ncols: usize = 0;
    var it1 = LinesIter.init(slice);
    while (it1.next()) |line| {
        if (ncols == 0) ncols = line.len;
        if (line.len != ncols) return error.NotRectangular;
        nrows += 1;
    }
    if (nrows == 0 or ncols == 0) return error.EmptyGrid;

    // pass2: allocate rows slice and fill
    const rows = try alloc.alloc([]const u8, nrows);
    var it2 = LinesIter.init(slice);
    var i: usize = 0;
    while (it2.next()) |line| : (i += 1) rows[i] = line;
    if (i != nrows) return error.Internal;

    return .{ .rows = rows, .nrows = nrows, .ncols = ncols };
}

pub fn stripByteInPlace(buf: []const u8, skip: u8) []const u8 {
    // NB: если хочешь строго in-place, нужен []u8.
    // Здесь проще: команды можно оставить как слайс и собрать в новый буфер.
    // Но если cmd_group ссылается на Input.buf (а он []u8), можно сделать так:
    var b = @constCast(buf);
    var w: usize = 0;
    for (b) |c| {
        if (c != skip) {
            b[w] = c;
            w += 1;
        }
    }
    return b[0..w];
}

pub const Dir = struct {
    isize,
    isize,
};

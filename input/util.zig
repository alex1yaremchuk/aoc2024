const std = @import("std");
const iter = @import("iter.zig");

pub inline fn tokensAny(buf: []const u8, delims: []const u8) iter.TokensIter {
    return iter.TokensIter.init(buf, delims);
}

pub inline fn groupLines(group: []const u8) iter.LinesIter {
    return iter.LinesIter.init(group);
}

pub fn stringsAny(
    arena: *std.heap.ArenaAllocator,
    buf: []const u8,
    delims: []const u8,
) ![][]const u8 {
    const alloc = arena.allocator();

    var count: usize = 0;
    var it1 = tokensAny(buf, delims);
    while (it1.next()) |_| count += 1;

    const out = try alloc.alloc([]const u8, count);
    var i: usize = 0;
    var it2 = tokensAny(buf, delims);
    while (it2.next()) |tok| : (i += 1) {
        out[i] = tok;
    }
    return out;
}

pub fn stringsAnyTrim(
    arena: *std.heap.ArenaAllocator,
    buf: []const u8,
    delims: []const u8,
    trim_set: []const u8,
) ![][]const u8 {
    const alloc = arena.allocator();

    var count: usize = 0;
    var it1 = tokensAny(buf, delims);
    while (it1.next()) |tok| {
        const t = std.mem.trim(u8, tok, trim_set);
        if (t.len != 0) count += 1;
    }

    const out = try alloc.alloc([]const u8, count);
    var i: usize = 0;
    var it2 = tokensAny(buf, delims);
    while (it2.next()) |tok| {
        const t = std.mem.trim(u8, tok, trim_set);
        if (t.len == 0) continue;
        out[i] = t;
        i += 1;
    }
    return out;
}

pub fn stringsScalarKeepEmpty(
    arena: *std.heap.ArenaAllocator,
    buf: []const u8,
    delim: u8,
) ![][]const u8 {
    const alloc = arena.allocator();

    var count: usize = 0;
    var it1 = std.mem.splitScalar(u8, buf, delim);
    while (it1.next()) |_| count += 1;

    const out = try alloc.alloc([]const u8, count);
    var i: usize = 0;
    var it2 = std.mem.splitScalar(u8, buf, delim);
    while (it2.next()) |part| : (i += 1) {
        out[i] = part;
    }
    return out;
}

pub fn stripByteInPlace(buf: []const u8, skip: u8) []const u8 {
    // In-place removal; mutates the underlying buffer.
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

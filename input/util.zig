const iter = @import("iter.zig");

pub inline fn tokensAny(buf: []const u8, delims: []const u8) iter.TokensIter {
    return iter.TokensIter.init(buf, delims);
}

pub inline fn groupLines(group: []const u8) iter.LinesIter {
    return iter.LinesIter.init(group);
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

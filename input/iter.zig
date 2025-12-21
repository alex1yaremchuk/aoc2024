const std = @import("std");

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

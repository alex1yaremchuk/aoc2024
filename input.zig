const std = @import("std");

pub fn readLinesUnmanaged(
    allocator: std.mem.Allocator,
    path: []const u8,
) !struct {
    lines: std.ArrayListUnmanaged([]const u8),
    buffer: []u8,
} {
    const data = try std.fs.cwd().readFileAlloc(path, allocator, .unlimited);
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
    const data = try std.fs.cwd().readFileAlloc(path, allocator, .unlimited);
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

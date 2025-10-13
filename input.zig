const std = @import("std");

pub fn readChars(
    allocator: std.mem.Allocator,
    path: []const u8,
) ![]u8 {
    const data = try std.fs.cwd().readFileAlloc(path, allocator, .unlimited);
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

pub fn readNumbersLineSlices(
    allocator: std.mem.Allocator,
    path: []const u8,
    comptime T: type,
) !struct { all: []T, rows: [][]T } {
    const data = try std.fs.cwd().readFileAlloc(path, allocator, .unlimited);
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

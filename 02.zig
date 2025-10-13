const std = @import("std");
const input = @import("input.zig");
const timed = @import("timed.zig");

fn part1(allocator: std.mem.Allocator) !void {
    var vals = try input.readNumbersLineSlices(allocator, "02.txt", i8);
    defer {
        allocator.free(vals.all);
        allocator.free(vals.rows);
    }

    var result: u64 = 0;

    for (vals.rows) |row| {
        var ok = true;
        var order: i8 = 0;

        for (row, 0..) |_, i| {
            if (order == 0) {
                order = if (row[i] > row[i + 1]) -1 else 1;
            }
            if (i == (row.len - 1)) break;
            const diff = if (row[i] > row[i + 1]) row[i] - row[i + 1] else row[i + 1] - row[i];

            if (diff < 1 or diff > 3 or (row[i + 1] - row[i]) * order <= 0) {
                // std.debug.print("wrong pair: {} {}\n", .{ row[i], row[i + 1] });
                ok = false;
                break;
            }
        }

        if (ok) {
            for (row, 0..) |v, j| {
                if (j != 0) std.debug.print(" ", .{});
                std.debug.print("{d}", .{v});
            }
            std.debug.print("\n", .{});
        }

        // std.debug.print("{} {} \n", .{ ok, result });

        result += if (ok) 1 else 0;
    }

    std.debug.print("{}\n", .{result});
}

pub fn solvepart1(allocator: std.mem.Allocator) !void {
    try timed.timed("part1", part1, allocator);
}

fn part2(allocator: std.mem.Allocator) !void {
    var vals = try input.readNumbersLineSlices(allocator, "02.txt", i8);
    defer {
        allocator.free(vals.all);
        allocator.free(vals.rows);
    }

    var result: u64 = 0;

    for (vals.rows) |row| {
        const ok = checkSlice(row, null);
        if (ok) {
            for (row, 0..) |v, j| {
                if (j != 0) std.debug.print(" ", .{});
                std.debug.print("{d}", .{v});
            }
            std.debug.print("\n", .{});
        }

        // std.debug.print("{} {} \n", .{ ok, result });

        result += if (ok) 1 else 0;
    }

    std.debug.print("{}\n", .{result});
}

pub fn solvepart2(allocator: std.mem.Allocator) !void {
    try timed.timed("part2", part2, allocator);
}

fn checkSlice(row: []i8, exclude: ?usize) bool {
    var ok = true;
    var order: i8 = 0;
    for (row, 0..) |_, i| {
        if (i == exclude or ((i + 1) == exclude and exclude == (row.len - 1))) continue;
        const next = if (i + 1 == exclude) i + 2 else i + 1;
        if (order == 0) {
            order = if (row[i] > row[next]) -1 else 1;
        }
        if (i == (row.len - 1)) break;
        const diff = if (row[i] > row[next]) row[i] - row[next] else row[next] - row[i];

        if (diff < 1 or diff > 3 or (row[next] - row[i]) * order <= 0) {
            std.debug.print("wrong pair: {} {}\n", .{ row[i], row[next] });
            ok = false;
            if (exclude == null) {
                if (i > 0) {
                    ok = checkSlice(row, i - 1);
                }
                ok = ok or checkSlice(row, i);
                ok = ok or checkSlice(row, i + 1);
            }
            break;
        }
    }
    return ok;
}

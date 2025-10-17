const std = @import("std");
const input = @import("input.zig");
const timed = @import("timed.zig");

fn part1(alloc: std.mem.Allocator) !void {
    var arena_state = std.heap.ArenaAllocator.init(alloc);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const parsed = try input.readCharsLineSlices(arena, "06_.txt");

    const lines = parsed.rows;

    const h = lines.len;
    const w = lines[0].len;

    var visited = try std.bit_set.DynamicBitSetUnmanaged.initEmpty(arena, h * w);

    const start: Point =
        outer: for (lines, 0..) |line, i| {
            for (line, 0..) |char, j| {
                if (char == '^') {
                    break :outer Point{ .row = fromIndex(i), .col = fromIndex(j) };
                }
            }
        } else return error.NoStart;

    setVisited(&visited, start, h);

    var p = start;
    var dir = Dir.Up;

    while (true) {
        const next = p.next(dir);

        if (next.outOfGrid(h, w)) break;

        if (lines[toIndex(next.row)][toIndex(next.col)] != '#') {
            p = next;
            setVisited(&visited, next, h);
            continue;
        } else {
            dir = dir.turnRight();
        }
    }
    std.debug.print("result: {}\n", .{visited.count()});
}

pub fn solvepart1(allocator: std.mem.Allocator) !void {
    try timed.timed("part1", part1, allocator);
}

fn part2(alloc: std.mem.Allocator) !void {
    var arena_state = std.heap.ArenaAllocator.init(alloc);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const parsed = try input.readCharsLineSlices(arena, "06.txt");

    const lines = parsed.rows;

    const h = lines.len;
    const w = lines[0].len;

    var visited = try std.bit_set.DynamicBitSetUnmanaged.initEmpty(arena, h * w);

    const start: Point =
        outer: for (lines, 0..) |line, i| {
            for (line, 0..) |char, j| {
                if (char == '^') {
                    break :outer Point{ .row = fromIndex(i), .col = fromIndex(j) };
                }
            }
        } else return error.NoStart;

    setVisited(&visited, start, h);

    var p = start;
    var dir = Dir.Up;
    var result: usize = 0;

    const visited_cycle = try arena.alloc(u8, h * w);

    while (true) {
        const next = p.next(dir);

        if (next.outOfGrid(h, w)) break;

        if (lines[toIndex(next.row)][toIndex(next.col)] != '#') {
            p = next;
            if (!isSet(visited, next, h)) {
                @memset(visited_cycle, 5);
                result += try isCycle(visited_cycle, start, lines, next);
            }

            setVisited(&visited, next, h);

            continue;
        } else {
            dir = dir.turnRight();
        }
    }
    std.debug.print("result: {}\n", .{result});
}

pub fn solvepart2(allocator: std.mem.Allocator) !void {
    try timed.timed("part2", part2, allocator);
}

const Point = struct {
    row: i16,
    col: i16,

    pub fn next(p: Point, dir: Dir) Point {
        const d = dir.delta();
        return Point{ .row = p.row + d.row, .col = p.col + d.col };
    }

    pub fn outOfGrid(p: Point, h: usize, w: usize) bool {
        return !(p.row >= 0 and p.col >= 0 and
            p.row < fromIndex(h) and
            p.col < fromIndex(w));
    }

    pub fn eql(p: Point, q: Point) bool {
        return p.col == q.col and p.row == q.row;
    }
};

const Dir = enum(u8) {
    Up,
    Right,
    Down,
    Left,

    pub fn delta(dir: Dir) Point {
        return switch (dir) {
            .Up => .{ .row = -1, .col = 0 },
            .Right => .{ .row = 0, .col = 1 },
            .Down => .{ .row = 1, .col = 0 },
            .Left => .{ .row = 0, .col = -1 },
        };
    }

    pub fn turnRight(dir: Dir) Dir {
        // return @enumFromInt((@intFromEnum(dir) + 1) % 4);
        // return .{ .Up = .Right, .Right = .Down, .Down = .Left, .Left = .Up }[dir];

        return switch (dir) {
            .Up => .Right,
            .Right => .Down,
            .Down => .Left,
            .Left => .Up,
        };
    }
};

fn fromIndex(idx: usize) i16 {
    return @as(i16, @intCast(idx));
}

fn toIndex(idx: i16) usize {
    return @as(usize, @intCast(idx));
}

fn isCycle(visited: []u8, start: Point, lines: [][]const u8, change: Point) !usize {
    // lines[toIndex(change.row)][toIndex(change.col)] = '#';

    const h = lines.len;
    const w = lines[0].len;

    if (start.eql(change)) return 0;

    var p = start;

    var dir = Dir.Up;

    setVisitedWithDirection(visited, start, h, dir);

    return while (true) {
        const next = p.next(dir);

        if (next.outOfGrid(h, w)) {
            // std.debug.print("\nresult false: {} {}\n", .{ change.row, change.col });

            break 0;
        }

        if (lines[toIndex(next.row)][toIndex(next.col)] != '#' and
            !next.eql(change))
        {
            p = next;

            if (isSetWithDirection(visited, next, h, @intFromEnum(dir))) {
                // std.debug.print("\nresult true: {} {}\n", .{ change.row, change.col });
                break 1;
            }

            setVisitedWithDirection(visited, next, h, dir);

            continue;
        } else {
            // std.debug.print("4change {} {} ", .{ change.row, change.col });
            dir = dir.turnRight();
        }
    } else 0;
}

fn setVisited(visited: *std.bit_set.DynamicBitSetUnmanaged, p: Point, w: usize) void {
    visited.set(toIndex(p.row) * w + toIndex(p.col));
}

fn isSet(visited: std.bit_set.DynamicBitSetUnmanaged, p: Point, w: usize) bool {
    return visited.isSet(toIndex(p.row) * w + toIndex(p.col));
}

fn setVisitedWithDirection(visited: []u8, p: Point, w: usize, dir: Dir) void {
    visited[toIndex(p.row) * w + toIndex(p.col)] = @intFromEnum(dir);
}

fn isSetWithDirection(visited: []u8, p: Point, w: usize, dir: u8) bool {
    return (dir == visited[toIndex(p.row) * w + toIndex(p.col)]);
}

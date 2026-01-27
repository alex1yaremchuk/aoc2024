const std = @import("std");
const timed = @import("timed.zig");
const print = std.debug.print;
const inp = @import("input/index.zig");
const maxInt = std.math.maxInt;

const side = 71;
const dirs = [4][2]isize{
    [2]isize{ 1, 0 },
    [2]isize{ -1, 0 },
    [2]isize{ 0, 1 },
    [2]isize{ 0, -1 },
};
const size = side * side;
const end = (side - 1) * side + side - 1;
const timeToSolve = 1024;

fn part1(_: std.mem.Allocator) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    // const alloc = arena.alloc();

    const input = try inp.readFile(&arena, "18_.txt");

    const arr = try input.intsAny(&arena, u8, ",\n");
    // defer alloc.free(arr);

    var field: [size]u16 = [_]u16{maxInt(u16)} ** (size);

    for (0..arr.len / 2) |ind| {
        const a: u16 = arr[ind * 2];
        const b: u16 = arr[ind * 2 + 1];
        field[a + b * side] = @intCast(ind + 1);
    }

    print("shortest path for time {d} is {d}\n", .{ timeToSolve, searchPathToExit(timeToSolve, field[0..]) });
}

fn searchPathToExit(time: u16, field: []u16) usize {
    var shortestPaths: [size]u16 = [_]u16{std.math.maxInt(u16)} ** size;
    var toCheck = std.StaticBitSet(size).initEmpty();

    toCheck.set(0);
    shortestPaths[0] = 0;

    while (toCheck.count() > 0) {
        if (toCheck.findFirstSet()) |check| {
            toCheck.unset(check);

            const row: isize = @intCast(check / side);
            const col: isize = @intCast(check % side);
            for (dirs) |dir| {
                if (row + dir[0] < 0 or row + dir[0] >= side or col + dir[1] < 0 or col + dir[1] >= side) continue;
                const new_u: usize = @intCast((row + dir[0]) * side + col + dir[1]);
                if (field[new_u] > time and shortestPaths[new_u] > shortestPaths[check] + 1) {
                    toCheck.set(new_u);
                    shortestPaths[new_u] = shortestPaths[check] + 1;
                }
            }
        }
        // printDebug(time, field, &shortestPaths);
    }

    return if (shortestPaths[end] == maxInt(u16))
        0
    else
        shortestPaths[end];
}

fn printDebug(time: u16, field: []u16, shortest: []u16) void {
    for (0..side) |row| {
        for (0..side) |col| {
            const ind = row * side + col;
            if (field[ind] <= time) {
                print("#", .{});
                continue;
            }
            if (shortest[ind] < maxInt(u16)) {
                print("o", .{});
                continue;
            }
            print(" ", .{});
        }
        print("\n", .{});
    }
    print("\n", .{});
    print("\n", .{});
}

fn part2(_: std.mem.Allocator) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    // const alloc = arena.alloc();

    const input = try inp.readFile(&arena, "18.txt");

    const arr = try input.intsAny(&arena, u8, ",\n");
    // defer alloc.free(arr);

    var field: [size]u16 = [_]u16{maxInt(u16)} ** (size);

    for (0..arr.len / 2) |ind| {
        const a: u16 = arr[ind * 2];
        const b: u16 = arr[ind * 2 + 1];
        field[a + b * side] = @intCast(ind + 1);
    }

    var min: u16 = 0;
    var max: u16 = @intCast(arr.len / 2);
    while (max - min > 0) {
        const check = (max + min) / 2;
        // print("from {d} to {d}  | check {d} \n", .{ min, max, check });
        if (searchPathToExit(check, &field) > 0)
            min = check + 1
        else
            max = check;
    }

    print("result is {d},{d}\n", .{ arr[(min - 1) * 2], arr[(min - 1) * 2 + 1] });
}

pub fn solvepart1(allocator: std.mem.Allocator) !void {
    try timed.timed("part1", part1, allocator);
}

pub fn solvepart2(allocator: std.mem.Allocator) !void {
    try timed.timed("part2", part2, allocator);
}
